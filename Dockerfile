FROM php:8.3.28-fpm-alpine3.22 

# Set the working directory inside the container
WORKDIR /app

# 1. Copy necessary files for the dependency installation layer
# This ensures Docker's cache is only invalidated when these files change.
COPY ./check.txt ./composer*.json ./composer.lock ./

# 2. Install Alpine system dependencies, PHP extensions, and Composer
# We use 'apk add' (Alpine's package manager) instead of 'apt-get'.
# 'g++' is installed temporarily to compile PHP extensions and then cleaned up.
# The entire block uses '\' to combine commands into a single, efficient layer.
RUN apk update && \
    apk add --no-cache \
        libxml2-dev \
        libpng-dev \
        libpq-dev \
        libonig-dev \
        libcurl-dev \
        libzip-dev \
        g++ \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer install --no-dev --ignore-platform-reqs \
    \
    # Install the necessary PHP extensions using the 'docker-php-ext-install' helper.
    && docker-php-ext-install mbstring gd curl pdo pdo_pgsql zip \
    \
    # Cleanup: Remove build dependencies to minimize the final image size.
    && apk del --purge --no-cache \
        libxml2-dev \
        libpng-dev \
        libpq-dev \
        libonig-dev \
        libcurl-dev \
        libzip-dev \
        g++ \
    && rm -rf /var/cache/apk/*

# 3. Copy application files (The rest of your code)
COPY . .

#.env source and destination arguments
ARG source_file=./.env
ARG destination_dir=./.env

#.env copying management
# This logic checks if .env exists and handles the copying process based on its presence and dockerignore status.
RUN if [ -f "$source_file" ]; then \
        if [ "$source_file" != "$destination_dir" ]; then \
            echo "Copying $source_file to $destination_dir"; \
            cp "$source_file" "$destination_dir"; \
        else \
            echo "Source and destination paths are the same; skipping copy."; \
        fi \
    else \
        echo ".env has been added to dockerignore; skipping copy; if you want to copy it, remove it from dockerignore."; \
    fi

# 4. Expose the standard PHP-FPM port (9000), which will be used by Nginx/Apache.
EXPOSE 9000

# 5. Start the application
# The base image (php:*-fpm) already includes the correct default command (CMD ["php-fpm", "-F"])
# to run PHP-FPM in the foreground, so we don't need to explicitly add a CMD here.