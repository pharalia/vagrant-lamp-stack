#!/usr/bin/env bash

# Generate Apache VirtualHost Configuration
vhost="<VirtualHost *:80>

  ServerName $1
  
  Alias /fcgi-bin /usr/sbin/php5-fpm
  
  <FilesMatch \"\.ph(p3?|tml)$\">
    SetHandler php5-fcgi
    Action php5-fcgi /fcgi-bin virtual
  </FilesMatch>

  <Directory /fcgi-bin>
    Options -Indexes +FollowSymLinks +ExecCGI +Includes
    Order deny,allow
    Deny from all
    Require env REDIRECT_STATUS
  </Directory>
  
  DocumentRoot $2
  
  <Directory $2>
	Options -Indexes +FollowSymLinks
	AllowOverride All
  </Directory>
  
</VirtualHost>"

echo "$vhost" > "/etc/apache2/sites-available/$1.conf"
a2ensite $1

# Restart Services
service apache2 restart
service php5-fpm restart