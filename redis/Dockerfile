# Use the official Redis image as the base
FROM redis:7

# Install procps to enable the use of sysctl
RUN apt-get update && apt-get install -y procps && rm -rf /var/lib/apt/lists/*

# Copy the custom Redis configuration file into the container
COPY redis.conf /usr/local/etc/redis/redis.conf

# Copy the entrypoint script into the container
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the custom port
EXPOSE 6399 

# Run the container as the root user to execute sysctl
USER root

# Use the entrypoint script to start Redis
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
