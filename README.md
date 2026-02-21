# ClickHouse 1GB RAM Template

> [!WARNING]
> **UNSTABLE / WORK-IN-PROGRESS**: This repository is currently in an active testing and debugging phase. It's not yet stable for general use or production deployment.

This repository contains a pre-tuned configuration for running **ClickHouse 26.1** on a **1GB RAM** machine (e.g., GCE e2-micro, AWS t3.micro, or Railway's smallest instance).

## Features
- **Mark Cache & Uncompressed Cache**: Reduced to 32MB each to prevent OOM.
- **Max Memory Usage**: Capped at ~800MB to leave room for the OS and background tasks.
- **HTTPS Enabled**: Configured for port 8443 with self-signed SSL support.
- **Swap Support**: Included automation for 2GB swap creation.

## Method 1: Bare Metal / VM (Recommended)
1. Provision a fresh Ubuntu 22.04 or 24.04 VM (1 vCPU, 1GB RAM).
2. Clone this repo to the VM.
3. Update the `users.xml` password to your own strong password.
4. Run the setup script:
   ```bash
   chmod +x setup_vm.sh
   sudo ./setup_vm.sh
   ```
5. Your instance is now ready.

## Method 2: Docker
1. Ensure your Docker host has a swap file (important if the host has only 1GB RAM).
2. Update the memory limits in `docker-compose.yaml` if needed.
3. Run:
   ```bash
   docker-compose up -d
   ```
4. Access HTTPS via `https://localhost:8443`.

## Customizations Performed
- `mark_cache_size`: 33554432 (32MB)
- `uncompressed_cache_size`: 33554432 (32MB)
- `max_memory_usage`: (in users.xml) 300000000 (300MB per query)
- `max_threads`: 1 (Ensures stability over speed)
- `max_bytes_before_external_group_by`: 2147483648 (Spills large aggregations to disk safely)

## Managing Credentials
The `users.xml` included is a copy of the live server's settings. **Change the password** before deploying this in anything other than a test environment.
