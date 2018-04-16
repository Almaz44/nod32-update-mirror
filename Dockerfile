FROM debian:jessie-slim

ENV DEBIAN_FRONTEND noninteractive
ENV UNRAR_VERSION '5.5.0'

# Install main dependencies
RUN \
  apt-get -yq update && apt-get install -yq curl apt-transport-https ca-certificates \
  && echo "deb http://nginx.org/packages/debian/ jessie nginx" >> /etc/apt/sources.list.d/nginx.list \
  && curl -L http://nginx.org/keys/nginx_signing.key | apt-key add - \
  && apt-get -yq update && apt-get install -yq wget tar cron nano nginx openssl

# Make unrar installation
RUN \
  mkdir -p /tmp/rar \
  && curl -L -o /tmp/rar/rarlinux.tar.gz https://rarlab.com/rar/rarlinux-x64-${UNRAR_VERSION}.tar.gz \
  && tar xvzf /tmp/rar/rarlinux.tar.gz --directory /tmp/rar \
  && cp -v /tmp/rar/rar/unrar /bin/unrar && chmod +x /bin/unrar \
  && cp -v /tmp/rar/rar/rar /bin/rar && chmod +x /bin/rar \
  && rm -Rf /tmp/rar

# Make check
RUN curl -V && wget -V | head -n 4 && unrar | head -n 2 | tail -n 1 && nginx -v

# Put sources and other resources into container
COPY ./configs /configs
COPY ./src /app
COPY ./www /var/www
COPY ./docker-entrypoint.sh /docker-entrypoint.sh

# Install crontab task
RUN \
  cp -fv /configs/crontab/crontab.conf /etc/cron.d/app \
  && chmod 0644 /etc/cron.d/app \
  && crontab -u root /etc/cron.d/app \
  && crontab -l

# Setup nginx

# Make clear
RUN apt-get -yq autoremove && apt-get -yq clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /app

ENTRYPOINT ["/docker-entrypoint.sh"]