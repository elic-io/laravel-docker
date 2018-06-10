# FROM shakyshane/laravel-php:latest
FROM php:7.2.6-fpm
SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y vim \
    libmcrypt-dev zip unzip libzip-dev \    
    libpq-dev libmagickwand-dev --no-install-recommends \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && pecl install mcrypt-1.0.1 \
    && docker-php-ext-enable mcrypt \
    && pecl install zip \
    && docker-php-ext-enable zip \
    && docker-php-ext-install pdo_pgsql

RUN chown -R www-data:www-data /var/www

# Install Composer
# RUN curl -sS https://getcomposer.org/installer -o ~/composer-setup.php
# RUN php -r "if (hash_file('SHA384', 'composer-setup.php') === '669656bab3166a7aff8a7506b8cb2d1c292f042046c5a994c43155c0be6190fa0355160742ab2e1c88d40d5be660b410') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
COPY composer-setup.php /root/
RUN php ~/composer-setup.php --install-dir=/usr/local/bin --filename=composer 

USER www-data
COPY composer.lock composer.json /var/www/
COPY database /var/www/database
WORKDIR /var/www/
COPY . /var/www/
RUN composer install --no-scripts --prefer-dist 

USER root
RUN ls && chown -R www-data:www-data storage bootstrap/cache public \
    && pushd /var/www/storage/framework \
    && mkdir views sessions cache \
    || popd \
    && find /var/www -type d -exec chmod 755 {} \; \
    && find /var/www/storage -type d -exec chmod 777 {} \; \
    && find /var/www -type d -exec chmod ug+s {} \; \
    && find /var/www -type f -exec chmod 644 {} \; \
    && pwd && ls && cd /var/www/ && chgrp -R www-data storage bootstrap/cache \
    && chmod -R ug+rwx storage bootstrap/cache

USER www-data
# RUN if [ ! -f .env ]; then cp .env.example .env; fi
RUN php artisan optimize; \
    #php artisan key:generate; \
    php artisan storage:link; \
    php artisan cache:clear; \
    php artisan config:clear; \
    php artisan view:clear; \
    php artisan config:cache

CMD  php artisan migrate:refresh --seed
