domain=bmlt.jrb.lol

rm -f bmlt
mysql --execute='DROP DATABASE IF EXISTS bmlt; CREATE DATABASE bmlt;'
gzip -d bmlt.gz
mysql bmlt < bmlt
rm -f bmlt

rm -f yap
mysql --execute='DROP DATABASE IF EXISTS yap; CREATE DATABASE yap;'
gzip -d yap.gz
mysql yap < yap
rm -f yap

sudo mv /home/ubuntu/auto-config.inc.php /var/www/${domain}/
sudo sed -i 's/^.*\$dbPassword.*$/$dbPassword = \"bmlt\";/' /var/www/${domain}/auto-config.inc.php
sudo chown www-data: /var/www/${domain}/auto-config.inc.php

sudo mv /home/ubuntu/config.php /var/www/${domain}/zonal-yap/config.php
sudo sed -i 's/^static \$mysql_username.*$/static $mysql_username = \"yap\";/' /var/www/${domain}/zonal-yap/config.php
sudo sed -i 's/^static \$mysql_password.*$/static $mysql_password = \"yap\";/' /var/www/${domain}/zonal-yap/config.php
sudo chown www-data: /var/www/${domain}/zonal-yap/config.php
