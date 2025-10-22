#!/bin/bash -xe
exec > /tmp/userdata.log 2>&1

apt update
apt upgrade -y
apt-get install apache2 -y