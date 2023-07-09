#!/bin/bash
########################################################################################
#
# This is a script intended to be used by SABnzbd to trigger all scripts that may be
# available to handle a job.
# This was written in bash, but may run under Z shell and possibly under /bin/sh without
# error - though that is not gauranteed.
#
# Requirements:
# * SABnzbd
#
# This script will need to be placed within the scripts directory specified in SABnzbd.
#
########################################################################################
# User Settings
########################################################################################

# Enable Verbose Output?
VERBOSE_OUTPUT="true"

# Script Directory Path
SCRIPT_DIRECTORY="${HOME}/tools/script"

########################################################################################
#
# No user configurable parameters exist below this line.
#
########################################################################################

# Function to print an ISO8601 timestamp.
timestamp()
{
        echo $(date +%F)"T"$(date +%T)$(date +%z)
}

if [ "${VERBOSE_OUTPUT}" = "true" ]
then
	echo -e "[$(timestamp)][\e[1;33mNOTICE\e[0m] Executing all scripts present in \"${SCRIPT_DIRECTORY}\"."
fi

# Find and execute all scripts with no regard for order.
find ${SCRIPT_DIRECTORY} \( -name '*.sh' ! -name 'wrapper.sh' \) -exec bash -c {} \;

if [ "${VERBOSE_OUTPUT}" = "true" ]
then
        echo -e "[$(timestamp)][\e[1;33mNOTICE\e[0m] All scripts that were found have been executed."
fi

exit
