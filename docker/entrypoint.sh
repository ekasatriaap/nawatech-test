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

# Function to check database connectivity
wait_for_db() {
    echo "Waiting for database to be ready..."
    until PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d "$DB_DATABASE" -c "SELECT 1" > /dev/null 2>&1; do
        sleep 1
    done
    echo "Database is ready."
}

wait_for_db

# Check if users table exists
TABLE_EXISTS=$(PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d "$DB_DATABASE" -t -c "SELECT count(*) FROM information_schema.tables WHERE table_name = 'users';" | tr -d '[:space:]')

if [ "$TABLE_EXISTS" = "0" ]; then
    echo "Database is empty. Running migrations first..."
    php artisan migrate --force
fi

# Check if data import is needed
ORDER_COUNT=$(PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d "$DB_DATABASE" -t -c "SELECT count(*) FROM orders;" 2>/dev/null | tr -d '[:space:]' || echo "0")

if [ -z "$ORDER_COUNT" ] || [ "$ORDER_COUNT" = "0" ]; then
    echo "Orders table is empty or doesn't exist. Importing database.sql..."
    if [ -f "database.sql" ]; then
        # database.sql has DROP TABLE IF EXISTS CASCADE, so it's safe to run even if migrate ran
        PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d "$DB_DATABASE" < database.sql
        echo "Database imported successfully."
        
        # After importing database.sql, we MUST run migrations again to ensure jobs table etc.
        # because database.sql might have dropped them if it was a full dump (though unlikely for jobs)
        # and we need to ensure the migrations table is in a consistent state.
        echo "Running migrations after import..."
        php artisan migrate --force
    else
        echo "Warning: database.sql not found, jumping to migrations."
        php artisan migrate --force
    fi
else
    echo "Orders table already has data ($ORDER_COUNT records). Running incremental migrations..."
    # If migrations fail because a table exists but isn't in migrations table, 
    # we try to run it but don't exit if it fails (common when users mix manual SQL and migrations)
    php artisan migrate --force || echo "Migration failed, likely due to existing tables. Check your database state."
fi

# Cache configuration and routes
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Start Laravel Octane with FrankenPHP or run custom command
if [ $# -gt 0 ]; then
    echo "Running custom command: $@"
    exec "$@"
else
    echo "Starting Laravel Octane..."
    exec php artisan octane:start --server=frankenphp --host=0.0.0.0 --port=80
fi
