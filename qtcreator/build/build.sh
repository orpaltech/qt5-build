TARGET=$1
[[ -z $TARGET ]] && TARGET="build"

if [ $TARGET != build ] && [ $TARGET != clean ]; then
	echo "Invalid target"
	exit 1
fi
QT5_PREFIX=/usr/local/qt-5.9
PWD=$(pwd)
BUILD_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd $BUILD_DIR/../
QTCREATOR_SRC=$(pwd)/qt-creator
cd $PWD
BRANCH="master"
QMAKE=$QT5_PREFIX/bin/qmake
if [ ! -e $QMAKE ]; then
	echo "QT5 make tool not found. Please, build QT5."
	exit 1
fi

startsudo() {
    sudo -v
    if [[ $? != 0 ]]; then
        exit 1
    fi
    ( while true; do sudo -v; sleep 50; done; ) &
    SUDO_PID="$!"
    trap stopsudo SIGINT SIGTERM
}
stopsudo() {
    kill "$SUDO_PID"
    trap - SIGINT SIGTERM
    sudo -k
    exit 0
}

startsudo

if [ $TARGET = build ]; then
	wget -O - http://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -

	sudo apt-add-repository "deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-5.0 main"
	sudo apt-get update
	sudo apt-get install -y clang-5.0 libclang-5.0-dev lldb-5.0 lld-5.0 llvm-5.0

	export LLVM_INSTALL_DIR=/usr/lib/llvm-5.0/


	if [ -d $QTCREATOR_SRC ] && [ -d $QTCREATOR_SRC/.git ] ; then
		# update sources
	        git -C $QTCREATOR_SRC fetch
        	git -C $QTCREATOR_SRC reset --hard
	        git -C $QTCREATOR_SRC clean -fd
	        git -C $QTCREATOR_SRC pull --recurse-submodules
	else
		rm -rf $QTCREATOR_SRC
	        # clone sources
		git clone --depth 1 --recursive -b $BRANCH https://code.qt.io/qt-creator/qt-creator.git $QTCREATOR_SRC
	fi
fi

mkdir -p $BUILD_DIR/qt-creator

if [ $TARGET = clean ]; then
	rm -rf $BUILD_DIR/qt-creator/*
	echo "Clean finished."
	stopsudo &>/dev/null
	exit 0
fi

$QMAKE $QTCREATOR_SRC/qtcreator.pro

cd $BUILD_DIR/qt-creator/

make qmake_all
make -j 2

sudo rm -rf /opt/qtcreator
sudo make install INSTALL_ROOT=/opt/qtcreator

stopsudo &>/dev/null
