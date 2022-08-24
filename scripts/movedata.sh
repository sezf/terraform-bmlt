srcip=bmlt.sezf.org
destip=tlmb.sezf.org

scp makebackups.sh root@${srcip}:makebackups.sh
ssh root@${srcip} sudo chmod +x /root/makebackups.sh
ssh root@${srcip} /root/makebackups.sh
ssh root@${srcip} sudo rm -f /root/makebackups.sh
scp root@${srcip}:/root/bmlt.gz .
scp root@${srcip}:/root/yap.gz .
scp root@${srcip}:/var/www/${srcip}/auto-config.inc.php .
scp root@${srcip}:/var/www/${srcip}/zonal-yap/config.php .
ssh root@${srcip} tar -czvf recordings.tar.gz -C /var/www/${srcip} recordings
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
ssh ubuntu@${destip} sudo mv /home/ubuntu/recordings.tar.gz /var/www/${destip}/
ssh ubuntu@${destip} sudo tar -xzvf /var/www/${destip}/recordings.tar.gz -C /var/www/${destip}
ssh ubuntu@${destip} sudo chown www-data: /var/www/${destip}/recordings
ssh ubuntu@${destip} sudo rm /var/www/${destip}/recordings.tar.gz
