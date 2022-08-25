srcip=159.223.170.0
srcdomain=bmlt.sezf.org
destip=129.80.254.82
destdomain=gyro.sezf.org

scp makebackups.sh root@${srcip}:makebackups.sh
ssh root@${srcip} sudo chmod +x /root/makebackups.sh
ssh root@${srcip} /root/makebackups.sh
ssh root@${srcip} sudo rm -f /root/makebackups.sh
scp root@${srcip}:/root/bmlt.gz .
scp root@${srcip}:/root/yap.gz .
scp root@${srcip}:/var/www/${srcdomain}/auto-config.inc.php .
scp root@${srcip}:/var/www/${srcdomain}/zonal-yap/config.php .
ssh root@${srcip} tar -czvf recordings.tar.gz -C /var/www/${srcdomain} recordings
scp root@${srcip}:/root/recordings.tar.gz .
ssh root@${srcip} rm /root/recordings.tar.gz

scp restorebackups.sh ubuntu@${destip}:restorebackups.sh
ssh ubuntu@${destip} sudo chmod +x /home/ubuntu/restorebackups.sh
scp bmlt.gz ubuntu@${destip}:bmlt.gz
scp yap.gz  ubuntu@${destip}:yap.gz
scp auto-config.inc.php ubuntu@${destip}:auto-config.inc.php
scp config.php ubuntu@${destip}:config.php
ssh ubuntu@${destip} sudo /home/ubuntu/restorebackups.sh
ssh ubuntu@${destip} sudo rm -f /home/ubuntu/restorebackups.sh
scp recordings.tar.gz ubuntu@${destip}:recordings.tar.gz
ssh ubuntu@${destip} sudo mv /home/ubuntu/recordings.tar.gz /var/www/${destdomain}/
ssh ubuntu@${destip} sudo tar -xzvf /var/www/${destdomain}/recordings.tar.gz -C /var/www/${destdomain}
ssh ubuntu@${destip} sudo chown www-data: /var/www/${destdomain}/recordings
ssh ubuntu@${destip} sudo rm /var/www/${destdomain}/recordings.tar.gz

rm -f auto-config.inc.php bmlt.gz config.php recordings.tar.gz yap.gz
