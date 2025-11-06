#!/bin/bash -xe
exec > /tmp/userdata.log 2>&1

apt update
apt upgrade -y
apt install apache2 -y

# Se crean los virtualHost de los puertos 80 y 8008
cat > /etc/apache2/sites-available/primero.conf << EOF
<VirtualHost *:80>
    DocumentRoot /var/www/primero
</VirtualHost>
EOF

cat > /etc/apache2/sites-available/segundo.conf << EOF
<VirtualHost *:8008>
    DocumentRoot /var/www/segundo
</VirtualHost>
EOF

# Se habilitan los sitios y se desabilitan el que hay por defecto
a2ensite primero
a2ensite segundo
a2dissite 000-default.conf 
mkdir /var/www/primero
mkdir /var/www/segundo
systemctl reload apache2

# Se crean los index.html con el codigo
cat > /var/www/primero/index.html << EOF
    <html>
        <body>
            <h1>
                Servido desde el puerto 80.
            </h1>
        </body>
    </html>
EOF

cat > /var/www/segundo/index.html << EOF
    <html>
        <body>
            <h1>
                Servido desde el puerto 8008.
            </h1>
        </body>
    </html>
EOF


