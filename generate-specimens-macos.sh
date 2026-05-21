#!/bin/bash
#
# Script to generate Apple disklabel test files
# Requires Mac OS

EXIT_SUCCESS=0
EXIT_FAILURE=1

# Checks the availability of a binary and exits if not available.
#
# Arguments:
#   a string containing the name of the binary
#
assert_availability_binary()
{
	local BINARY=$1

	which ${BINARY} > /dev/null 2>&1
	if test $? -ne ${EXIT_SUCCESS}
	then
		echo "Missing binary: ${BINARY}"
		echo ""

		exit ${EXIT_FAILURE}
	fi
}

assert_availability_binary diskutil
assert_availability_binary hdiutil
assert_availability_binary sw_vers

MACOS_VERSION=`sw_vers -productVersion`
SHORT_VERSION=`echo "${MACOS_VERSION}" | sed 's/^\([0-9][0-9]*[.][0-9][0-9]*\).*$/\1/'`
MAJOR_VERSION=`echo "${MACOS_VERSION}" | sed 's/^\([0-9][0-9]*\).*$/\1/'`

# Note that versions of Mac OS before 10.13 do not support "sort -V"
MAXIMUM_VERSION=`echo "${MAJOR_VERSION} 10" | tr ' ' '\n' | sed 's/[.]//' | sort -rn | head -n 1`

if test "${MAXIMUM_VERSION}" == "10"
then
	MINIMUM_VERSION=`echo "${SHORT_VERSION} 10.13" | tr ' ' '\n' | sed 's/[.]//' | sort -n | head -n 1`

	if test "${MINIMUM_VERSION}" != "1013"
	then
		echo "Unsupported MacOS version: ${MACOS_VERSION}"

		exit ${EXIT_FAILURE}
	fi
fi

SPECIMENS_PATH="specimens/${MACOS_VERSION}"

if test -d ${SPECIMENS_PATH}
then
	echo "Specimens directory: ${SPECIMENS_PATH} already exists."

	exit ${EXIT_FAILURE}
fi

mkdir -p ${SPECIMENS_PATH}

set -e

DEVICE_NUMBER=`diskutil list | grep -e '^/dev/disk' | tail -n 1 | sed 's?^/dev/disk??;s? .*$??'`

VOLUME_DEVICE_NUMBER=$(( ${DEVICE_NUMBER} + 1 ))

IMAGE_FILE="${SPECIMENS_PATH}/apple-disklabel"

echo "Creating: apple-disklabel"
hdiutil create -layout "NONE" -size "4M" -type UDIF "${IMAGE_FILE}"

hdiutil attach -nomount "${IMAGE_FILE}.dmg"

disklabel -create /dev/rdisk${VOLUME_DEVICE_NUMBER} -msize=1M owner-uid=${UID} dev-name=test owner-mode=0644

hdiutil detach disk${VOLUME_DEVICE_NUMBER}

exit ${EXIT_SUCCESS}
