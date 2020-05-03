FROM phusion/baseimage:0.11
LABEL maintainer="mfenner@datacite.org"

# use www-data user
RUN usermod -a -G docker_env www-data && \
    mkdir /var/www

# Set correct environment variables.
ENV HOME /var/www
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]

# Update installed APT packages
RUN apt-get update -y -o Dpkg::Options::="--force-confold" && \
    apt-get install --no-install-recommends build-essential patch ruby-dev zlib1g-dev liblzma-dev libmysqlclient-dev nginx ntp wget tzdata imagemagick git -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Remove default nginx site and send logs to stderr/stdout
RUN rm /etc/nginx/sites-enabled/default && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log
COPY vendor/docker/webapp.conf /etc/nginx/sites-enabled/webapp.conf

# Use Amazon NTP servers
COPY vendor/docker/ntp.conf /etc/ntp.conf

# Add Runit script for shoryuken workers
RUN mkdir /etc/service/shoryuken
COPY vendor/docker/shoryuken.sh /etc/service/shoryuken/run

# Add Runit script for puma
RUN mkdir /etc/service/puma
COPY vendor/docker/puma.sh /etc/service/puma/run

# Install Ruby gems
COPY Gemfile* $HOME/
WORKDIR $HOME
RUN mkdir -p vendor/bundle && \
    chown -R www-data:www-data . && \
    chmod -R 755 . && \
    gem install bundler:2.1.4 && \
    /sbin/setuser www-data bundle config set path 'vendor/bundle' && \
    /sbin/setuser www-data bundle install

# Copy webapp folder
COPY . $HOME/
RUN mkdir -p tmp/storage tmp/pids && \
    mkdir -p shared/pids shared/sockets && \
    chown -R www-data:www-data $HOME && \
    chmod -R 755 $HOME

# enable SSH
RUN rm -f /etc/service/sshd/down && \
    /etc/my_init.d/00_regen_ssh_host_keys.sh

# Run additional scripts during container startup (i.e. not at build time)
RUN mkdir -p /etc/my_init.d

# install custom ssh key during startup
COPY vendor/docker/10_ssh.sh /etc/my_init.d/10_ssh.sh

# restart nginx
COPY vendor/docker/30_nginx.sh /etc/my_init.d/30_nginx.sh

# COPY vendor/docker/80_flush_cache.sh /etc/my_init.d/80_flush_cache.sh
COPY vendor/docker/90_migrate.sh /etc/my_init.d/90_migrate.sh

# Expose web
EXPOSE 80
