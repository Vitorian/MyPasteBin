#!/bin/bash -x

PKGSRC_VER=2020Q1
SOURCE_DIR=$HOME/git
INSTALL_DIR=$HOME/pkg-${PKGSRC_VER}
export SH=/bin/bash

# Make the entire script fail if something fails
set -exo pipefail

# Create the build directory and clone pkgsrc
mkdir -p ${SOURCE_DIR}
cd ${SOURCE_DIR}
if [ ! -f pkgsrc-${PKGSRC_VER}.tar.gz ]; then
    rm -rf pkgsrc-${PKGSRC_VER} pkgsrc
    cvs -q -z2 -d anoncvs@anoncvs.NetBSD.org:/cvsroot checkout -r pkgsrc-${PKGSRC_VER} -P pkgsrc
    mv pkgsrc pkgsrc-${PKGSRC_VER}
    tar caf pkgsrc-${PKGSRC_VER}.tar.gz pkgsrc-${PKGSRC_VER}
fi
rm -rf pkgsrc-${PKGSRC_VER}
tar xaf pkgsrc-${PKGSRC_VER}.tar.gz

# Build the bootstrap
if [ ! -f ${INSTALL_DIR}/bin ]; then
    cd ${SOURCE_DIR}/pkgsrc-${PKGSRC_VER}/bootstrap
    unset PKG_PATH
    export bootstrap_sh=/bin/bash
    ./bootstrap --unprivileged --prefix ${INSTALL_DIR}
fi

# Put the bootstrap into PATH
# Consider putting this in your .bashrc or .bash_profile
export PATH=${INSTALL_DIR}/bin:${INSTALL_DIR}/sbin:$PATH
export MAKECONF=$PKG_PATH/etc/pkgsrc.mk.conf

(
cat << 'ENDTEXT'
GROUP!=		/usr/bin/id -gn
SU_CMD=		sh -c
DISTDIR=	${INSTALL_DIR}/distfiles/All
PKG_DBDIR=	${INSTALL_DIR}/pkgdb
LOCALBASE=	${INSTALL_DIR}
PKG_TOOLS_BIN=	${INSTALL_DIR}/sbin
#INSTALL_DATA=	install -c -o ${BINOWN} -g ${BINGRP} -m 444
WRKOBJDIR=	${INSTALL_DIR}/tmp		# build here instead of in pkgsrc
OBJHOSTNAME= yes			# use work.`hostname`
VARBASE=	${INSTALL_DIR}/var

CHOWN=		true
CHGRP=		true

ROOT_USER=	${USER}
ROOT_GROUP=	${GROUP}

BINOWN=		${USER}
BINGRP=		${GROUP}
DOCOWN=		${USER}
DOCGRP=		${GROUP}
INFOOWN=	${USER}
INFOGRP=	${GROUP}
KMODOWN=	${USER}
KMODGRP=	${GROUP}
LIBOWN=		${USER}
LIBGRP=		${GROUP}
LOCALEOWN=	${USER}
LOCALEGRP=	${GROUP}
MANOWN=		${USER}
MANGRP=		${GROUP}
NLSOWN=		${USER}
NLSGRP=		${GROUP}
SHAREOWN=	${USER}
SHAREGRP=	${GROUP}
ALLOW_VULNERABLE_PACKAGES=yes
.-include "${INSTALL_DIR}/etc/mk.conf"
ENDTEXT
) > ${INSTALL_DIR}/etc/pkgsrc.mk.conf

unset PKG_PATH
cd ${SOURCE_DIR}/pkgsrc-${PKGSRC_VER}
bmake configure
bmake install
