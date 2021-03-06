#!/bin/bash

source ~/os-env

# create keystone database

./dbcreate.sh keystone keystone $OS_KEYSTONEDBPW

# install packages

dnf -y install openstack-keystone httpd python3-mod_wsgi

# conf file work
./bak.sh /etc/keystone/keystone.conf

./conf.sh /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:${OS_KEYSTONEDBPW}@${OS_CONTROLLER_NM}/keystone
./conf.sh /etc/keystone/keystone.conf token provider fernet

# sync database

su -s /bin/sh -c "keystone-manage db_sync" keystone

# initialize fernet

keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone

keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

# bootstrap keystone

keystone-manage bootstrap --bootstrap-password $OS_ADMINPW \
  --bootstrap-admin-url http://$OS_CONTROLLER_NM:5000/v3/ \
  --bootstrap-internal-url http://$OS_CONTROLLER_NM:5000/v3/ \
  --bootstrap-public-url http://$OS_CONTROLLER_NM:5000/v3/ \
  --bootstrap-region-id $OS_REGION

# setup/initialize apache/wsgi
sed -i "s/^#ServerName.*/ServerName $OS_CONTROLLER_NM/" /etc/httpd/conf/httpd.conf

ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/

for i in enable start;do systemctl $i httpd;done

# create basic projects and roles

source ~/adminrc

openstack project create --domain default --description "Service Project" service

if [ "$OS_CREATEDEMO" == "TRUE" ]; then
  openstack project create --domain default --description "Demo Project" demoproject

  openstack user create --domain default --password password demouser

  openstack role add --project demoproject --user demouser member

  cp ~/adminrc ~/demorc

  sed -i -e '/OS_PROJECT_NAME/ s/admin/demoproject/'\
   -e '/OS_USERNAME/ s/admin/demouser/'\
   -e '/OS_PASSWORD/ s/password/password/'\
   -e '/PS1/ s/$red/$yellow/' ~/demorc
fi

exit
