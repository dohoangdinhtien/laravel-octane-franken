# https://career.weroad.travel/monkeys/laravel-frankenphp-docker/
# https://chriswhite.is/coding/frankenphp-and-laravel-octane-with-docker/
# https://frankenphp.dev/docs/docker/
# https://www.abdulwaheed.me/blog/frankenphp-via-docker
# https://laradock.io/documentation/#use-redis-cluster
# https://speakerdeck.com/dunglas/running-laravel-apps-with-frankenphp?slide=16
FROM dunglas/frankenphp

RUN apt-get update

# Install useful tools
RUN apt-get -y install apt-utils nano wget dialog vim

# Install system dependencies
RUN apt-get -y install --fix-missing \
    apt-utils \
    build-essential \
    git \
    curl \
    libcurl4 \
    libcurl4-openssl-dev \
    zlib1g-dev \
    libzip-dev \
    zip \
    libbz2-dev \
    locales \
    libmcrypt-dev \
    libicu-dev \
    libonig-dev \
    libxml2-dev

RUN install-php-extensions \
    exif \
    pcntl \
    bcmath \
    ctype \
    curl \
    pcntl \
    zip \
    pgsql \
    pdo_pgsql \
	gd \
	intl \
	opcache

# Install NPM
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
RUN apt-get install -y nodejs

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Composer
# COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Enable PHP production settings
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Set working directory
WORKDIR /app

COPY . /app

# Copy .env file
RUN cp .env.example .env

# Change APP_ENV and APP_DEBUG to be production ready
RUN sed -i'' -e 's/^APP_ENV=.*/APP_ENV=production/' -e 's/^APP_DEBUG=.*/APP_DEBUG=false/' .env

# Make other changes to your .env file if needed

# Install the dependencies
RUN composer install --ignore-platform-reqs --no-dev -a

# RUN php artisan migrate:reset
# RUN php artisan migrate
# RUN php artisan db:seed

RUN php artisan route:clear
RUN php artisan config:clear
RUN php artisan cache:clear
RUN php artisan storage:link

RUN php artisan key:generate

RUN php artisan route:cache
RUN php artisan config:cache

ENV FRANKENPHP_CONFIG="worker ./app/public/index.php"

ENTRYPOINT ["php", "artisan", "octane:frankenphp", "--workers=4"]
