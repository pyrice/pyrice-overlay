# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Dracut module enabling Resizable BAR on Intel Arc dGPUs from the initramfs"
HOMEPAGE="https://github.com/pyrice/supermicro-rebar"

# The module is two small shell scripts carried in FILESDIR; nothing to fetch.
S="${WORKDIR}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

# setpci/lspci (pciutils) are pulled into the initramfs by module-setup.sh and run
# by the boot-time hook, and dracut itself rebuilds the initramfs on the target
# machine -- both are runtime, not build-time, dependencies.
RDEPEND="
	sys-apps/pciutils
	sys-kernel/dracut
"

src_install() {
	exeinto /usr/lib/dracut/modules.d/91rebar
	doexe "${FILESDIR}"/module-setup.sh
	doexe "${FILESDIR}"/rebar.sh

	insinto /etc/dracut.conf.d
	doins "${FILESDIR}"/95-rebar.conf
}

pkg_postinst() {
	elog "The 'rebar' dracut module is installed and enabled via"
	elog "/etc/dracut.conf.d/95-rebar.conf. It takes effect only after the"
	elog "initramfs (and, on this machine, the Unified Kernel Image) are rebuilt."
	elog
	elog "This ebuild does NOT regenerate the UKI. To activate the change:"
	elog
	elog "    cd /usr/src/linux && make install"
	elog "    cp /boot/efi/EFI/Linux/gentoo-x86_64.efi /boot/efi/EFI/BOOT/BOOTX64.EFI"
	elog
	elog "Verify after reboot with:  lspci -vv -s <gpu> | grep -i 'BAR.*size'"
	elog "The hook is fault-tolerant and always exits 0, so it cannot break boot;"
	elog "it also skips any PCI subtree that contains storage, as a safety guard."
}
