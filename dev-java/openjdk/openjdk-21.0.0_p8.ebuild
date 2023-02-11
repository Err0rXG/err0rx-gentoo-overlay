# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit check-reqs flag-o-matic java-pkg-2 java-vm-2 multiprocessing toolchain-funcs

# Variable Name Format: <UPPERCASE_KEYWORD>_BOOT
X86_BOOT="jdk${SLOT}-x86"
ARM64_BOOT="jdk20-arm64"
PPC64_BOOT="jdk20-ppc64"
RISCV_BOOT="jdk20-riscv"

#JAVA
javaselc() {
      local flags="$1"
      for flag in $flags; do
            flag_name=${flag##*_}
            flag_values=${!flag}
            values=""
            for value in $flag_values; do
                  if [[ ${value:0:1} == "+" ]]; then
                        if [ "$flag_name" == "MISC" ]; then
                              values+="--enable-${value:1}=yes\n"
                        else
                              values+=${value:1}","
                        fi
                  else
                        values+="--enable-${value:1}=no\n"
                  fi
            done
            if [ -n "$values" ]; then
                  values=${values::-1}
                  if [ "$flag_name" == "MISC" ]; then
                        myconf+=( "${values}" )
                  else
                        myconf+=( --with-jvm-"${flag_name}"="${values}" )
                  fi
            fi
      done
}


JAVA_VARIANTS="+server client minimal core zero"
JAVA_GC="+epsilongc +g1gc +parallelgc +serialgc +shenandoahgc +zgc"
JAVA_FEATURES="+cds +compiler1 +compiler2 +jfr +jni-check jvmci jvmti +javac-server static-build management vm-structs systemtap"
JAVA_MISC="openjdk-only linktime-gc native-coverage branch-protection hsdis-bundling libffi-bundling generate-classlist cds-archive compatible-cds-alignment"

JAVA_FLAGS="JAVA_VARIANTS JAVA_GC JAVA_FEATURES JAVA_MISC"

MY_PV="${PV%%.*}+${PV##*_p}"
MY_EXT="${PV%%.*}-${PV##*_p}"
MY_PAT="${PV##*_p}"
SLOT="${PV%%.*}"

DESCRIPTION="Open source implementation of the Java programming language"
HOMEPAGE="https://openjdk.org"
SRC_URI="
	https://github.com/openjdk/jdk/archive/refs/tags/jdk-${MY_PV}.tar.gz
		-> ${P}.tar.gz
	!system-bootstrap? (
		amd64? ( https://download.java.net/java/early_access/jdk${SLOT}/${MY_PAT}/GPL/openjdk-${SLOT}-ea+${MY_PAT}_linux-x64_bin.tar.gz -> jdk${SLOT}-amd64.tar.gz )
		x86? ( https://download.java.net/java/early_access/jdk${SLOT}/${MY_PAT}/GPL/openjdk-${SLOT}-ea+${MY_PAT}_linux-x64_bin.tar.gz -> jdk${SLOT}-x86.tar.gz )
		arm64? ( https://github.com/adoptium/temurin20-binaries/releases/download/jdk20-2023-02-08-12-00-beta/OpenJDK20U-jdk_aarch64_linux_hotspot_2023-02-08-12-00.tar.gz -> jdk20-arm64.tar.gz )
		ppc64? ( https://github.com/adoptium/temurin20-binaries/releases/download/jdk20-2023-02-08-12-00-beta/OpenJDK20U-jdk_ppc64le_linux_hotspot_2023-02-08-12-00.tar.gz -> jdk20-ppc64.tar.gz )
		riscv? ( https://github.com/adoptium/temurin20-binaries/releases/download/jdk20-2023-02-08-12-00-beta/OpenJDK20U-jdk_riscv64_linux_hotspot_2023-02-08-12-00.tar.gz -> jdk20-riscv.tar.gz )
	)
"

LICENSE="GPL-2-with-classpath-exception"
KEYWORDS="~amd64 ~arm ~arm64 ~ppc64 ~riscv ~x86"

IUSE="alsa cups examples headless-awt javafx selinux source"
# Java Docs
IUSE+=" man doc"
# Variants
IUSE+=" ${JAVA_VARIANTS}"
# Compilation With Optimization
IUSE+=" clang lto opt-size services +jbootstrap precompiled-headers ccache system-bootstrap icecream debug"
# Java Features
IUSE+=" ${JAVA_FEATURES}"
# Garbage Collectors
IUSE+=" ${JAVA_GC}"
# Java Sanitizer
IUSE+=" asan ubsan"
# Java Misc
IUSE+=" ${JAVA_MISC}"

REQUIRED_USE="
        javafx? ( alsa !headless-awt )
        !system-bootstrap? ( jbootstrap )

	cds? ( !minimal !core )
	generate-classlist? ( cds )
	cds-archive? ( cds )
	compatible-cds-alignment? ( cds )
"

COMMON_DEPEND="
	media-libs/freetype:2=
	media-libs/giflib:0/7
	media-libs/harfbuzz:=
	media-libs/libpng:0=
	media-libs/lcms:2=
	sys-libs/zlib
	media-libs/libjpeg-turbo:0=
	systemtap? ( dev-util/systemtap )
	clang? ( >=sys-devel/clang-14.0.6-r1 )
"

# Many libs are required to build, but not to run, make is possible to remove
# by listing conditionally in RDEPEND unconditionally in DEPEND
RDEPEND="
	${COMMON_DEPEND}
	>=sys-apps/baselayout-java-0.1.0-r1
	!headless-awt? (
		x11-libs/libX11
		x11-libs/libXext
		x11-libs/libXi
		x11-libs/libXrandr
		x11-libs/libXrender
		x11-libs/libXt
		x11-libs/libXtst
	)
	alsa? ( media-libs/alsa-lib )
	cups? ( net-print/cups )
	selinux? ( sec-policy/selinux-java )
"

DEPEND="
	${COMMON_DEPEND}
	app-arch/zip
	media-libs/alsa-lib
	net-print/cups
	x11-base/xorg-proto
	x11-libs/libX11
	x11-libs/libXext
	x11-libs/libXi
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libXt
	x11-libs/libXtst
	javafx? ( dev-java/openjfx:${SLOT}= )
	ccache? ( dev-util/ccache )
	doc? (
		app-text/pandoc
		media-gfx/graphviz
	)
	system-bootstrap? (
		|| (
			dev-java/openjdk-bin:${SLOT}
			dev-java/openjdk:${SLOT}
		)
	)
"

S="${WORKDIR}/jdk-jdk-${MY_EXT}"

# The space required to build varies wildly depending on USE flags,
# ranging from 2GB to 16GB. This function is certainly not exact but
# should be close enough to be useful.
openjdk_check_requirements() {
	local M
	M=2048
	M=$(($(usex jbootstrap 2 1) * $M))
	M=$(($(usex debug 3 1) * $M))
	M=$(($(usex doc 320 0) + $(usex source 128 0) + 192 + $M))

	CHECKREQS_DISK_BUILD=${M}M check-reqs_pkg_${EBUILD_PHASE}
}


pkg_pretend() {
	openjdk_check_requirements
	if [[ ${MERGE_TYPE} != binary ]]; then
		has ccache ${FEATURES} && die "FEATURES=ccache doesn't work with ${PN}, bug #677876"
	fi
}

pkg_setup() {
	openjdk_check_requirements
	java-vm-2_pkg_setup

	[[ ${MERGE_TYPE} == "binary" ]] && return

	JAVA_PKG_WANT_BUILD_VM="openjdk-${SLOT} openjdk-bin-${SLOT}"
	JAVA_PKG_WANT_SOURCE="${SLOT}"
	JAVA_PKG_WANT_TARGET="${SLOT}"

	# The nastiness below is necessary while the gentoo-vm USE flag is
	# masked. First we call java-pkg-2_pkg_setup if it looks like the
	# flag was unmasked against one of the possible build VMs. If not,
	# we try finding one of them in their expected locations. This would
	# have been slightly less messy if openjdk-bin had been installed to
	# /opt/${PN}-${SLOT} or if there was a mechanism to install a VM env
	# file but disable it so that it would not normally be selectable.

	local vm
	for vm in ${JAVA_PKG_WANT_BUILD_VM}; do
		if [[ -d ${BROOT}/usr/lib/jvm/${vm} ]]; then
			java-pkg-2_pkg_setup
			return
		fi
	done
}

src_prepare() {
	use riscv && eapply "${DISTDIR}"/java17-riscv64.patch
	default
	chmod +x configure || die
}

src_configure() {
	if has_version dev-java/openjdk:${SLOT}; then
		export JDK_HOME=${BROOT}/usr/$(get_libdir)/openjdk-${SLOT}
	elif use !system-bootstrap ; then
		local bootvar="${ARCH^^}_BOOT"
		export JDK_HOME="${WORKDIR}/${!bootvar}"
	else
		JDK_HOME=$(best_version -b dev-java/openjdk-bin:${SLOT})
		[[ -n ${JDK_HOME} ]] || die "Build VM not found!"
		JDK_HOME=${JDK_HOME#*/}
		JDK_HOME=${BROOT}/opt/${JDK_HOME%-r*}
		export JDK_HOME
	fi

	# Work around stack alignment issue, bug #647954. in case we ever have x86
	use x86 && append-flags -mincoming-stack-boundary=2

	# Work around -fno-common ( GCC10 default ), bug #713180
	append-flags -fcommon

	# Strip some flags users may set, but should not. #818502
	filter-flags -fexceptions

	# Flags To Build
	local myconf=(
		# Required
		--enable-keep-packaged-modules
		--enable-unlimited-crypto
		--enable-waring-as-errors=no

		--enable-native-coverage=$(usex native-coverage yes no)
		--enable-headless-only=$(usex headless-awt yes no)

		# Sanitizers
		--enable-asan=$(usex asan yes no)
		--enable-ubsan=$(usex ubsan yes no)

		# Docs
		--enable-full-docs=$(usex doc yes no)
		--enable-manpages=$(usex man yes no)

		# Compile and Optimize
		--enable-jvm-feature-link-time-opt=$(usex lto yes no)
		--enable-jvm-feature-opt-size=$(usex opt-size yes no)
		--enable-jvm-feature-services=$(usex services yes no)
		--enable-precompiled-headers=$(usex precompiled-headers yes no)
		--enable-ccache=$(usex ccache yes no)
		--enable-icecc=$(usex icecream yes no)

		# Features
		--enable-static-build=$(usex static-build yes no)
		#--enable-jvm-feature-static-build=$(usex static-build yes no)

		# Default Flags
		--with-boot-jdk="${JDK_HOME}"
		--with-toolchain-type=$(usex clang clang gcc)
		--with-extra-cflags="${CFLAGS}"
		--with-extra-cxxflags="${CXXFLAGS}"
		--with-extra-ldflags="${LDFLAGS}"

		--with-vendor-name="Gentoo"
		--with-vendor-url="https://gentoo.org"
		--with-vendor-bug-url="https://bugs.gentoo.org"
		--with-vendor-vm-bug-url="https://bugs.openjdk.java.net"
		--with-vendor-version-string="${PVR}"

		--with-version-pre=""
		--with-version-string="${PV%_p*}"
		--with-version-build="${PV#*_p}"

		--with-version-feature
		--with-version-interim
		--with-version-update
		--with-version-patch
	)

	use riscv && myconf+=( --with-boot-jdk-jvmargs="-Djdk.lang.Process.launchMechanism=vfork" )
	
	# Setting Java Flags
	$(javaselc ${JAVA_FLAGS})
	
	#JavaFx
	if use javafx; then
		local zip="${EPREFIX}/usr/$(get_libdir)/openjfx-${SLOT}/javafx-exports.zip"
		if [[ -r ${zip} ]]; then
			myconf+=( --with-import-modules="${zip}" )
		else
			die "${zip} not found or not readable"
		fi
	fi

	if use !system-bootstrap ; then
		addpredict /dev/random
		addpredict /proc/self/coredump_filter
	fi

	(
		unset _JAVA_OPTIONS JAVA JAVA_TOOL_OPTIONS JAVAC XARGS
		CFLAGS= CXXFLAGS= LDFLAGS= \
		CONFIG_SITE=/dev/null \
		econf "${myconf[@]}"
	)
}

src_compile() {
	local myemakeargs=(
		JOBS=$(makeopts_jobs)
		LOG=debug
		CFLAGS_WARNINGS_ARE_ERRORS= # No -Werror
		NICE= # Use PORTAGE_NICENESS, don't adjust further down
		$(usex doc docs '')
		$(usex jbootstrap bootcycle-images product-images)
	)
	emake "${myemakeargs[@]}" -j1 #nowarn
}


src_install() {
	local dest="/usr/$(get_libdir)/${PN}-${SLOT}"
	local ddest="${ED}/${dest#/}"

	cd "${S}"/build/*-release/images/jdk || die

	# Create files used as storage for system preferences.
	mkdir .systemPrefs || die
	touch .systemPrefs/.system.lock || die
	touch .systemPrefs/.systemRootModFile || die

	# Oracle and IcedTea have libjsoundalsa.so depending on
	# libasound.so.2 but OpenJDK only has libjsound.so. Weird.
	if ! use alsa ; then
		rm -v lib/libjsound.* || die
	fi

	if ! use examples ; then
		rm -vr demo/ || die
	fi

	if ! use source ; then
		rm -v lib/src.zip || die
	fi

	rm -v lib/security/cacerts || die

	dodir "${dest}"
	cp -pPR * "${ddest}" || die

	dosym8 -r /etc/ssl/certs/java/cacerts "${dest}"/lib/security/cacerts

	# must be done before running itself
	java-vm_set-pax-markings "${ddest}"

	einfo "Creating the Class Data Sharing archives and disabling usage tracking"
	"${ddest}/bin/java" -server -Xshare:dump -Djdk.disableLastUsageTracking || die

	java-vm_install-env "${FILESDIR}"/${PN}.env.sh
	java-vm_revdep-mask
	java-vm_sandbox-predict /dev/random /proc/self/coredump_filter

	if use doc ; then
		docinto html
		dodoc -r "${S}"/build/*-release/images/docs/*
		dosym ../../../usr/share/doc/"${PF}" /usr/share/doc/"${PN}-${SLOT}"
	fi
}

pkg_postinst() {
	java-vm-2_pkg_postinst
}
