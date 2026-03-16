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

# Extract DB credentials from .env
DB_HOST=$(grep DB_HOST .env | cut -d'=' -f2)
DB_PORT=$(grep DB_PORT .env | cut -d'=' -f2)
DB_DATABASE=$(grep DB_DATABASE .env | cut -d'=' -f2)
DB_USERNAME=$(grep DB_USERNAME .env | cut -d'=' -f2)
DB_PASSWORD=$(grep DB_PASSWORD .env | cut -d'=' -f2)

# Run migrations first (ensure jobs and other tables are created)
echo "Running migrations..."
php artisan migrate --force

# Database data initialization
echo "Checking if data import is needed..."
# Check if orders table has any data. If it fails (e.g. table not migrated yet), it returns "error"
ORDER_COUNT=$(PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d "$DB_DATABASE" -t -c "SELECT count(*) FROM orders;" 2>/dev/null | tr -d '[:space:]' || echo "0")

if [ -z "$ORDER_COUNT" ] || [ "$ORDER_COUNT" = "0" ]; then
    echo "Orders table is empty. Importing database.sql..."
    if [ -f "database.sql" ]; then
        PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d "$DB_DATABASE" < database.sql
        echo "Database imported successfully."
    else
        echo "Warning: database.sql not found, skipping data import."
    fi
else
    echo "Orders table already has data ($ORDER_COUNT records). Skipping SQL import."
fi

# Cache configuration and routes
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Start Laravel Octane with FrankenPHP
exec php artisan octane:start --server=frankenphp --host=0.0.0.0 --port=80
