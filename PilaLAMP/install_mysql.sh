#!/bin/bash -xe
exec > /tmp/userdata.log 2>&1

apt update
apt upgrade -y
apt install mysql-server -y


