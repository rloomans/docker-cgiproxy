#!/bin/bash

set -eo nounset

if [ ! -e /cgiproxy/etc/cgiproxy.conf ]; then
  if [ -n "$SECRET_PATH" ]; then
    SECRET_PATH=$(perl -e '@chars = (0..9, q(a)..q(z), q(A)..q(Z), q(_)); print join q(), map $chars[rand @chars], 0..12;')
  fi

  perl -p -E 's{^\$SECRET_PATH=.*;\$}{\$SECRET_PATH= "'"$SECRET_PATH"'" ;}' /cgiproxy/etc/cgiproxy.conf.template > /cgiproxy/etc/cgiproxy.conf

  chown root:proxy /cgiproxy/etc/cgiproxy.conf
  chmod 0640 /cgiproxy/etc/cgiproxy.conf

  echo "========================================"
  echo "New secret: $SECRET_PATH"
  echo "========================================"
fi
