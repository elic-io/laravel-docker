if [ ! -f .env ]; then cp .env.example .env; fi
docker-compose up --force-recreate
