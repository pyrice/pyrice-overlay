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
    # Every external tool rebar.sh calls must be pulled into the initramfs -- the
    # pre-udev environment is minimal and ships almost nothing by default. Listing
    # only setpci+lspci was the bug: sort/dirname/basename/find were absent, so the
    # detection pipe "lspci ... | cut | sort -u" produced nothing (sort not found)
    # and the hook logged "no Intel GPU found" and did nothing.
    inst_multiple setpci lspci sort cut sed grep head readlink dirname basename \
        find printf sleep ls

    # The pre-udev hook runs BEFORE udev starts, and therefore before xe is
    # autoloaded and binds the GPU. That ordering is the whole point: the BAR
    # size has to be set before the driver sees the card.
    inst_hook pre-udev 90 "$moddir/rebar.sh"
}
