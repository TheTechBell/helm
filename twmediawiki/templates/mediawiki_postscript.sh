#!/bin/bash

# Set variables
MEDIAWIKI_VERSION="1.39.2"
MEDIAWIKI_FILENAME="mediawiki-$MEDIAWIKI_VERSION.tar.gz"
MEDIAWIKI_URL="https://releases.wikimedia.org/mediawiki/$MEDIAWIKI_VERSION/$MEDIAWIKI_FILENAME"
MEDIAWIKI_SIGNATURE_URL="https://releases.wikimedia.org/mediawiki/$MEDIAWIKI_VERSION/$MEDIAWIKI_FILENAME.sig"


# Create non-privileged user for MediaWiki
useradd mediawiki

# Download MediaWiki and verify signature
cd /home/mediawiki
wget $MEDIAWIKI_URL
wget $MEDIAWIKI_SIGNATURE_URL
gpg --verify $MEDIAWIKI_FILENAME.sig $MEDIAWIKI_FILENAME

# Install MediaWiki
cd /var/www
tar -zxf /home/mediawiki/$MEDIAWIKI_FILENAME
ln -s mediawiki-$MEDIAWIKI_VERSION/ mediawiki
chown -R apache:apache /var/www/mediawiki-$MEDIAWIKI_VERSION

# Configure Apache
sed -i 's/DocumentRoot "\/var\/www\/html"/DocumentRoot "\/var\/www"/g' /etc/httpd/conf/httpd.conf
sed -i 's/<Directory "\/var\/www\/html">/<Directory "\/var\/www">/g' /etc/httpd/conf/httpd.conf
sed -i 's/DirectoryIndex index.html index.html.var/DirectoryIndex index.html index.html.var index.php/g' /etc/httpd/conf/httpd.conf
systemctl enable httpd
systemctl start httpd

# Configure Firewall
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
systemctl restart firewalld

# Configure SELinux
if [[ $(getenforce) == "Enforcing" ]]; then
    restorecon -FR /var/www/mediawiki-$MEDIAWIKI_VERSION/
    chcon -R -t httpd_sys_content_t /var/www/mediawiki-$MEDIAWIKI_VERSION/
fi

