#!/bin/bash -xe 
exec > /tmp/userdata.log 2>&1

apt upgrade -y
apt update
apt install apache2 -y

hostnamectl set-hostname Login

cat > /etc/apache2/sites-available/login.conf << EOF
<VirtualHost *:80>
    DocumentRoot /var/www/login
</VirtualHost>
EOF

mkdir /var/www/login

cat > /var/www/login/index.html << EOF
    <html>
        <body>
            <h1>
                Soy el Login.
            </h1>
        </body>
    </html>
EOF

a2ensite login
a2dissite 000-default.conf 

systemctl reload apache2