# Ansible Automation

## Overview
Ansible is used to automate configuration sync and service deployment.

---

## Flow
Local Repo -> Ansible Sync -> Validation -> Deployment

---

## Components
- inventory.ini -> Defines server and SSH access
- infra-sync.yml -> Syncs configuration files to server
- deploy-all.yml -> Deploys all services
- Individual/ -> Individual service deployment playbooks

---

## Workflow

### 1. Sync Infrastructure
Copies required files to the server:

```bash
ansible-playbook -i inventory.ini infra-sync.yml
```

### 2. Deploy All Services
Validates and deploys all services:

```bash
ansible-playbook -i inventory.ini deploy-all.yml
```

### 3. Deploy Single Service
Deploy only one service:

```
ansible-playbook -i inventory.ini individual/deploy-portfolio.yml
```

---

## Validation

Before deployment:

- Directory exists
- docker-compose.yml exists
- .env exists (if required)

If any check fails -> deployment stops

---

## Design Decisions

- Validation-first deployment
- Modular playbooks for each service
- Loop-based deployment for all services
- Separation between sync and deploy

---

## Summary

- Safe deployment process
- No manual SSH deployment
- Supports full and single service deployment
- Scalable for multiple services
