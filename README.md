# qt5-build

Provides folder structure and build scripts for Qt5 (version 5.9) and Qt-creator software on Linux OS (tested with Ubuntu 16.04).


QT5 Framework
---------------------
Build script provided will make a set of essential Qt5 modules and deploy them to /usr/local/qt59. To override Qt5 framework location, please, use:


    export QT5_PREFIX = "[your local path to Qt5]"


By default, the build script will stop right after QtBase configuration is finished so that you can review configuration results. You can switch off the behavior above by changing the variable:


    export STOP_ON_CONFIG = "no"


You can also change Qt5 branch (default 5.9), but this is not guaranteed to work correctly (as the Git URL may change from version to version):

    export QT5_BRANCH = "[branch of your choice]"
    
    
In order to add or remove a Qt5 module to build you should modify the array QT5_MODULES in the script.


QT Creator
---------------------

Build script requires pre-built Qt5 framework (see chapter above). Default location is /usr/local/qt59. To override Qt5 framework location, please, use:


    export QT5_PREFIX = "[your local path to Qt5]"

