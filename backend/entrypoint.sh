#!/bin/sh
set -e

echo "==> Removing stale server PID..."
rm -f /app/tmp/pids/server.pid

echo "==> Running migrations..."
bundle exec rails db:create db:migrate 2>&1

echo "==> Seeding database (skip if already seeded)..."
bundle exec rails db:seed 2>&1 || true

# Start Sidekiq in background only if SIDEKIQ_ENABLED=true
if [ "$SIDEKIQ_ENABLED" = "true" ]; then
  echo "==> Starting Sidekiq in background..."
  bundle exec sidekiq &
fi

echo "==> Starting Rails server..."
exec bundle exec rails server -b 0.0.0.0 -p "${PORT:-3000}"
