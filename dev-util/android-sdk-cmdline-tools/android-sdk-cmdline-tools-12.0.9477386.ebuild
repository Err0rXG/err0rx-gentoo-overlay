# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
EAPI=8

MY_PV=${PV//${PV%.*}./}

DESCRIPTION="Android SDK Command-line Tools"
HOMEPAGE="https://developer.android.com/studio/command-line"

SRC_URI="https://dl.google.com/android/repository/commandlinetools-linux-${MY_PV}_latest.zip -> ${P}.zip"
KEYWORDS="~amd64"

SLOT="0"
LICENSE="Apache-2.0"

RDEPEND="
    app-shells/bash
    net-misc/curl
    dev-vcs/git
    sys-apps/coreutils
    app-arch/unzip
    app-arch/xz-utils
    app-arch/zip
"
BDEPEND="${RDEPEND}"
DEPEND="${RDEPEND}"
S="${WORKDIR}/${PN//android-sdk-/}"

src_install() {
    insinto /opt/android-sdk/cmdline-tools/
    doins -r bin
    doins -r lib

    # bins
    chmod +x ${D}/opt/android-sdk/cmdline-tools/*

    # docs
    dodoc source.properties NOTICE.txt

    # environment
    doenvd ${FILESDIR}/99${PN}
}
