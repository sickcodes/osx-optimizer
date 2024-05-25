# OSX-Optimizer
OSX Optimizer: Optimize MacOS - Shell scripts to speed up your mac boot time, accelerate loading, and prevent unnecessary throttling.

macOS can be heavily modified using the `defaults` command. In fact, almost every option is accessible via `defaults`.

A great way to see what ticking and unticking a box in the Settings App is by using:

```bash
defaults read > defaults.pre.txt

# *make a change in Settings*

defaults read > defaults.post.txt

diff defaults.pre.txt defaults.post.txt
```

# OSX Optimizations

Below you will find extremely good optimizers, particularly for virtual machines.

Some of the commands are dangerous from a remote access perspective, but they will greatly optimize your VM.


## Skip the GUI login screen (at your own risk!)
```bash
defaults write com.apple.loginwindow autoLoginUser -bool true
```

User accounts and root/administrator have different `defaults`

## Disable spotlight indexing on macOS to heavily speed up Virtual Instances.

```bash
# massively increase virtualized macOS by disabling spotlight.
sudo mdutil -i off -a

# since you can't use spotlight to find apps, you can re-enable with
# sudo mdutil -i on -a

```

## Enable performance mode

Turn on performance mode to dedicate additional system resources for server applications.

Details: https://support.apple.com/en-us/HT202528

```
# check if enabled (should contain `serverperfmode=1`)
nvram boot-args

# turn on
sudo nvram boot-args="serverperfmode=1 $(nvram boot-args 2>/dev/null | cut -f 2-)"

# turn off
sudo nvram boot-args="$(nvram boot-args 2>/dev/null | sed -e $'s/boot-args\t//;s/serverperfmode=1//')"
```

## Disable heavy login screen wallpaper

```bash
sudo defaults write /Library/Preferences/com.apple.loginwindow DesktopPicture ""
```

## Reduce Motion & Transparency

```bash
defaults write com.apple.Accessibility DifferentiateWithoutColor -int 1
defaults write com.apple.Accessibility ReduceMotionEnabled -int 1
defaults write com.apple.universalaccess reduceMotion -int 1
defaults write com.apple.universalaccess reduceTransparency -int 1
```


## Enable multi-sessions

```bash
sudo /usr/bin/defaults write .GlobalPreferences MultipleSessionsEnabled -bool TRUE

defaults write "Apple Global Domain" MultipleSessionsEnabled -bool true
```

## Disable updates (at your own risk!)
This will prevent macOS from downloading huge updates, filling up your disk space.

Disabling updates heavily speeds up virtualized macOS because the qcow2 image does not grow out of proportion.

```bash
# as roots
sudo su
defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false
defaults write com.apple.commerce AutoUpdate -bool false
defaults write com.apple.commerce AutoUpdateRestartRequired -bool false
defaults write com.apple.SoftwareUpdate ConfigDataInstall -int 0
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 0
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 0
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 0
```

## Enable `osascript` over SSH automatically without **sshd-keygen warning** and **full disk access**

```bash

defaults write com.apple.universalaccessAuthWarning /System/Applications/Utilities/Terminal.app -bool true
defaults write com.apple.universalaccessAuthWarning /usr/libexec -bool true
defaults write com.apple.universalaccessAuthWarning /usr/libexec/sshd-keygen-wrapper -bool true
defaults write com.apple.universalaccessAuthWarning com.apple.Messages -bool true
defaults write com.apple.universalaccessAuthWarning com.apple.Terminal -bool true

```

## Disable screen locking

```bash
defaults write com.apple.loginwindow DisableScreenLock -bool true
```

## Show a lighter username/password prompt instead of a list of all the users

```bash
defaults write /Library/Preferences/com.apple.loginwindow.plist SHOWFULLNAME -bool true
defaults write com.apple.loginwindow AllowList -string '*'

```

## Disable saving the application state on shutdown

This speeds up boot as the session state (currently opened apps) are not running when you reboot.

This may be slower for you depending on what you are doing.

```bash
defaults write com.apple.loginwindow TALLogoutSavesState -bool false
```

Enable AnyDesk automatically

```bash

defaults write com.apple.universalaccessAuthWarning "/Applications/AnyDesk.app" -bool true
defaults write com.apple.universalaccessAuthWarning "/Applications/AnyDesk.app/Contents/MacOS/AnyDesk" -bool true
defaults write com.apple.universalaccessAuthWarning "3::/Applications" -bool true
defaults write com.apple.universalaccessAuthWarning "3::/Applications/AnyDesk.app" -bool true
defaults write com.apple.universalaccessAuthWarning "com.philandro.anydesk" -bool true

```

## Enable remote access (at your own risk!)

```bash
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
    -activate \
    -configure \
    -access \
    -off \
    -restart \
    -agent \
    -privs \
    -all \
    -allowAccessFor -allUsers
```

## Connect WiFi to strongest Access Point
Make WiFi stay connected to the strongest (usually closest) AP available.

MacOS did not specify this behavior by default.

```bash
sudo /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport prefs JoinMode=Strongest
```



# EXTREMELY INSECURE METHODS (at your own risk!)

These macOS optimizations should only be used in CI/CD, behind a VPN, and with no external connectivity.

This is not a warning, it is absolutely essential, or anyone can just SSH into the remote mac.

If you do any of the below commands on a remote server, you will

## Disable passwords globally

- Everyone is now root
- No need to type passwords
- SSH login just hit enter for password

As root:

```bash
sudo su
# nuke pam
for PAM_FILE in /etc/pam.d/*; do
    sed -i -e s/required/optional/g "${PAM_FILE}"
    sed -i -e s/sufficient/optional/g "${PAM_FILE}"
done
```



sudo killall Finder || true
sudo killall Dock || true
sudo killall mds


## Make everyone a sudoer

```bash
cd /Users
# add everyone to sudoers and import the control center plist
for REAL_NAME in *; do
    echo "${REAL_NAME}"
    tee "/etc/sudoers.d/${REAL_NAME}" <<< "${REAL_NAME}     ALL=(ALL)       NOPASSWD: ALL"
    # sudo -u "${REAL_NAME}" defaults write -globalDomain NSUserKeyEquivalents  -dict-add "Save as PDF\\U2026" "@\$p";
    sudo -u "${REAL_NAME}" sudo mdutil -i off -a
    # sudo -u "${REAL_NAME}" defaults import com.apple.controlcenter /tmp/com.apple.controlcenter.plist
    # sudo -u "${REAL_NAME}" defaults write "/Users/${REAL_NAME}/Library/Preferences/.GlobalPreferences MultipleSessionEnabled" -bool 'YES'
    # sudo -u mdutil -i off -a
    # sudo dscl . -create "/Users/${REAL_NAME}" UserShell "${USERSHELL}"
    sudo -u "${REAL_NAME}" "whoami"
done
#############################3

```


# Disable apps from going to sleep at all
This command will prevent applications from sleeping, completely in the background.

You can verify this using the `top` command and an App should never go into `sleeping` state.

This increases RAM usage, but means your apps, like Xcode, will spring into action.

```bash
sudo -u "${REAL_NAME}" sudo defaults write NSGlobalDomain NSAppSleepDisabled -bool YES
```



