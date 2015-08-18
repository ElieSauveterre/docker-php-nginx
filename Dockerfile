FROM phusion/baseimage:0.9.16
MAINTAINER Harsh Vakharia <harshjv@gmail.com>

# Default baseimage settings
ENV HOME /root
ENV MAX_UPLOAD "50M"

RUN /etc/my_init.d/00_regen_ssh_host_keys.sh
CMD ["/sbin/my_init"]
ENV DEBIAN_FRONTEND noninteractive

# Update software list, install php-nginx & clear cache
RUN apt-get update && \
    apt-get install -y --force-yes nginx \
    php5-fpm php5-cli php5-mysql php5-mcrypt \
    php5-curl php5-gd php5-intl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* \
           /tmp/* \
           /var/tmp/*

# Configure nginx
RUN echo "daemon off;" >>                                                   /etc/nginx/nginx.conf
RUN sed -i "s/sendfile on/sendfile off/"                                    /etc/nginx/nginx.conf
RUN sed -i "s/http {/http {\n        client_max_body_size $MAX_UPLOAD;/"    /etc/nginx/nginx.conf
RUN mkdir -p                                                            /var/www

# Configure PHP
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/"                  /etc/php5/fpm/php.ini
RUN sed -i "s/;date.timezone =.*/date.timezone = America\/Montreal/"    /etc/php5/fpm/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g"                 /etc/php5/fpm/php-fpm.conf
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/"                  /etc/php5/cli/php.ini
RUN sed -i "s/;date.timezone =.*/date.timezone = America\/Montreal/"    /etc/php5/cli/php.ini
RUN sed -i "s/upload_max_filesize = 2M/upload_max_filesize = $MAX_UPLOAD/"  /etc/php5/fpm/php.ini
RUN sed -i "s/post_max_size = 8M/post_max_size = $MAX_UPLOAD/"              /etc/php5/fpm/php.ini

RUN php5enmod mcrypt

# Add nginx service
RUN mkdir                                                               /etc/service/nginx
ADD build/nginx/run.sh                                                  /etc/service/nginx/run
RUN chmod +x                                                            /etc/service/nginx/run

# Add PHP service
RUN mkdir                                                               /etc/service/phpfpm
ADD build/php/run.sh                                                    /etc/service/phpfpm/run
RUN chmod +x                                                            /etc/service/phpfpm/run

# Add nginx
VOLUME ["/var/www", "/etc/nginx/sites-available", "/etc/nginx/sites-enabled"]

# Workdir
WORKDIR /var/www

EXPOSE 80
