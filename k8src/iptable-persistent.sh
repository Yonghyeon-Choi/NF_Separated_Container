./iptables.sh &&\
iptables-persistent iptables-persistent/autosave_v4 boolean false | debconf-set-selections &&\
iptables-persistent iptables-persistent/autosave_v4 boolean false | debconf-set-selections &&\
apt-get -y install iptables-persistent
