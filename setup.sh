#!/bin/bash

# Set static IP address
sudo cp /etc/netplan/01-netcfg.yaml /etc/netplan/01-netcfg.yaml.bak
sudo tee /etc/netplan/01-netcfg.yaml > /dev/null <<EOT
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: no
      addresses: [192.168.1.100/24]
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
EOT
sudo netplan apply

# Set up IPtables firewall
sudo apt-get update
sudo apt-get install iptables-persistent -y
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -j DROP
sudo netfilter-persistent save
sudo netfilter-persistent reload

# Create groups
sudo groupadd grad
sudo groupadd ugrad
sudo groupadd staff

echo "created groups:"
getent group grad
getent group ugrad
getent group staff


# Grant staff group sudo privileges
echo "%staff ALL=(ALL) ALL" | sudo tee /etc/sudoers.d/staff

# Create users and assign primary groups
sudo useradd -m -g grad user1
sudo useradd -m -g ugrad user2
sudo useradd -m -g staff user3

# Create directories and set permissions
sudo mkdir /grad
sudo mkdir /ugrad
sudo mkdir /everyone
sudo chown root:grad /grad
sudo chown root:ugrad /ugrad
sudo chown root:staff /everyone
sudo chmod 775 /grad
sudo chmod 775 /ugrad
sudo chmod 775 /everyone
sudo chmod +t /everyone

# Install MySQL server
sudo apt-get install mysql-server -y

# Create MySQL database and table
mysql -u root -e "CREATE DATABASE class;"
mysql -u root -e "USE class; CREATE TABLE students (first_name VARCHAR(20), last_name VARCHAR(20));"

# Install Apache2 web server
sudo apt-get install apache2 -y

# Create sample webpage
sudo tee /var/www/html/index.html > /dev/null <<EOT
<!DOCTYPE html>
<html>
<head>
  <title>Hello, world!</title>
</head>
<body>
  <h1>Hello, world!</h1>
</body>
</html>
EOT

# Restart Apache2
sudo systemctl restart apache2

# Display summary
echo "Ubuntu server setup complete!"
echo "Static IP address: 192.168.1.100"
echo "MySQL database 'class' created."
echo "Apache2 web server running. Access your webpage at http://192.168.1.100/"
