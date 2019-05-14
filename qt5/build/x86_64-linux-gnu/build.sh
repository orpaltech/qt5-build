TARGET=$1

[[ -z $TARGET ]] && TARGET="build.release"

IFS='.' read -r -a target_array <<< "$TARGET"
TARGET=${target_array[0]}
BUILD=${target_array[1]}
[[ -z $BUILD ]] && BUILD="release"

if [ $TARGET != build ] && [ $TARGET != clean ]; then
        echo "invalid target"
        exit 0
fi

if [ $BUILD != debug ] && [ $BUILD != release ]; then
	echo "invalid build config"
	exit 0
fi

STOP_ON_CONFIG=${STOP_ON_CONFIG:="yes"}

#====================
#find root dir
PWD=$(pwd)
BUILD_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd $BUILD_DIR/../../
QT5_ROOT=$(pwd)
#and get back
cd $PWD
#====================
QT5_GIT_ROOT=git://code.qt.io/qt
QT5_BRANCH=${QT5_BRANCH:="5.13"}
QT5_PREFIX=${QT5_PREFIX:="/usr/local/qt-$QT5_BRANCH"}
QT5_MODULES=("qtxmlpatterns" "qtimageformats" "qtsvg" "qtscript" "qtdeclarative" "qtquickcontrols" "qtquickcontrols2" "qtcharts" "qt3d" "qttranslations" "qttools" "qtmultimedia")
if [ $BUILD = debug ]; then
        QT5_PREFIX=$BUILD_DIR/dist
        QT5_BUILD="-developer-build"
fi
QMAKE=$QT5_PREFIX/bin/qmake
QTBASE_SRC=$QT5_ROOT/qtbase

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

#############################################################################

if [ $TARGET != clean ]; then

	if [ ! -e /usr/bin/gcc-7 ]; then
		sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
		sudo apt-get update
		sudo apt-get -y dist-upgrade
	        sudo apt install -y gcc-7 g++-7
		sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 70 --slave /usr/bin/g++ g++ /usr/bin/g++-7
	else
		sudo apt-get update
                sudo apt-get -y dist-upgrade
	fi

	sudo apt-get install -y "^libxcb.*" libx11-xcb-dev libglu1-mesa-dev libxrender-dev libgles2-mesa-dev libglfw3-dev libfreetype6-dev libfontconfig1-dev
	sudo apt-get install -y libedit-dev
	sudo apt-get install -y flex bison gperf libicu-dev libxslt1-dev
	sudo apt-get install -y libasound2-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
	sudo apt-get install -y libjpeg-dev
fi

#############################################################################

if [ $TARGET != clean ]; then
        echo "Prepare Qt5 sources..."

        if [ -d $QTBASE_SRC ] && [ -d $QTBASE_SRC/.git ] ; then
		echo "Update sources for qtbase..."

		sudo git -C $QTBASE_SRC fetch origin --tags

		sudo git -C $QTBASE_SRC reset --hard
		sudo git -C $QTBASE_SRC clean -fd

		echo "Checking out branch: ${QT5_BRANCH}"
		sudo git -C $QTBASE_SRC checkout -B $QT5_BRANCH origin/$QT5_BRANCH
		sudo git -C $QTBASE_SRC pull

        else
		echo "Clone fresh sources for qtbase..."

		[[ -d $QTBASE_SRC ]] && rm -rf $QTBASE_SRC

		# clone sources
		sudo git clone $QT5_GIT_ROOT/qtbase.git -b $QT5_BRANCH $QTBASE_SRC
		[ $? -eq 0 ] || exit $?;
        fi

	for MODULE in "${QT5_MODULES[@]}" ; do
		QT5_MODULE_DIR=${QT5_ROOT}/${MODULE}
		QT5_MODULE_URL=${QT5_GIT_ROOT}/${MODULE}.git

		if [ -d $QT5_MODULE_DIR ] && [ -d $QT5_MODULE_DIR/.git ] ; then
			# update sources
                	sudo git -C $QT5_MODULE_DIR fetch origin --tags
			sudo git -C $QT5_MODULE_DIR reset --hard
			sudo git -C $QT5_MODULE_DIR clean -fd

                        echo "Checking out branch: ${QT5_BRANCH}"
                        sudo git -C $QT5_MODULE_DIR checkout -B $QT5_BRANCH origin/$QT5_BRANCH
                        sudo git -C $QT5_MODULE_DIR pull

                else
			echo "Clone fresh sources for ${mod}..."

			[[ -d $QT5_MODULE_DIR ]] && rm -rf $QT5_MODULE_DIR

			# clone sources
			sudo git clone $QT5_MODULE_URL -b $QT5_BRANCH $QT5_MODULE_DIR
			[ $? -eq 0 ] || exit $?;
                fi
        done

fi

#############################################################################

sudo mkdir -p $QT5_PREFIX

mkdir -p $BUILD_DIR/qtbase
for MODULE in "${QT5_MODULES[@]}" ; do
	mkdir -p $BUILD_DIR/${MODULE}
done

if [[ $TARGET = clean ]]; then
	sudo rm -rf $BUILD_DIR/qtbase/*
	sudo rm -rf $QT5_ROOT/qtbase/*
	for MODULE in "${QT5_MODULES[@]}" ; do
		sudo rm -rf $BUILD_DIR/${MODULE}/*
		sudo rm -rf $QT5_ROOT/${MODULE}/*
	done

	echo "Clean finished."
	stopsudo &>/dev/null
	exit 0
fi

#############################################################################

cd $BUILD_DIR/qtbase/

$QTBASE_SRC/configure -v -silent \
			-opensource -confirm-license \
			-prefix $QT5_PREFIX \
			$QT5_BUILD \
			-make libs \
			-nomake examples \
			-nomake tests \
			-no-pch \
			-no-use-gold-linker \
			-opengl es2 \
			-no-openssl \
			-system-zlib \
			-system-libjpeg \
			-system-libpng \
			-system-freetype \
			-no-sql-db2 -no-sql-ibase -no-sql-mysql -no-sql-oci -no-sql-odbc -no-sql-psql -no-sql-tds


if [ $STOP_ON_CONFIG != no ]; then
	echo "=================================================================================="
	read -p "Please, review configuration output. Press any key to continue or Ctrl+C to exit... " -n1 -s
fi

make -j 2
sudo rm -rf $QT5_PREFIX/*
sudo make install


#############################################################################

for MODULE in "${QT5_MODULES[@]}" ; do
	cd $BUILD_DIR/${MODULE}/
	$QMAKE $QT5_ROOT/${MODULE}/

	make -j 2
	sudo make install
done

#############################################################################

if [ $BUILD = release ]; then
sudo -S bash -c "cat <<EOF > /usr/share/qtchooser/qt5-x86_64-linux-gnu.conf
$QT5_PREFIX/bin
$QT5_PREFIX/lib
EOF"
sudo rm -f /usr/lib/x86_64-linux-gnu/qt-default/qtchooser/default.conf
sudo ln -s /usr/share/qtchooser/qt5-x86_64-linux-gnu.conf  /usr/lib/x86_64-linux-gnu/qt-default/qtchooser/default.conf
fi

stopsudo &>/dev/null
