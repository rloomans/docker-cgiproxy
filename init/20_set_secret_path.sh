#!/bin/bash

set -o nounset

new_secret=$(perl -e '@chars = (0..9, q(a)..q(z), q(A)..q(Z), q(_)); print join q(), map $chars[rand @chars], 0..12;')

if [ ! -e /opt/etc/cgiproxy.conf -a ! -e /opt/cgiproxy/etc/apache-cgiproxy.conf ]; then
  perl -p -E 's{^\$SECRET_PATH=.*;\$}{\$SECRET_PATH= "'"$new_secret"'" ;}' /opt/cgiproxy/etc/cgiproxy.conf.template > /opt/cgiproxy/etc/cgiproxy.conf
  chown root:www-data /opt/cgiproxy/etc/cgiproxy.conf
  chmod 0640 /opt/cgiproxy/etc/cgiproxy.conf
  perl -p -E 's{BAD_SECRET_B4M_79PKppfP}{'"$new_secret"'}' /opt/cgiproxy/etc/apache-cgiproxy.conf.template > /opt/cgiproxy/etc/apache-cgiproxy.conf
fi
