#!/bin/bash
#
# Original script by fornesia, rzengineer and fawzya
# ==================================================

# initialisasi var
export DEBIAN_FRONTEND=noninteractive
OS=`uname -m`;
MYIP=$(wget -qO- ipv4.icanhazip.com);
MYIP2="s/xxxxxxxxx/$MYIP/g";

# set time GMT +7
ln -fs /usr/share/zoneinfo/Asia/Kuala_Lumpur /etc/localtime

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

# install screenfetch
cd
rm -rf /root/.bashrc
wget -O /root/.bashrc https://raw.githubusercontent.com/emue25/cream/mei/.bashrc

#text gambar
apt install sudo
apt-get install boxes
# text pelangi
sudo apt-get install ruby -y
sudo gem install lolcat
# update repository
apt update -y

# Install PHP 5.6
usermod -aG sudo root

sudo apt -y install ca-certificates apt-transport-https
wget -q https://packages.sury.org/php/apt.gpg -O- | sudo apt-key add -
echo "deb https://packages.sury.org/php/ stretch main" | sudo tee /etc/apt/sources.list.d/php.list

sudo apt update -y
sudo apt install php5.6 -y
sudo apt install php5.6-mcrypt php5.6-mysql php5.6-fpm php5.6-cli php5.6-common php5.6-curl php5.6-mbstring php5.6-mysqlnd php5.6-xml -y

# install webserver
cd
sudo apt-get -y install nginx
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
wget -O /etc/nginx/nginx.conf "https://raw.githubusercontent.com/emue25/sshtunnel/master/debian9/nginx-default.conf"
mkdir -p /home/vps/public_html
echo "<?php phpinfo() ?>" > /home/vps/public_html/info.php
wget -O /etc/nginx/conf.d/vps.conf "https://raw.githubusercontent.com/emue25/sshtunnel/master/debian9/vhost-nginx.conf"
/etc/init.d/nginx restart

# instal nginx php5.6 
apt-get -y install nginx php5.6-fpm
apt-get -y install nginx php5.6-cli
apt-get -y install nginx php5.6-mysql
apt-get -y install nginx php5.6-mcrypt
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/5.6/cli/php.ini

# cari config php fpm dengan perintah berikut "php --ini |grep Loaded"
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/5.6/cli/php.ini

# Cari config php fpm www.conf dengan perintah berikut "find / \( -iname "php.ini" -o -name "www.conf" \)"
sed -i 's/listen = \/run\/php\/php5.6-fpm.sock/listen = 127.0.0.1:9000/g' /etc/php/5.6/fpm/pool.d/www.conf
cd


# Edit port apache2 ke 8090
wget -O /etc/apache2/ports.conf "https://raw.githubusercontent.com/emue25/sshtunnel/master/debian9/apache2.conf"

# Edit port virtualhost apache2 ke 8090
wget -O /etc/apache2/sites-enabled/000-default.conf "https://raw.githubusercontent.com/emue25/sshtunnel/master/debian9/virtualhost.conf"

# restart apache2
/etc/init.d/apache2 restart

# Install OpenVPN dan Easy-RSA
apt install openvpn easy-rsa -y
apt install openssl iptables -y 

# copykan script generate Easy-RSA ke direktori OpenVPN
cp -r /usr/share/easy-rsa/ /etc/openvpn

# Buat direktori baru untuk easy-rsa keys
mkdir /etc/openvpn/easy-rsa/keys

# Kemudian edit file variabel easy-rsa
# nano /etc/openvpn/easy-rsa/vars
wget -O /etc/openvpn/easy-rsa/vars "https://raw.githubusercontent.com/emue25/sshtunnel/master/debian9/vars.conf"
# edit projek export KEY_NAME="white-vps"
# Save dan keluar dari editor

# generate Diffie hellman parameters
openssl dhparam -out /etc/openvpn/dh2048.pem 2048

# inialisasikan Public Key
cd /etc/openvpn/easy-rsa

# inialisasikan openssl.cnf
ln -s openssl-1.0.0.cnf openssl.cnf
echo "unique_subject = no" >> keys/index.txt.attr

# inialisasikan vars
. ./vars

# inialisasikan Public clean all
./clean-all

# Certificate Authority (CA)
./build-ca

# buat server key name yang telah kita buat sebelum nya yakni "white-vps"
./build-key-server white-vps

# generate ta.key
openvpn --genkey --secret keys/ta.key

# Buat config server UDP 110
cd /etc/openvpn

cat > /etc/openvpn/server-udp-110.conf <<-END
port 110
proto udp
dev tun
ca easy-rsa/keys/ca.crt
cert easy-rsa/keys/white-vps.crt
key easy-rsa/keys/white-vps.key
dh dh2048.pem
plugin /usr/lib/openvpn/openvpn-plugin-auth-pam.so login
client-cert-not-required
username-as-common-name
server 192.168.10.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1"
push "dhcp-option DNS 1.1.1.1"
push "dhcp-option DNS 1.0.0.1"
keepalive 5 30
comp-lzo
persist-key
persist-tun
status server-udp-110.log
verb 3
END

# Buat config server TCP 110
cat > /etc/openvpn/server-tcp-110.conf <<-END
port 110
proto tcp
dev tun
ca easy-rsa/keys/ca.crt
cert easy-rsa/keys/white-vps.crt
key easy-rsa/keys/white-vps.key
dh dh2048.pem
plugin /usr/lib/openvpn/openvpn-plugin-auth-pam.so login
client-cert-not-required
username-as-common-name
server 192.168.20.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1"
push "dhcp-option DNS 1.1.1.1"
push "dhcp-option DNS 1.0.0.1"
push "route-method exe"
push "route-delay 2"
socket-flags TCP_NODELAY
push "socket-flags TCP_NODELAY"
keepalive 5 30
comp-lzo
persist-key
persist-tun
status server-tcp-110.log
verb 3
END

# Buat config server UDP 25
cat > /etc/openvpn/server-udp-25.conf <<-END
port 25
proto udp
dev tun
ca easy-rsa/keys/ca.crt
cert easy-rsa/keys/white-vps.crt
key easy-rsa/keys/white-vps.key
dh dh2048.pem
plugin /usr/lib/openvpn/openvpn-plugin-auth-pam.so login
client-cert-not-required
username-as-common-name
server 192.168.30.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1"
push "dhcp-option DNS 1.1.1.1"
push "dhcp-option DNS 1.0.0.1"
push "route-method exe"
push "route-delay 2"
socket-flags TCP_NODELAY
push "socket-flags TCP_NODELAY"
keepalive 5 30
comp-lzo
persist-key
persist-tun
status server-udp-25.log
verb 3
END

# Buat config server TCP 25
cat > /etc/openvpn/server-tcp-25.conf <<-END
port 25
proto tcp
dev tun
ca easy-rsa/keys/ca.crt
cert easy-rsa/keys/white-vps.crt
key easy-rsa/keys/white-vps.key
dh dh2048.pem
plugin /usr/lib/openvpn/openvpn-plugin-auth-pam.so login
client-cert-not-required
username-as-common-name
server 192.168.40.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1"
push "dhcp-option DNS 1.1.1.1"
push "dhcp-option DNS 1.0.0.1"
push "route-method exe"
push "route-delay 2"
socket-flags TCP_NODELAY
push "socket-flags TCP_NODELAY"
keepalive 5 30
comp-lzo
persist-key
persist-tun
status server-tcp-25.log
verb 3
END

cd

cp /etc/openvpn/easy-rsa/keys/{white-vps.crt,white-vps.key,ca.crt,ta.key} /etc/openvpn
ls /etc/openvpn

# nano /etc/default/openvpn
sed -i 's/#AUTOSTART="all"/AUTOSTART="all"/g' /etc/default/openvpn
# Cari pada baris #AUTOSTART=”all” hilangkan tanda pagar # didepannya sehingga menjadi AUTOSTART=”all”. Save dan keluar dari editor

# restart openvpn dan cek status openvpn
/etc/init.d/openvpn restart
/etc/init.d/openvpn status

# aktifkan ip4 forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
# edit file sysctl.conf
# nano /etc/sysctl.conf
# Uncomment hilangkan tanda pagar pada #net.ipv4.ip_forward=1

# Konfigurasi dan Setting untuk Client
mkdir clientconfig
cp /etc/openvpn/easy-rsa/keys/{white-vps.crt,white-vps.key,ca.crt,ta.key} clientconfig/
cd clientconfig

# Buat config client UDP 110
cd /etc/openvpn
cat > /etc/openvpn/client-udp-110.ovpn <<-END
##### DONT FORGET FOR SUPPORT US #####
client
dev tun
proto udp
remote xxxxxxxxx 110
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
END

sed -i $MYIP2 /etc/openvpn/client-udp-110.ovpn;

# Buat config client TCP 110
cat > /etc/openvpn/client-tcp-110.ovpn <<-END
##### DONT FORGET FOR SUPPORT US #####
client
dev tun
proto tcp
remote xxxxxxxxx 110
http-proxy xxxxxxxxx 8080
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
END

sed -i $MYIP2 /etc/openvpn/client-tcp-110.ovpn;

# Buat config client UDP 25
cat > /etc/openvpn/client-udp-25.ovpn <<-END
##### DONT FORGET FOR SUPPORT US #####
client
dev tun
proto udp
remote xxxxxxxxx 25
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
END

sed -i $MYIP2 /etc/openvpn/client-udp-25.ovpn;

# Buat config client TCP 25
cat > /etc/openvpn/client-tcp-25.ovpn <<-END
##### DONT FORGET FOR SUPPORT US #####
client
dev tun
proto tcp
remote xxxxxxxxx 25
http-proxy xxxxxxxxx 8080
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
END

sed -i $MYIP2 /etc/openvpn/client-tcp-25.ovpn;

# Buat config client SSL 443
cat > /etc/openvpn/client-ssl-443.ovpn <<-END
##### DONT FORGET FOR SUPPORT US #####
client
dev tun
proto tcp
remote xxxxxxxxx 443
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
up /etc/openvpn/update-resolv-conf
down /etc/openvpn/update-resolv-conf
route xxxxxxxxx 255.255.255.255 net_gateway
END
cd
sed -i $MYIP2 /etc/openvpn/client-ssl-443.ovpn;

# pada tulisan xxx ganti dengan alamat ip address VPS anda 
/etc/init.d/openvpn restart

# masukkan certificatenya ke dalam config client TCP 110
echo '<ca>' >> /etc/openvpn/client-tcp-110.ovpn
cat /etc/openvpn/ca.crt >> /etc/openvpn/client-tcp-110.ovpn
echo '</ca>' >> /etc/openvpn/client-tcp-110.ovpn

# masukkan certificatenya ke dalam config client UDP 1194
echo '<ca>' >> /etc/openvpn/client-udp-110.ovpn
cat /etc/openvpn/ca.crt >> /etc/openvpn/client-udp-110.ovpn
echo '</ca>' >> /etc/openvpn/client-udp-110.ovpn

# Copy config OpenVPN client ke home directory root agar mudah didownload ( TCP 110 )
cp /etc/openvpn/client-tcp-110.ovpn /home/vps/public_html/client-tcp-110.ovpn

# Copy config OpenVPN client ke home directory root agar mudah didownload ( UDP 110 )
cp /etc/openvpn/client-udp-110.ovpn /home/vps/public_html/client-udp-110.ovpn

# masukkan certificatenya ke dalam config client TCP 25
echo '<ca>' >> /etc/openvpn/client-tcp-25.ovpn
cat /etc/openvpn/ca.crt >> /etc/openvpn/client-tcp-25.ovpn
echo '</ca>' >> /etc/openvpn/client-tcp-25.ovpn

# masukkan certificatenya ke dalam config client UDP 25
echo '<ca>' >> /etc/openvpn/client-udp-25.ovpn
cat /etc/openvpn/ca.crt >> /etc/openvpn/client-udp-25.ovpn
echo '</ca>' >> /etc/openvpn/client-udp-25.ovpn

# Copy config OpenVPN client ke home directory root agar mudah didownload ( TCP 25 )
cp /etc/openvpn/client-tcp-25.ovpn /home/vps/public_html/client-tcp-25.ovpn

# Copy config OpenVPN client ke home directory root agar mudah didownload ( UDP 25 )
cp /etc/openvpn/client-udp-25.ovpn /home/vps/public_html/client-udp-25.ovpn


# masukkan certificatenya ke dalam config client SSL 443
echo '<ca>' >> /etc/openvpn/client-ssl-443.ovpn
cat /etc/openvpn/ca.crt >> /etc/openvpn/client-ssl-443.ovpn
echo '</ca>' >> /etc/openvpn/client-ssl-443.ovpn

# Copy config OpenVPN client ke home directory root agar mudah didownload ( SSL 443 )
cp /etc/openvpn/client-ssl-443.ovpn /home/vps/public_html/client-ssl-443.ovpn

# iptables-persistent
apt install iptables-persistent -y

# firewall untuk memperbolehkan akses UDP dan akses jalur TCP

iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -I POSTROUTING -s 192.168.10.0/24 -o eth0 -j MASQUERADE
iptables -t nat -I POSTROUTING -s 192.168.20.0/24 -o eth0 -j MASQUERADE
iptables -t nat -I POSTROUTING -s 192.168.30.0/24 -o eth0 -j MASQUERADE
iptables -t nat -I POSTROUTING -s 192.168.40.0/24 -o eth0 -j MASQUERADE

iptables -A INPUT -i eth0 -m state --state NEW -p tcp --dport 3306 -j ACCEPT
iptables -A INPUT -i eth0 -m state --state NEW -p tcp --dport 7300 -j ACCEPT
iptables -A INPUT -i eth0 -m state --state NEW -p udp --dport 7300 -j ACCEPT

iptables -t nat -I POSTROUTING -s 192.168.10.0/24 -o ens3 -j MASQUERADE
iptables -t nat -I POSTROUTING -s 192.168.20.0/24 -o ens3 -j MASQUERADE
iptables -t nat -I POSTROUTING -s 192.168.30.0/24 -o ens3 -j MASQUERADE
iptables -t nat -I POSTROUTING -s 192.168.40.0/24 -o ens3 -j MASQUERADE

iptables-save > /etc/iptables/rules.v4
chmod +x /etc/iptables/rules.v4

# Reload IPTables
iptables-restore -t < /etc/iptables/rules.v4
netfilter-persistent save
netfilter-persistent reload

# Restart service openvpn
systemctl enable openvpn
systemctl start openvpn
/etc/init.d/openvpn restart

# set iptables tambahan
iptables -F -t nat
iptables -X -t nat
iptables -A POSTROUTING -t nat -j MASQUERADE
iptables-save > /etc/iptables-opvpn.conf

# Restore iptables
wget -O /etc/network/if-up.d/iptables "https://raw.githubusercontent.com/emue25/sshtunnel/master/debian9/iptables-local"
chmod +x /etc/network/if-up.d/iptables

#Create Admin
useradd admin
echo "admin:kopet" | chpasswd

# install squid3
cd
apt-get -y install squid3
wget -O /etc/squid/squid.conf "https://raw.githubusercontent.com/emue25/sshtunnel/master/debian9/squid3.conf"
sed -i $MYIP2 /etc/squid/squid.conf;
/etc/init.d/squid restart

#remove
apt-get -y remove --purge unscd
apt-get -y install dnsutils

# download script
cd
sudo apt-get install zip
sudo apt-get install unzip
cd /usr/local/bin/
wget "https://github.com/emue25/cream/raw/mei/menu.zip"
unzip menu.zip
chmod +x /usr/local/bin/*

#cronjoob
echo "0 0 * * * root /sbin/reboot" > /etc/cron.d/reboot

# restart opevpn
/etc/init.d/openvpn restart

#ssl
apt update && apt upgrade -y
apt install stunnel4 -y
cd /etc/stunnel/
openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -sha256 -subj '/CN=127.0.0.1/O=localhost/C=US' -keyout /etc/stunnel/stunnel.pem -out /etc/stunnel/stunnel.pem
sudo touch stunnel.conf
echo "client = no" | sudo tee -a /etc/stunnel/stunnel.conf
echo "[openvpn]" | sudo tee -a /etc/stunnel/stunnel.conf
echo "accept = 443" | sudo tee -a /etc/stunnel/stunnel.conf
echo "connect = 127.0.0.1:110" | sudo tee -a /etc/stunnel/stunnel.conf
echo "cert = /etc/stunnel/stunnel.pem" | sudo tee -a /etc/stunnel/stunnel.conf

sudo sed -i -e 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo cp /etc/stunnel/stunnel.pem ~
/etc/init.d/stunnel4 restart

#auto delete
wget -O /usr/local/bin/userdelexpired "https://www.dropbox.com/s/cwe64ztqk8w622u/userdelexpired?dl=1" && chmod +x /usr/local/bin/userdelexpired

# install ddos deflate
apt install tcpdump -y
apt install grepcidr -y
cd
sudo apt-get -y install dnsutils dsniff
wget https://github.com/jgmdev/ddos-deflate/archive/master.zip
unzip master.zip
cd ddos-deflate-master
./install.sh
rm -rf /root/master.zip

#finishing
apt-get -y autoremove
chown -R www-data:www-data /home/vps/public_html
/etc/init.d/squid restart
/etc/init.d/openvpn restart
# Delete script
rm -f /root/openvpn.sh

