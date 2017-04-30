set -e

export CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export HOSTNAME=""
export SSL_CA_BUNDLE_FILE="/etc/dovecot/dovecot.pem"
export SSL_PRIVATE_KEY_FILE="/etc/dovecot/private/dovecot.pem"

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "Please log in as root"
   exit
fi

# Check for min system requirements
if (($(($(free -mt|awk '/^Total:/{print $2}')*1)) <= 900)); then
   echo -e "The installation of EasyMail has been stopped because of the following minimum requirements:\n";
   echo -e "- RAM (or RAM + SWAP) >= 1GB\n\n";
   exit;
fi

# Check if some of the services are already installed
function is_installed {
    is_installed=$(dpkg -l | grep $1 | wc -c)

    if [ $is_installed != "0" ]; then
        is_installed=1
    fi

   echo $is_installed
}

if [ $(is_installed php) == 1 ]; then
	echo "PHP is already installed, installation aborted"; exit
elif [ $(is_installed nginx) == 1 ]; then
	echo "Nginx is already installed, installation aborted"; exit
elif [ $(is_installed postfix) == 1 ]; then
	echo "Postfix is already installed, installation aborted"; exit
elif [ $(is_installed dovecot) == 1 ]; then
	echo "Dovecot is already installed, installation aborted"; exit
elif [ $(is_installed mysql) == 1 ]; then
	echo "MySQL is already installed, installation aborted"; exit
elif [ $(is_installed spamassassin) == 1 ]; then
	echo "SpamAssassin is already installed, installation aborted"; exit
fi

# Update and install initially required services
apt-get update -y && apt-get install openssl python dialog cron -y

# Use config
while [[ "$#" > 1 ]]; do case $1 in
    --config) useConfig="$2";;
    -c) useConfig="$2";;
    *) break;;
  esac; shift; shift
done

while [[ "$#" > 1 ]]; do case $1 in
    --config) useConfig="$2";;
    -c) useConfig="$2";;
    *) break;;
  esac; shift; shift
done

if [  "$useConfig" != "" ]; then
        if [ -f "$useConfig" ]; then     
                export HOSTNAME=$(cat $useConfig | grep HOSTNAME: | awk '{ print $2 }')                   
        else
                echo "The config file does not exist!"; exit;
        fi
fi

# Define some functions and variables
function set_hostname {
	sed -i "s/__EASYMAIL_HOSTNAME__/$HOSTNAME/g" $1
}

function get_rand_password() {
	openssl rand  32 | md5sum | awk '{print $1;}'
}

export -f set_hostname

export PASSWORD=$(get_rand_password)

export ADMIN_EMAIL="admin@__EASYMAIL_HOSTNAME__"
export ADMIN_PASSWORD=$(openssl passwd -1 $PASSWORD)

export ROOT_MYSQL_USERNAME='root'
export ROOT_MYSQL_PASSWORD=$(get_rand_password)

export MYSQL_DATABASE='mailserver'
export MYSQL_HOSTNAME='127.0.0.1'
export MYSQL_USERNAME='mailuser'
export MYSQL_PASSWORD=$(get_rand_password)

export ROUNDCUBE_MYSQL_DATABASE='roundcube_dbname'
export ROUNDCUBE_MYSQL_USERNAME='roundcube_user'
export ROUNDCUBE_MYSQL_PASSWORD=$(get_rand_password)
export ROUNDCUBE_VERSION=1.2.3

export MANAGEMENT_API_USERNAME='easyadmin'
export MANAGEMENT_API_PASSWORD=$(get_rand_password)
export MANAGEMENT_API_SECRETKEY=$(get_rand_password)

export EASY_MAIL_DIR="/opt/easymail" && mkdir $EASY_MAIL_DIR

# Install
bash $CURRENT_DIR/mysql/install.sh
bash $CURRENT_DIR/postfix/install.sh
bash $CURRENT_DIR/dovecot/install.sh
bash $CURRENT_DIR/nginx/install.sh
bash $CURRENT_DIR/roundcube/install.sh
bash $CURRENT_DIR/autoconfig/install.sh
bash $CURRENT_DIR/spamassassin/install.sh
bash $CURRENT_DIR/autostart/install.sh
bash $CURRENT_DIR/ManagementAPI/install.sh

# Save the system configurations
echo "
[ssl]
public_dovecot_key:$SSL_CA_BUNDLE_FILE
private_dovecot_key:$SSL_PRIVATE_KEY_FILE

[mysql_root]
username:$ROOT_MYSQL_USERNAME
password:$ROOT_MYSQL_PASSWORD

[mysql_easymail]
database:$MYSQL_DATABASE
hostname:$MYSQL_HOSTNAME
username:$MYSQL_USERNAME
password:$MYSQL_PASSWORD

[mysql_roundcube]
database:$ROUNDCUBE_MYSQL_DATABASE
username:$ROUNDCUBE_MYSQL_USERNAME
password:$ROUNDCUBE_MYSQL_PASSWORD

[roundcube]
url:
username:
password:$PASSWORD

[api]
url:
username:$MANAGEMENT_API_USERNAME
password:$MANAGEMENT_API_PASSWORD
"  >> $EASY_MAIL_DIR/config.ini

# Execute some post installation commands
bash $CURRENT_DIR/post_install.sh	
bash $CURRENT_DIR/dkim/install.sh



echo -e "\n----------------------"
echo -e "\nApplications - access:"
echo "Roundcube: https://$HOSTNAME/ | username: $ADMIN_EMAIL | password: $PASSWORD"
echo "API url: https://$HOSTNAME/api/ | username: $MANAGEMENT_API_USERNAME | password: $MANAGEMENT_API_PASSWORD"

echo -e "\nInstallation has finished"
echo "All services have been started automatically."
