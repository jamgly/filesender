FROM php:8.3.28-fpm-alpine3.22 

# Set the working directory inside the container
WORKDIR /app

# 1. Copy necessary files for the dependency installation layer
COPY ./check.txt ./composer*.json ./composer.lock ./

# 2. Install Alpine system dependencies, PHP extensions, and Composer
# FIX: 'onig-dev' is replaced with 'oniguruma-dev' for Alpine compatibility.
RUN apk update && \
    apk add --no-cache \
        libxml2-dev \
        libpng-dev \
        libpq-dev \
        oniguruma-dev \
        curl-dev \
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
        oniguruma-dev \
        curl-dev \
        libzip-dev \
        g++ \
    && rm -rf /var/cache/apk/*

# 3. Copy application files (The rest of your code)
COPY . .

#.env source and destination arguments
ARG source_file=./.env
ARG destination_dir=./.env

#.env copying management
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

# 4. Expose the standard PHP-FPM port (9000).
EXPOSE 9000