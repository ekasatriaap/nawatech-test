FROM dunglas/frankenphp:php8.4

LABEL maintainer="Eka S Ariaputra <ekasatria.ariaputra@gmail.com>"
ENV SERVER_NAME=":80"

# Set working directory
WORKDIR /app

# Install system dependencies and PHP extensions
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/
RUN install-php-extensions \
    pdo_pgsql \
    pgsql \
    mbstring \
    zip \
    exif \
    pcntl \
    bcmath \
    gd \
    intl \
    opcache \
    redis

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy application source
COPY . .

# Create new user and set permissions
RUN useradd -m -s /bin/bash -G www-data dev && \
    chown -R dev:dev /app && \
    chmod -R 775 /app/storage /app/bootstrap/cache

# Move entrypoint script and make executable
RUN chmod +x /app/docker/entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/app/docker/entrypoint.sh"]

# Optional: switch to dev user if needed, but often FrankenPHP needs root to bind ports
# USER dev
