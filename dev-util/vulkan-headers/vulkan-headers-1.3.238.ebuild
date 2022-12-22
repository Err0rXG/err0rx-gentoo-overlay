# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
EAPI=8

MY_PN=Vulkan-Headers
inherit cmake

SRC_URI="https://github.com/KhronosGroup/${MY_PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
KEYWORDS="amd64 arm arm64 ~loong ppc ppc64 ~riscv x86"
S="${WORKDIR}"/${MY_PN}-v${PV}

DESCRIPTION="Vulkan Header files and API registry"
HOMEPAGE="https://github.com/KhronosGroup/Vulkan-Headers"

LICENSE="Apache-2.0"
SLOT="0"

BDEPEND=">=dev-util/cmake-3.10.2"
