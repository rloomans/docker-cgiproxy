#!/bin/bash

set -o nounset

new_secret=$(perl -e '@chars = (0..9, q(a)..q(z), q(A)..q(Z), q(_)); print join q(), map $chars[rand @chars], 0..12;')

perl -pi -E 's{^\$SECRET_PATH=.*;\$}{\$SECRET_PATH= "'"$new_secret"'" ;}' /opt/cgiproxy/cgiproxy.conf
perl -p -E 's{BAD_SECRET_B4M_79PKppfP}{'"$new_secret"'}' /etc/apache2/conf-enabled/cgiproxy.conf.template > /etc/apache2/conf-enabled/cgiproxy.conf

