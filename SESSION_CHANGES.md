# Session Changes

August 29, 2026

This file summarizes the codebase and deployment changes made while moving the project from PostgreSQL to SQLite and deploying it on a Hetzner VPS using OpenCode CLI tool with OpenAI GPT-5.5.

## Database

- Switched Django from PostgreSQL to SQLite in `bncapi/bncapi/settings.py`.
- Added support for `DB_PATH`, with fallback to `SQLITE_DATABASE_PATH`, then `BASE_DIR / "db.sqlite3"`.
- Removed PostgreSQL environment variable configuration from Django settings.
- Removed PostgreSQL-only dependencies from `bncapi/pyproject.toml`.
- Removed the old PostgreSQL dev database SQL file `bncapi/create_dev_db.sql`.
- Updated `bncapi/setup_dev_db.sh` to run Django migrations through Docker Compose instead of creating PostgreSQL databases.

## Docker Compose

- Added a root-level `docker-compose.yml` for production deployment.
- Added a persistent SQLite bind mount from `./data` on the host to `/app/data` in the API container.
- Configured the API container to use `DB_PATH=/app/data/bnc.db`.
- Kept Redis as an internal service for Django Channels.
- Exposed the client container on host port `8080`.
- Mounted `nginx.production.conf` into the client container so production routing does not depend on the client submodule's bundled Nginx config.

## Deployment Script

- Replaced the original manual Docker deployment script with a VPS-oriented `deploy.sh`.
- Added `git pull origin main` for updates.
- Added recursive submodule sync/update before Docker builds.
- Added a global Git URL rewrite so `git@github.com:` submodule URLs resolve through HTTPS on fresh VPS machines.
- Added checks for missing `bncapi/Dockerfile` and `bnc-client/Dockerfile`.
- Added SQLite `./data` directory creation and write permissions.
- Added Docker Compose build/start.
- Added Django migration execution after containers start.
- Added Nginx reverse proxy creation for `bnc.siliconvalleytrail.xyz`.
- Added WebSocket upgrade headers to the generated host Nginx config.
- Added Let's Encrypt certificate provisioning through Certbot.
- Forced production frontend build URLs in `deploy.sh`:

```bash
VITE_API_URL=https://bnc.siliconvalleytrail.xyz
VITE_WS_URL=wss://bnc.siliconvalleytrail.xyz
PUBLIC_API_URL=https://bnc.siliconvalleytrail.xyz/api
```

## Nginx Routing

- Added root-level `nginx.production.conf`.
- Routed `/` to the React static build.
- Routed `/api/` to the Django API service at `bncapi:8000`.
- Routed `/ws/` to the Django Channels WebSocket service at `bncapi:8000`.
- Added WebSocket proxy headers inside the container Nginx config.
- Changed React routing fallback from a static `404` to `/index.html` for SPA routes.

## Frontend

- Updated `bnc-client/Dockerfile` to use Node `22.13.1` instead of Node `23.6.0`, fixing package engine compatibility during Docker builds.
- Updated `bnc-client/src/hooks/useGameWebSocket.ts` so production WebSockets derive their origin from the current browser location.
- Production WebSockets now resolve to `wss://<current-host>/ws/...` instead of relying only on `VITE_WS_URL`.
- Development WebSockets still use `VITE_WS_URL`.

## Submodules

- Changed top-level `.gitmodules` URLs from SSH to HTTPS for `bncapi` and `bnc-client`.
- Added deployment guidance for nested submodules under `bncapi` that still use SSH URLs.
- Used a global Git URL rewrite on the VPS to make nested `git@github.com:` submodules clone over HTTPS.

## Documentation

- Added `DEPLOY_HETZNER.md` with setup and troubleshooting instructions for Hetzner VPS deployment.
- Updated deployment documentation with SQLite persistence, submodule setup, Docker build troubleshooting, API proxy routing, and WSS troubleshooting.
- Added this `SESSION_CHANGES.md` summary.

## Production Issues Fixed

- Fixed Docker build failures caused by missing submodule Dockerfiles.
- Fixed nested submodule clone failures caused by SSH GitHub URLs on the VPS.
- Fixed frontend Docker build failure caused by incompatible Node version.
- Fixed API `404 nginx/1.27.5` responses by proxying `/api/` from the client container to Django.
- Fixed insecure WebSocket attempts to `ws://0.0.0.0:8000` by using WSS on the public domain in production.

## Current Production Shape

- Public traffic hits the host Nginx server on `https://bnc.siliconvalleytrail.xyz`.
- Host Nginx proxies traffic to the `bnc-client` container on `127.0.0.1:8080`.
- The client container serves React static files and proxies API/WebSocket paths internally.
- Django runs in the `bncapi` container on port `8000` inside Docker.
- Redis runs internally for Django Channels.
- SQLite persists on the VPS at `./data/bnc.db`.
