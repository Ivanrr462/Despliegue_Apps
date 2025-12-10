#!/bin/bash -xe 
exec > /tmp/userdata.log 2>&1

apt upgrade -y
apt update
apt install apache2 -y
apt install php libapache2-mod-php -y

hostnamectl set-hostname BackEnd

cat > /etc/apache2/sites-available/backend.conf << EOF
<VirtualHost *:80>
    DocumentRoot /var/www/backend
</VirtualHost>
EOF

mkdir /var/www/backend

cat > /var/www/backend/index.php << EOF
    <?php
        phpinfo();
    ?>
EOF

a2ensite backend
a2dissite 000-default.conf 

systemctl reload apache2