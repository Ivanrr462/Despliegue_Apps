#!/bin/bash -xe 
exec > /tmp/userdata.log 2>&1

apt upgrade -y
apt update
apt install apache2 -y

hostnamectl set-hostname FrontEnd

a2enmod proxy_http

cat > /etc/apache2/sites-available/frontend.conf << EOF
<VirtualHost *:80>
    ProxyPass "/api/" "http://${backend_ip}/"
    ProxyPassReverse "/api/" "http://${backend_ip}/"

    DocumentRoot /var/www/frontend
</VirtualHost>
EOF

mkdir /var/www/frontend

cat > /var/www/frontend/index.html << EOF
    <html>
        <body>
            <h1>
                Soy el Front.
            </h1>
        </body>
    </html>
EOF

a2ensite frontend
a2dissite 000-default.conf 

systemctl reload apache2