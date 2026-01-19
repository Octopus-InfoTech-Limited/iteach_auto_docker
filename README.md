# iteach_auto_docker

This repo wraps the iteach Spring Boot services in Docker Compose for local runs.

## Prerequisites
- Both `iteach_api` and `iteach_web` must support `mvn spring-boot:run`.
- Prepare branches of `iteach_api` and `iteach_web` that run on Spring Boot. Default branches: `feat/Qurio-spring-boot-sp1`.
- Docker and Docker Compose installed.

## Usage
1. Clone and enter the repo:
   ```bash
   git clone https://github.com/Octopus-InfoTech-Limited/iteach_auto_docker.git
   cd iteach_auto_docker
   ```
2. Copy the sample env file: `cp .env.default .env`.
3. Open `.env` and edit credentials (database, ports, etc.).
4. Start the stack: `docker compose up` (or `docker compose up -d` to run detached).

## Notes
- `.env.default` pins the default branches for `iteach_api` and `iteach_web`.
- Adjust `NGINX_HOST_PORT` in `.env` if 27080 is already in use.
- Contact **Vanson** if you wish to make any iteach_api/web branch support Spring Boot.
