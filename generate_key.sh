#!/bin/bash

##############################################
##title           : generateLiveImage.sh
##description     : this script builds a debian live image, then writes it on a given media
##author          : ksamak
##Date            : 2014/01/27
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
        --archive-area "main contrib non-free" \
        --firmware-binary true \
        --backports true \
        --updates true \
        --distribution jessie \
        --apt-recommends true \
	--system live

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
    # vital section
#    echo "vim most tmux openssh-server"     >> config/package-lists/system.list.chroot
    echo "brltty openssh-server"     >> config/package-lists/system.list.chroot
#    check "failed to set install packages."
#    echo "htop"     >> config/package-lists/system.list.chroot
#    echo "cryptsetup ecryptfs-utils"                   >> config/package-lists/system.list.chroot
    # desktop section
    #echo "task-french-desktop task-french"  >> config/package-lists/desktop.french.list.chroot # for the french
#    echo "task-xfce-desktop"                >> config/package-lists/desktop.xfce.list.chroot
    echo "task-mate-desktop"                >> config/package-lists/desktop.mate.list.chroot
    echo "gparted"                          >> config/package-lists/desktop.tools.list.chroot
    # non-free section
    echo "flashplugin-nonfree"              >> config/package-lists/desktop.non-free.list.chroot

    # a11y section

	# Add Hypra's repository
  echo "deb http://debian.hypra.fr/debian/ jessie main" >> config/archives/hypra.list.chroot
  echo "deb-src http://debian.hypra.fr/debian/ jessie main" >> config/archives/hypra.list.chroot
cat << EOF >> config/archives/hypra.key.choot

-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.4.12 (GNU/Linux)

mQINBFRSQMIBEACUKn8LkfTnVx+74FMC4smfjZpURgJw5vvEcce/Sk28Ih5QVXt/
bi+jZTTnxOspDCqVc36g1wYKaFf5XuKl5Frg1PKAC0z5GT+s2hHT3W4DTBBq9arB
Upf33cTb/0X+h2u+hjvLxu82Y8ikMrb+yfNUG3d+b1wExlT9RVycFD6FyVLGuUcl
Ocm6wVu9xKvK/elenY4CjZANC1Y9ABAAWsphnVWpQZ84B6J2yB5T95DTwCxulzFT
wYo40HfMwwDHy/kTziYz5o0P8BYVIDOXSMdVHxsPQhbNx36Uo1hzDtRf0Rggc1gj
Ly5g/HBYaOSDBiVHPcn2VNe+WYUZGyJAPpV/5OJdmbmrj5GPC5WjKfOJkZ3+zrDo
23vPV4ebWTvr1OZGE5QQlv9r7zqzdPLSQ3YJ8ujSWTppMeG3e/Z+ZG2/eSJek1la
7XqmivlkEpvJMrFd66nYm8j1d6ldMUgIRvWeCIJlQG9pfTUsRvq7iRMLO6gEN1Hn
G/hjWC5/0b/dqjU4dTR7h4RVShN1RAf6WT2zmqcfjth59ci1WoGAQ1X3Pp5YoI3m
deHa7MwnWwsgsLS73mhD1w2/PREzkZgZ1Qs4xSOwlt+t5m38y8sUQVlQr7m1xto6
mH7yonfQG+cHC6dL/f27TcoDcWnYiOEEMcWq8IPn4L1gO5jkwfWSLvpcvwARAQAB
tCJhY2NlbGlicmVpbmZvIC0gamVua2lucyBhdXRvIGJ1aWxkiQI4BBMBAgAiBQJU
UkDCAhsDBgsJCAcDAgYVCAIJCgsEFgIDAQIeAQIXgAAKCRCw6vGaAjhHHsR9D/wM
kJFLh9+9Yoe7anrMAg2CxZpY7SskOeCqJMZx1qUdy9UG9xs0dAIT+/RXMdDFMOGU
ibsZfmr10PFOh+U8iUSgipq199uGk8R7G8B5/LqhFK8eWEJwGa9FNDhvUfkfT/fp
kGRwLD07g+0XuEiEgiOQa9bnYmcUjwdZR4FJdT5p/rIfrIAi2ldtb8La29Oz2Kmo
ed6K1pUrJ3Aw6CD1O2o6/PLVJ4b2hid5/WFqwFkI1XwO7445Xs4zLYLs+pf3KGGk
vNGEjy3aIEMgXKziVboMYNpGhzuWIZZULRAg7lk9lQg8WRc+I3evj/wD9aL9OoUP
m8WUmZtTfqt0i/bzJzBcw444vDumkw/aE4hPzvypmfJLgZyNSKLSqk4eZuRUW/aG
QVxWYQXUeoMUMPEw5OAH/GlLdUTf2iv/FxEo7zQINsALwz1ZJAlUPaNuBeF5M4ut
oi8l50CncpouwosHFdst6kxftujUG6RmCTqB679pXHx6UPzTbcPcyJ9Z0SfR1ZDc
PATYEWZNBCecFEIHhui7ybtZ35OeUgKlFPfm38d4xpZfzlO4+Ot9fx7bGi9pVSop
DZczyGz3JOAmhMtzso9p+zTDftvu4U4qfzPz9rcOJVOvUkgsHzpx2PUNbw2bpwVJ
xCDZZY8gcKeNCK8cpSyEnrjuxkDBRp5ym+M/FCiDjQ==
=acfX
-----END PGP PUBLIC KEY BLOCK-----
EOF

	# Hypra and its dependencies
    echo "gnome-orca hypra"              >> config/package-lists/desktop.a11y.list.chroot
    green "packaging configured"


    #########################################
    ###### set the optional watch loop ######

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
    # abort and kill optional loop subshell.
    if [ ${?} -ne 0 ]; then
        red "[ERROR] Build of image failed";
        if [ -n "$splash_image" ]; then
            kill -9 $!; # kill the watch loop.
        fi
        exit 1;
    fi

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

