#!/bin/bash

apt update
apt install -y apache2 unzip
systemctl start apache2
systemctl enable apache2

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

aws s3 cp s3://kwashingtonproject1/index.html /var/www/html/ 
aws s3 cp s3://kwashingtonproject1/newyears.html /var/www/html/ 

instance_Id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)                                    
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)

sed -i "s/_instanceID_/$instance_Id/g" /var/www/html/index.html
sed -i "s/_AZ_/$AZ/g" /var/www/html/index.html

sed -i "s/_instanceID_/$instance_Id/g" /var/www/html/newyears.html
sed -i "s/_AZ_/$AZ/g" /var/www/html/newyears.html