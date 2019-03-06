#!/bin/bash


basedir=$(dirname $(readlink -f $0))


upgrade=false
if [ "x$1" = "x--upgrade" ]; then
    upgrade=true
fi


if [ "$upgrade" != "true" ]; then


    echo ""
    echo ""
    echo "This script assumes you're installing in /var/www/publisher"
    echo "..it also assumes you're running on some Debian based system"
    echo ""
    echo ""
    echo " If that isn't okay, you have 5 seconds to CTRL+C and review the source"
    echo " code of all the files"
    echo ""
    echo "Hint: grep -R \"var/www/publisher\" ."
    echo ""


    sleep 5


    # sanity checking
    if [ ! -d "/etc/cron.d/" ]; then
        echo "No /etc/cron.d directory..."
        exit 1
    fi
    if [ ! -d "/etc/apache2/conf-available" ]; then
        echo "No /etc/apache2/conf-available directory..."
        exit 1
    fi


    # create directory for publisher
    if ! mkdir -p "/var/www/publisher" 2>/dev/null; then
        echo "Can't create directory"
        exit 1
    fi


    # copy or create all relevant files
    touch "/var/www/publisher/bloglog"

    cp "${basedir}/blog.apache.conf" "/etc/apache2/conf-available/blog.apache.conf"
    cp "${basedir}/blog.cron.d" "/etc/cron.d/blog"


    # enable apache module
    if which a2enconf >/dev/null 2>&1; then
        a2enconf blog.apache
    elif [ -d /etc/apache/conf-enabled ]; then
        ln -s /etc/apache2/conf-available/blog.apache.conf /etc/apache2/conf-enabled/blog.apache.conf
    else
        echo "How shall we enable your apache module?"
        exit 1
    fi


    # restart apache
    if which systemctl >/dev/null 2>&1; then
        systemctl restart apache2
    else
        service apache2 restart
    fi


    cp -p ${basedir}/config /var/www/publisher
fi


cp -p ${basedir}/publisher.sh /var/www/publisher
cp -pr ${basedir}/../{executor,plugins} /var/www/publisher


if [ "$upgrade" != "true" ]; then

    # set appropriate permissions
    chown -R www-data:www-data /var/www/publisher
fi
