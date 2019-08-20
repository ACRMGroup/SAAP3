#packagemanager=yum
packagemanager=dnf

# Needed for conservation
sudo $packagemanager -y install R
# Needed to download files
sudo $packagemanager -y install perl-LWP-Protocol-https
# Needed for Muscle
sudo $packagemanager -y install libstdc++-static glibc-static
# Needed to read JSON files
sudo $packagemanager -y install perl-JSON
# Needed to create PDF versions of web pages
sudo $packagemanager -y install wkhtmltopdf

