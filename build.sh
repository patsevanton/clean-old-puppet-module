#!/bin/bash

list_dependencies=(rpm-build rpmdevtools)

for i in ${list_dependencies[*]}
do
    if ! rpm -qa | grep -qw $i; then
        echo "__________Dont installed '$i'__________"
        #yum -y install $i
    fi
done

rm -rf ~/rpmbuild/
mkdir -p ~/rpmbuild/{RPMS,SRPMS,BUILD,SOURCES,SPECS}
cd SOURCES
cp clean-old-puppet-modules-cron ~/rpmbuild/SOURCES
cp clean-old-puppet-modules.py ~/rpmbuild/SOURCES
cd ..
spectool -g -R delete-old-puppet-config.spec
rpmbuild -bb delete-old-puppet-config.spec
