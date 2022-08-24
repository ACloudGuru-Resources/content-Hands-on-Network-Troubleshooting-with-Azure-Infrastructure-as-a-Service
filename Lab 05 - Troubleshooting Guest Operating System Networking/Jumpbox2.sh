#!/bin/sh
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install xfce4
sudo apt install xfce4-session
sudo apt-get -y install 
sudo systemctl enable xrdp
sudo adduser xrdp ssl-cert
echo xfce4-session >~/.xsession
sudo service xrdp restart
sudo apt install firefox -y
xfconf-query -c xfwm4 -p /general/use_compositing -t bool -s false