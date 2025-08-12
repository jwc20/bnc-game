# bnc-game

DEMO: https://bnc-client-psi.vercel.app/lobby

## Installation

Clone this repo and run:

```bash
git submodule update --init --recursive
```

Here are two ways to start the project:

**Option 1: With startup script**
Run the provided startup script to initialize and launch the project automatically.

**Option 2: Manual start**
Start the project manually without using the startup script.

### Option 1

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

### Option 2

#### Start frontend

Open a terminal and run:

```bash
cd bnc-client
yarn dev
```

#### Start backend

Open another terminal and run:

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
