#!/bin/sh
set -e

echo "==> Removing stale server PID..."
rm -f /app/tmp/pids/server.pid

echo "==> Running migrations..."
bundle exec rails db:migrate 2>&1

echo "==> Seeding database..."
bundle exec rails db:seed 2>&1 || echo "==> Seed failed or already seeded, continuing..."

# Start Sidekiq in background only if SIDEKIQ_ENABLED=true
if [ "$SIDEKIQ_ENABLED" = "true" ]; then
  echo "==> Starting Sidekiq in background..."
  bundle exec sidekiq &
fi

echo "==> Starting Rails server on port ${PORT:-3000}..."
exec bundle exec rails server -b 0.0.0.0 -p "${PORT:-3000}"
