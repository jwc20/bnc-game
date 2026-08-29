#!/bin/bash
set -e

DOMAIN="bnc.siliconvalleytrail.xyz"
PORT=8080

echo "Deploying $DOMAIN..."

git pull origin main

echo "Updating Git submodules..."
git config url.https://github.com/.insteadOf git@github.com:
git submodule sync --recursive
git submodule update --init --recursive --remote

if [ ! -f bncapi/Dockerfile ] || [ ! -f bnc-client/Dockerfile ]; then
    echo "Missing bncapi/Dockerfile or bnc-client/Dockerfile. Check that submodules cloned correctly."
    exit 1
fi

echo "Ensuring SQLite data directory exists..."
mkdir -p ./data
chmod 777 ./data

docker compose up --build -d
docker compose exec -T bncapi python manage.py migrate

NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"
if [ ! -f "$NGINX_CONF" ]; then
    echo "Creating Nginx server block..."
    sudo tee "$NGINX_CONF" > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

    sudo ln -sf "$NGINX_CONF" "/etc/nginx/sites-enabled/$DOMAIN"
    sudo nginx -t
    sudo systemctl reload nginx

    echo "Provisioning SSL certificate..."
    sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email
fi

echo "Deployment successful!"
