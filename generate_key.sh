#!/bin/bash

##############################################
##title           : generateLiveImage.sh
##description     : this script builds a debian live image, then writes it on a given media
##author          : ksamak
##Date            : 2014/01/27
##Licence         : GPLv3+
##Version         : 1.0.0
##usage           : generateLiveImage.sh
##notes           : Install live-build cdebootstrap parted to use this script
##############################################



usage() {
    echo "should display usage"
    exit 0;
}

version() {
    echo "0.2"
    exit 0
}

##################
## ARG PARSING
while [[ $# > 0 ]]; do
    key="$1"
    shift;
    case $key in
        -v|--verbose) DEBUG=YES;;
        --version) vers=YES;;
        -i|--input) file="$1"; shift;;
        -s|--splash) splash_image="$1"; shift;;
        --no-build) no_build=YES;;
        --no-write) no_write=YES;;
        -q|--quiet) quiet=YES;;
        *) if [ -n "$media" ]; then
           usage;
           else
           media="$key"; 
           fi;; # positionnal arg
    esac
done
##################

## support functions ##
NORMAL=$(tput -T xterm sgr0)
GREEN=$(tput -T xterm setaf 2; tput -T xterm bold)
YELLOW=$(tput -T xterm setaf 3)
RED=$(tput -T xterm setaf 1)

red() {
    echo "$RED$*$NORMAL"
}
green() {
    echo "$GREEN[INFO]  $*$NORMAL"
}
yellow() {
    echo "$YELLOW[INFO]  $*$NORMAL"
}
debug() {
    [ "$DEBUG" ] && echo "$YELLOW[DEBUG] $NORMAL$*";
}
debug "debug on"

check() {
    if [ ${?} -ne 0 ]; then red "[ERROR] $*"; exit 1; fi
}

# you should exec "apt-get install live-build cdebootstrap parted" if not done TODO

watch_splash() {
    while true; do
        stat "binary/isolinux/splash.png" 2> /dev/null
        if [ ${?} = 0 ]; then
            red "copying $1 to binary/isolinux/splash.png NOW!";
            cp $1 binary/isolinux/splash.png;
            break
        fi
        sleep 0.2
    done
}

killAndQuit() {
    kill -9 $!
    red "killing loop and existing"
    exit 0
}
hooks() {
	# A11Y environment
	cat << EOF > config/hooks/a11y.chroot
	#!/bin/sh

	set -e

	echo "GTK_MODULES=gail:atk-bridge" >> /etc/profile

		cat << EOF > /etc/xdg/autostart/orca-autostart.desktop
[Desktop Entry]
Type=Application
Name=Orca screen reader
Exec=orca
NoDisplay=true
AutostartCondition=GSettings org.gnome.desktop.a11y.applications screen-reader-enabled
X-GNOME-AutoRestart=true
#X-GNOME-Autostart-Phase=Initialization
OnlyShowIn=GNOME;MATE;Unity;Cinnamon;
		EOF

	# Automatic lightdm login
	cat << EOF > /etc/lightdm/lightdm.conf
#
# General configuration
#
# start-default-seat = True to always start one seat if none are defined in the configuration
# greeter-user = User to run greeter as
# minimum-display-number = Minimum display number to use for X servers
# minimum-vt = First VT to run displays on
# lock-memory = True to prevent memory from being paged to disk
# user-authority-in-system-dir = True if session authority should be in the system location
# guest-account-script = Script to be run to setup guest account
# logind-load-seats = True to automatically set up multi-seat configuration from logind
# logind-check-graphical = True to on start seats that are marked as graphical by logind
# log-directory = Directory to log information to
# run-directory = Directory to put running state in
# cache-directory = Directory to cache to
# sessions-directory = Directory to find sessions
# remote-sessions-directory = Directory to find remote sessions
# greeters-directory = Directory to find greeters
#
[LightDM]
#start-default-seat=true
#greeter-user=lightdm
#minimum-display-number=0
#minimum-vt=7
#lock-memory=true
#user-authority-in-system-dir=false
#guest-account-script=guest-account
#logind-load-seats=false
#logind-check-graphical=false
#log-directory=/var/log/lightdm
#run-directory=/var/run/lightdm
#cache-directory=/var/cache/lightdm
#sessions-directory=/usr/share/lightdm/sessions:/usr/share/xsessions
#remote-sessions-directory=/usr/share/lightdm/remote-sessions
#greeters-directory=/usr/share/lightdm/greeters:/usr/share/xgreeters

#
# Seat defaults
#
# type = Seat type (xlocal, xremote)
# xdg-seat = Seat name to set pam_systemd XDG_SEAT variable and name to pass to X server
# pam-service = PAM service to use for login
# pam-autologin-service = PAM service to use for autologin
# pam-greeter-service = PAM service to use for greeters
# xserver-command = X server command to run (can also contain arguments e.g. X -special-option)
# xserver-layout = Layout to pass to X server
# xserver-config = Config file to pass to X server
# xserver-allow-tcp = True if TCP/IP connections are allowed to this X server
# xserver-share = True if the X server is shared for both greeter and session
# xserver-hostname = Hostname of X server (only for type=xremote)
# xserver-display-number = Display number of X server (only for type=xremote)
# xdmcp-manager = XDMCP manager to connect to (implies xserver-allow-tcp=true)
# xdmcp-port = XDMCP UDP/IP port to communicate on
# xdmcp-key = Authentication key to use for XDM-AUTHENTICATION-1 (stored in keys.conf)
# unity-compositor-command = Unity compositor command to run (can also contain arguments e.g. unity-system-compositor -special-option)
# unity-compositor-timeout = Number of seconds to wait for compositor to start
# greeter-session = Session to load for greeter
# greeter-hide-users = True to hide the user list
# greeter-allow-guest = True if the greeter should show a guest login option
# greeter-show-manual-login = True if the greeter should offer a manual login option
# greeter-show-remote-login = True if the greeter should offer a remote login option
# user-session = Session to load for users
# allow-user-switching = True if allowed to switch users
# allow-guest = True if guest login is allowed
# guest-session = Session to load for guests (overrides user-session)
# session-wrapper = Wrapper script to run session with
# greeter-wrapper = Wrapper script to run greeter with
# guest-wrapper = Wrapper script to run guest sessions with
# display-setup-script = Script to run when starting a greeter session (runs as root)
# display-stopped-script = Script to run after stopping the display server (runs as root)
# greeter-setup-script = Script to run when starting a greeter (runs as root)
# session-setup-script = Script to run when starting a user session (runs as root)
# session-cleanup-script = Script to run when quitting a user session (runs as root)
# autologin-guest = True to log in as guest by default
# autologin-user = User to log in with by default (overrides autologin-guest)
# autologin-user-timeout = Number of seconds to wait before loading default user
# autologin-session = Session to load for automatic login (overrides user-session)
# autologin-in-background = True if autologin session should not be immediately activated
# exit-on-failure = True if the daemon should exit if this seat fails
#
[SeatDefaults]
#type=xlocal
#xdg-seat=seat0
#pam-service=lightdm
#pam-autologin-service=lightdm-autologin
#pam-greeter-service=lightdm-greeter
#xserver-command=X
#xserver-layout=
#xserver-config=
#xserver-allow-tcp=false
#xserver-share=true
#xserver-hostname=
#xserver-display-number=
#xdmcp-manager=
#xdmcp-port=177
#xdmcp-key=
#unity-compositor-command=unity-system-compositor
#unity-compositor-timeout=60
#greeter-session=example-gtk-gnome
#greeter-hide-users=false
#greeter-allow-guest=true
#greeter-show-manual-login=false
#greeter-show-remote-login=true
#user-session=default
#allow-user-switching=true
#allow-guest=true
#guest-session=
#session-wrapper=lightdm-session
#greeter-wrapper=
#guest-wrapper=
#display-setup-script=
#display-stopped-script=
#greeter-setup-script=
#session-setup-script=
#session-cleanup-script=
#autologin-guest=false
autologin-user=user
autologin-user-timeout=0
#autologin-in-background=false
#autologin-session=UNIMPLEMENTED
#exit-on-failure=false

#
# Seat configuration
#
# Each seat must start with "Seat:".
# Uses settings from [SeatDefaults], any of these can be overriden by setting them in this section.
#
#[Seat:0]

#
# XDMCP Server configuration
#
# enabled = True if XDMCP connections should be allowed
# port = UDP/IP port to listen for connections on
# key = Authentication key to use for XDM-AUTHENTICATION-1 or blank to not use authentication (stored in keys.conf)
#
# The authentication key is a 56 bit DES key specified in hex as 0xnnnnnnnnnnnnnn.  Alternatively
# it can be a word and the first 7 characters are used as the key.
#
[XDMCPServer]
#enabled=false
#port=177
#key=

#
# VNC Server configuration
#
# enabled = True if VNC connections should be allowed
# command = Command to run Xvnc server with
# port = TCP/IP port to listen for connections on
# width = Width of display to use
# height = Height of display to use
# depth = Color depth of display to use
#
[VNCServer]
#enabled=false
#command=Xvnc
#port=5900
#width=1024
#height=768
#depth=8
	EOF
EOF
}

build_image() {
    yellow "cleaning potential previous builds"
    ## cleaning in case of previous build ##
    debug "rm -rf auto .build chroot* config local *.iso* binary.* binary*"
    rm -rf auto .build chroot* local *.iso* binary.* config binary*
    if [ ${?} -ne 0 ]; then debug "removal of previous build went wrong."; fi
    debug "removal ok."

    ############################################################
    ######### Image configuration. choose your options #########
    yellow "configuring build"  # for more info on building options, run man lb_config
    lb config \
        --binary-images iso-hybrid \
        --apt apt-get \
        --architecture amd64 \
        --bootappend-live 'boot=live access=v3 config quiet splash persistence' \
        --firmware-chroot true \
        --firmware-binary true \
        --backports false \
        --updates true \
        --distribution jessie \
        --apt-recommends true \

    check "Config of image failed."
    green "build configured"

##################################################
############## CONFIG THAT WORK!! ################
#        --binary-images iso-hybrid \
#        --apt aptitude \
#        --architecture i386 \
#        --bootappend-live 'boot=live config quiet splash persistence' \
##################################################
#        --bootappend-live 'boot=live config quiet splash persistence' \
#        --binary-images iso-hybrid \
#        --apt aptitude \
#        --architecture i386 \
#        --firmware-chroot true \
#        --archive-area "main contrib non-free" \
#        --firmware-binary true \
#        --backports true \
#        --updates true \
#        --apt aptitude \
#        --grub-splash "splash.png" \
#        --distribution wheezy \
#        --apt-recommends true \
##################################################
##################################################


    ####################################################################
    ########## Packages section. choose wich packages you like #########
    ## Debian recommends the maintained metapackages beginning by "task-"
    yellow "setting installation packages"
    # system section
    echo "brltty openssh-server"     >> config/package-lists/system.list.chroot
    check "failed to set install packages."
    echo "cryptsetup ecryptfs-utils"                   >> config/package-lists/system.list.chroot
    # desktop section
    echo "task-french-desktop task-french"  >> config/package-lists/desktop.french.list.chroot # for the french
    echo "task-mate-desktop"                >> config/package-lists/desktop.mate.list.chroot
    echo "gparted"                          >> config/package-lists/desktop.tools.list.chroot
    # non-free section
    #echo "flashplugin-nonfree"              >> config/package-lists/desktop.non-free.list.chroot

    # a11y section

	# Add Hypra's repository
    echo "deb http://debian.hypra.fr/debian/ jessie main" >> config/archives/hypra.list.chroot
    echo "deb-src http://debian.hypra.fr/debian/ jessie main" >> config/archives/hypra.list.chroot
    cat hypra-repository >> config/archives/hypra.key.chroot

	# Hypra and its dependencies
    #echo "gnome-orca hypra"              >> config/package-lists/desktop.a11y.list.chroot
>>>>>>> e31476dc17024fc7dff85f6251a716cd822e8b37

    green "packaging configured"


    ##############################################################
    ###### set the optional watch loop for the splash image ######
    if [ -n "$splash_image" ]; then
        stat $splash_image > /dev/null
        check "ooops, can't reach selected splash image?"
        debug "mkdir binary/isolinux"
        watch_splash $splash_image &
        trap "killAndQuit" SIGINT
    fi

    ##############################
    ######### then build #########
    yellow "building"
    if [ -n "$DEBUG" ]; then
        lb build;
    else
        lb build --quiet > /dev/null;
    fi
    check "Build of image failed";

    # kill optional splash image loop subshell.
    if [ -n "$splash_image" ]; then
        kill -9 $!; # kill the watch loop.
        trap - SIGINT;
    fi

    green "build complete"
}

write_image() {
    debug "writing image"
    yellow "checking parameters for image write"
    stat $media > /dev/null
    check "selected device does not exist."
    stat binary.hybrid.iso  > /dev/null
    check "couldn't find hybrid iso to write."
    green "ready to write media"

    if [ -z "$quiet" ]; then 
        yellow "about to override partitions on $media, do you wish to continue?"
        read -p "type \"yes\" to continue: " CONFIRM
        if [ "$CONFIRM" != "yes" ]; then exit 0; fi
    else
        debug "not asking for permission to write on media"
    fi
    yellow "overwriting partitions on $media"
    debug "dd if=binary.hybrid.iso of=$media"
    dd if=binary.hybrid.iso of=$media
    check "unable to write image on media, you may need root priviledges. (note: use --no-build to bypass build and write directly)"
    green "base image written to media"

    PART1_SIZE=$(parted -m $media unit s print | grep "boot\, hidden" | cut -d ":" -f 3 | cut -d "s" -f 1)
    check "couldn't read media partition size"
    PART2_BEGINNING=$(($PART1_SIZE+1))
    PART2_END=$(parted -m $media unit s print | grep "$media" | cut -d ":" -f 2 | cut -d "s" -f 1)
    check "couldn't read media key size"
    PART2_END=$(($PART2_END-1))

    debug "parted -a optimal -s $media unit s mkpart primary $PART2_BEGINNING $PART2_END"
    yellow "overrideing partitions on $media"
    parted -a optimal -s $media unit s mkpart primary $PART2_BEGINNING $PART2_END
    debug "mkfs.ext4 -L persistence $media$((2))"
    mkfs.ext4 -L persistence $media$((2))
    check "unable to create ext4 filesystem on media"
    green "persistence filesystem created"

    mkdir mounted
    check "unable to create folder to mount media"
    yellow "mounting partition to insert persistence.conf"
    debug "mount -t ext4 $media$((2)) mounted"
    mount -t ext4 $media$((2)) mounted
    echo "/ union" > mounted/persistence.conf
    #echo "/ union" >> mounted/persistence.conf ## feel free to customize the folders.
    yellow "mounted persistence partition and set persistence folders"
    umount mounted
    rmdir mounted
    green "persistence file set"
    green "image sucessfully written."

}

if [ -n "$file" ]; then
    file=binary.hybrid.iso;
fi

if [ -n "$vers" ]; then
    version;
fi

if [ -z "$no_build" ]; then
    build_image;
else
    yellow "not building image";
fi

if [ -z "$no_write" ]; then
    write_image;
else
    yellow "not writing image";
fi

exit 0

