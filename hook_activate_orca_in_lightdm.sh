#!/bin/sh
set -e

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
[LightDM]

[SeatDefaults]
autologin-user=user
autologin-user-timeout=0

[XDMCPServer]

[VNCServer]
EOF

