# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop wrapper

DESCRIPTION="JetBrains IDE for Rust Developers"
HOMEPAGE="https://www.jetbrains.com/rust/"
SRC_URI="https://download.jetbrains.com/rust/RustRover-${PV}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="bindist mirror splitdebug"

BDEPEND="dev-util/patchelf"

RDEPEND="
	>=app-accessibility/at-spi2-core-2.46.0:2
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	dev-libs/wayland
	dev-util/cmake
	dev-util/ninja
	media-libs/alsa-lib
	media-libs/freetype:2
	media-libs/mesa
	net-print/cups
	sys-apps/dbus
	sys-devel/clang
	sys-devel/gdb
	sys-libs/zlib
	x11-libs/cairo
	x11-libs/libdrm
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXi
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libXtst
	x11-libs/libXxf86vm
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/pango"

QA_PREBUILT="opt/${PN}/*"

src_prepare() {
	default

	local remove_me=(
		help/ReferenceCardForMac.pdf
		bin/cmake
		bin/gdb/linux
		bin/lldb/linux
		bin/ninja
		license/CMake*
		plugins/cwm-plugin/quiche-native/darwin-aarch64
		plugins/cwm-plugin/quiche-native/darwin-x86-64
		plugins/cwm-plugin/quiche-native/linux-aarch64
		plugins/cwm-plugin/quiche-native/win32-x86-64
		plugins/remote-dev-server/selfcontained
	)

	rm -rv "${remove_me[@]}" || die

	for file in "jbr/lib/{libjcef.so,jcef_helper}"
	do
		if [[ -f "${file}" ]]; then
			patchelf --set-rpath '$ORIGIN' "${file}" || die
		fi
	done
}

src_install() {
	local dir="/opt/${PN}"

	insinto "${dir}"
	doins -r *
	fperms 755 "${dir}"/bin/{clion.sh,fsnotifier,inspect.sh,ltedit.sh,repair,restart.py,clang/linux/x64/{clangd,clang-tidy,clazy-standalone,llvm-symbolizer}}

	if [[ -d jbr ]]; then
		fperms 755 "${dir}"/jbr/bin/{java,javac,jdb,jrunscript,keytool,rmiregistry,serialver}
		# Fix #763582
		fperms 755 "${dir}"/jbr/lib/{chrome-sandbox,jcef_helper,jexec,jspawnhelper}
	fi

	dosym -r "${EPREFIX}/usr/bin/ninja" "${dir}"/bin/ninja/linux/x64/ninja

	make_wrapper "${PN}" "${dir}/bin/${PN}.sh"
	newicon "bin/${PN}.svg" "${PN}.svg"
	make_desktop_entry "${PN}" "CLion" "${PN}" "Development;IDE;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	insinto /usr/lib/sysctl.d
	newins - 30-"${PN}"-inotify-watches.conf <<<"fs.inotify.max_user_watches = 524288"
}
