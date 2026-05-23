ARG PHP_VERSION=8.0
FROM php:${PHP_VERSION}-fpm

RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    zip unzip git \
    mariadb-client \
    bash wget \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_mysql mysqli zip opcache \
    && pecl install redis \
    && docker-php-ext-enable redis

COPY opcache.ini /usr/local/etc/php/conf.d/opcache.ini
