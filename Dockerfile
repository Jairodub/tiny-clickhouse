# Low-RAM ClickHouse 26.1 Template
FROM clickhouse/clickhouse-server:24.3-alpine
# Using Alpine version for smaller footprint on 1GB RAM instances.
# Or latest/current version we were using (26.1):
# FROM clickhouse/clickhouse-server:26.1

# We will mount our tuned config files via Docker Compose
# but we can also copy them into the image for a "fixed" build.
COPY config.xml /etc/clickhouse-server/config.xml
COPY users.xml /etc/clickhouse-server/users.xml
COPY users.d /etc/clickhouse-server/users.d

# Ensure correct permissions
RUN chown -R clickhouse:clickhouse /etc/clickhouse-server/

EXPOSE 8123 9000 8443 9440
