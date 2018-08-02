#!/bin/bash

##############################################
##title           : generate_key.sh
##description     : this script builds a debian live image, then writes it on a given media
##authors         : ksamak raphaelpoitevin Nornort
##Date            : 2018/08/01
##Licence         : GNU AGPLv3
##Version         : 0.0.2
##usage           : generate_key.sh
##notes           : Install live-build cdebootstrap parted to use this script
##############################################



usage() {
    echo "should display usage"
    exit 0;
}

version() {
    echo "0.0.2"
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
	cat hook_activate_gail_gtk_module.sh > config/hooks/activate_gail_gtk_module.chroot
	cat hook_activate_orca_in_lightdm.sh > config/hooks/activate_orca_in_lightdm.chroot
}

build_image() {
    yellow "cleaning potential previous builds"
    ## cleaning in case of previous build ##
    debug "rm -rf auto local *.iso* config binary.* binary* chroot* .build"
    rm -rf auto local *.iso* config binary.* binary* chroot* .build
    if [ ${?} -ne 0 ]; then debug "removal of previous build went wrong."; fi
    debug "removal ok."

    ############################################################
    ######### Image configuration. choose your options #########
    yellow "configuring build"  # for more info on building options, run man lb_config
    lb config \
        --binary-images iso-hybrid \
        --architecture amd64 \
        --apt aptitude \
        --bootappend-live 'boot=live access=v3 config quiet splash persistence' \
        --firmware-chroot true \
        --firmware-binary true \
        --backports false \
        --updates true \
        --distribution stretch \
        --apt-recommends true \
        --debian-installer live \
        --security true \
        --source true \
        --archive-areas "main contrib non-free" \
        --iso-preparer Nornort \
        --iso-publisher Nornort
#        --mirror-bootstrap http://ftp.fr.debian.net/debian/ \
#        --mirror-binary http://ftp.fr.debian.net/debian/ \
#        --mirror-chroot-security http://security.debian.org/ \

        #--debian-installer-preseedfile TODO
        #--bootappend-install TODO add speech n shit, like access=v3

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
#        --distribution stretch \
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
    echo "kexec-tools debian-installer debian-installer-launcher"                   >> config/package-lists/system.list.chroot
    echo "firmware-linux-free firmware-linux-nonfree"                   >> config/package-lists/system.list.chroot
    # desktop section
    echo "task-french-desktop task-french"  >> config/package-lists/desktop.french.list.chroot
    echo "task-mate-desktop"                >> config/package-lists/desktop.mate.list.chroot
    echo "gparted"                          >> config/package-lists/desktop.tools.list.chroot
    # non-free section
    #echo "flashplugin-nonfree"              >> config/package-lists/desktop.non-free.list.chroot

    # a11y section

	# Add Hypra's repository
    echo "deb http://debian.hypra.fr/debian/ stretch main contrib non-free" >> config/archives/hypra.list.chroot
    check "couldn't add extra repository"
    echo "deb-src http://debian.hypra.fr/debian/ stretch main contrib non-free" >> config/archives/hypra.list.chroot
    echo "deb http://debian.hypra.fr/debian/ stretch main contrib non-free" >> config/archives/hypra.list.binary
    echo "deb-src http://debian.hypra.fr/debian/ stretch main contrib non-free" >> config/archives/hypra.list.binary
    cat hypra-repository.gpg >> config/archives/hypra.key.chroot
    #add mate-access packages
    echo "hypra-full-fr"                          >> config/package-lists/desktop.tools.list.chroot
    echo "hypra-archive-keyring"                          >> config/package-lists/desktop.tools.list.chroot
    echo "hypra-dropbox"                          >> config/package-lists/desktop.tools.list.chroot
    echo "hypra-kali"                          >> config/package-lists/desktop.tools.list.chroot
    echo "hypra-qt"                          >> config/package-lists/desktop.tools.list.chroot
    echo "hypra-voxygen-fr"                          >> config/package-lists/desktop.tools.list.chroot

	# Hypra and its dependencies
    #echo "gnome-orca hypra"              >> config/package-lists/desktop.a11y.list.chroot

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

