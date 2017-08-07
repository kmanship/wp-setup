#!/usr/bin/env bash

# ###############################################
# WORDPRESS LOCAL DEVELOPMENT ENVIRONMENT (macOS)
#
# Inspired by:
# https://indigotree.co.uk/automated-wordpress-installation-with-bash-wp-cli/
# 
# Note: 
# If PHP timezone error occurs do the following:
# $ php -i | grep 'Configuration File'
# $ sudo nano <path to php.ini>
# Set date.timzone = 'Australia/Perth' OR
# Set date.timzone = 'UTC'
# Restart Apache with 'sudo apachectl restart'
#
# ###############################################

# ##############
# Local Database
# ##############

MYSQL_USERNAME=root
MYSQL_PASSWORD=

# ###############
# Setup Questions
# ###############

echo "Enter installation directory, relative to this script: "
read -e INSTALL_DIR

echo "Enter Site URL: "
read -e SITE_URL

echo "Enter Site Title: "
read -e SITE_TITLE

echo "Enter Database Name: "
read -e DB_NAME

echo "Enter Admin Username: "
read -e ADMIN_USER

echo "Enter Admin Email: "
read -e ADMIN_EMAIL

# ############
# Installation
# ############

echo ""
echo "Starting Installation ..."
echo ""

echo ""
echo "Checking prerequisites ..."
echo ""
wp --info >/dev/null 2>&1 || {
	echo >&2 "WP-CLI is not installed. Installing ..."
	brew -v >/dev/null 2>&1 || {
		echo >&2 "Unable to install WP-CLI, Homebrew is not installed. Exiting."
		exit 1
	}	
	brew install homebrew/php/wp-cli
}

mkdir $INSTALL_DIR
cd $INSTALL_DIR

echo ""
echo "Start MySQL"
echo ""
mysql.server start

echo ""
echo "Downloading latest version of Wordpress ..."
echo ""
# Download latest version of Wordpress
wp core download

echo ""
echo "Creating wp-config.php ..."
echo ""
wp config create --dbhost=127.0.0.1  --dbname=$DB_NAME --dbuser=$MYSQL_USERNAME --dbpass=$MYSQL_PASSWORD --extra-php <<PHP
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_LOG', true );
define( 'FS_METHOD', 'direct');
PHP
	
echo ""
echo "Creating database ..."
echo ""
wp db create

echo ""
echo "Creating site ..."
echo ""
# ADMIN_PASSWORD=$(LC_CTYPE=C tr -dc A-Za-z0-9_\!\@\#\$\%\^\&\*\(\)-+= < /dev/urandom | head -c 12)
ADMIN_PASSWORD=wordpress

# https://wp-cli.org/commands/core/install/
wp core install --url=$SITE_URL --title="$SITE_TITLE" --admin_user=$ADMIN_USER --admin_password=$ADMIN_PASSWORD --admin_email=$ADMIN_EMAIL --skip-email

# Update plugins to their latest version
# wp plugin update --all

echo ""
echo "Removing default plugins, posts, pages, tag line and widgets ..."
echo ""

# Delete plugins
wp plugin delete akismet hello

# Delete themes
wp theme delete twentyfifteen twentysixteen

# Delete 'Hello world' post and 'Sample page'
wp post delete 1 --force
wp post delete 2 --force

# Remove widgets from sidebar
wp widget delete $(wp widget list sidebar-1 --format=ids)

# Remove site description/tag line
wp option update blogdescription ""

echo ""
echo "Turning off comments and setting permalink structure ..."
echo ""

# Turn off comments by default
wp option set default_comment_status closed

# Update permalink [Note: wp-cli.yml with 'apache_module: mod_rewrite' is required]
wp rewrite structure '/%postname%/' --hard

# Create standard pages
echo ""
echo "Creating common website pages ..."
echo ""

wp post create --post_type=page --post_status=publish --post_title='Home'
wp post create --post_type=page --post_status=publish --post_title='About'
wp post create --post_type=page --post_status=publish --post_title='Blog'
wp post create --post_type=page --post_status=publish --post_title='Contact'

# Set static homepage 
wp option update page_on_front 3
wp option update page_for_posts 5
wp option update show_on_front page

# Don't organize my uploads into month- and year-based folders
wp option update uploads_use_yearmonth_folders 0

# Install plugins
echo ""
echo "Installing additional plugins ..."
echo ""
wp plugin install wordpress-seo --activate
wp plugin install advanced-custom-fields --activate

# Remove unnecessary files
echo ""
echo "Removing unnecessary files ..."
echo ""
rm readme.html
rm wp-config-sample.php

# Change directory permissions
echo ""
echo "Changing directory and file permissions ..."
echo ""
cd ..

# Directories
# Change directory permissions rwxr-xr-x
find $INSTALL_DIR -type d -exec chmod 755 {} \; 

# Files
# Change file permissions rw-r--r--
find $INSTALL_DIR -type f -exec chmod 644 {} \;

# ###########################
# Clean Up
# ###########################

# Clear Bash History
history -cw

echo "==========================================================================="
echo "Wordpress installation is complete. Your username/password is listed below."
echo ""
echo "Site Admin URL: http://$SITE_URL/wp-admin/"
echo "Username: $ADMIN_USER"
echo "Password: $ADMIN_PASSWORD"
echo ""
echo "==========================================================================="