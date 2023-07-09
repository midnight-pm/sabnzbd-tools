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
SCRIPT_DIRECTORY="${HOME}/tools/scripts"

# Specify the List of Scripts by their name.
# This list should be ordered in the intended order with which to execute the scripts.
declare -a ARRAY_OF_SCRIPTS=(
    "clamav_scan.sh"
    "cleanup_extraneous_aggressive.sh"
)

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

# This is declared just in case.
ERROR_STATE="0"

for SCRIPT_TO_EXEC in ${ARRAY_OF_SCRIPTS[@]}
do
    # Define the full path to the script
    SCRIPT="${SCRIPT_DIRECTORY}/${SCRIPT_TO_EXEC}"

    # Execute the script
    if [ "${VERBOSE_OUTPUT}" = "true" ]
    then
        echo -e "[$(timestamp)][\e[1;33mNOTICE\e[0m] Executing \"${SCRIPT}\"."
    fi
    bash ${SCRIPT}

    # Determine the status
    EXECUTE_STATUS=$?
    if [ ${EXECUTE_STATUS} -eq 0 ]
    then
	# Everything is fine.

        if [ "${VERBOSE_OUTPUT}" = "true" ]
        then
            echo -e "[$(timestamp)][\e[1;32mSUCCESS\e[0m] Script \"${SCRIPT}\" Completed Successfully."
	fi
    else
	# Update the error_state variable.
	ERROR_STATE=${EXECUTE_STATUS}

	if [ "${VERBOSE_OUTPUT}" = "true" ]
        then
            echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] Script \"${SCRIPT}\" Did Not Complete Successfully."
        fi
    fi
done

if [ "${VERBOSE_OUTPUT}" = "true" ]
then
        echo -e "[$(timestamp)][\e[1;33mNOTICE\e[0m] All designated scripts have been executed."
fi

echo "Script Processing Finished"
if [ ! "${ERROR_STATE}" = "0" ]
then
        echo "An error occurred during script execution. Reviewing available logs is recommended."
fi

exit
