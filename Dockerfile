# Stage 1: Build Composer dependencies
FROM composer:2.0 AS build

WORKDIR /app
COPY . /app

RUN composer install --prefer-dist --no-dev --optimize-autoloader --no-interaction

# Stage 2: Production Apache/PHP image
FROM php:8.2-apache

# Install PHP extensions required for Laravel and PostgreSQL
RUN apt-get update && \
    apt-get install -y libpq-dev && \
    docker-php-ext-install pdo pdo_pgsql

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Make Apache listen on the port Render expects ($PORT)
RUN sed -i 's/Listen 80/Listen ${PORT}/g' /etc/apache2/ports.conf && \
    sed -i 's/:80>/:${PORT}>/g' /etc/apache2/sites-available/000-default.conf

# Copy app from build stage
COPY --from=build /app /var/www/html

WORKDIR /var/www/html

# Permissions for Laravel
RUN chown -R www-data:www-data storage bootstrap/cache && \
    chmod -R ug+rwx storage bootstrap/cache

# Expose the port Render expects
EXPOSE ${PORT}

# Start: run migrations (needed for free Render) and then Apache
CMD php artisan migrate --force && apache2-foreground
