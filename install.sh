#!/bin/bash

echo "Automated VPS Setup for Ubuntu 10.04 LTS (Lucid) - Rails with Nginx"
echo "------------------------------------------------------------------"
echo ""

echo "Set Timezone"
echo "------------------------------------------------------------------"

sudo ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime


echo "Install Essencials"
echo "------------------------------------------------------------------"

sudo aptitude install build-essential -y
sudo aptitude install zlib1g-dev libreadline5-dev libssl-dev -y


echo "Install REE"
echo "------------------------------------------------------------------"

mkdir sources
cd sources
wget http://rubyforge.org/frs/download.php/68719/ruby-enterprise-1.8.7-2010.01.tar.gz
tar xzvf ruby-enterprise-1.8.7-2010.01.tar.gz
sudo ./ruby-enterprise-1.8.7-2010.01/installer --auto=/usr/local/ruby-enterprise
cd ..
rm -rf sources

sudo ln -s /usr/local/ruby-enterprise/bin/erb /usr/local/bin/erb
sudo ln -s /usr/local/ruby-enterprise/bin/gem /usr/local/bin/gem
sudo ln -s /usr/local/ruby-enterprise/bin/rackup /usr/local/bin/rackup
sudo ln -s /usr/local/ruby-enterprise/bin/rails /usr/local/bin/rails
sudo ln -s /usr/local/ruby-enterprise/bin/rake /usr/local/bin/rake
sudo ln -s /usr/local/ruby-enterprise/bin/rdoc /usr/local/bin/rdoc
sudo ln -s /usr/local/ruby-enterprise/bin/ree-version /usr/local/bin/ree-version
sudo ln -s /usr/local/ruby-enterprise/bin/ri /usr/local/bin/ri
sudo ln -s /usr/local/ruby-enterprise/bin/ruby /usr/local/bin/ruby
sudo ln -s /usr/local/ruby-enterprise/bin/testrb /usr/local/bin/testrb


echo "Install Passenger and Nginx"
echo "------------------------------------------------------------------"

sudo gem install passenger

sudo ln -s /usr/local/ruby-enterprise/bin/passenger-config /usr/local/bin/passenger-config
sudo ln -s /usr/local/ruby-enterprise/bin/passenger-install-nginx-module /usr/local/bin/passenger-install-nginx-module
sudo ln -s /usr/local/ruby-enterprise/bin/passenger-install-apache2-module /usr/local/bin/passenger-install-apache2-module
sudo ln -s /usr/local/ruby-enterprise/bin/passenger-make-enterprisey /usr/local/bin/passenger-make-enterprisey
sudo ln -s /usr/local/ruby-enterprise/bin/passenger-memory-stats /usr/local/bin/passenger-memory-stats
sudo ln -s /usr/local/ruby-enterprise/bin/passenger-spawn-server /usr/local/bin/passenger-spawn-server
sudo ln -s /usr/local/ruby-enterprise/bin/passenger-status /usr/local/bin/passenger-status
sudo ln -s /usr/local/ruby-enterprise/bin/passenger-stress-test /usr/local/bin/passenger-stress-test

sudo passenger-install-nginx-module --auto --auto-download --prefix=/usr/local/nginx

wget http://github.com/benschwarz/passenger-stack/raw/master/config/stack/nginx/init.d
sudo cp init.d /etc/init.d/nginx
rm init.d
sudo chmod +x /etc/init.d/nginx
sudo /usr/sbin/update-rc.d -f nginx defaults
sudo /etc/init.d/nginx start

echo "RAILS_ENV=production" | sudo tee -a /etc/environment


echo "Install Git"
echo "------------------------------------------------------------------"

sudo aptitude install git-core -y


echo "Install MySQL"
echo "------------------------------------------------------------------"

# http://nagios.intuitinnovations.com/downloads/asterisk/asterisk1.4.2-A-install
# http://forum.slicehost.com/comments.php?DiscussionID=2187
# install MySQL non-interactively
# export DEBIAN_FRONTEND=noninteractive
# sudo aptitude -q -y install mysql-server
# unset DEBIAN_FRONTEND
# mysqladmin -u root password $mysqlpwd

sudo aptitude install mysql-server mysql-client libmysqlclient-dev -y

sudo gem install mysql --no-ri --no-rdoc


echo "Configure iptables"
echo "------------------------------------------------------------------"

# http://stackoverflow.com/questions/850730/how-can-i-append-text-to-etc-apt-sources-list-from-the-command-line
sudo cat | sudo tee -a /etc/init.d/firewall <<ENDOFFILE
#!/bin/bash

start(){

iptables -A INPUT -p tcp -i lo -j ACCEPT

# SSH:
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# DNS:
iptables -A INPUT -p tcp --dport 53 -j ACCEPT
iptables -A INPUT -p udp --dport 53 -j ACCEPT

# HTTP e HTTPS:
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 7080 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

iptables -A INPUT -p tcp --syn -j DROP

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -A INPUT -p udp --dport 0:1023 -j DROP

}
stop(){
iptables -F
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
}

case "\$1" in
"start") start ;;
"stop") stop ;;
"restart") parar; iniciar ;;
*) echo "start or stop params"
esac

ENDOFFILE

sudo chmod +x /etc/init.d/firewall
sudo update-rc.d firewall defaults 99
sudo /etc/init.d/firewall start

# To remove:
# sudo update-rc.d -f firewall remove


echo "Install apache, php and phpmyadmin"
echo "------------------------------------------------------------------"

sudo aptitude -y install apache2
sudo aptitude -y install php5 php5-mysql

sed -e 's/<VirtualHost \*:80>/<VirtualHost *:7080>/' /etc/apache2/sites-available/default | sudo tee /etc/apache2/sites-available/new_default
sudo mv /etc/apache2/sites-available/new_default /etc/apache2/sites-available/default

sed -e 's/NameVirtualHost \*:80/NameVirtualHost *:7080/' -e 's/Listen 80/Listen 7080/' /etc/apache2/ports.conf | sudo tee /etc/apache2/new_ports_conf
sudo mv /etc/apache2/new_ports_conf /etc/apache2/ports.conf

sudo aptitude -y install phpmyadmin
ln -s /usr/share/phpmyadmin/ /var/www/phpmyadmin


# echo "Install postfix"
# echo "------------------------------------------------------------------"
# http://articles.slicehost.com/2010/3/1/barebones-postfix-install-for-ubuntu

# sudo aptitude install postfix
# Install type: Internet Site
# Default email domain name: example.com

# sudo /etc/init.d/postfix start
# sudo /usr/sbin/update-rc.d postfix defaults

echo "Clear bash histories as the password got exposed"
echo "------------------------------------------------------------------"

history -c
tput bel


echo "VPS Setup Complete"
echo "------------------------------------------------------------------"
