TARGET=$1
[[ -z $TARGET ]] && TARGET="build"

if [ $TARGET != build ] && [ $TARGET != clean ] && [ $TARGET != purge ]; then
	echo "Invalid target"
	exit 1
fi
QT5_RELEASE="5.13"
QT5_PREFIX=${QT5_PREFIX:="/usr/local/qt-${QT5_RELEASE}"}

PWD=$(pwd)
BUILD_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd $BUILD_DIR/../
QTCREATOR_SRC=$(pwd)/qt-creator
cd $PWD

INSTALL_DIR="/home/sergey/Projects/orpaltech/qtcreator"
QTCREATOR_URL="git://code.qt.io/qt-creator/qt-creator.git"
BRANCH="master"
QT5_QMAKE="${QT5_PREFIX}/bin/qmake"
if [ ! -e $QT5_QMAKE ]; then
	echo "QT5 make tool not found. Please, build QT5."
	exit 1
fi

NUM_CPU_CORES=$(grep -c ^processor /proc/cpuinfo)

# ---------------------------------------------------------------------------
sudo_init() {
    # Ask for the administrator password upfront
    sudo -v
    [[ $? != 0 ]] && exit 1

    # Keep-alive: update existing `sudo` timestamp until the calling script has finished
    ( while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null ) &
}

sudo_init

$QT5_QMAKE -v

if [ $TARGET = build ]; then
	wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -

	sudo apt-add-repository "deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-8 main"
	sudo apt-get update
	sudo apt-get install -y clang-8 libclang-8-dev lldb-8 lld-8 llvm-8

	export LLVM_INSTALL_DIR=/usr/lib/llvm-8/

	if [ -d $QTCREATOR_SRC ] && [ -d "${QTCREATOR_SRC}/.git" ] ; then
		# update sources
	        git -C $QTCREATOR_SRC fetch origin --tags --recurse-submodules

		git -C $QTCREATOR_SRC reset --hard
		git -C $QTCREATOR_SRC clean -fdx
		git -C $QTCREATOR_SRC submodule update --init

		echo "Checking out branch: ${BRANCH}"
		git -C $QTCREATOR_SRC checkout -B $BRANCH origin/$BRANCH
		git -C $QTCREATOR_SRC pull
	else
		rm -rf $QTCREATOR_SRC

	        # clone sources
		git clone $QTCREATOR_URL -b $BRANCH --recursive $QTCREATOR_SRC
	fi
fi

mkdir -p "${BUILD_DIR}/qt-creator"

if [ $TARGET = clean ] || [ $TARGET = purge ]; then
	rm -rf "${BUILD_DIR}/qt-creator/*"

	if [[ $TARGET = purge ]] ; then
		echo "Purge source dir"
		rm -rf ${QTCREATOR_SRC}
	fi

	echo "Clean finished."
	exit 0
fi

cd "${BUILD_DIR}/qt-creator"
$QT5_QMAKE "${QTCREATOR_SRC}/qtcreator.pro"

make qmake_all
# QMAKE_CXXFLAGS="-I/home/sergey/Projects/orpaltech/qt5-build/qtcreator/qt-creator/src/shared/qbs/src/shared/qtscript/src/script/api"
chrt -i 0 make -j${NUM_CPU_CORES}

sudo rm -rf $INSTALL_DIR
sudo make install INSTALL_ROOT=$INSTALL_DIR
