#!/bin/bash
  #Author:Esther
  #Date:January 2023
## Install Jenkins and Requirements - Tested for Latest Jenkins v2.222.3
# (run as root or sudo ./install.sh)

# update dnf before installing packages
dnf -y update

# install requirement wget if not installed
dnf -y install wget

# must install OpenJDk 8 or 11 - install 8
dnf -y install java-1.8.0-openjdk-devel
export JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk"
installed=$( cat /root/.bash_profile | grep -c JAVA_HOME )
if [ $installed -eq 0 ]; then
echo "JAVA_HOME=\"/usr/lib/jvm/java-1.8.0-openjdk\"" >> /root/.bash_profile
fi

# enable the Jenkins repo and import GPG key
wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://jenkins.io/redhat-stable/jenkins.io.key

# install latest version of Jenkins
dnf -y install jenkins

# if software/hardware firewall is enabled -- open port 8080/tcp
no_ufw=$( which ufw | grep -c no )
if [ $no_ufw -ne 0 ]; then
        ufw allow 8080/tcp
        ufw allow http
        ufw allow https
fi
no_firewall-cmd=$( which firewall | grep -c no )
if [ $no_firewall-cmd -ne 0 ]; then
        YOURPORT=8080
        PERM="--permanent"
        SERV="$PERM --service=jenkins"
        firewall-cmd $PERM --new-service=jenkins
        firewall-cmd $SERV --set-short="Jenkins ports"
        firewall-cmd $SERV --set-description="Jenkins port exceptions"
        firewall-cmd $SERV --add-port=$YOURPORT/tcp
        firewall-cmd $PERM --add-service=jenkins
        firewall-cmd --zone=public --add-service=http --permanent
fi

# redirect IP Tables to allow connection from 8080 or 80 and 8443 or 443
# source: https://wiki.jenkins.io/display/JENKINS/Running+Jenkins+on+Port+80+or+443+using+iptables
iptables -I INPUT 1 -p tcp --dport 8443 -j ACCEPT
iptables -I INPUT 1 -p tcp --dport 8080 -j ACCEPT
iptables -I INPUT 1 -p tcp --dport 443 -j ACCEPT
iptables -I INPUT 1 -p tcp --dport 80 -j ACCEPT
iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 8080
iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 443 -j REDIRECT --to-port 8443
iptables-save > /etc/sysconfig/iptables

# enable and start Jenkins Service and enable on boot
systemctl start jenkins
systemctl enable jenkins

sleep 3

echo "http://<ip>/ -- Administrator Password:"
cat /var/lib/jenkins/secrets/initialAdminPassword
echo Jenkins install successfully!