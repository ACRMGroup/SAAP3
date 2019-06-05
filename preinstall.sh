#packagemanager=yum
packagemanager=dnf

# Needed for conservation
sudo $packagemanager -y install R
# Needed to download files
sudo $packagemanager -y install perl-LWP-Protocol-https
# Needed for Muscle
sudo $packagemanager -y install libstdc++-static glibc-static
