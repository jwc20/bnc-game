# Benjamin and Charlotte

**Sept. 2025 Cohort Submission**

Online Multiplayer code guessing game. 

---

Demo: https://bnc-client-psi.vercel.app

Docs: https://jwc20.github.io/bnc-docs/

Mono-repo: https://github.com/jwc20/bnc-game

FE: https://github.com/jwc20/bnc-client

BE: https://github.com/jwc20/bncapi


```bash
 ________________________________________
/ Try the demo at:                       \
\   https://bnc-client-psi.vercel.app    /
 ----------------------------------------
        \   ^__^
         \  (oo)\_________
            (__)\  Char   )\/\
                ||-----w |
                ||      ||
```

---

## Play

```bash
1. Login or signup
2. Join or create a room
3. Play the game but inputting numbers inside the code input
```

<img src="https://github.com/user-attachments/assets/82b31f80-5987-4169-a217-b8c65acf6387" alt="CleanShot 2025-08-13 at 10 51 01@2x" width="40%">


## Game Mode

1. Co-op: guess the code with other players
2. Battle: race with other players to win


Co-op Mode:

<img src="https://github.com/user-attachments/assets/c501155e-e6f4-470f-ba8d-35458daf3968" alt="CleanShot 2025-08-13 at 07 08 51" width="20%">



Battle Mode:

<img src="https://github.com/user-attachments/assets/dbcb2ac6-ce83-4a46-a8e5-f1f8a884bed2" alt="CleanShot 2025-08-12 at 17 22 45" width="40%">



---

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

---

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

---

### Option 2

#### Start frontend

Open a terminal and run:

```bash
cd bnc-client

yarn install
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
