#!/bin/bash
########################################################################################
# User Settings
########################################################################################

# Enable Verbose Output?
VERBOSE_OUTPUT="true"
REMOVE_UNWANTED_EXTS="true"
REMOVE_SAMPLE_PROOFF="true"
REMOVE_SAMPLE_PROOFD="true"

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
	echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] Missing SABnzbd Job ID (\${SAB_NZO_ID})."
	exit 1
fi
if [ -z "$SABNZBD_JOBNME" ]
then
	echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] Missing SABnzbd Job Final Name (\${SAB_FINAL_NAME})."
	exit 1
fi
if [ -z "$SABNZBD_JOBSTS" ]
then
	echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] Missing SABnzbd Status (\${SAB_STATUS})."
	exit 1
fi
if [ -z "$SABNZBD_JOB_PP" ]
then
	echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] Missing SABnzbd Job Post-Processing Type (\${SAB_PP})."
	exit 1
fi
if [ -z "$SABNZBD_JOBPPS" ]
then
	echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] Missing SABnzbd Job Post-Processing Status (\${SAB_PP_STATUS})."
	exit 1
fi
if [ -z "$SABNZBD_JOBDIR" ]
then
	echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] Missing Completed SABnzbd Job Directory (\${SAB_COMPLETE_DIR})."
	exit 1
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
			echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] SABnzbd indicates that this job failed to properly unpack during post-processing."
		elif [ $SABNZBD_JOBPPS -eq 3 ]
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

if [ "$VERBOSE_OUTPUT" = "true" ]
then
	# Verbose output.
	# Remove Files with unwanted extensions
	if [ "$REMOVE_UNWANTED_EXTS" = "true" ]
	then
		echo -e "[$(timestamp)][\e[1;33mNOTICE\e[0m] Searching for and attempting to remove files with unwanted extensions."
		find "$SABNZBD_JOBDIR/" -type f \( \
		-iname "*.exe" \
		-o -iname "*.jpg" \
		-o -iname "*.html" \
		-o -iname "*.sfv" \
		-o -iname "*.srr" \
		-o -iname "*.url" \
		\) -delete -print
		find_exec_status=$?
		if [ $find_exec_status -ne 0 ]
		then
			echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] An error was encountered while executing \"find\". [$find_exec_status]"
		fi
	fi

	# Remove sample files, proof files, and associated directories.
	if [ "$REMOVE_SAMPLE_PROOFF" = "true" ]
		echo -e "[$(timestamp)][\e[1;33mNOTICE\e[0m] Searching for and attempting to remove sample and proof files."
		find "$SABNZBD_JOBDIR/" -type f \( \
		-iname "*.sample.mkv" \
		-o -iname "*.sample.mp4" \
		-o -iname "*-sample.mkv" \
		-o -iname "*-sample.mp4" \
		-o -iname "*_sample.mkv" \
		-o -iname "*_sample.mp4" \
		-o -iname "*.proof.mkv" \
		-o -iname "*_proof.mkv" \
		-o -iname "*_proof.mp4" \
		\) -delete -print
		find_exec_status=$?
		if [ $find_exec_status -ne 0 ]
		then
			echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] An error was encountered while executing \"find\". [$find_exec_status]"
		fi
	fi

	# Remove sample directories and proof directories.
	if [ "$REMOVE_SAMPLE_PROOFD" = "true" ]
		echo -e "[$(timestamp)][\e[1;33mNOTICE\e[0m] Searching for and attempting to remove sample and proof directories."
		find "$SABNZBD_JOBDIR/" -type d \( \
		-iname "sample" \
		-o -iname "proof" \
		\) -delete
		find_exec_status=$?
		if [ $find_exec_status -ne 0 ]
		then
			echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] An error was encountered while executing \"find\". [$find_exec_status]"
		fi
	fi
else
	# No Verbose Output
	# Does not suppress errors.
	# Remove Files with unwanted extensions
	if [ "$REMOVE_UNWANTED_EXTS" = "true" ]
	then
		echo -e "[$(timestamp)][\e[1;33mNOTICE\e[0m] Searching for and attempting to remove files with unwanted extensions."
		find "$SABNZBD_JOBDIR/" -type f \( \
		-iname "*.exe" \
		-o -iname "*.jpg" \
		-o -iname "*.html" \
		-o -iname "*.sfv" \
		-o -iname "*.srr" \
		-o -iname "*.url" \
		\) -delete
		find_exec_status=$?
		if [ $find_exec_status -ne 0 ]
		then
			echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] An error was encountered while executing \"find\". [$find_exec_status]"
		fi
	fi

	# Remove sample files and proof files.
	if [ "$REMOVE_SAMPLE_PROOFF" = "true" ]
	echo -e "[$(timestamp)][\e[1;33mNOTICE\e[0m] Searching for and attempting to remove sample and proof files."
		find "$SABNZBD_JOBDIR/" -type f \( \
		-iname "*.sample.mkv" \
		-o -iname "*.sample.mp4" \
		-o -iname "*-sample.mkv" \
		-o -iname "*-sample.mp4" \
		-o -iname "*_sample.mkv" \
		-o -iname "*_sample.mp4" \
		-o -iname "*.proof.mkv" \
		-o -iname "*_proof.mkv" \
		-o -iname "*_proof.mp4" \
		\) -delete
		find_exec_status=$?
		if [ $find_exec_status -ne 0 ]
		then
			echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] An error was encountered while executing \"find\". [$find_exec_status]"
		fi
	fi

	# Remove sample directories and proof directories.
	if [ "$REMOVE_SAMPLE_PROOFD" = "true" ]
		echo -e "[$(timestamp)][\e[1;33mNOTICE\e[0m] Searching for and attempting to remove sample and proof directories."
		find "$SABNZBD_JOBDIR/" -type d \( \
		-iname "sample" \
		-o -iname "proof" \
		\) -delete
		find_exec_status=$?
		if [ $find_exec_status -ne 0 ]
		then
			echo -e "[$(timestamp)][\e[1;31mERROR\e[0m] An error was encountered while executing \"find\". [$find_exec_status]"
		fi
	fi
fi

echo -e "[$(timestamp)][\e[1;33mNOTICE\e[0m] Exiting."
exit 0