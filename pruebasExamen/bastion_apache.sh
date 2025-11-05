#!/bin/bash -xe
exec > /tmp/userdata.log 2>&1

apt update
apt upgrade -y
apt install apache2 -y

# Repo para PHP 8.1
add-apt-repository -y ppa:ondrej/php
apt-get update -y

# Instalar Apache y PHP 8.1
apt-get install -y apache2 php8.1 libapache2-mod-php8.1 openssh-server

# Deshabilitar módulo autoindex
a2dismod autoindex || true

cat > /etc/apache2/sites-available/primero.conf << EOF
<VirtualHost *:80>
    DocumentRoot /var/www/primero
</VirtualHost>
EOF

a2ensite primero
a2enmod php8.1 || true
mkdir /var/www/primero
systemctl reload apache2

cat > /var/www/primero/index.html << EOF
    <html>
        <body>
            <h1>
                Ivan Rios Raya
            </h1>
        </body>
    </html>
EOF

systemctl enable --now apache2
systemctl enable --now ssh