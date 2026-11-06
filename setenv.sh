#!/bin/bash

#
# Load the Tomcat Native module that matches the currently active JVM, if it's
# enabled (TOMCAT_NATIVE_ENABLE, true by default) and available.
#
# Its version may be chosen with TOMCAT_NATIVE_VER, and defaults to 1.3 for
# Tomcat 9 and 10 (which can't use 2.x), and 2.0 otherwise. The module is loaded
# in place, by adding its directory to the head of LD_LIBRARY_PATH (keeping
# whatever was there before), so nothing is written into the Tomcat installation.
#
# This file is sourced by catalina.sh, so it must remain POSIX sh.
#
if bash -c '. /.functions && as_boolean "${1}"' -- "${TOMCAT_NATIVE_ENABLE:-true}" ; then
	TOMCAT_NATIVE_JAVA="$(get-java)" || TOMCAT_NATIVE_JAVA=""
	if [ -z "${TOMCAT_NATIVE_VER:-}" ] ; then
		case "${TOMCAT_MAJOR_VER:-}" in
			9 | 10 ) TOMCAT_NATIVE_VER="1.3" ;;
			* ) TOMCAT_NATIVE_VER="2.0" ;;
		esac
	fi
	TOMCAT_NATIVE_DIR="${TOMCAT_NATIVE_HOME:-${CATALINA_HOME}/lib/native}/${TOMCAT_NATIVE_VER}/${TOMCAT_NATIVE_JAVA}"
	if [ -n "${TOMCAT_NATIVE_JAVA}" ] && [ -d "${TOMCAT_NATIVE_DIR}" ] && [ -r "${TOMCAT_NATIVE_DIR}" ] ; then
		TOMCAT_NATIVE_DIR="$(readlink -f "${TOMCAT_NATIVE_DIR}")"
		echo "Loading the Tomcat Native module for Java ${TOMCAT_NATIVE_JAVA} from [${TOMCAT_NATIVE_DIR}]"
		case ":${LD_LIBRARY_PATH:-}:" in
			*":${TOMCAT_NATIVE_DIR}:"* ) ;;
			* ) export LD_LIBRARY_PATH="${TOMCAT_NATIVE_DIR}${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}" ;;
		esac
	else
		echo "The Tomcat Native module version ${TOMCAT_NATIVE_VER} for Java ${TOMCAT_NATIVE_JAVA:-(unknown)} is not available at [${TOMCAT_NATIVE_DIR}]" 1>&2
	fi
else
	echo "The Tomcat Native module is disabled"
fi
