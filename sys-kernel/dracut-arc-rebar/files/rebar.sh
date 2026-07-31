#!/bin/sh
# Resizable BAR for Intel discrete GPUs (Arc A-series / B-series and later).
# Runs from the initramfs (pre-udev hook), BEFORE xe/i915 is loaded.
#
# Method: write the size field of the card's Resizable BAR control register, then
# remove the root port and rescan the PCI tree. This makes the kernel assign every
# bridge window from scratch with the large BAR requirement already known, instead
# of trying to grow an already-assigned window (which fails when the card sits
# behind a PCIe switch that pins the window with its own BAR).
#
# GENERIC: hardcodes neither device ID nor size. Finds every Intel dGPU exposing a
# Resizable BAR capability and sets each one to its largest supported size, so it
# works unchanged for B580, A770 (8/16GB), A750 and future cards.
#
# MUST NEVER break boot: everything is fault tolerant and it always exits 0.

log() { echo "rebar: $*" > /dev/kmsg 2>/dev/null || true; }

# Convert a size string ("16GB") to N, where size = 2^N MB (the register encoding).
size_to_n() {
    num=$(echo "$1" | sed 's/[A-Za-z]*$//')
    unit=$(echo "$1" | sed 's/^[0-9]*//')
    case "$unit" in
        MB|M) mb=$num ;;
        GB|G) mb=$((num * 1024)) ;;
        TB|T) mb=$((num * 1024 * 1024)) ;;
        *) return 1 ;;
    esac
    [ -z "$mb" ] && return 1
    n=0; x=1
    while [ "$x" -lt "$mb" ]; do x=$((x * 2)); n=$((n + 1)); done
    echo "$n"
}

# --- find candidates: Intel VGA (0300) and Display (0380) controllers -------
CANDIDATES=$(
    { lspci -D -d 8086::0300 2>/dev/null; lspci -D -d 8086::0380 2>/dev/null; } \
    | cut -d' ' -f1 | sort -u
)
[ -z "$CANDIDATES" ] && { log "no Intel GPU found"; exit 0; }

for GPU in $CANDIDATES; do
    # Does the card expose a Resizable BAR capability? If not it is uninteresting
    # (an integrated GPU, for example).
    REBARLINE=$(lspci -vv -s "$GPU" 2>/dev/null \
        | grep -oE 'BAR [0-9]+: current size: [^,]+, supported: .*' | head -1)
    [ -z "$REBARLINE" ] && continue

    CUR=$(echo "$REBARLINE" | sed -E 's/.*current size: ([^,]+),.*/\1/')
    SUP=$(echo "$REBARLINE" | sed -E 's/.*supported: //')
    BARIDX=$(echo "$REBARLINE" | sed -E 's/^BAR ([0-9]+):.*/\1/')

    # Pick the largest supported size.
    BEST=""; BESTN=0
    for s in $SUP; do
        n=$(size_to_n "$s") || continue
        [ "$n" -gt "$BESTN" ] && { BESTN=$n; BEST=$s; }
    done
    [ -z "$BEST" ] && continue

    CURN=$(size_to_n "$CUR")
    if [ "$CURN" -ge "$BESTN" ]; then
        log "$GPU already at $CUR (max), skipping"
        continue
    fi

    # --- walk up to the root port ------------------------------------------
    dev=$(readlink -f "/sys/bus/pci/devices/$GPU" 2>/dev/null)
    [ -z "$dev" ] && continue
    parent=$(dirname "$dev")
    while :; do
        case "$(basename "$parent")" in
            pci0000:*) break ;;
            "" | "/") dev=""; break ;;
        esac
        dev="$parent"; parent=$(dirname "$dev")
    done
    [ -z "$dev" ] && { log "$GPU: no root port found"; continue; }
    PORT=$(basename "$dev")

    # --- safety guard: never touch a subtree that contains storage ---------
    if find "/sys/bus/pci/devices/$PORT/" -maxdepth 6 \
            \( -name 'nvme*' -o -name 'host*' -o -name 'block' \) 2>/dev/null | grep -q .; then
        log "$GPU: STORAGE present under $PORT - skipping for safety"
        continue
    fi

    log "$GPU (BAR$BARIDX) $CUR -> $BEST (N=$BESTN) via root port $PORT"

    # --- unbind any drivers in the subtree (normally none at pre-udev) -----
    for d in $(ls "/sys/bus/pci/devices/$PORT" 2>/dev/null | grep '^0000:'); do
        [ -e "/sys/bus/pci/devices/$d/driver/unbind" ] \
            && echo "$d" > "/sys/bus/pci/devices/$d/driver/unbind" 2>/dev/null || true
    done

    # --- write the control register ----------------------------------------
    # Spec: Resizable BAR Control Register bits [13:8] hold the BAR size, where
    # the size is 2^N MB. Memory decoding must be disabled before changing it.
    setpci -s "$GPU" COMMAND=0000 2>/dev/null || true
    old=$(setpci -s "$GPU" ECAP_REBAR+0x08.l 2>/dev/null)
    [ -z "$old" ] && { log "$GPU: could not read the REBAR register"; continue; }
    new=$(printf '%08x' $(( (0x$old & 0xFFFFC0FF) | (BESTN << 8) )) 2>/dev/null)
    setpci -s "$GPU" ECAP_REBAR+0x08.l=$new 2>/dev/null || true
    chk=$(setpci -s "$GPU" ECAP_REBAR+0x08.l 2>/dev/null)
    log "$GPU: REBAR 0x$old -> 0x$chk"

    # --- re-enumerate the PCI tree ------------------------------------------
    echo 1 > "/sys/bus/pci/devices/$PORT/remove" 2>/dev/null || true
    sleep 1
    echo 1 > /sys/bus/pci/rescan 2>/dev/null || true
    sleep 1

    if lspci -vv -s "$GPU" 2>/dev/null | grep -q "size=${BEST%B}"; then
        log "$GPU: OK, BAR$BARIDX = $BEST"
    else
        log "$GPU: BAR did not become $BEST (the system still boots normally)"
    fi
done

exit 0
