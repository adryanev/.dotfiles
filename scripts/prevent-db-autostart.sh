#!/bin/bash

# This script prevents MySQL and PostgreSQL from auto-starting
# It's useful when you use Docker for database containers but need the binaries for clients like DBeaver

# Stop services if they're running
brew services stop mysql 2>/dev/null
brew services stop postgresql 2>/dev/null

echo "MySQL and PostgreSQL services have been configured to not start automatically."
echo "The binaries are still available for use with tools like DBeaver."