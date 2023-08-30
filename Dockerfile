#FROM  debian:bookworm-slim as base
FROM  phusion/baseimage:jammy-1.0.1 as base
#FROM  rloomans/phusion-baseimage:latest as base
MAINTAINER rloomans, https://github.com/rloomans/docker-cgiproxy

ARG APT_HTTP_PROXY=http://apt-proxy.zots.org:3142

ENV \
        TERM="xterm" \
        LC_ALL=C \
        LANG=C

RUN \
        export DEBIAN_FRONTEND=noninteractive && \
        if [ -n "$APT_HTTP_PROXY" ]; then \
            printf 'Acquire::http::Proxy "%s";\n' "${APT_HTTP_PROXY}" > /etc/apt/apt.conf.d/apt-proxy.conf; \
        fi && \
        apt-get update && \
        apt-get upgrade -y -o Dpkg::Options::="--force-confold" && \
        apt-get install -y \
            curl && \
        apt-get clean && \
        rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /etc/apt/apt.conf.d/apt-proxy.conf

FROM base as download
MAINTAINER rloomans, https://github.com/rloomans/docker-smokeping

RUN \
        mkdir -m 770 /cgiproxy/ && \
        chown proxy:proxy /cgiproxy/ && \
        mkdir -m 750 /cgiproxy/sqlite /cgiproxy/bin /cgiproxy/etc /cgiproxy/perl5 && \
        chmod 0770 /cgiproxy/sqlite && \
        chown -R proxy:proxy /cgiproxy/

RUN \
        mkdir /tmp/cgiproxy/ && \
        cd /tmp/cgiproxy/ &&  \
        curl -Lv -O https://www.jmarshall.com/tools/cgiproxy/releases/cgiproxy.latest.tar.gz &&  \
        tar xvzf cgiproxy.latest.tar.gz &&  \
        tar xvzf cgiproxy-inner.*.tar.gz &&  \
        perl -pi -E 's{^\$PROXY_DIR=.*;$}{\$PROXY_DIR= "/cgiproxy" ;}' nph-proxy.cgi && \
        cp nph-proxy.cgi /cgiproxy/bin/ && \
        chown proxy:proxy /cgiproxy/bin/nph-proxy.cgi && \
        chmod 0750 /cgiproxy/bin/nph-proxy.cgi && \
        rm -rf /tmp/* /var/tmp/*

FROM base as runtime
MAINTAINER rloomans, https://github.com/rloomans/docker-smokeping

RUN \
        export DEBIAN_FRONTEND=noninteractive && \
        if [ -n "$APT_HTTP_PROXY" ]; then \
            printf 'Acquire::http::Proxy "%s";\n' "${APT_HTTP_PROXY}" > /etc/apt/apt.conf.d/apt-proxy.conf; \
        fi && \
        apt-get update && \
        apt-get install -y \
            cron \
            curl \
            libcompress-raw-lzma-perl \
            libconfig-yaml-perl \
            libcpan-meta-perl \
            libcrypt-ssleay-perl \
            libdbd-sqlite3 \
            libdbd-sqlite3-perl \
            libfcgi-perl \
            libfcgi-procmanager-perl \
            libio-compress-lzma-perl \
            libio-compress-perl \
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
            tzdata && \
        apt-get clean && \
        rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /etc/apt/apt.conf.d/apt-proxy.conf

COPY    init/ /etc/my_init.d/
COPY    services/ /etc/service/

RUN \
        chmod -v +x /etc/service/*/run && \
        chmod -v +x /etc/my_init.d/*.sh

COPY    --from=download /cgiproxy /cgiproxy

COPY    cgiproxy.conf.template /cgiproxy/etc/cgiproxy.conf.template

RUN \
        ln -s etc/cgiproxy.conf /cgiproxy/cgiproxy.conf

ENV     HOME="/cgiproxy"

RUN \
        /cgiproxy/bin/nph-proxy.cgi install-modules && \
        /cgiproxy/bin/nph-proxy.cgi create-db

WORKDIR /cgiproxy

EXPOSE 8002

#HEALTHCHECK --interval=60s --timeout=15s --start-period=20s \
#        CMD curl -skL https://localhost/ | \
#            grep -qm1 'Start browsing through this CGI-based proxy by entering a URL below' && \
#            curl -sL http://localhost/ | \
#            grep -qm1 'Start browsing through this CGI-based proxy by entering a URL below'

VOLUME ["/cgiproxy/sqlite", "/cgiproxy/etc"]

# Use baseimage-docker's init system
CMD ["/sbin/my_init"]

