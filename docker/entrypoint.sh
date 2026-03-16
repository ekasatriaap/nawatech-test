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

# Robust migration function: try to run all migrations, but don't stop if one fails
# (useful when mixing manual SQL dumps with migrations)
run_migrations() {
    echo "Applying migrations..."
    # First try a normal migrate (faster if it works)
    if php artisan migrate --force; then
        echo "All migrations applied successfully."
    else
        echo "Standard migration failed. Attempting to apply migrations individually..."
        # Find all migration files and run them one by one
        # This ensures that if 'users' table exists, it doesn't block 'jobs' table creation
        for m in $(ls database/migrations/*.php | sort); do
            echo "Processing migration: $m"
            php artisan migrate --path="$m" --force || echo "Migration $m skipped or already exists."
        done
        echo "Individual migration pass completed."
    fi
}

# Check if data import is needed
# We check 'orders' table. If it doesn't exist, psql returns error, we catch it and assume 0.
ORDER_COUNT=$(PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d "$DB_DATABASE" -t -c "SELECT count(*) FROM orders;" 2>/dev/null | tr -d '[:space:]' || echo "0")

if [ -z "$ORDER_COUNT" ] || [ "$ORDER_COUNT" = "0" ]; then
    echo "Data import needed (Orders table is empty)."

    # 1. Run migrations first to create schema and migrations table
    run_migrations

    # 2. Import database.sql (this will drop and recreate users, products, orders, order_items)
    if [ -f "database.sql" ]; then
        echo "Importing database.sql..."
        PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d "$DB_DATABASE" < database.sql
        echo "Database data imported successfully."
    else
        echo "Warning: database.sql not found."
    fi
else
    echo "Database already contains data ($ORDER_COUNT orders). Skipping SQL import."
    # still run migrations to ensure jobs table exists if it was missed before
    run_migrations
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
    echo "Starting Laravel Queue Worker..."
    php artisan queue:work --verbose --tries=3 --timeout=90 &

    echo "Starting Laravel Octane..."
    exec php artisan octane:start --server=frankenphp --host=0.0.0.0 --port=80 --admin-port=2019
fi
