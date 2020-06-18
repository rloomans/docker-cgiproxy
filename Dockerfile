FROM    phusion/baseimage:master-amd64
MAINTAINER rloomans, https://github.com/rloomans/docker-cgiproxy

ENV     DEBIAN_FRONTEND=noninteractive \
        HOME="/root" \
        TERM="xterm" \
        APACHE_LOG_DIR="/var/log/apache2" \
        APACHE_LOCK_DIR="/var/lock/apache2" \
        APACHE_PID_FILE="/var/run/apache2.pid" \
        LC_ALL=C \
        LANG=C

ADD     init/ /etc/my_init.d/
ADD     services/ /etc/service/


RUN \
        chmod -v +x /etc/service/*/run && \
        chmod -v +x /etc/my_init.d/*.sh && \
        apt-get update && \
        apt-get install -y curl perl-modules sudo build-essential vim less \
            procps ssmtp cron apache2 libapache2-mod-perl2 \
            libcrypt-ssleay-perl libnet-ssleay-perl \
            libcompress-raw-lzma-perl libio-compress-lzma-perl libyaml-perl \
            libconfig-yaml-perl fcgiwrap spawn-fcgi libfcgi-perl \
            libfcgi-procmanager-perl perl-modules libnet-ssleay-perl \
            libcrypt-ssleay-perl liburi-perl libjson-perl \
            libjavascript-minifier-xs-perl libperlio-gzip-perl \
            libmodule-install-perl libmodule-build-perl liblocal-lib-perl \
            libjson-pp-perl libjson-xs-perl libcpan-meta-perl libdbd-sqlite3 \
            libdbd-sqlite3-perl && \
        # Enable SSL default vhost
        a2ensite default-ssl && \
        # Enable cgid and SSL support in apache
        a2enmod ssl perl && \
        sed -i 's/#AddHandler cgi-script .cgi/AddHandler cgi-script .cgi/' /etc/apache2/mods-available/mime.conf && \
        # Adjusting SyslogNG - see https://github.com/phusion/baseimage-docker/pull/223/commits/dda46884ed2b1b0f7667b9cc61a961e24e910784
        sed -ie "s/^       system();$/#      system(); #This is to avoid calls to \/proc\/kmsg inside docker/g" /etc/syslog-ng/syslog-ng.conf && \

RUN \
        mkdir /var/run/cgiproxy/ && \
        chmod -R 770 /var/run/cgiproxy/ && \
        chown -R www-data:www-data /var/run/cgiproxy/ && \
        mkdir /opt/cgiproxy/ /opt/cgiproxy/sqlite /opt/cgiproxy/usage /opt/cgiproxy/releases /opt/cgiproxy/bin && \
        chmod -R 770 /opt/cgiproxy && \
        chown -R www-data:www-data /opt/cgiproxy/

ADD     cgiproxy.conf /opt/cgiproxy/cgiproxy.conf
ADD     apache-cgiproxy.conf /etc/apache2/conf-enabled/cgiproxy.conf
ADD     cgiproxy.cron /etc/cron.d/cgiproxy

RUN \
        export SECRET_PATH=$(perl -e '@chars = (0..9, q(a)..q(z), q(A)..q(Z), q(_)); print join q(), map $chars[rand @chars], 0..12;') && \
        perl -pi -E 's{BAD_SECRET_B4M_79PKppfP}{$ENV{SECRET_PATH}}' /opt/cgiproxy/cgiproxy.conf /etc/apache2/conf-enabled/cgiproxy.conf && \
        mkdir /tmp/cgiproxy/ && cd /tmp/cgiproxy/ &&  \
        curl -L -O https://www.jmarshall.com/tools/cgiproxy/releases/cgiproxy.latest.tar.gz &&  \
        tar xvzf cgiproxy.latest.tar.gz &&  \
        tar xvzf cgiproxy-inner.*.tar.gz &&  \
        perl -pi -E 's{^\$PROXY_DIR=.*;$}{\$PROXY_DIR= \x27/opt/cgiproxy\x27 ;}' nph-proxy.cgi && \
        cp nph-proxy.cgi /opt/cgiproxy/bin/ && \
        chown root:www-data /opt/cgiproxy/bin/nph-proxy.cgi /opt/cgiproxy/cgiproxy.conf && \
        chmod 0750 /opt/cgiproxy/bin/nph-proxy.cgi && \
        chmod 0640 /opt/cgiproxy/cgiproxy.conf && \
        /opt/cgiproxy/bin/nph-proxy.cgi install-modules && \
        /opt/cgiproxy/bin/nph-proxy.cgi create-db

# Clean up
RUN \
        apt-get clean; \
        rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /etc/dpkg/dpkg.cfg.d/02apt-speedup

WORKDIR /opt/cgiproxy

EXPOSE 443

HEALTHCHECK --interval=60s --timeout=15s --start-period=20s \
        CMD curl -skL https://localhost/ | \
            grep -qm1 'Start browsing through this CGI-based proxy by entering a URL below'

# Use baseimage-docker's init system
CMD ["/sbin/my_init"]

