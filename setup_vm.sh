#!/bin/bash
# 1-Click Setup for 1GB RAM ClickHouse 26.1 (Ubuntu/Debian)
# Run with: sudo bash setup_vm.sh

set -e # Exit on error

echo "--- STEP 1: Creating 2GB Swap File (Crucial for 1GB RAM) ---"
if [ ! -f /swapfile ]; then
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
    echo "Swap enabled (2GB)"
else
    echo "Swap already exists."
fi

echo "--- STEP 2: Installing ClickHouse 26.1 ---"
# Install dependencies
apt-get update && apt-get install -y apt-transport-https ca-certificates curl gnupg

# Add official repo
GNUPGHOME=$(mktrep -d)
curl -fsSL 'https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key' | gpg --dearmor -o /usr/share/keyrings/clickhouse-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg] https://packages.clickhouse.com/deb stable main" | tee \
    /etc/apt/sources.list.d/clickhouse.list
apt-get update

# Note: Using 'stable' instead of a fixed version for convenience, but the template configs are tuned for this branch.
apt-get install -y clickhouse-server clickhouse-client

echo "--- STEP 3: Applying 1GB RAM Tuning Configs ---"
# Assuming config files are in the same dir as this script
if [ -f "config.xml" ] && [ -f "users.xml" ]; then
    cp config.xml /etc/clickhouse-server/config.xml
    cp users.xml /etc/clickhouse-server/users.xml
    chown clickhouse:clickhouse /etc/clickhouse-server/config.xml /etc/clickhouse-server/users.xml
    echo "Tuned configurations applied."
else
    echo "Warning: config.xml or users.xml not found. Using defaults."
fi

echo "--- STEP 4: Generating HTTPS Certificates ---"
if [ ! -f /etc/clickhouse-server/server.crt ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/clickhouse-server/server.key \
        -out /etc/clickhouse-server/server.crt \
        -subj "/CN=localhost"
    chown clickhouse:clickhouse /etc/clickhouse-server/server.key /etc/clickhouse-server/server.crt
    chmod 600 /etc/clickhouse-server/server.key
    echo "Self-signed certificates generated."
else
    echo "Certificates already exist."
fi

echo "--- STEP 5: Restarting ClickHouse ---"
systemctl enable clickhouse-server
systemctl restart clickhouse-server

echo "--- DONE! ---"
echo "ClickHouse is running on ports 8123 (HTTP) and 8443 (HTTPS)."
echo "Verify with: clickhouse-client --password YOUR_PASS"
