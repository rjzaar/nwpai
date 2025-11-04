# Docker, Docker Compose, and DDEV: A Comprehensive Comparison

## Docker

**What it is:** Docker is the foundational container platform that packages applications and their dependencies into isolated containers. It's the base layer that both Docker Compose and DDEV build upon.

### Core Commands

```bash
docker run [image]               # Run a container
docker ps                        # List running containers
docker ps -a                     # List all containers
docker images                    # List images
docker build -t [name] .        # Build image from Dockerfile
docker exec -it [container] bash # Access container shell
docker logs [container]          # View container logs
docker stop [container]          # Stop container
docker rm [container]            # Remove container
docker rmi [image]              # Remove image
docker volume ls                # List volumes
docker network ls               # List networks
docker system prune -a          # Clean up everything
```

### Configuration Locations (Ubuntu)

- Docker daemon config: `/etc/docker/daemon.json`
- Systemd service: `/lib/systemd/system/docker.service`
- Docker data directory: `/var/lib/docker/` (images, containers, volumes)
- Container-specific configs: Individual `Dockerfile` in your project directories
- User socket: `/var/run/docker.sock`

### How Configuration Works

Docker uses Dockerfiles to define images. A Dockerfile contains instructions like `FROM`, `RUN`, `COPY`, and `CMD` that build your application layer by layer. You can also configure the Docker daemon itself through `daemon.json` to control things like storage drivers, logging, and default runtime options.

### Best Practices

- Use `.dockerignore` files to exclude unnecessary files from build context
- Leverage multi-stage builds to keep final images small
- Don't run containers as root; use `USER` directive in Dockerfiles
- Pin specific image versions rather than using `latest` tags
- Use volume mounts for persistent data, never store important data in containers
- Clean up unused images and containers regularly with `docker system prune`
- One process per container philosophy (though not always strictly followed)

---

## Docker Compose

**What it is:** Docker Compose orchestrates multiple containers as a single application stack. It's perfect for defining multi-service applications (web server, database, cache, etc.) in a single YAML file.

### Core Commands

```bash
docker-compose up                # Start all services
docker-compose up -d            # Start in background
docker-compose down             # Stop and remove containers
docker-compose ps               # List services
docker-compose logs [service]   # View logs
docker-compose exec [service] bash  # Access service shell
docker-compose build            # Build/rebuild services
docker-compose restart [service] # Restart service
docker-compose stop             # Stop services without removing
docker-compose pull             # Pull latest images
docker-compose config           # Validate and view config
```

### Configuration Locations (Ubuntu)

- Main config file: `docker-compose.yml` or `compose.yaml` (in your project root)
- Override file: `docker-compose.override.yml` (automatically merged)
- Environment variables: `.env` file in same directory
- Multiple compose files can be specified: `docker-compose -f file1.yml -f file2.yml up`

### How Configuration Works

Docker Compose uses YAML files to define services, networks, and volumes. Each service specifies an image or build context, along with ports, environment variables, volumes, and dependencies. The format includes:

- Version declarations (though v3+ is mostly compatible)
- Service definitions
- Network configurations
- Volume declarations

Environment variable substitution works with `${VARIABLE}` syntax, pulling from `.env` files or system environment.

### Best Practices

- Use `.env` files for environment-specific variables, never commit secrets to version control
- Leverage `docker-compose.override.yml` for local development overrides
- Use named volumes instead of bind mounts for databases when possible
- Define explicit networks to control service communication
- Use `depends_on` to manage service startup order (though it doesn't wait for "ready" state)
- Keep production and development configs separate
- Use healthchecks to ensure services are truly ready
- Version lock your service images in production

---

## DDEV

**What it is:** DDEV is a developer-friendly local development environment specifically designed for PHP applications like Drupal, WordPress, and Laravel. It wraps Docker and Docker Compose with intelligent defaults and convenience commands.

### Core Commands

```bash
ddev start                      # Start project
ddev stop                       # Stop project
ddev restart                    # Restart project
ddev describe                   # Show project info and URLs
ddev ssh                        # SSH into web container
ddev exec [command]            # Run command in web container
ddev composer [command]         # Run Composer
ddev drush [command]           # Run Drush
ddev import-db --file=dump.sql # Import database
ddev export-db                  # Export database
ddev snapshot                   # Create database snapshot
ddev snapshot restore          # Restore snapshot
ddev logs                       # View logs
ddev config                     # Configure project
ddev debug test                 # Test DDEV functionality
ddev poweroff                   # Stop all DDEV projects
ddev delete                     # Delete project containers
```

### Configuration Locations (Ubuntu)

- Global DDEV config: `~/.ddev/global_config.yaml`
- Project config: `.ddev/config.yaml` (in project root)
- Additional configs: `.ddev/config.*.yaml` (automatically merged)
- Docker Compose overrides: `.ddev/docker-compose.*.yaml`
- Custom commands: `.ddev/commands/`
- Web server config: `.ddev/nginx_full/` or `.ddev/apache/`
- PHP config: `.ddev/php/` (php.ini overrides)
- MySQL config: `.ddev/mysql/` (my.cnf overrides)
- Provider configs: `.ddev/providers/`

### How Configuration Works

DDEV generates Docker Compose configurations from its own YAML format. When you run `ddev start`, it creates `.ddev/.ddev-docker-compose-*.yaml` files that are actual Docker Compose files. 

The `.ddev/config.yaml` file controls:

- Project type (drupal, wordpress, etc.)
- PHP version
- Database type
- Router HTTP port
- Additional services

You can extend DDEV with:

- Custom Docker Compose files
- Add-ons
- Hooks that run at different lifecycle stages

### Best Practices

- Always commit `.ddev/config.yaml` and custom configs to version control
- Use `.ddev/.gitignore` to exclude generated and local-only files
- Add project-specific commands in `.ddev/commands/web/` for team consistency
- Leverage DDEV hooks (post-start, pre-import-db) for automation
- Use `ddev snapshot` before risky database operations
- Create custom `docker-compose.*.yaml` files for additional services rather than modifying generated files
- Use `router_http_port` and `router_https_port` to avoid port conflicts between projects
- Set `use_dns_when_possible: false` if you have DNS issues
- For team consistency, set `upload_dirs` to match production
- Use `ddev describe` to get quick access to URLs and credentials

---

## Key Relationships

**Docker** provides the container runtime.

**Docker Compose** adds multi-container orchestration using YAML configs.

**DDEV** sits on top of both, providing an opinionated, simplified interface specifically for web development with intelligent defaults, helper commands, and project type awareness.

### The Layered Architecture

```
┌─────────────────────────────────────┐
│            DDEV                     │  ← High-level dev environment
│  (Drupal/WordPress specific tools)  │
├─────────────────────────────────────┤
│        Docker Compose               │  ← Multi-container orchestration
│     (docker-compose.yml)            │
├─────────────────────────────────────┤
│            Docker                   │  ← Container runtime
│    (dockerd, containerd)            │
├─────────────────────────────────────┤
│         Linux Kernel                │  ← OS-level containerization
└─────────────────────────────────────┘
```

For Drupal/OpenSocial work specifically, DDEV handles the complexity of setting up Drupal with proper PHP versions, database containers, Drush integration, and Composer management, while still giving you access to underlying Docker commands when you need lower-level control. The layered approach means you can drop down to `docker-compose` commands when DDEV's abstractions aren't sufficient, or even directly use `docker` commands for debugging specific containers.
