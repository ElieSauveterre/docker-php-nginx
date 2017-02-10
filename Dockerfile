FROM phusion/baseimage:0.9.19
MAINTAINER Elie Sauveterre <contact@eliesauveterre.com>

# Default baseimage settings
ENV HOME /root
ENV MAX_UPLOAD "50M"
ENV COMPOSER_VERSION 1.0.0-alpha10

RUN /etc/my_init.d/00_regen_ssh_host_keys.sh
CMD ["/sbin/my_init"]
ENV DEBIAN_FRONTEND noninteractive

# Update software list, install php-nginx & clear cache
RUN apt-get update && \
    apt-get install -y --force-yes nginx git \
    php7.0-fpm php7.0-cli php7.0-mysql php7.0-mcrypt php7.0-dev \
    php7.0-curl php7.0-gd php7.0-intl php7.0-sqlite phpunit \
    tesseract-ocr tesseract-ocr-eng wget build-essential && \
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
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/"                  /etc/php/7.0/fpm/php.ini
RUN sed -i "s/;date.timezone =.*/date.timezone = America\/Montreal/"    /etc/php/7.0/fpm/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g"                 /etc/php/7.0/fpm/php-fpm.conf
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/"                  /etc/php/7.0/cli/php.ini
RUN sed -i "s/;date.timezone =.*/date.timezone = America\/Montreal/"    /etc/php/7.0/cli/php.ini
RUN sed -i "s/upload_max_filesize = 2M/upload_max_filesize = $MAX_UPLOAD/"  /etc/php/7.0/fpm/php.ini
RUN sed -i "s/post_max_size = 8M/post_max_size = $MAX_UPLOAD/"              /etc/php/7.0/fpm/php.ini
RUN echo "; zend_extension=xdebug.so" >                                     /etc/php/7.0/fpm/conf.d/20-xdebug.ini

RUN phpenmod mcrypt

# Add GEOS
RUN wget http://download.osgeo.org/geos/geos-3.6.1.tar.bz2
RUN tar xjf geos-3.6.1.tar.bz2
RUN cd geos-3.6.1 && ./configure --enable-php && make && make install
RUN echo "; configuration for php geos module" >                            /etc/php/7.0/mods-available/geos.ini
RUN echo "; priority=50" >>                                                 /etc/php/7.0/mods-available/geos.ini
RUN echo "extension=geos.so" >>                                            /etc/php/7.0/mods-available/geos.ini
RUN phpenmod geos

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version=${COMPOSER_VERSION}
# Display version information
RUN composer --version


# Add nginx service
RUN mkdir                                                               /etc/service/nginx
ADD build/nginx/run.sh                                                  /etc/service/nginx/run
RUN chmod +x                                                            /etc/service/nginx/run

# Add PHP service
RUN mkdir                                                               /etc/service/phpfpm
ADD build/php/run.sh                                                    /etc/service/phpfpm/run
RUN chmod +x                                                            /etc/service/phpfpm/run

# Add nginx
VOLUME ["/var/www", "/etc/nginx/sites-available", "/etc/nginx/sites-enabled", "/etc/nginx/ssl"]

# Workdir
WORKDIR /var/www

EXPOSE 80 443 8000
