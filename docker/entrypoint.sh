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

# Database initialization
echo "Checking database status..."
# Extract DB credentials from .env
DB_HOST=$(grep DB_HOST .env | cut -d'=' -f2)
DB_PORT=$(grep DB_PORT .env | cut -d'=' -f2)
DB_DATABASE=$(grep DB_DATABASE .env | cut -d'=' -f2)
DB_USERNAME=$(grep DB_USERNAME .env | cut -d'=' -f2)
DB_PASSWORD=$(grep DB_PASSWORD .env | cut -d'=' -f2)

# Check if tables exist
TABLE_COUNT=$(PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d "$DB_DATABASE" -t -c "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';" | tr -d '[:space:]' || echo "error")

if [ "$TABLE_COUNT" = "0" ]; then
    echo "Database is empty. Importing database.sql..."
    if [ -f "database.sql" ]; then
        PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d "$DB_DATABASE" < database.sql
        echo "Database imported successfully."
    else
        echo "Error: database.sql not found."
    fi
else
    echo "Database already initialized or inaccessible (Count: $TABLE_COUNT). Skipping SQL import."
fi

# Cache configuration and routes
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Start Laravel Octane with FrankenPHP
exec php artisan octane:start --server=frankenphp --host=0.0.0.0 --port=80
