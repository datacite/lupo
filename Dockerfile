FROM phusion/passenger-full:0.9.22
MAINTAINER Kristian Garza "kgarza@datacite.org"

# Set correct environment variables.
ENV HOME /home/app
ENV DOCKERIZE_VERSION v0.2.0

# Allow app user to read /etc/container_environment
RUN usermod -a -G docker_env app

# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]

# Install Ruby 2.3.3
RUN bash -lc 'rvm --default use ruby-2.4.1'

# Update installed APT packages
RUN apt-get update && apt-get upgrade -y -o Dpkg::Options::="--force-confold" && \
    apt-get install ntp wget tzdata -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# install dockerize
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && \
    tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

# Remove unused SSH service
RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

# Enable Passenger and Nginx and remove the default site
# Preserve env variables for nginx
RUN rm -f /etc/service/nginx/down && \
    rm /etc/nginx/sites-enabled/default && \
    rm /etc/nginx/nginx.conf

# send logs to STDOUT and STDERR
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

COPY vendor/docker/webapp.conf /etc/nginx/sites-enabled/webapp.conf
COPY vendor/docker/00_app_env.conf /etc/nginx/conf.d/00_app_env.conf

# Use Amazon NTP servers
COPY vendor/docker/ntp.conf /etc/ntp.conf

# WORKDIR /tmp
# ADD Gemfile Gemfile
# ADD Gemfile.lock Gemfile.lock
# RUN gem update --system && \
#     gem install bundler && \
#     /sbin/setuser app bundle install

# Copy webapp folder
COPY . /home/app/webapp/
RUN mkdir -p /home/app/webapp/tmp/pids && \
    mkdir -p /home/app/webapp/vendor/bundle && \
    chown -R app:app /home/app/webapp && \
    chmod -R 755 /home/app/webapp

# Install Ruby gems
WORKDIR /home/app/webapp
RUN gem update --system && \
    gem install bundler && \
    /sbin/setuser app bundle install --path vendor/bundle

# Add Runit script for sidekiq workers
RUN mkdir /etc/service/sidekiq
ADD vendor/docker/sidekiq.sh /etc/service/sidekiq/run

# Configure handle client
RUN mkdir -p /home/app/.handle \
  && cp vendor/docker/siteinfo.json /home/app/.handle/resolver_site \
  && sed -i 's/0.0.0.0/127.0.0.1/g' /home/app/.handle/resolver_site \
  && echo "*" > /home/app/.handle/local_nas

# Run additional scripts during container startup (i.e. not at build time)
RUN mkdir -p /etc/my_init.d
COPY vendor/docker/70_templates.sh /etc/my_init.d/70_templates.sh
COPY vendor/docker/80_flush_cache.sh /etc/my_init.d/80_flush_cache.sh
COPY vendor/docker/90_migrate.sh /etc/my_init.d/90_migrate.sh

# Expose web
EXPOSE 80
