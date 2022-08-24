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
xfconf-query -c xfwm4 -p /general/use_compositing -t bool -s false --create
#Add a hosts entry
echo "192.168.0.1 escapedoor.lab.vnet" | sudo tee -a /etc/hosts