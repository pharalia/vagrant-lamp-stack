#!/usr/bin/env bash
apt-get -y install lsb-release

# Enable non-free sources to gain access to libapache2-mod-fastcgi
DEBIAN_VERSION="$(command lsb_release -cs)"

MIRROR=$(command egrep "^deb.*${DEBIAN_VERSION}" '/etc/apt/sources.list' \
    | command egrep -v "updates|-src|cdrom" \
    | cut --delimiter=" " --fields=2)

echo "# Debian contrib repository.
deb http://ftp.fr.debian.org/debian/ ${DEBIAN_VERSION} contrib
deb-src http://ftp.fr.debian.org/debian/ ${DEBIAN_VERSION} contrib

deb http://security.debian.org/ ${DEBIAN_VERSION}/updates contrib
deb-src http://security.debian.org/ ${DEBIAN_VERSION}/updates contrib" \
    > '/etc/apt/sources.list.d/contrib.list'

echo "# Debian non-free repository.
deb http://ftp.fr.debian.org/debian/ ${DEBIAN_VERSION} non-free
deb-src http://ftp.fr.debian.org/debian/ ${DEBIAN_VERSION} non-free

deb http://security.debian.org/ ${DEBIAN_VERSION}/updates non-free
deb-src http://security.debian.org/ ${DEBIAN_VERSION}/updates non-free" \
    > '/etc/apt/sources.list.d/non-free.list'

echo "# 1: Updating Packages #"
apt-get update

echo "# 2: Running Upgrade #"
apt-get upgrade

echo "# 3: Installing Apache #"
apt-get -y install apache2 libapache2-mod-fastcgi

# Fix FastCgi permission and create server
echo "<IfModule mod_fastcgi.c>
    FastCgiExternalServer /usr/sbin/php5-fpm -socket /var/run/php5-fpm.sock -user www-data -group www-data -idle-timeout 240 -appConnTimeout 0
    <Directory /usr/sbin>
        Require all granted
    </Directory>
</IfModule>" \
	> /etc/apache2/conf-available/php5-fpm.conf
	
a2enconf php5-fpm
	
a2enmod actions
a2enmod rewrite
service apache2 restart

echo "# 4: Installing MySQL #"
# Auto-set root password for package installation
debconf-set-selections <<< 'mysql-server mysql-server/root_password password vagrant'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password vagrant'

apt-get -y install mysql-server mysql-client

# Bind MySQL to loopback device, so you can access via desktop forwarded port
#sed -e 's/^bind-address.*$/bind-address = 127.0.0.1/' -i /etc/mysql/my.cnf
#service mysql restart

echo "# 5: Installing PHP #"
apt-get -y install php5 php5-fpm php5-intl php5-gd php5-xdebug php5-mysqlnd php5-mcrypt

# Enable remote debugging configuration
echo "xdebug.remote_enable = on
xdebug.remote_connect_back = on
xdebug.idekey = \"vagrant\"
xdebug.remote_autostart = on" \
	>> /etc/php5/mods-available/xdebug.ini
	
service php5-fpm restart

echo "# 6: Installing Adminer #"
apt-get -y install adminer

origpath=$(pwd)
cd /usr/share/adminer
php compile.php
find . -maxdepth 1 -name 'adminer*.php' -type f -exec ln -s {} adminer.php \;
cd $origpath

# Allow larger file uploads
sed -e '/^[^;]*post_max_size/s/=.*$/= 128M/' -i /etc/php5/fpm/php.ini
sed -e '/^[^;]*upload_max_filesize/s/=.*$/= 128M/' -i /etc/php5/fpm/php.ini

echo "Alias /adminer /usr/share/adminer/adminer.php" > /etc/apache2/conf-available/adminer.conf
a2enconf adminer

echo "# 7: Installing wkhtmltopdf and fonts #"
apt-get -y install gdebi-core

# Install the "static binary" version of wkhtmltopdf
wget http://download.gna.org/wkhtmltopdf/0.12/0.12.2/wkhtmltox-0.12.2_linux-jessie-amd64.deb
gdebi --n wkhtmltox-0.12.2_linux-jessie-amd64.deb
apt-get -y install fonts-crosextra-carlito fonts-crosextra-caladea