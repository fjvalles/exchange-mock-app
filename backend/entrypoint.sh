#!/bin/sh
set -e

echo "==> Waiting for database..."
# Remove stale server PID if present (avoids 'server already running' errors)
rm -f /app/tmp/pids/server.pid

echo "==> Running migrations..."
bundle exec rails db:create db:migrate 2>&1

echo "==> Seeding database (skip if already seeded)..."
bundle exec rails db:seed 2>&1 || true

echo "==> Starting Rails server..."
exec bundle exec rails server -b 0.0.0.0
