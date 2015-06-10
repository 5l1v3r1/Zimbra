#!/bin/sh
## Preparing all the variables like IP, Hostname, etc, all of them from the container
sleep 5
HOSTNAME=$(hostname -a)
DOMAIN=$(hostname -d)
CONTAINERIP=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
RANDOMHAM=$(date +%s|sha256sum|base64|head -c 10)
RANDOMSPAM=$(date +%s|sha256sum|base64|head -c 10)
RANDOMVIRUS=$(date +%s|sha256sum|base64|head -c 10)
## Installing the DNS Server ##
echo "Installing DNSMASQ DNS Server"
sudo apt-get update && sudo sudo apt-get install -y dnsmasq dnsutils
## was originally a full "bind9" install

echo "Configuring DNS Server"
## START of changes for DNSMASQ
# See: www.thekelleys.org.uk/dnsmasq/docs/dnsmasq.conf.example
cat <<EOF >>/etc/dnsmasq/dnsmasq.conf
listen-address=$CONTAINERIP
no-dhcp-interface=eth0
no-poll
address=/double-click.net/127.0.0.1
# doubleclick to loopback is just for kicks
domain=$DOMAIN
mx-host=$DOMAIN,$HOSTNAME,50
#mx-target=$HOSTNAME
#localmx
txt-record=$DOMAIN,"v=spf1 a -all"
#for debugging
log-queries
EOF

cat <<EOF >>/etc/default/dnsmasq
DOMAIN_SUFFIX=`$DOMAIN`
ENABLED=1
EOF

sudo service dnsmasq restart 
## END OF TODO changes for DNSMASQ

##Install the Zimbra Collaboration OS dependencies and Zimbra package ##
apt-get update
echo "Download and install Zimbra Collaboration dependencies"
sudo apt-get install -y netcat-openbsd sudo libidn11 libpcre3 libgmp10 libexpat1 libstdc++6 libperl5.18 libaio1 resolvconf unzip pax sysstat sqlite3
## https://wiki.zimbra.com/wiki/Install_Zimbra_Collaboration_and_a_DNS_Server_with_Script
## Building and adding the Scripts keystrokes and the config.defaults
touch /tmp/zcs/installZimbra-keystrokes
cat <<EOF >/tmp/zcs/installZimbra-keystrokes
y
y
y
y
n
y
y
y
y
y
y
y
EOF

touch /tmp/zcs/installZimbraScript
cat <<EOF >/tmp/zcs/installZimbraScript
AVDOMAIN="$DOMAIN"
AVUSER="admin@$DOMAIN"
CREATEADMIN="admin@$DOMAIN"
CREATEADMINPASS="$PASSWORD"
CREATEDOMAIN="$DOMAIN"
DOCREATEADMIN="yes"
DOCREATEDOMAIN="yes"
DOTRAINSA="yes"
EXPANDMENU="no"
HOSTNAME="$HOSTNAME.$DOMAIN"
HTTPPORT="8080"
HTTPPROXY="TRUE"
HTTPPROXYPORT="80"
HTTPSPORT="8443"
HTTPSPROXYPORT="443"
IMAPPORT="7143"
IMAPPROXYPORT="143"
IMAPSSLPORT="7993"
IMAPSSLPROXYPORT="993"
INSTALL_WEBAPPS="service zimlet zimbra zimbraAdmin"
JAVAHOME="/opt/zimbra/java"
LDAPAMAVISPASS="$PASSWORD"
LDAPPOSTPASS="$PASSWORD"
LDAPROOTPASS="$PASSWORD"
LDAPADMINPASS="$PASSWORD"
LDAPREPPASS="$PASSWORD"
LDAPBESSEARCHSET="set"
LDAPHOST="$HOSTNAME.$DOMAIN"
LDAPPORT="389"
LDAPREPLICATIONTYPE="master"
LDAPSERVERID="2"
MAILBOXDMEMORY="972"
MAILPROXY="TRUE"
MODE="https"
MYSQLMEMORYPERCENT="30"
POPPORT="7110"
POPPROXYPORT="110"
POPSSLPORT="7995"
POPSSLPROXYPORT="995"
PROXYMODE="https"
REMOVE="no"
RUNARCHIVING="no"
RUNAV="yes"
RUNCBPOLICYD="no"
RUNDKIM="yes"
RUNSA="yes"
RUNVMHA="no"
SERVICEWEBAPP="yes"
SMTPDEST="admin@$DOMAIN"
SMTPHOST="$HOSTNAME.$DOMAIN"
SMTPNOTIFY="yes"
SMTPSOURCE="admin@$DOMAIN"
SNMPNOTIFY="yes"
SNMPTRAPHOST="$HOSTNAME.$DOMAIN"
SPELLURL="http://$HOSTNAME.$DOMAIN:7780/aspell.php"
STARTSERVERS="yes"
SYSTEMMEMORY="3.8"
TRAINSAHAM="ham.$RANDOMHAM@$DOMAIN"
TRAINSASPAM="spam.$RANDOMSPAM@$DOMAIN"
UIWEBAPPS="yes"
UPGRADE="yes"
USESPELL="yes"
VERSIONUPDATECHECKS="TRUE"
VIRUSQUARANTINE="virus-quarantine.$RANDOMVIRUS@$DOMAIN"
ZIMBRA_REQ_SECURITY="yes"
ldap_bes_searcher_password="$PASSWORD"
ldap_dit_base_dn_config="cn=zimbra"
ldap_nginx_password="$PASSWORD"
mailboxd_directory="/opt/zimbra/mailboxd"
mailboxd_keystore="/opt/zimbra/mailboxd/etc/keystore"
mailboxd_keystore_password="$PASSWORD"
mailboxd_server="jetty"
mailboxd_truststore="/opt/zimbra/java/jre/lib/security/cacerts"
mailboxd_truststore_password="changeit"
postfix_mail_owner="postfix"
postfix_setgid_group="postdrop"
ssl_default_digest="sha256"
zimbraFeatureBriefcasesEnabled="Enabled"
zimbraFeatureTasksEnabled="Enabled"
zimbraIPMode="ipv4"
zimbraMailProxy="FALSE"
zimbraMtaMyNetworks="127.0.0.0/8 $CONTAINERIP/24 [::1]/128 [fe80::]/64"
zimbraPrefTimeZoneId="America/Los_Angeles"
zimbraReverseProxyLookupTarget="TRUE"
zimbraVersionCheckNotificationEmail="admin@$DOMAIN"
zimbraVersionCheckNotificationEmailFrom="admin@$DOMAIN"
zimbraVersionCheckSendNotifications="TRUE"
zimbraWebProxy="FALSE"
zimbra_ldap_userdn="uid=zimbra,cn=admins,cn=zimbra"
zimbra_require_interprocess_security="1"
INSTALL_PACKAGES="zimbra-core zimbra-ldap zimbra-logger zimbra-mta zimbra-snmp zimbra-store zimbra-apache zimbra-spell zimbra-memcached zimbra-proxy"
EOF

##Install the Zimbra Collaboration ##
echo "Downloading Zimbra Collaboration 8.6"
cd /tmp/zcs 
wget https://files.zimbra.com/downloads/8.6.0_GA/zcs-8.6.0_GA_1153.UBUNTU14_64.20141215151116.tgz
tar xzvf zcs-*
echo "Installing Zimbra Collaboration just the Software"
cd /tmp/zcs/zcs-* && ./install.sh -s < /tmp/zcs/installZimbra-keystrokes
echo "Installing Zimbra Collaboration injecting the configuration"
/opt/zimbra/libexec/zmsetup.pl -c /tmp/zcs/installZimbraScript

if [[ $1 == "-d" ]]; then
  while true; do sleep 1000; done
fi

if [[ $1 == "-bash" ]]; then
  /bin/bash
fi
