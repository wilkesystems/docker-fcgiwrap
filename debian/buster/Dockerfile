FROM debian:buster

MAINTAINER wilkesystems <maintainer@wilke.systems>

RUN apt-get update; \
apt-get install -y fcgiwrap cron exim4-daemon-light cpanminus imagemagick \
libarchive-zip-perl libauthen-sasl-perl libauthen-ntlm-perl libcgi-fast-perl \
libcgi-pm-perl libcrypt-eksblowfish-perl libcrypt-ssleay-perl \
libdbd-mysql-perl libdbd-odbc-perl libdbd-pg-perl libdbi-perl \
libencode-hanextra-perl libio-socket-ssl-perl libjson-xs-perl \
libmail-imapclient-perl libnet-dns-perl libnet-ldap-perl libtemplate-perl \
libtext-csv-xs-perl libxml-libxml-perl libxml-libxslt-perl \
libxml-parser-perl libyaml-libyaml-perl locales locales-all make perlmagick \
rsyslog supervisor wget; rm -r /var/lib/apt/lists/*

EXPOSE 9000

COPY ["docker-entrypoint.sh", "/usr/bin/docker-entrypoint.sh"]

WORKDIR /var/www

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["fcgiwrap"]
