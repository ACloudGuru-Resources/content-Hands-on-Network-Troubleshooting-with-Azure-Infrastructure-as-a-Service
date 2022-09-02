#!/bin/sh
sudo apt update > /dev/null
#Install xfce4
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install xfce4
sudo apt install xfce4-session
#Install and configure xrdp
sudo apt-get -y install xrdp
sudo systemctl enable xrdp
sudo adduser xrdp ssl-cert
echo xfce4-session >~/.xsession
sudo service xrdp restart
#Install firefox
sudo apt install firefox -y
#Disable compositing for improved performance
/usr/bin/xfconf-query -c xfwm4 -p /general/use_compositing -s false
#Remove wallpapers for performance
sudo rm /usr/share/backgrounds/xfce/xfce/xfce-blue.jpg
sudo rm /usr/share/backgrounds/xfce/xfce/xfce-teal.jpg
#Add a hosts entry
echo "192.168.0.1 escape.lab.vnet" | sudo tee -a /etc/hosts