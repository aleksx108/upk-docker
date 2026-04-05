FROM php:8.3-fpm-alpine

RUN apk add --no-cache \
    $PHPIZE_DEPS \
    bash \
    curl \
    git \
    icu-dev \
    libzip-dev \
    oniguruma-dev \
    sqlite \
    sqlite-dev \
    unzip \
    zip

RUN docker-php-ext-configure intl \
  && docker-php-ext-install -j$(nproc) \
    exif \
    intl \
    mbstring \
    opcache \
    pdo \
    pdo_sqlite \
    zip

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY docker/php/init.sh /usr/local/bin/init-laravel
RUN chmod +x /usr/local/bin/init-laravel
