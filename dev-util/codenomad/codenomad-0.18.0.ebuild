# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg

DESCRIPTION="Desktop GUI client and server for AI coding assistants"
HOMEPAGE="https://github.com/NeuralNomadsAI/CodeNomad"
BASE_URI="https://github.com/NeuralNomadsAI/CodeNomad/releases/download/v${PV}"
SRC_URI="
	amd64? (
		tauri? (
			${BASE_URI}/CodeNomad-Tauri-linux-x64-${PV}.AppImage -> ${P}-tauri-amd64.AppImage
		)
		!tauri? (
			${BASE_URI}/CodeNomad-Electron-linux-x64-${PV}.zip -> ${P}-electron-amd64.zip
		)
	)
"

S="${WORKDIR}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+tauri"

RESTRICT="bindist mirror"

RDEPEND="
	net-libs/nodejs
	tauri? (
		dev-libs/glib:2
		media-libs/libpng:=
		net-libs/libsoup:3.0
		net-libs/webkit-gtk:4.1
		x11-libs/gtk+:3
	)
	!tauri? (
		app-accessibility/at-spi2-core
		app-crypt/libsecret
		dev-libs/nspr
		dev-libs/nss
		media-libs/alsa-lib
		media-libs/fontconfig
		media-libs/freetype
		media-libs/mesa
		net-print/cups
		sys-apps/dbus
		sys-apps/util-linux
		x11-libs/cairo
		x11-libs/gtk+:3
		x11-libs/libX11
		x11-libs/libXcomposite
		x11-libs/libXcursor
		x11-libs/libXdamage
		x11-libs/libXext
		x11-libs/libXfixes
		x11-libs/libXrandr
		x11-libs/libXrender
		x11-libs/libxcb
		x11-libs/libxkbcommon
		x11-libs/pango
	)
"
BDEPEND="
	!tauri? ( app-arch/unzip )
"

QA_PREBUILT="opt/codenomad/* usr/bin/codenomad"

src_unpack() {
	if use tauri; then
		cp "${DISTDIR}/${P}-tauri-amd64.AppImage" "${WORKDIR}/${P}-tauri-amd64.AppImage" || die "cp failed"
		chmod +x "${WORKDIR}/${P}-tauri-amd64.AppImage" || die "chmod failed"
		"${WORKDIR}/${P}-tauri-amd64.AppImage" --appimage-extract >/dev/null || die "failed to extract appimage"
	else
		default
	fi
}

src_compile() {
	:
}

src_install() {
	if use tauri; then
		local dest="/opt/${PN}"

		insinto "${dest}"
		doins squashfs-root/usr/bin/codenomad-tauri
		mv "${ED}/${dest}/codenomad-tauri" "${ED}/${dest}/codenomad" || die "mv failed"
		fperms +x "${dest}/codenomad"

		doins -r squashfs-root/usr/lib/CodeNomad/resources

		dosym "../../opt/${PN}/codenomad" "/usr/bin/codenomad"

		if [[ -f "squashfs-root/CodeNomad.png" ]]; then
			newicon -s 512 "squashfs-root/CodeNomad.png" "${PN}.png"
		elif [[ -f "squashfs-root/codenomad-tauri.png" ]]; then
			newicon -s 512 "squashfs-root/codenomad-tauri.png" "${PN}.png"
		elif [[ -f "resources/icon.png" ]]; then
			newicon -s 512 "resources/icon.png" "${PN}.png"
		fi
		make_desktop_entry "${PN}" "CodeNomad" "${PN}" "Development;IDE;"
	else
		local dest="/opt/${PN}"

		insinto "${dest}"
		doins -r .

		if [[ -f "${ED}/${dest}/@neuralnomadscodenomad-electron-app" ]]; then
			mv "${ED}/${dest}/@neuralnomadscodenomad-electron-app" "${ED}/${dest}/codenomad" || die "mv failed"
		fi

		fperms +x "${dest}/codenomad"
		dosym "../../opt/${PN}/codenomad" "/usr/bin/codenomad"

		if [[ -f "${ED}/${dest}/chrome-sandbox" ]]; then
			fperms 4755 "${dest}/chrome-sandbox"
		fi
		if [[ -f "${ED}/${dest}/chrome_crashpad_handler" ]]; then
			fperms +x "${dest}/chrome_crashpad_handler"
		fi

		local lib
		for lib in "${ED}/${dest}"/lib*.so*; do
			if [[ -f ${lib} ]]; then
				fperms +x "${dest}/${lib##*/}"
			fi
		done

		if [[ -f "resources/icon.png" ]]; then
			newicon -s 512 "resources/icon.png" "${PN}.png"
		fi
		make_desktop_entry "${PN}" "CodeNomad" "${PN}" "Development;IDE;"
	fi

	dodir "/opt/codenomad/resources/node/linux-x64/bin"
	rm -f "${ED}/opt/codenomad/resources/node/linux-x64/bin/node" || die
	dosym "../../../../../../usr/bin/node" "/opt/codenomad/resources/node/linux-x64/bin/node"
}
