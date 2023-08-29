FROM  phusion/baseimage:jammy-1.0.1 as base
MAINTAINER rloomans, https://github.com/rloomans/docker-cgiproxy

ARG APT_HTTP_PROXY

ENV \
        HOME="/root" \
        TERM="xterm" \
        APACHE_LOG_DIR="/var/log/apache2" \
        APACHE_LOCK_DIR="/var/lock/apache2" \
        APACHE_PID_FILE="/var/run/apache2.pid" \
        LC_ALL=C \
        LANG=C

RUN \
        export DEBIAN_FRONTEND=noninteractive && \
        if [ -n "$APT_HTTP_PROXY" ]; then \
            printf 'Acquire::http::Proxy "%s";\n' "${APT_HTTP_PROXY}" > /etc/apt/apt.conf.d/apt-proxy.conf; \
        fi && \
        apt-get update && \
        apt-get upgrade -y -o Dpkg::Options::="--force-confold" && \
        apt-get clean && \
        rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /etc/apt/apt.conf.d/apt-proxy.conf

RUN \
        export DEBIAN_FRONTEND=noninteractive && \
        if [ -n "$APT_HTTP_PROXY" ]; then \
            printf 'Acquire::http::Proxy "%s";\n' "${APT_HTTP_PROXY}" > /etc/apt/apt.conf.d/apt-proxy.conf; \
        fi && \
        apt-get update && \
        apt-get install -y \
            apache2 \
            cron \
            curl \
            fcgiwrap \
            libapache2-mod-perl2 \
            libcompress-raw-lzma-perl \
            libconfig-yaml-perl \
            libcpan-meta-perl \
            libcrypt-ssleay-perl \
            libdbd-sqlite3 \
            libdbd-sqlite3-perl \
            libfcgi-perl \
            libfcgi-procmanager-perl \
            libio-compress-lzma-perl \
            libjavascript-minifier-xs-perl \
            libjson-perl \
            libjson-pp-perl \
            libjson-xs-perl \
            liblocal-lib-perl \
            libmodule-build-perl \
            libmodule-install-perl \
            libnet-ssleay-perl \
            libperlio-gzip-perl \
            liburi-perl \
            libyaml-perl \
            perl-modules \
            spawn-fcgi \
            tzdata && \
        apt-get clean && \
        rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /etc/apt/apt.conf.d/apt-proxy.conf

RUN \
        mkdir -m 770 /var/run/cgiproxy/ && \
        chown www-data:www-data /var/run/cgiproxy/ && \
        mkdir -m 750 /opt/cgiproxy/ /opt/cgiproxy/sqlite /opt/cgiproxy/bin /opt/cgiproxy/etc && \
        chmod 0770 /opt/cgiproxy/sqlite && \
        chown -R root:www-data /opt/cgiproxy/

RUN \
        # Enable SSL default vhost
        a2ensite default-ssl && \
        # Enable mod_perl and SSL support in apache
        a2enmod ssl perl

COPY    init/ /etc/my_init.d/
COPY    services/ /etc/service/

RUN \
        chmod -v +x /etc/service/*/run && \
        chmod -v +x /etc/my_init.d/*.sh

COPY    cgiproxy.conf /opt/cgiproxy/etc/cgiproxy.conf.template
COPY    apache-cgiproxy.conf /opt/cgiproxy/etc/apache-cgiproxy.conf.template
COPY    cgiproxy.cron /etc/cron.d/cgiproxy

RUN \
        ln -s /opt/cgiproxy/etc/cgiproxy.conf /opt/cgiproxy/cgiproxy.conf && \
        ln -s /opt/cgiproxy/etc/apache-cgiproxy.conf /etc/apache2/conf-enabled/cgiproxy.conf && \
        mkdir /tmp/cgiproxy/ && cd /tmp/cgiproxy/ &&  \
        curl -L -O https://www.jmarshall.com/tools/cgiproxy/releases/cgiproxy.latest.tar.gz &&  \
        tar xvzf cgiproxy.latest.tar.gz &&  \
        tar xvzf cgiproxy-inner.*.tar.gz &&  \
        perl -pi -E 's{^\$PROXY_DIR=.*;$}{\$PROXY_DIR= "/opt/cgiproxy" ;}' nph-proxy.cgi && \
        cp nph-proxy.cgi /opt/cgiproxy/bin/ && \
        chown root:www-data /opt/cgiproxy/bin/nph-proxy.cgi && \
        chmod 0750 /opt/cgiproxy/bin/nph-proxy.cgi && \
        /opt/cgiproxy/bin/nph-proxy.cgi install-modules && \
        /opt/cgiproxy/bin/nph-proxy.cgi create-db && \
        chown www-data:www-data /opt/cgiproxy/sqlite/* && \
        chmod 0640 /opt/cgiproxy/sqlite/* && \
        rm -rf /tmp/* /var/tmp/*

WORKDIR /opt/cgiproxy

EXPOSE 80
EXPOSE 443

HEALTHCHECK --interval=60s --timeout=15s --start-period=20s \
        CMD curl -skL https://localhost/ | \
            grep -qm1 'Start browsing through this CGI-based proxy by entering a URL below' && \
            curl -sL http://localhost/ | \
            grep -qm1 'Start browsing through this CGI-based proxy by entering a URL below'

VOLUME ["/opt/cgiproxy/sqlite", "/opt/cgiproxy/etc"]

# Use baseimage-docker's init system
CMD ["/sbin/my_init"]

