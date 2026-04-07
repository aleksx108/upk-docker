# upk-docker

Docker development config for **UPK** - "**uznemuma personala kartoteka**" demo project.
Demo project repo: https://github.com/aleksx108/upk

Dev stack: **Laravel 13 + Vue.js + Nginx + PHP 8.3 + Vite** with **SQLite** (no DB container).

## Prerequisites

- Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) before starting the project.

## Quick start

1. Open Command Prompt:
   - Press `Win + R`, type `cmd`, and press Enter.
2. Go to your upk-docker project directory, for example:
   - `cd C:\projects\upk-docker`
3. Run all Docker commands from this project directory.
4. Start everything (first run downloads Laravel + dependencies into a Docker volume):
   - `docker compose up --build`
5. Open:
   - App: `http://localhost`

## Tips

- Open a shell in the PHP app container:
  `docker-compose exec app sh`
- Open a shell in the Node container:
  `docker-compose exec node sh`
- Open a shell in the Nginx container:
  `docker-compose exec nginx sh`
- If Git reports a `safe.directory` warning for the Docker volume, run (for Windows WSL:
  `git config --global --add safe.directory '%(prefix)///wsl.localhost/docker-desktop/mnt/docker-desktop-disk/data/docker/volumes/upk_volume/_data'`

## Notes

- The project code lives in a **single named Docker volume**: `upk_volume` (mounted into all services at `/var/www/html`).
- SQLite was used for simplicity and fast setup in a prototype environment. The application is designed so it can be easily migrated to MySQL/PostgreSQL for production use.
- The init container will clone `GIT_REPO` (default set in `docker-compose.yml`) on first run; to pull fresh code later, re-create the volume (`docker compose down -v`).
