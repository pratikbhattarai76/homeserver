# Ansible Automation

Ansible is used to provision the server, sync configuration files from the local repo, and deploy services. The whole automation lives in three playbooks plus one shared task file.

---

## Files

```text
.
├── deploy-all.yml         # deploy services
├── deploy-service.yml     # shared deployment task list for deploy-all.yml
├── infra-sync.yml         # sync local repo files to the server
├── inventory.ini          # the inventory containing the server hosts
├── inventory.ini.example  # the inventory template 
└── setup.yml              # one-time server provisioning

```

---

## The Three Playbooks

### setup.yml
One-time bootstrap of a fresh server. Installs Docker and the Compose plugin, mounts the 1TB HDD, creates the Docker networks (`docker-proxy` and `docker-cloudflared`), creates the directories the rest of the playbooks expect, and adds the cron job for the portfolio update script. Only run this once when setting up a new server.

### infra-sync.yml
Copies the `docker/` and `scripts/` directories from the local repo to the server, plus the `.env` files for services that need them. The `.env` files live only on the local laptop and are pushed with `mode: 0600` so the server user owns them and nothing else can read them. Run this whenever a compose file or env file changes locally and needs to be reflected on the server.

### deploy-all.yml
Runs `docker compose up -d` for each service after validating that its directory, compose file, and (if required) env file exist. Idempotent - running it when nothing has changed is safe and finishes in seconds because Compose detects that nothing needs recreating.

---

## The Shared Task File

`deploy-service.yml` holds the deployment procedure once. It is included by `deploy-all.yml` via `import_tasks`, with per-service variables passed in. The procedure is:

1. Check that the service directory exists, fail if missing.
2. Check that `docker-compose.yml` exists in that directory, fail if missing.
3. If the service requires an env file, check that `.env` exists, fail if missing.
4. Run `docker compose up -d` in the service directory.

The same procedure is reused for every service. Adding a new service is now a about 7-10 line addition to `deploy-all.yml` instead of writing a new playbook.

---

## Tags for Targeted Deployment

Each service in `deploy-all.yml` is tagged with its name. This means a single service can be deployed without running the whole stack:

```bash
# Deploy everything
ansible-playbook -i inventory.ini deploy-all.yml --limit local --ask-become-pass

# Deploy only monitoring
ansible-playbook -i inventory.ini deploy-all.yml --limit local --ask-become-pass --tags monitoring

# Deploy nextcloud and vaultwarden together
ansible-playbook -i inventory.ini deploy-all.yml --limit local --ask-become-pass --tags "nextcloud,vaultwarden"

# List all available tags
ansible-playbook -i inventory.ini deploy-all.yml --list-tags
```

The original structure had one playbook per service in an `individual/` directory. These were nearly identical and have been consolidated into the tag-based approach. See [decisions.md](decisions.md#ansible-refactor) for the full reasoning behind the refactor.

---

## Typical Workflow

1. Edit a compose file or env file locally.
2. Run `infra-sync.yml` to copy the changes to the server.
3. Run `deploy-all.yml` (with or without `--tags`) to recreate the affected containers.

The `--limit local` flag restricts execution to the LAN host in the inventory. Without it, Ansible would try every host defined under `[homelab]`, which currently includes both the LAN address and a Tailscale address pointing at the same machine. The `--ask-become-pass` flag prompts for the sudo password used by `become: true` in the playbooks.

---
