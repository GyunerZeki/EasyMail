# Install autoconfig and autodiscover

AUTOCONFIG_DIR="$CURRENT_DIR/autoconfig"

mkdir /usr/share/nginx/autoconfig_and_autodiscover

cp $AUTOCONFIG_DIR/autoconfig.php /usr/share/nginx/autoconfig_and_autodiscover/
set_hostname /usr/share/nginx/autoconfig_and_autodiscover/autoconfig.php

cp $AUTOCONFIG_DIR/autodiscover.php /usr/share/nginx/autoconfig_and_autodiscover/
set_hostname /usr/share/nginx/autoconfig_and_autodiscover/autodiscover.php

cp $AUTOCONFIG_DIR/nginx_config /etc/nginx/sites-enabled/autoconfig_and_autodiscover
sed -i "s#__EASYMAIL_SSL_CA_BUNDLE_FILE__#$SSL_CA_BUNDLE_FILE#g" /etc/nginx/sites-enabled/autoconfig_and_autodiscover
sed -i "s#__EASYMAIL_SSL_PRIVATE_KEY_FILE__#$SSL_PRIVATE_KEY_FILE#g" /etc/nginx/sites-enabled/autoconfig_and_autodiscover

service nginx reload

# Set up the bash script for autostarting the services in case of reboot
cp $AUTOCONFIG_DIR/run.sh /run.sh

if [ $IS_ON_DOCKER == true ]; then 
  chmod +x /run.sh
  sh /run.sh
fi
