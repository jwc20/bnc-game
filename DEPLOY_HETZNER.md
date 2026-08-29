# Deploy To Hetzner VPS

August 29, 2026

This guide deploys the app to a Hetzner VPS using Docker Compose, Nginx, Let's Encrypt, and a persistent SQLite database file.

## Server Requirements

- Ubuntu server on Hetzner
- Domain pointing to the server IP: `bnc.siliconvalleytrail.xyz`
- SSH access with a sudo user
- Ports `80` and `443` open in the Hetzner firewall

## 1. Install Dependencies

SSH into the server:

```bash
ssh root@YOUR_SERVER_IP
```

Install Docker, Git, Nginx, and Certbot:

```bash
apt update
apt install -y git nginx certbot python3-certbot-nginx ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Start services:

```bash
systemctl enable --now docker
systemctl enable --now nginx
```

## 2. Clone The Repo

```bash
git clone https://github.com/jwc20/bnc-game.git
cd bnc-game
```

This repo uses Git submodules for `bncapi` and `bnc-client`. Initialize them before deploying:

```bash
git submodule update --init --recursive --remote
```

If the server already cloned the repo before the submodule URLs changed, sync them first:

```bash
git config --global url.https://github.com/.insteadOf git@github.com:
git submodule sync --recursive
git submodule update --init --recursive --remote
```

If you use a different remote or branch, update the clone URL and `deploy.sh` accordingly.

## 3. Configure DNS

Create an `A` record:

```text
bnc.siliconvalleytrail.xyz -> YOUR_SERVER_IP
```

Wait until DNS resolves before running Certbot:

```bash
dig bnc.siliconvalleytrail.xyz
```

## 4. Configure Secrets

Create a `.env` file in the repo root:

```bash
nano .env
```

Recommended contents:

```env
SECRET_KEY=replace_with_a_long_random_secret
VITE_API_KEY=replace_with_the_api_key_if_required
VITE_API_URL=https://bnc.siliconvalleytrail.xyz
VITE_WS_URL=wss://bnc.siliconvalleytrail.xyz
PUBLIC_API_URL=https://bnc.siliconvalleytrail.xyz/api
```

Generate a strong secret if needed:

```bash
openssl rand -hex 32
```

## 5. Deploy

Make the deployment script executable:

```bash
chmod +x deploy.sh
```

Run deployment:

```bash
./deploy.sh
```

The script will:

- Pull the latest code from `main`
- Create `./data` for the SQLite database
- Build and start Docker containers
- Run Django migrations
- Create an Nginx reverse proxy for `bnc.siliconvalleytrail.xyz`
- Provision a Let's Encrypt SSL certificate

During deployment, `deploy.sh` forces these frontend build URLs so the browser uses the public HTTPS/WSS domain:

```bash
VITE_API_URL=https://bnc.siliconvalleytrail.xyz
VITE_WS_URL=wss://bnc.siliconvalleytrail.xyz
PUBLIC_API_URL=https://bnc.siliconvalleytrail.xyz/api
```

If the frontend still connects to `ws://0.0.0.0:8000`, rebuild the client without cache:

```bash
docker compose build --no-cache bnc-client
docker compose up -d
```

## SQLite Persistence

The root `docker-compose.yml` mounts this host directory:

```text
./data:/app/data
```

The Django API writes SQLite to:

```text
/app/data/bnc.db
```

On the VPS, the persistent database file is:

```text
./data/bnc.db
```

Do not delete the `data` directory unless you intentionally want to remove production data.

## Routing

The public Nginx server proxies all traffic to the `bnc-client` container on host port `8080`.

Inside Docker, `nginx.production.conf` is mounted into the client container and routes:

- `/` to the React static build
- `/api/` to the Django API container on `bncapi:8000`
- `/ws/` to the Django WebSocket server on `bncapi:8000`

Production WebSocket traffic should use:

```text
wss://bnc.siliconvalleytrail.xyz/ws/game/<room_id>/?token=<token>
```

It should not use:

```text
ws://0.0.0.0:8000/ws/game/<room_id>/?token=<token>
```

The frontend hook should derive the production WebSocket origin from the current page:

```ts
const wsBaseUrl = import.meta.env.PROD
  ? `${window.location.protocol === "https:" ? "wss:" : "ws:"}//${
      window.location.host
    }`
  : import.meta.env.VITE_WS_URL;
```

## Useful Commands

View running containers:

```bash
docker compose ps
```

View logs:

```bash
docker compose logs -f
```

Run migrations manually:

```bash
docker compose exec bncapi python manage.py migrate
```

Inspect the mounted client Nginx config:

```bash
docker compose exec bnc-client nginx -T
```

Check the Django API through the public domain:

```bash
curl -i https://bnc.siliconvalleytrail.xyz/api/ping
```

Restart the app:

```bash
docker compose restart
```

Stop the app:

```bash
docker compose down
```

Renew/check SSL certificates:

```bash
certbot renew --dry-run
```

## Updating Production

From the repo directory on the VPS:

```bash
./deploy.sh
```

## Backup SQLite

Create a timestamped database backup:

```bash
mkdir -p backups
cp data/bnc.db "backups/bnc-$(date +%Y%m%d-%H%M%S).db"
```

Download the backup from your local machine:

```bash
scp root@YOUR_SERVER_IP:/path/to/bnc-game/backups/bnc-YYYYMMDD-HHMMSS.db .
```

## Troubleshooting

If Nginx config fails:

```bash
nginx -t
journalctl -u nginx -n 100 --no-pager
```

If the app cannot write to SQLite:

```bash
ls -la data
chmod 777 data
docker compose restart bncapi
```

If Certbot fails, confirm DNS points to the VPS and ports `80` and `443` are open.

If browser requests to `/api/auth/login` or `/api/auth/signup` return a plain `nginx/1.27.5` 404 page, rebuild the deployment after confirming `nginx.production.conf` is mounted:

```bash
docker compose up --build -d
docker compose exec bnc-client nginx -T
```

If browser WebSocket requests try to connect to `ws://0.0.0.0:8000`, the client was built with local development environment values. Pull the latest deployment script and rebuild without cache:

```bash
git pull origin main
docker compose build --no-cache bnc-client
docker compose up -d
```

If rebuilding does not fix it, inspect the generated frontend bundle for the old URL:

```bash
docker compose exec bnc-client sh -c 'grep -R "0.0.0.0:8000" -n /var/www/html || true'
```

If that command finds a match, the client source or build args still contain local development values.

The host Nginx reverse proxy must also pass WebSocket upgrade headers. The generated `deploy.sh` Nginx location block includes:

```nginx
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

If Docker reports `failed to read dockerfile: open Dockerfile: no such file or directory`, initialize the submodules:

```bash
git config --global url.https://github.com/.insteadOf git@github.com:
git submodule update --init --recursive --remote
ls bncapi/Dockerfile bnc-client/Dockerfile
```

If nested submodules under `bncapi` fail with `git@github.com: Permission denied (publickey)`, run the same HTTPS rewrite and retry:

```bash
git config --global url.https://github.com/.insteadOf git@github.com:
git submodule sync --recursive
git submodule update --init --recursive --remote
```

If the client build fails with a Node engine error, make sure `bnc-client/Dockerfile` uses Node `22.13.1` or newer LTS:

```dockerfile
FROM node:22.13.1-alpine3.21 AS build
```
