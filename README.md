# qt5-build

Provides folder structure and build scripts for Qt5 (version 5.9) and Qt-creator software on Linux OS (tested with Ubuntu 16.04).


QT5 Framework
---------------------
The script provided will build a set of essential Qt5 modules and deploy the Qt5 framework to /usr/local/qt59. To override Qt5 framework location, please, use:


export QT5_PREFIX = [your local path to Qt5]


By default build script will stop upon QtBase configuration so that you can review configration results. You can switch off the behavior above by changing the variable:


export STOP_ON_CONFIG = "no"



QT Creator
---------------------

Build script requires pre-built Qt5 framework (see chapter above). Default location is /usr/local/qt59. To override Qt5 framework location, please, use:


export QT5_PREFIX = [your local path to Qt5]
