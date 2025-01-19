#!/bin/bash

# Apply the memory overcommit configuration
sysctl -w vm.overcommit_memory=1

# Start Redis with the custom configuration
exec redis-server /usr/local/etc/redis/redis.conf
