#!/bin/bash
set -e

# Create .env from .env.example if it doesn't exist
if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    cp .env.example .env
fi

# Install composer dependencies if vendor doesn't exist
if [ ! -d "vendor" ]; then
    composer install --no-interaction --optimize-autoloader
fi

# Generate app key if not set
if [ -z "$APP_KEY" ] && [ ! -f .env ] || ! grep -q "APP_KEY=base64" .env; then
    php artisan key:generate --no-interaction
fi

# Run migrations
php artisan migrate --force

# Cache configuration and routes
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Start Laravel Octane with FrankenPHP
exec php artisan octane:start --server=frankenphp --host=0.0.0.0 --port=80
