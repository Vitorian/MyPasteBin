
INSTALL_DIR=$HOME/git
PKGSRC_VER=2020Q1

mkdir -p $INSTALL_DIR
cd $INSTALL_DIR
cvs -q -z2 -d anoncvs@anoncvs.NetBSD.org:/cvsroot checkout -r pkgsrc-${PKGSRC_VER} -P pkgsrc

cd ${INSTALL_DIR}/pkgsrc/bootstrap
unset PKG_PATH 
export SH=/bin/bash
export bootstrap_sh=/bin/bash 
./bootstrap --unprivileged

export PATH=$HOME/pkg/bin:$HOME/pkg/sbin:$PATH
export PKG_PATH=$HOME/pkg
export MAKECONF=$PKG_PATH/etc/pkgsrc.mk.conf

( 
cat << 'ENDTEXT'
GROUP!=		/usr/bin/id -gn
SU_CMD=		sh -c
DISTDIR=	${HOME}/pkg/distfiles/All
PKG_DBDIR=	${HOME}/pkg/pkgdb
LOCALBASE=	${HOME}/pkg
PKG_TOOLS_BIN=	${HOME}/pkg/sbin
#INSTALL_DATA=	install -c -o ${BINOWN} -g ${BINGRP} -m 444
WRKOBJDIR=	${HOME}/tmp		# build here instead of in pkgsrc
OBJHOSTNAME=	yes			# use work.`hostname`
VARBASE=	${HOME}/var

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
.-include "$HOME/pkg/etc/mk.conf"
ENDTEXT
) > $HOME/pkg/etc/pkgsrc.mk.conf

unset PKG_PATH
cd $INSTALL_DIR/pkgsrc
bmake configure
bmake install


