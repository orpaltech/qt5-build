# qt5-build

The repository provides folder structure and build scripts for QT5 (default 5.13) and QT-Creator software on Linux OS (tested with Ubuntu 18.04). Initially was created for https://github.com/orpaltech/armlinux project, in which every board-specific QT5 build will be placed into a dedicated **qt5-build/qt5/build/[DEVICE_CONFIG]** folder.


QT5 Framework
---------------------
Build script provided will make a set of essential QT5 modules and deploy them to /usr/local/qt-5.<x>/ directory. In order to override QT5 framework target location, please, use:


    export QT5_PREFIX = "[your local path to QT5]"


Typical usage:
1) to build Qt5

         build.sh
    
2) to clean 

         build.sh clean

3) to clean and remove cloned sources

         build.sh purge

By default, the build script will pause just after qtbase configure so that you can review the resulting configuration. You can switch off the behavior by setting the variable:


    export STOP_ON_CONFIG = "no"


You can also change QT5 branch (default 5.13), but this is not guaranteed to work correctly:

    export QT5_BRANCH = "[branch of your choice]"
    
    
In order to add or remove a QT5 module to build you should modify the array QT5_MODULES in the script.


**Please, note that the script will update your system-default QT5 to the recently built QT5. If this behavior is undesired then you should modify the final part of the script.**


QT-Creator
---------------------

The QT-Creator software is used for development and remote debugging in https://github.com/orpaltech/armlinux project. The build script provided requires a pre-built QT5 framework (see above). The default location is /usr/local/qt-5.13/ directory. In order to override the QT5 framework location, please, use:


    export QT5_PREFIX = "[your local path to Qt5]"


Typical usage:
1) to build QT-Creator

         build.sh
    
2) to clean 

         build.sh clean
         
3) to clean and remove cloned sources

         build.sh purge
