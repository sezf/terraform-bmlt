srcip=bmlt.sezf.org
destip=150.136.141.229

scp makebackups.sh root@${srcip}:makebackups.sh
ssh root@${srcip} sudo chmod +x /root/makebackups.sh
ssh root@${srcip} /root/makebackups.sh
ssh root@${srcip} sudo rm -f /root/makebackups.sh
scp root@${srcip}:/root/bmlt.gz .
scp root@${srcip}:/root/yap.gz .
scp root@${srcip}:/var/www/${srcip}/auto-config.inc.php .
scp root@${srcip}:/var/www/${srcip}/zonal-yap/config.php .

scp restorebackups.sh ubuntu@${destip}:restorebackups.sh
ssh ubuntu@${destip} sudo chmod +x /home/ubuntu/restorebackups.sh
scp bmlt.gz ubuntu@${destip}:bmlt.gz
scp yap.gz  ubuntu@${destip}:yap.gz
scp auto-config.inc.php ubuntu@${destip}:auto-config.inc.php
scp config.php ubuntu@${destip}:config.php
ssh ubuntu@${destip} sudo /home/ubuntu/restorebackups.sh
ssh ubuntu@${destip} sudo rm -f /home/ubuntu/restorebackups.sh
