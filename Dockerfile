FROM php:apache 
#Add a work directory
WORKDIR /app
#Copy dependencies




#Install dependencies
COPY ./check.txt ./composer*.json ./composer.lock[t] ./
RUN apt-get update && apt-get install -y libxml2-dev libpng-dev libpq-dev libonig-dev libcurl4-openssl-dev libzip-dev && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && docker-php-ext-install mbstring gd curl pdo pdo_pgsql zip && composer install --no-dev --ignore-platform-reqs
#Copy app files
COPY . .
#Cache and Install dependencies



#.env Source destination argument
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



#Expose port
EXPOSE 80 
#Build command


#Start the app
CMD apache2-foreground
