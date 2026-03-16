# Nawatech Test Application

A high-performance Laravel application specialized in order management, built with a focus on efficiency and modern architecture.

## 🚀 Tech Stack

- **Framework**: [Laravel 12](https://laravel.com)
- **Runtime**: [Laravel Octane](https://laravel.com/docs/octane) with **FrankenPHP**
- **PHP Version**: 8.4
- **Database**: PostgreSQL 16
- **Cache**: Redis
- **Architecture**: Domain Driven Design (DDD) influenced.

## 🛠 Features

- **High Performance**: Powered by FrankenPHP for sub-millisecond response times.
- **Large Dataset Handling**: Efficient JSON streaming for fetching thousands of records without memory exhaustion.
- **Clean Architecture**: Separation of concerns using Repositories and Use Cases.
- **Dockerized**: Fully containerized environment for consistent deployment.

## 🐳 Installation (Using Docker - Recommended)

The easiest way to get started is by using Docker Compose. The setup is fully automated via an entrypoint script.

1. **Clone the repository**:

    ```bash
    git clone <repository-url>
    cd nawatech-test-app
    ```

2. **Build and start the containers**:

    ```bash
    docker-compose up -d --build
    ```

3. **Access the application**:
   The app will be available at [http://localhost:8085](http://localhost:8085).

> [!NOTE]
> On the first build, the `entrypoint.sh` script will automatically:
>
> - Copy `.env.example` to `.env`
> - Install PHP dependencies via Composer
> - Generate the application key
> - Import database schema and data from `database.sql`
> - Run database migrations (e.g., for `jobs` table)

---

## 💻 Installation (Manual - Without Docker)

If you prefer to run the application directly on your host machine:

### Prerequisites

- **PHP 8.4** with extensions: `pdo_pgsql`, `pgsql`, `redis`, `intl`, `zip`.
- **PostgreSQL 16**
- **Redis Server**
- **Composer**

### Steps

1. **Clone and Install Dependencies**:

    ```bash
    composer install
    ```

2. **Environment Configuration**:

    ```bash
    cp .env.example .env
    php artisan key:generate
    ```

    _Edit `.env` to configure your PostgreSQL and Redis connections._

3. **Migrations and Data Import**:
   You can run migrations, or import the provided SQL dump:
   ```bash
   # Import the PostgreSQL dump
   psql -U postgres -d postgres < database.sql
   ```

4. **Start the Server**:
   You can use the standard Laravel server or Octane (recommended):

    ```bash
    # Using Octane (FrankenPHP)
    php artisan octane:start --server=frankenphp

    # Or standard serve
    php artisan serve
    ```

---

## 📡 API Endpoints

All APIs are prefixed with `/api/v1`.

| Method | Endpoint                  | Description                       |
| :----- | :------------------------ | :-------------------------------- |
| `GET`  | `/v1/orders`              | Fetch all orders (Streaming JSON) |
| `POST` | `/v1/orders/checkout`     | Create a new order                |
| `POST` | `/v1/orders/{id}/payment` | Process payment for an order      |
| `GET`  | `/v1/orders/report`       | Get order aggregate statistics    |

---

## ⚡ Load Testing (k6)

We use [k6](https://k6.io/) to perform load testing on the checkout endpoint.

### Prerequisites

- Docker

### Running the Load Test

Run the following command to perform a load test on the checkout endpoint within the docker network:

```bash
docker run --rm --network nawatech-test-app_nawatech-network -i grafana/k6 run - <checkout-test.js
```

The test script `checkout-test.js` simulates 500 concurrent users performing checkouts over a 10-second period.

---

## 📄 License

This project is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
