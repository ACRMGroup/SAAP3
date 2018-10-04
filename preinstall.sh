#packagemanager=yum
packagemanager=dnf

sudo $packagemanager -y install R
sudo $packagemanager -y install perl-LWP-Protocol-https
sudo $packagemanager -y install libstdc++-static glibc-static
