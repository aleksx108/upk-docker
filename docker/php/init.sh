#!/usr/bin/env sh
set -eu

cd /var/www/html

export COMPOSER_ALLOW_SUPERUSER=1

fix_perms() {
  mkdir -p \
    storage/framework/cache \
    storage/framework/sessions \
    storage/framework/views \
    storage/framework/testing \
    storage/framework/data \
    bootstrap/cache \
    database

  if [ ! -f database/database.sqlite ]; then
    : > database/database.sqlite
  fi

  chmod -R a+rwX storage bootstrap/cache 2>/dev/null || true
  chown -R www-data:www-data storage bootstrap/cache 2>/dev/null || true

  chmod -R a+rwX database 2>/dev/null || true
  chown -R www-data:www-data database 2>/dev/null || true
}

is_dir_empty() {
  [ -z "$(find . -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null || true)" ]
}

echo "Bootstrapping Laravel into /var/www/html ..."

GIT_REPO="${GIT_REPO:-}"
GIT_REF="${GIT_REF:-main}"

if [ -n "$GIT_REPO" ]; then
  if [ -d .git ]; then
    echo "Updating from $GIT_REPO ($GIT_REF) ..."
    
    # Check for untracked/modified files that would conflict
    if git status --porcelain | grep -q .; then
      echo ""
      echo "ERROR: You have untracked or modified files that would be overwritten by git update."
      echo "Please resolve these changes manually before starting Docker:"
      echo ""
      git status --short
      echo ""
      echo "Options:"
      echo "1. Commit your changes: git add . && git commit -m 'your message'"
      echo "2. Stash changes: git stash"
      echo "3. Discard changes: git reset --hard && git clean -fd"
      echo ""
      echo "Then restart Docker: docker compose up --build"
      exit 1
    fi
    
    git remote set-url origin "$GIT_REPO" >/dev/null 2>&1 || true
    git fetch --prune origin "$GIT_REF"
    # Reset any local changes before checkout (keeps untracked files)
    git reset --hard HEAD >/dev/null 2>&1 || true
    # Remove git clean -fd to preserve untracked files
    git checkout -B "$GIT_REF" "origin/$GIT_REF"
    git reset --hard "origin/$GIT_REF"
  else
    if ! is_dir_empty; then
      echo "ERROR: /var/www/html is not empty and not a git repo."
      echo "Delete the Docker volume (docker compose down -v) and try again."
      exit 1
    fi

    echo "Cloning $GIT_REPO ($GIT_REF) ..."
    git clone --depth 1 --branch "$GIT_REF" "$GIT_REPO" .
  fi
fi

# If no repo was provided (or cloning failed), fall back to a fresh Laravel install.
if [ ! -f artisan ]; then
  if [ -n "$GIT_REPO" ]; then
    echo "ERROR: Repo cloned, but artisan was not found at the repo root."
    echo "This usually means your GitHub repo does not contain a Laravel app (or it's not at the repository root)."
    echo ""
    echo "Repo contents:"
    ls -la
    echo ""
    echo "Searching for artisan (max depth 4):"
    find . -maxdepth 4 -type f -name artisan -print 2>/dev/null || true
    echo ""
    echo "Fix: commit/push your Laravel project (the one that contains artisan) to $GIT_REPO on branch $GIT_REF."
    echo "Then recreate the volume: docker compose down -v && docker compose up --build"
    exit 1
  fi

  composer create-project laravel/laravel . --no-interaction
fi

# App env
if [ ! -f .env ]; then
  cp .env.example .env
fi

# Use SQLite (keeps the project self-contained; no separate DB volume/container).
mkdir -p database
if [ ! -f database/database.sqlite ]; then
  : > database/database.sqlite
fi

fix_perms

sed -i 's|^APP_URL=.*|APP_URL=http://localhost|' .env
if grep -q '^DB_CONNECTION=' .env; then
  sed -i 's|^DB_CONNECTION=.*|DB_CONNECTION=sqlite|' .env
else
  printf '\nDB_CONNECTION=sqlite\n' >> .env
fi

if grep -q '^DB_DATABASE=' .env; then
  sed -i 's|^DB_DATABASE=.*|DB_DATABASE=/var/www/html/database/database.sqlite|' .env
else
  printf 'DB_DATABASE=/var/www/html/database/database.sqlite\n' >> .env
fi

# Dependencies
if [ -f composer.json ]; then
  composer install --no-interaction --prefer-dist
fi

# Only generate if key is missing/empty.
if ! grep -q '^APP_KEY=base64:' .env; then
  php artisan key:generate --ansi
fi

# Create storage link for media files (Spatie Media Library)
php artisan storage:link || true

# Install Breeze only if not already present.
if [ -f composer.json ] && ! grep -q '"laravel/breeze"' composer.json; then
  composer require laravel/breeze --dev --no-interaction
fi

# Install Breeze (Blade) scaffolding only if not already present.
# Use the traditional Blade stack (Tailwind + Alpine), not the Inertia/Vue SPA stack.
if [ -f resources/views/auth/login.blade.php ]; then
  echo "Breeze Blade scaffolding already present."
else
  php artisan breeze:install blade --no-interaction
fi

# Docker-friendly Vite config (bind mounts on Windows benefit from polling).
cat > vite.config.js <<'EOF'
import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';

export default defineConfig({
    server: {
        host: '0.0.0.0',
        port: 5173,
        strictPort: true,
        watch: {
            usePolling: true,
        },
        hmr: {
            host: 'localhost',
        },
    },
    plugins: [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.js'],
            refresh: true,
        }),
    ],
});
EOF

php artisan migrate --ansi

fix_perms

echo "Init complete."