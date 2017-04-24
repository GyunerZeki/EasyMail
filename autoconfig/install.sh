# Install autoconfig and autodiscover
set -e

AUTOCONFIG_DIR="$CURRENT_DIR/autoconfig"

mkdir /usr/share/nginx/autoconfig_and_autodiscover

cp $AUTOCONFIG_DIR/autoconfig.php /usr/share/nginx/autoconfig_and_autodiscover/
cp $AUTOCONFIG_DIR/autodiscover.php /usr/share/nginx/autoconfig_and_autodiscover/
cp $AUTOCONFIG_DIR/nginx_config /etc/nginx/sites-enabled/autoconfig_and_autodiscover

sed -i "s#__EASYMAIL_SSL_CA_BUNDLE_FILE__#$SSL_CA_BUNDLE_FILE#g" /etc/nginx/sites-enabled/autoconfig_and_autodiscover
sed -i "s#__EASYMAIL_SSL_PRIVATE_KEY_FILE__#$SSL_PRIVATE_KEY_FILE#g" /etc/nginx/sites-enabled/autoconfig_and_autodiscover

service nginx reload
