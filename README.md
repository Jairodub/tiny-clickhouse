# ClickHouse 1GB RAM Template

> [!WARNING]
> **UNSTABLE / WORK-IN-PROGRESS**: This repository is currently in an active testing and debugging phase. It's not yet stable for general use or production deployment.

This repository contains a pre-tuned configuration for running **ClickHouse 24.3** on a **1GB RAM** machine (e.g., GCE e2-micro, AWS t3.micro, or Railway's smallest instance).

## Features
- **Mark Cache & Uncompressed Cache**: Reduced to 32MB each to prevent OOM.
- **Max Memory Usage**: Capped at ~800MB to leave room for the OS and background tasks.
- **Environment Driven**: Password management via `CLICKHOUSE_PASSWORD` environment variable.
- **Swap Support**: Included automation for 2GB swap creation.

## Method 1: Bare Metal / VM
1. Provision a fresh Ubuntu 22.04 or 24.04 VM (1 vCPU, 1GB RAM).
2. Clone this repo to the VM.
3. Update the `users.xml` password to your own strong password.
4. Run the setup script:
   ```bash
   chmod +x setup_vm.sh
   sudo ./setup_vm.sh
   ```

## Method 2: Docker
1. **Environment**: Set `CLICKHOUSE_PASSWORD` in your environment settings (defaults to `clickhouse` in `docker-compose.yaml`).
2. **Setup**: Run `docker-compose up -d --build`.
3. **Local Stability**: This template uses **named volumes** (`clickhouse_data`, `clickhouse_logs`) by default. Using bind-mounts (e.g., `./data:/var/lib/clickhouse`) on Docker Desktop often causes the engine to hang due to high I/O burst on startup.

## Method 3: Cloud Platforms (Railway, Render, etc.)
This template is tested on platforms like **Railway** as a container-native deployment:
1. **SSL/HTTPS**: Most cloud providers provide automated HTTPS termination. This template listens on HTTP (8123) by default, allowing the platform proxy to handle secure traffic.
2. **Configuration**: Point the platform to the `Dockerfile`.
3. **Variables**: Set the `CLICKHOUSE_PASSWORD` environment variable in the platform's dashboard.
4. **Volume**: Mount volume to `var\lib\clickhouse` before deploying. Deployment may fail if no volume is mounted.

## Network & SSL
- **HTTP**: Default port `8123`.
- **Native Protocol**: Default port `9000` (Mapped to `9004` in `docker-compose`).
- **HTTPS**: Disabled by default in `config.xml`. If you are NOT using a proxy/load balancer that terminates SSL, you must uncomment `<https_port>8443</https_port>` and provide valid certificates in `/etc/clickhouse-server/server.crt`.

## Real-world Performance & Testing
This configuration has been stress-tested in a **Google Cloud (GCP)** environment (e2-micro instance) using the **default Ubuntu image provided by GCP** with the following parameters:
- **Data Volume**: 227 million rows of real-life production data.
- **Ingestion**: Stably ingested without OOM crashes using sequential streaming.
- **Resource Constraints**:
  - **Host OS**: **Ubuntu (GCP Default Image)**.
  - **CPU**: 2 vCPUs (shared/burstable).
  - **RAM**: 1GB physical memory.
  - **Storage**: 30GB (Standard/Balanced Persistent Disk).
    - **Observed Peak Usage**: ~13GB - 17GB total system usage.
    - **Database Footprint**: ~4.8GB for 227M rows (highly compressed).

## Customizations Performed
- `mark_cache_size`: 33554432 (32MB)
- `uncompressed_cache_size`: 33554432 (32MB)
- `max_memory_usage`: (in users.xml) 300000000 (300MB per query)
- `max_threads`: 1 (Ensures stability on single-core instances)
- `max_bytes_before_external_group_by`: 2147483648 (Spills large aggregations to disk safely)

## Managing Credentials
The configuration pulls the password from the `CLICKHOUSE_PASSWORD` environment variable. 
In `docker-compose.yaml`, it defaults to `clickhouse`. **You must override this in production.**
