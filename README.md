# upk-docker

Docker config to start up **upk** - "**uznemuma personala kartoteka**" demo project.

Dev stack: **Laravel + Vue.js + Nginx + PHP-FPM + Vite** with **SQLite** (no DB container).

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

## Notes

- The project code lives in a **single named Docker volume**: `upk_volume` (mounted into all services at `/var/www/html`).
- The init container will clone `GIT_REPO` (default set in `docker-compose.yml`) on first run; to pull fresh code later, re-create the volume (`docker compose down -v`).
