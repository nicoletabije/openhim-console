#!/bin/bash
#Exit on error
set -e

CONSOLEDIR=/usr/share/openhim-console

HOME=`pwd`
AWK=/usr/bin/awk
HEAD=/usr/bin/head
DCH=/usr/bin/dch

cd $HOME/targets
TARGETS=(*)
echo "Targets: $TARGETS"
cd $HOME

PKG=openhim-console

echo -n "Which version of the OpenHIM-console (from github releases) would you like this package to install? (eg. 1.3.0) "
read OPENHIM_VERSION

echo -n "Would you like to upload the build(s) to Launchpad? [y/N] "
read UPLOAD
if [[ "$UPLOAD" == "y" || "$UPLOAD" == "Y" ]];  then
    if [ -n "$LAUNCHPADPPALOGIN" ]; then
      echo Using $LAUNCHPADPPALOGIN for Launchpad PPA login
      echo "To Change You can do: export LAUNCHPADPPALOGIN=$LAUNCHPADPPALOGIN"
    else 
      echo -n "Enter your launchpad login for the ppa and press [ENTER]: "
      read LAUNCHPADPPALOGIN
      echo "You can do: export LAUNCHPADPPALOGIN=$LAUNCHPADPPALOGIN to avoid this step in the future"
    fi

    if [ -n "${DEB_SIGN_KEYID}" ]; then
      echo Using ${DEB_SIGN_KEYID} for Launchpad PPA login
      echo "To Change You can do: export DEB_SIGN_KEYID=${DEB_SIGN_KEYID}"
      echo "For unsigned you can do: export DEB_SIGN_KEYID="
    else 
      echo "No DEB_SIGN_KEYID key has been set.  Will create an unsigned"
      echo "To set a key for signing do: export DEB_SIGN_KEYID=<KEYID>"
      echo "Use gpg --list-keys to see the available keys"
    fi

    echo -n "Enter the name of the PPA: "
    read PPA
fi


BUILDDIR=$HOME/builds


for TARGET in "${TARGETS[@]}"
do
    TARGETDIR=$HOME/targets/$TARGET
    RLS=`$HEAD -1 $TARGETDIR/debian/changelog | $AWK '{print $2}' | $AWK -F~ '{print $1}' | $AWK -F\( '{print $2}'`
    BUILDNO=$((${RLS##*-}+1))

    if [ -z "$BUILDNO" ]; then
        BUILDNO=1
    fi

    BUILD=${PKG}_${OPENHIM_VERSION}-${BUILDNO}~${TARGET}
    echo "Building $BUILD ..."

    # Update changelog
    cd $TARGETDIR
    echo "Updating changelog for build ..."
    $DCH -Mv "${OPENHIM_VERSION}-${BUILDNO}~${TARGET}" --distribution "${TARGET}" "Release Debian Build ${OPENHIM_VERSION}-${BUILDNO}. Find v${OPENHIM_VERSION} changelog here: https://github.com/jembi/openhim-console/releases"

    # Clear and create packaging directory
    PKGDIR=${BUILDDIR}/${BUILD}
    rm -fr $PKGDIR
    mkdir -p $PKGDIR
    cp -R $TARGETDIR/* $PKGDIR

    # Fetch openhim-console from github releases
    mkdir -p $PKGDIR$CONSOLEDIR
    wget -O /tmp/openhim-console.tar.gz https://github.com/jembi/openhim-console/releases/download/v${OPENHIM_VERSION}/openhim-console-v${OPENHIM_VERSION}.tar.gz
    tar -vxzf /tmp/openhim-console.tar.gz --directory $PKGDIR$CONSOLEDIR

    cd $PKGDIR  
    if [[ "$UPLOAD" == "y" || "$UPLOAD" == "Y" ]] && [[ -n "${DEB_SIGN_KEYID}" && -n "{$LAUNCHPADLOGIN}" ]]; then
        echo "Uploading to PPA ${LAUNCHPADPPALOGIN}/${PPA}"

        CHANGES=${BUILDDIR}/${BUILD}_source.changes

        DPKGCMD="dpkg-buildpackage -k${DEB_SIGN_KEYID} -S -sa "
        $DPKGCMD
        DPUTCMD="dput ppa:$LAUNCHPADPPALOGIN/$PPA $CHANGES"
        $DPUTCMD
    else
        echo "Not uploading to launchpad"
        DPKGCMD="dpkg-buildpackage -uc -us"
        $DPKGCMD
    fi
done
