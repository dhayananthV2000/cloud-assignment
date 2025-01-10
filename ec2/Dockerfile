# Use the slim Debian image as a base
FROM debian:bullseye-slim

# Install echo (usually included, but in case it's not)
RUN apt-get update && apt-get install -y coreutils bash

# Run echo every minute using a while loop
CMD while true; do echo "Namaste from Docker"; sleep 60; done
