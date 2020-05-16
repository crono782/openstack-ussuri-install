#!/bin/bash

source ~/os-env

# make some controller specific helper scripts

# script for adding service endpoints

cat << EOF > endpoint.sh
#!/bin/bash
eptype=\$1
epport=\$2
ephost=\${3:-controller}
for i in public internal admin; do openstack endpoint create --region RegionOne \$eptype \$i http://\$ephost:\$epport;done
EOF

chmod +x endpoint.sh

# script for creating mysql project dbs

cat << EOF > dbcreate.sh
#!/bin/bash
dbname=\$1
dbuser=\$2
pass=\$3
cat << EOS > ~/.sqlfiles/\$dbname-\$dbuser.sql
CREATE DATABASE \$dbname;
GRANT ALL PRIVILEGES ON \$dbname.* TO '\$dbuser'@'localhost' IDENTIFIED BY '\$pass';
GRANT ALL PRIVILEGES ON \$dbname.* TO '\$dbuser'@'%' IDENTIFIED BY '\$pass';
EOS
mysql -u root -p$OS_MYSQLPW < ~/.sqlfiles/\$dbname-\$dbuser.sql
EOF

chmod +x dbcreate.sh

# create basic rc files

# rc file for admin user

cat << EOF > adminrc
black=\$(tput setaf 0)
red=\$(tput setaf 1)
green=\$(tput setaf 2)
yellow=\$(tput setaf 3)
blue=\$(tput setaf 4)
magenta=\$(tput setaf 5)
cyan=\$(tput setaf 6)
white=\$(tput setaf 7)
reset=\$(tput sgr0)
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$OS_ADMINPW
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
export PS1='[\u@\h \[\$red\](\$OS_USERNAME:\$OS_PROJECT_NAME)\[\$reset\] \W]\$ '
EOF

# rc file to reset settings

cat << EOF > norc
unset OS_PROJECT_DOMAIN_NAME
unset OS_USER_DOMAIN_NAME
unset OS_PROJECT_NAME
unset OS_USERNAME
unset OS_PASSWORD
unset OS_AUTH_URL
unset OS_IDENTITY_API_VERSION
unset OS_IMAGE_API_VERSION
export PS1='[\u@\h \W]\$ '
EOF

# install/setup mysql database

dnf -y install mariadb mariadb-server python3-PyMySQL

cat << EOF > /etc/my.cnf.d/openstack.cnf
[mysqld]
bind-address = $OS_CONTROLLER_IP
default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
EOF

for i in enable start;do systemctl $i mariadb;done

# mysql setup (replicates mysql_secure_installation)

# set root pw
mysql -e "UPDATE mysql.user SET Password = PASSWORD('$OS_MYSQLPW') WHERE User = 'root';"
# remote anonymous user
mysql -e "DELETE FROM mysql.user WHERE User='';"
# clobber remote root login
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
# remove test db
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"
# reload privs
mysql -e "FLUSH PRIVILEGES"

mkdir ~/.sqlfiles # << for dbcreate script usage

# install/stup message queue

dnf -y install centos-release-rabbitmq-38
dnf -y --enablerepo=PowerTools install rabbitmq-server

for i in enable start;do systemctl $i rabbitmq-server;done

rabbitmqctl add_user openstack $OS_RMQPW

rabbitmqctl set_permissions openstack ".*" ".*" ".*"

# install/setup memcached

dnf -y install memcached python3-memcached

sed -i "s/OPTIONS=\"-l 127.0.0.1,::1\"/OPTIONS=\"-l 127.0.0.1,::1,$OS_CONTROLLER_NM\"/" /etc/sysconfig/memcached

for i in enable start;do systemctl $i memcached;done

# install/setup etcd

dnf -y install etcd

sed -ri -e '/(ETCD_LISTEN|ETCD_INITIAL)/ s/^#//' -e "s/localhost/$OS_CONTROLLER_IP/g" -e "/(ETCD_NAME|ETCD_INITIAL)/ s/default/$OS_CONTROLLER_NM/" -e 's/(etcd-cluster)/\1-01/' /etc/etcd/etcd.conf

for i in enable start;do systemctl $i etcd;done

exit
