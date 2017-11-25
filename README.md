# qt5-build

The repository provides folder structure and build scripts for Qt5 (default 5.9) and Qt-creator software on Linux OS (tested with Ubuntu 16.04). Created for use with https://github.com/orpaltech/antenna-analyzer-armbian project in which every board-specific Qt5 build will be placed into a dedicated **qt5-build/qt5/build/[BOARD]** folder.


Qt5 Framework
---------------------
Build script provided will make a set of essential Qt5 modules and deploy them to /usr/local/qt59. To override Qt5 framework location, please, use:


    export QT5_PREFIX = "[your local path to Qt5]"


Typical usage:
1) to build Qt5

         build.sh
    
2) to clean 

         build.sh clean

By default, the build script will pause just after QtBase configure so that you can review the resulting configuration. You can switch off the behavior above by changing the variable:


    export STOP_ON_CONFIG = "no"


You can also change Qt5 branch (default 5.9), but this is not guaranteed to work correctly (as the Git URL may change from version to version):

    export QT5_BRANCH = "[branch of your choice]"
    
    
In order to add or remove a Qt5 module to build you should modify the array QT5_MODULES in the script.


**Please, note that the script will update your system-default Qt5 to the recently built Qt5. If this behavior is undesired then you should modify the final part of the script.**


Qt-Creator
---------------------

The Qt-Creator software is used for remote debugging in https://github.com/orpaltech/antenna-analyzer-armbian project. Provided build script requires a pre-built Qt5 framework (see chapter above). Default location is /usr/local/qt-5.9. To override Qt5 framework location, please, use:


    export QT5_PREFIX = "[your local path to Qt5]"


Typical usage:
1) to build Qt-Creator

         build.sh
    
2) to clean 

         build.sh clean
         
