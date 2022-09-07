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
#Improve performance
echo 'cp /etc/xdg/xfce4/panel/default.xml ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml' | sudo tee -a /etc/profile
echo 'xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/image-style -n -t int -s 0' | sudo tee -a /etc/profile
echo '/usr/bin/xfconf-query -c xfwm4 -p /general/use_compositing -s false' | sudo tee -a /etc/profile
#Generate a random number
rand=$(( ( RANDOM % 10 )  + 1 ))
if [ $rand -le 4 ]
then
    #Add a hosts entry to break DNS
    echo "192.168.0.1 escape.lab.vnet" | sudo tee -a /etc/hosts
fi
if [ $rand -ge 5 ]
then
    #Add a firewall and rule to break outbound traffic
    sudo iptables -t FILTER -A OUTPUT -p tcp --dport 80 -j REJECT
    sudo iptables save
fi