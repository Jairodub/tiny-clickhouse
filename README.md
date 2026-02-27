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

### Scenario A: Google Cloud (e2-micro)
This configuration was stress-tested in a **Google Cloud (GCP)** environment using the **default Ubuntu image** with the following parameters:
- **Data Volume**: 227 million rows of real-life production data.
- **Ingestion**: Stably ingested without OOM crashes using sequential streaming.
- **Resource Constraints**:
  - **Host OS**: Ubuntu (GCP Default Image).
  - **CPU**: 2 vCPUs (shared/burstable).
  - **RAM**: 1GB physical memory.
  - **Storage**: 30GB (Standard/Balanced Persistent Disk).
    - **Observed Peak Usage**: ~13GB - 17GB total system usage.
    - **Database Footprint**: ~4.8GB for 227M rows (highly compressed).

### Scenario B: Local Docker (Resource Constrained)
Validated on a local machine using the **850MB RAM limit** defined in `docker-compose.yaml`.
- **Data Volume**: 227 million rows.
- **Ingestion Time**: **25.98 minutes**.
- **Average Ingest Speed**: **~145,600 rows/sec**.
- **CPU Usage**: Peaked at ~25-30% during heavy load.
- **Resource Constraints**:
  - **Host OS**: Ubuntu (Local environment).
  - **RAM Limit**: 850MB (Docker-enforced).
  - **Database Footprint**: **5.03 GB** for 227M rows (LZ4 compression).
  - **Stability**: Tested with heavy group-by and distinct count aggregations without high-RAM crashes.

### Performance Breakdown
- **Memory Footprint**: ClickHouse process stable at **520MB - 650MB** RAM throughout full-volume operations.
- **Storage Strategy**: Disk-spilled `MergeTree` ensures large merges don't OOM the small instance.

## Customizations Performed
- `mark_cache_size`: 33554432 (32MB)
- `uncompressed_cache_size`: 33554432 (32MB)
- `max_memory_usage`: (in users.xml) Capped per profile.
- `max_threads`: 2 (Balanced for 1-2 vCPU instances)
- `max_bytes_before_external_group_by`: 209715200 (200MB - Forces disk-spilling earlier to prevent Docker OOM kills on 1GB RAM)
- `max_bytes_before_external_sort`: 209715200 (200MB)

## Managing Credentials
The configuration pulls the password from the `CLICKHOUSE_PASSWORD` environment variable. 
In `docker-compose.yaml`, it defaults to `clickhouse`. **You must override this in production.**
