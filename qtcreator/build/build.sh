TARGET=$1
if [ -z $TARGET ]; then
	TARGET="build"
fi
if [ $TARGET != build ] && [ $TARGET != clean ]; then
	echo "Invalid target"
	exit 1
fi
QT5_PREFIX="${QT5_PREFIX:-/usr/local/qt59}"
PWD=$(pwd)
BUILD_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd $BUILD_DIR/../
QTCREATOR_SRC_DIR=$(pwd)/qt-creator
cd $PWD
QTCREATOR_BRANCH="${QTCREATOR_BRANCH:-master}"
QTCREATOR_INSTALL_DIR="${QTCREATOR_INSTALL_DIR:-/opt/qtcreator}"
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

	sudo apt-add-repository "deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-3.9 main"
	sudo apt-get update
	sudo apt-get install -y clang-3.9 libclang-3.9-dev lldb-3.9


	if [ -d $QTCREATOR_SRC_DIR ] && [ -d $QTCREATOR_SRC_DIR/.git ] ; then
		# update sources
	        git -C $QTCREATOR_SRC_DIR fetch origin $QTCREATOR_BRANCH
        	git -C $QTCREATOR_SRC_DIR reset --hard $QTCREATOR_BRANCH
	        git -C $QTCREATOR_SRC_DIR clean -fd
	        git -C $QTCREATOR_SRC_DIR pull origin $QTCREATOR_BRANCH --recurse-submodules
	else
		rm -rf $QTCREATOR_SRC_DIR
	        # clone sources
		git clone --depth 1 --recursive -b $QTCREATOR_BRANCH https://code.qt.io/qt-creator/qt-creator.git $QTCREATOR_SRC_DIR
	fi
fi

mkdir -p $BUILD_DIR/qt-creator
cd $BUILD_DIR/qt-creator/

if [ $TARGET = clean ]; then
	rm -rf *
	echo "Clean finished."
	stopsudo &>/dev/null
	exit 0
fi

export LLVM_INSTALL_DIR=/usr/lib/llvm-3.9

${QMAKE} $QTCREATOR_SRC_DIR/qtcreator.pro

make qmake_all
make -j 2

# install qtcreator
sudo rm -rf $QTCREATOR_INSTALL_DIR
sudo make install INSTALL_ROOT=$QTCREATOR_INSTALL_DIR LLVM_INSTALL_DIR=/usr/lib/llvm-3.9

stopsudo &>/dev/null
