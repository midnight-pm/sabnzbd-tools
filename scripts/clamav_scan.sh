#!/bin/bash
########################################################################################
#
# This is a script intended to be used by SABnzbd to trigger a scan of a job's directory
# contents by ClamAV during post-processing.
# This was written in bash, but may run under Z shell and possibly under /bin/sh without
# error - though that is not gauranteed.
#
# Requirements:
# * ClamAV
# * SABnzbd
#
# An installation of ClamAV can be done using any given preferred package manager.
# At a minimum, installing clamav and clamav-update (or clamav-freshclam), and then
# running the latter as a service should be enough to get things running.
#
# This script will need to be placed within the scripts directory specified in SABnzbd.
#
# Pre-requisites -- Install ClamAV:
#     sudo dnf -y install clamav clamd
#     sudo sed -i -e "/^#*LocalSocket\s/s/^#//" /etc/clamd.d/scan.conf
#     sudo freshclam
#     sudo systemctl --now enable clamav-freshclam.service clamd@scan.service
#     sudo semanage boolean -m -1 antivirus_can_scan_system
#     sudo touch /etc/sudoers.d/clamdscan
#     sudo echo "sabnzbd ALL = (ALL) NOPASSWD: /usr/bin/clamdscan" > /etc/sudoers.d/clamdscan
#
########################################################################################
# User Settings
########################################################################################

# Enable Verbose Output?
VERBOSE_OUTPUT="true"
LOGGING_OUTPUT="false"
PROBLEMATIC_DIR="${HOME}/data/Suspicious/"

CLAMSCAN_BNRY="clamdscan"         # * ClamAV Binary Name
CLAMSCAN_PATH="/usr/bin"         # * ClamAV Binary Directory

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

# Environmental Variables
# https://sabnzbd.org/wiki/scripts/post-processing-scripts#env_vars

# Get SABnzbd Job Unique ID
SABNZBD_JOB_ID=${SAB_NZO_ID}

# Get SABnzbd Job Final Name
SABNZBD_JOBNME=${SAB_FINAL_NAME}

# Get SABnzbd Job Status
SABNZBD_JOBSTS=${SAB_STATUS}

# Get SABnzbd Job Post-Processing Type
SABNZBD_JOB_PP=${SAB_PP}

# Get SABnzbd Job Post-Processing Status
# Status of post processing.
# 
# 0 = OK
# 1 = Failed verification
# 2 = Failed unpack
# 3 = 1+2
# -1 = Failed post processing
SABNZBD_JOBPPS=${SAB_PP_STATUS}

# Get SABnzbd Job Output Directory
SABNZBD_JOBDIR=${SAB_COMPLETE_DIR}

# Test Parameters
if [ -z "$SABNZBD_JOB_ID" ]
then
	echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] Missing SABnzbd Job ID (\e[1;33m\${SAB_NZO_ID}\e[0m)."
	exit 1
fi
if [ -z "$SABNZBD_JOBNME" ]
then
	echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] Missing SABnzbd Job Final Name (\e[1;33m\${SAB_FINAL_NAME}\e[0m)."
	exit 1
fi
if [ -z "$SABNZBD_JOBSTS" ]
then
	echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] Missing SABnzbd Status (\e[1;33m\${SAB_STATUS}\e[0m)."
	exit 1
fi
if [ -z "$SABNZBD_JOB_PP" ]
then
	echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] Missing SABnzbd Job Post-Processing Type (\e[1;33m\${SAB_PP}\e[0m)."
	exit 1
fi
if [ -z "$SABNZBD_JOBPPS" ]
then
	echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] Missing SABnzbd Job Post-Processing Status (\e[1;33m\${SAB_PP_STATUS}\e[0m)."
	exit 1
fi
if [ -z "$SABNZBD_JOBDIR" ]
then
	echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] Missing Completed SABnzbd Job Directory (\e[1;33m\${SAB_COMPLETE_DIR}\e[0m)."
	exit 1
fi

# Find the ClamAV Binary.
echo -e "[$(timestamp)][\e[1;33mNOTICE\e[0m] Looking for \"$CLAMSCAN_BNRY\"."

which "$CLAMSCAN_BNRY" > /dev/null
exit_code_which=$?

# Test the exit status.
# Reference: https://stackoverflow.com/a/45817972/5812026
if [ $exit_code_which -eq 0 ]
then
	echo -e "[$(timestamp)][\e[1;32mSUCCESS\e[0m] Found \"$CLAMSCAN_BNRY\" on system \$PATH."
	CLAMAV_SCAN_PATH="$CLAMSCAN_BNRY"
else
	echo -e "[$(timestamp)][\e[1;33mWARNING\e[0m] Could not find \"$CLAMSCAN_BNRY\" on system \$PATH. Attempting to fall back to configured directory of \"$CLAMSCAN_PATH\"."
	CLAMAV_SCAN_PATH="$CLAMSCAN_PATH/$CLAMSCAN_BNRY"
	if [ -f "$CLAMAV_SCAN_PATH" ]
	then
		echo -e "[$(timestamp)][\e[1;32mSUCCESS\e[0m] Found \"$CLAMAV_SCAN_PATH\"."
	else
		echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] Could not find \"$CLAMAV_SCAN_PATH\". Please check the configuration, and/or verify that the specified program is installed."
		echo -e "[$(timestamp)][\e[1;33mNOTICE\e[0m] Exiting."
		exit $exit_code_which
	fi
fi

# Pre-Run Checks
if [ $SABNZBD_JOBSTS -ne 0 ]
then
	echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] SABnzbd indicates that the job was not completed successfully. This process cannot continue."
	exit 1
else
	echo -e "[$(timestamp)][\e[1;33mNOTICE\e[0m] SABnzbd indicates that the job was completed successfully."
	echo -e "[$(timestamp)][\e[1;33mNOTICE\e[0m] Validating that Post-Processing was completed successfully."
	if [ $SABNZBD_JOBPPS -ne 0 ]
	then
		if [ $SABNZBD_JOBPPS -eq 1 ]
		then
			echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] SABnzbd indicates that this job failed verification during post-processing."
		elif [ $SABNZBD_JOBPPS -eq 2 ]
		then
			echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] SABnzbd indicates that this job failed to properly unpack during post-processing."
		elif [ $SABNZBD_JOBPPS -eq 3 ]
		then
			echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] SABnzbd indicates that this job failed verification and failed to properly unpack during post-processing."
		else
			echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] SABnzbd indicates that post-processing for this job was not successful."
		fi
		echo -e "[$(timestamp)][\e[1;33mNOTICE\e[0m] Due to an error, this process cannot continue."
		exit 1
	else
		echo -e "[$(timestamp)][\e[1;33mNOTICE\e[0m] Post Processing Was Successful."
	fi
fi

if [ "$VERBOSE_OUTPUT" = "true" ]
then
	# Verbose output.
	# Display Parameters.
	echo -e "[$(timestamp)][\e[1;33mNOTICE\e[0m] SABnzbd provided the following parameters:"
	echo -e "\e[1;33mSABnzbd Job ID\e[0m]                        | $SABNZBD_JOB_ID"
	echo -e "\e[1;33mSABnzbd Job Name\e[0m]                      | $SABNZBD_JOBNME"
	echo -e "\e[1;33mSABnzbd Job Status\e[0m]                    | $SABNZBD_JOBSTS"
	echo -e "\e[1;33mSABnzbd Job Post-Processing Type\e[0m]      | $SABNZBD_JOB_PP"
	echo -e "\e[1;33mSABnzbd Job Post-Processing Status\e[0m]    | $SABNZBD_JOBPPS"
	echo -e "\e[1;33mSABnzbd Job Directory (Completed Job)\e[0m] | $SABNZBD_JOBDIR"
fi

# Validate that the directory exists
if [ -d "$SABNZBD_JOBDIR" ]
then
	echo -e "[$(timestamp)][\e[1;33mNOTICE\e[0m] Found the provided completed job directory."
	# Test that the directory is readable.
	if [ ! -r "$SABNZBD_JOBDIR" ]
	then
		echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] The provided directory is not readable by the user under whose context that this script was executed."
		exit 1
	else
		# Test that the directory is writeable.
		if [ ! -w "$SABNZBD_JOBDIR" ]
		then
			echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] The provided directory is not writeable by the user under whose context that this script was executed."
			exit 1
		fi
	fi
else
	echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] Could not find the provided completed job directory."
	exit 1
fi

echo -e "[$(timestamp)][\e[1;33mNOTICE\e[0m] Starting Scan with ClamAV."

LOGFILE="$SABNZBD_JOBDIR/clamav_scan.log"
if [ "$VERBOSE_OUTPUT" = "true" ]
then
	# Verbose output.
	sudo $CLAMAV_SCAN_PATH -v -l "$LOGFILE" "$SABNZBD_JOBDIR"
	
	CLAMAV_SCAN_STTS=$?
else
	# Quiet output.
	sudo $CLAMAV_SCAN_PATH -l "$LOGFILE" "$SABNZBD_JOBDIR" 2>&1 > /dev/null

	CLAMAV_SCAN_STTS=$?
fi

if [ ! "$LOGGING_OUTPUT" = "true" ]
then
	echo -e "[$(timestamp)][\e[1;33mNOTICE\e[0m] Logging disabled. Removing log file. [$CLAMAV_SCAN_STTS]"
	rm -f "$LOGFILE"
fi

if [ $CLAMAV_SCAN_STTS -eq 0 ]
then
	echo -e "[$(timestamp)][\e[1;33mNOTICE\e[0m] Scan completed. [$CLAMAV_SCAN_STTS]"

	echo "Scan Complete. No Malware Detected. [ClamAV]"
	exit 0
elif [ $CLAMAV_SCAN_STTS -eq 1 ]
then
	echo -e "[$(timestamp)][\e[1;31mWARNING\e[0m] This directory may have infected contents. [$CLAMAV_SCAN_STTS]"
	mv "$SABNZBD_JOBDIR" "$PROBLEMATIC_DIR/"

	echo "Scan Complete. Potentially Infected Job [ClamAV]"
	exit 0
else
	echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] Scan error. [$CLAMAV_SCAN_STTS]"

	echo "Scan Error [ClamAV]"
	exit 1
fi

# The script should never actually get here.
echo -e "[$(timestamp)][\e[1;33mNOTICE\e[0m] Exiting."
echo "Script Processing Finished"
exit 0
