#!/bin/bash
# Author:       sickcodes
# Contact:      https://twitter.com/sickcodes
# Project:      https://github.com/sickcodes/osx-optimizer
# Copyright:    sickcodes (C) 2021
# License:      GPLv3+

help_text="Usage: ./useradd-bulk.sh

Purpose:
    This script will create: user501, user502, etc.
    No passwords are set by default, so they can't login
    Set someones's password with 'sudo passwd billy'

General options:
    --count  <count>     Number of users to be created
    --prefix <string>    Prefix of usernames, default is user
    --name   <string>    Same as above
    --shell  <path>      New users' shell, e.g. /bin/bash
    --group  <integer>   Elect each user into a group ID
    --help               Display this help and exit

Flags:
    --mkdirs             Create a home directory for everyone
    --disable-spotlight  Disable spotlight for everyone

Insecure options:
    --passwd <string>    Give everyone this password

EXTREMELEY Insecure options:
    --disable-passwords  Disable passwords globally
    --all-sudoers        Make everyone super user (sudoer)

Author:  Sick.Codes https://sick.codes
Project: https://github.com/sickcodes/osx-optimizer
License: GPLv3+

--> AS ROOT <--

"

[[ "$(whoami)" != root ]] && { echo "${help_text}" && exit ; }

# gather arguments
while (( "$#" )); do
    case "${1}"  in

    --help | -h | h | help ) 
                echo "${help_text}" && exit 0
            ;;

    --count=* )
                export USER_COUNT="${1#*=}"
                shift
            ;;

    --count* )
                export USER_COUNT="${2}"
                shift
                shift
            ;;

    --prefix=* | --name=* ) 
                export PREFIX="${1#*=}"
                shift
            ;;
    --prefix* | --name* )
                export PREFIX="${2}"
                shift
                shift
            ;;

    --password=* | --passwd=* ) 
                export USER_PASSWORD="${1#*=}"
                shift
            ;;
    --password* | --passwd* )
                export USER_PASSWORD="${2}"
                shift
                shift
            ;;
    --group=* ) 
                export GROUP_ID="${1#*=}"
                shift
            ;;
    --group* )
                export GROUP_ID="${2}"
                shift
                shift
            ;;
    --shell=* ) 
                export USER_SHELL="${1#*=}"
                shift
            ;;
    --shell* )
                export USER_SHELL="${2}"
                shift
                shift
            ;;
    --disable-spotlight )
                export DISABLE_SPOTLIGHT=1
                shift
            ;;
    --mkdirs )
                export MKDIRS=1
                shift
            ;;
    --all-sudoers ) 
                export ALL_SUDOERS=1
                shift
            ;;
    --disable-passwords ) 
                export DISABLE_PASSWORDS=1
                shift
            ;;
    *)
                echo "${help_text}" && exit 0
            ;;
    esac
done

# fetch the next available UniqueID. For example 501, 502, 503...
CURRENT_MAX_USER="$(dscl . -list /Users UniqueID | awk -F\  '{ print $2 }' | sort -n | tail -n1)"
CURRENT_MAX_USER="${CURRENT_MAX_USER:=501}"

# shout out defaults
echo "User Count:       "${USER_COUNT:=0}""
echo "User Prefix:      "${PREFIX:=user}""
echo "User Shell        "${USER_SHELL:=/bin/bash}""
echo "User Password     "${PASSWORD:=''}""
echo "Current max       "${CURRENT_MAX_USER}""

STARTING_FROM="$((CURRENT_MAX_USER+1))"
echo "Starting from     "${STARTING_FROM}""

NEXT_USER="${STARTING_FROM}"
ENDING_AT="$((NEXT_USER+${USER_COUNT}))"
echo "Ending at         "$((NEXT_USER+USER_COUNT))""

# e.g. alf502 next
[[ "${PREFIX}" = None ]] && unset PREFIX

REAL_NAME="${PREFIX}${NEXT_USER}"
echo "FIRST username    "${REAL_NAME}""
LAST_NAME="${PREFIX}${ENDING_AT}"
echo "LAST  username    "${LAST_NAME}""

USER_ARRAY=($(seq "${STARTING_FROM}" "${ENDING_AT}"))
echo USER_ARRAY "${USER_ARRAY[@]}" | xargs printf '%s\n'


# the user creation loop
for USER_ID in "${USER_ARRAY[@]}"; do
    REAL_NAME="${PREFIX}${USER_ID}"
    echo "${REAL_NAME}"
    sysadminctl -addUser \
        -addUser "${REAL_NAME}" \
        -fullName "${REAL_NAME}" \
        -UID "${USER_ID}" \
        -GID "${GROUP_ID}" \
        -shell /bin/bash \
        -password '' \
        -home "/Users/${REAL_NAME}"
        # -admin
    mkdir -p "/Users/${REAL_NAME}"
    # chown -R ${REAL_NAME}:20 /Users/${REAL_NAME}
done

# # the REALLY OLD WAY of user creation
# for USER_ID in "${USER_ARRAY[@]}"; do
#     echo "Creating ${USER_ID} with ${REAL_NAME}"
#     sudo dscl . -create "/Users/${REAL_NAME}"
#     sudo mkdir -p "/Users/${REAL_NAME}"
#     sudo dscl . -create "/Users/${REAL_NAME}" UserShell "${USERSHELL}"
#     sudo dscl . -create "/Users/${REAL_NAME}" RealName "${REAL_NAME}"
#     sudo dscl . -create "/Users/${REAL_NAME}" UniqueID "${USER_ID}"
#     sudo dscl . -create "/Users/${REAL_NAME}" PrimaryGroupID "${USER_ID}"
#     sudo dscl . -create "/Users/${REAL_NAME}" NFSHomeDirectory "/Users/${REAL_NAME}"
#     sudo dscl . -passwd "/Users/${REAL_NAME}" "${PASSWORD}"
#     sudo dscl . -append /Groups/admin GroupMembership "${USER_ID}"
# done

for USER_DIR in /Users/*; do
    case "${USER_DIR}" in
        /Users/administrator ) continue
            ;;
        /Users/user ) continue
            ;;
        /Users/Guest ) continue
            ;;
        /Users/Shared ) continue
            ;;
        "/Users/$(whoami)" ) continue
            ;;
    esac

done


# Test logging in as everyone
for USER_DIR in /Users/*; do

    # skip these users
    # TODO: make an option
    case "${USER_DIR}" in
        /Users/administrator ) continue
            ;;
        /Users/user ) continue
            ;;
        /Users/Guest ) continue
            ;;
        /Users/Shared ) continue
            ;;
        "/Users/$(whoami)" ) continue
            ;;
    esac

    echo "Creating & chowning ${USER_DIR}"
    REAL_NAME="$(basename "${USER_DIR}")"
    echo "${REAL_NAME}"
    USER_ID="${REAL_NAME//[^[:digit:]]/}"
    echo "${USER_ID}"

    # briefly log in as everyone
    sudo -u "${REAL_NAME}" "whoami"

    [[ "${MKDIRS}" ]] && {
        sudo mkdir -p "/${USER_DIR}/Library/Preferences"
        sudo chown -R ${REAL_NAME}:${USER_ID} "${USER_DIR}" 2>/dev/null || true
    ; }

    
    [[ "${USER_PASSWORD}" ]] && {
        sudo dscl . -passwd "${USER_DIR}" "${PASSWORD}"
    ; }


    # optionals as specified in the help text:
    [[ "${DISABLE_SPOTLIGHT}" ]] \
        && sudo -u "${REAL_NAME}" sudo mdutil -i off -a



    [[ "${DISABLE_PASSWORDS}" ]] \
        && sudo tee "/etc/sudoers.d/${REAL_NAME}" <<< "${REAL_NAME}     ALL=(ALL)       NOPASSWD: ALL"


    sudo -u "${REAL_NAME}" "/bin/bash -c 'sleep 3; exit;'"


    # skip the entire setup assistant
    sudo su -l "${REAL_NAME}" &
    sw_vers="$(sw_vers -productVersion)"
    sw_build="$(sw_vers -buildVersion)"
    sudo chmod 700 "/Users/${REAL_NAME}/Library"
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed SkipAppearance -bool true
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed SkipCloudSetup -bool true
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed SkipiCloudStorageSetup -bool true
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed SkipPrivacySetup -bool true
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed SkipSiriSetup -bool true
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed SkipTrueTone -bool true
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed SkipScreenTime -bool true
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed SkipTouchIDSetup -bool true
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed SkipFirstLoginOptimization -bool true
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed DidSeeCloudSetup -bool true
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed LastPrivacyBundleVersion "2"
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed LastSeenCloudProductVersion "${sw_vers}"
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed LastSeenDiagnosticsProductVersion "${sw_vers}"
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed LastSeenSiriProductVersion "${sw_vers}"
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed LastSeenBuddyBuildVersion "${sw_build}"      
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant SkipAppearance -bool true
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant SkipCloudSetup -bool true
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant SkipiCloudStorageSetup -bool true
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant SkipPrivacySetup -bool true
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant SkipSiriSetup -bool true
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant SkipTrueTone -bool true
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant SkipScreenTime -bool true
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant SkipTouchIDSetup -bool true
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant SkipFirstLoginOptimization -bool true
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant DidSeeCloudSetup -bool true
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant LastPrivacyBundleVersion "2"
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant LastSeenCloudProductVersion "${sw_vers}"
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant LastSeenDiagnosticsProductVersion "${sw_vers}"
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant LastSeenSiriProductVersion "${sw_vers}"
    sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant LastSeenBuddyBuildVersion "${sw_build}"      

    # chown user's directory
    sudo -u "${USER_ID}" sudo chown -R "$USER":"$(id -g)" "/Users/${USER}" 2>/dev/null

done

# MAKE EVERYONE A SUDO USER if --all-sudoers
# Extremely insecure, but helpful for CI/CD
if [[ "${ALL_SUDOERS}" ]]; then
    sudo sed -i -e s/required/optional/g /etc/pam.d/*
    sudo sed -i -e s/sufficient/optional/g /etc/pam.d/*
fi

# TODO:
# sudo -u "${USER_ID}" whoami
# sudo -u "${USER_ID}" "sudo pmset -a sleep 0; sudo pmset -a hibernatemode 0; sudo pmset -a disablesleep 1;"
# # enable automatic login
# sudo -u "${USER_ID}" defaults write NSGlobalDomain NSAppSleepDisabled -bool YES

# for USER_ID in *; do
#     echo "${USER_ID}"
#     sudo -u "${USER_ID}" osascript -e "tell application \"System Events\" to get the text field of every window of every application process" 2>/dev/null &
# done

# ps -ef | grep softwareupdated | awk '{print $2}' | xargs sudo kill -9

# killall Finder
# killall Dock

# sudo launchctl asuser 501 open /Applications/Calculator.app
# sudo launchctl asuser 501 open /System/Library/CoreServices/Dock.app/Contents/MacOS/Dock

# sudo /bin/launchctl bsexec PID chroot -u $UID -g $(id -g) / open /System/Applications/Messages.app/Contents/MacOS/Messages

