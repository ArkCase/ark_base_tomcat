#!/bin/bash

# The install-tomcat-native-module script will install
# the correct binary module into ${CATALINA_BASE}/lib
# taking into account the currently active JVM.
#
# It will also consider whether the use of the native
# module is enabled (via envvar or some other means),
# and will exit with a 0 status to indicate so, or a
# non-0 status if it's disabled or not available.
#
# If it does exit with a 0 status, then the path
# ${CATALINA_BASE}/lib must be added to the head
# of the LD_LIBRARY_PATH environment variable so
# the module becomes available for use.
if "install-tomcat-native-module" ; then

	#
	# We have a native module!! Make it available!
	#
	echo "The Tomcat Native module was installed"
	export LD_LIBRARY_PATH="${CATALINA_BASE}/lib:${LD_LIBRARY_PATH}"
	echo "export LD_LIBRARY_PATH=${LD_LIBRARY_PATH@Q}"
fi
