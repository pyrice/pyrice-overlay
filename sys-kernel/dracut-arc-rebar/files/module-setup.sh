#!/bin/bash
# dracut module: enables Resizable BAR on Intel discrete GPUs before xe is loaded.
# This is the gist's initramfs-tools solution ported to dracut.

check() {
    # 0 = this module can be used.
    return 0
}

depends() {
    return 0
}

install() {
    # Binaries required by the hook script.
    inst_multiple setpci lspci

    # The pre-udev hook runs BEFORE udev starts, and therefore before xe is
    # autoloaded and binds the GPU. That ordering is the whole point: the BAR
    # size has to be set before the driver sees the card.
    inst_hook pre-udev 90 "$moddir/rebar.sh"
}
