# bnc-game

## Installation

Two options to start the project: either using the startup script or not

### With Docker

```bash
# start deployment in local
chmod +x deploy.sh
./deploy.sh
```

```bash
# setup and migrate postgres database
./bncapi/setup_dev_db.sh
```

```bash
# stop deployment
chmod +x shutdown.sh
./shutdown.sh
```

### Without Docker

#### Start frontend

Open a terminal and execute:

```bash
cd bnc-client
yarn dev
```

#### Start backend

Open another terminal and execute:

```bash
cd bncapi
# start .venv
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

#### Start Postgres

```bash
docker pull postgres:17-alpine
```

#### Start Redis

```bash
docker pull redis:7.2.7-alpine
```
