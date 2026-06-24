# Infrastructure Insight

## Project Overview

Infrastructure Insight is a small DevOps infrastructure project that demonstrates how a containerized diagnostic application can be deployed across multiple virtual machines.

The project uses four Ubuntu Server virtual machines managed by Vagrant and VirtualBox:

| VM       | Role               | IP Address      | Main Responsibility                             |
| -------- | ------------------ | --------------- | ----------------------------------------------- |
| `lb-01`  | Load Balancer      | `192.168.56.10` | Public HTTP entrypoint and traffic distribution |
| `web-01` | Web Server 1       | `192.168.56.11` | Frontend dashboard container                    |
| `web-02` | Web Server 2       | `192.168.56.12` | Frontend dashboard container                    |
| `app-01` | Application Server | `192.168.56.13` | Backend metrics API container                   |

The user accesses only the load balancer:

```text
Host / Browser
      |
      v
lb-01:80
      |
      +-------------------+
      |                   |
      v                   v
web-01:80             web-02:80
Frontend container    Frontend container
      |                   |
      +---------+---------+
                |
                v
app-01:3000
Backend metrics API container
```

The frontend dashboard displays:

* which web server served the current request;
* backend server information;
* OS information;
* CPU information;
* memory information;
* backend uptime;
* backend request count;
* raw backend JSON response.

The main success criterion is:

```text
http://192.168.56.10
```

opens the dashboard through the load balancer, shows backend metrics from `app-01`, and alternates between `web-01` and `web-02` after refreshing the page.

---

## Technologies Used

* Vagrant
* VirtualBox
* Ubuntu Server 22.04
* Docker Engine
* Node.js + Express
* NGINX
* UFW
* Fail2Ban
* unattended-upgrades
* PowerShell smoke tests
* Shell provisioning and deployment scripts

---

## Project Structure

```text
server-sorcery-101/
├── Vagrantfile
├── README.md
├── backend/
│   ├── Dockerfile
│   ├── package.json
│   ├── server.js
│   └── .dockerignore
├── frontend/
│   ├── Dockerfile
│   ├── index.html
│   ├── style.css
│   ├── app.js
│   ├── nginx.conf
│   └── docker-entrypoint.d/
│       └── 40-generate-server-info.sh
├── configs/
│   └── nginx-lb.conf
├── docs/
│   ├── architecture.md
│   ├── decisions.md
│   ├── troubleshooting.md
│   └── validation-checklist.md
└── scripts/
    ├── app.sh
    ├── common.sh
    ├── docker.sh
    ├── deploy-back.sh
    ├── deploy-frontend.sh
    ├── fail2ban.sh
    ├── final-hardening.sh
    ├── firewall.sh
    ├── lb.sh
    ├── smoke-test.ps1
    └── web.sh
```

---

## Requirements

Install the following tools on the host machine:

* VirtualBox
* Vagrant
* Git
* PowerShell

The project was developed and tested on Windows using PowerShell with VirtualBox as the Vagrant provider.

---

## Setup and Installation

### 1. Open the project directory

```powershell
cd C:\Users\joell\server-sorcery-101
```

### 2. Validate the Vagrantfile

```powershell
vagrant validate
```

### 3. Start all virtual machines

```powershell
vagrant up --no-parallel
```

The `--no-parallel` flag starts VMs one by one. This is useful on machines with limited RAM.

### 4. Check VM status

```powershell
vagrant status
```

Expected result:

```text
lb-01     running
web-01    running
web-02    running
app-01    running
```

### 5. Deploy the backend container on `app-01`

```powershell
vagrant ssh app-01 -c "sudo bash /vagrant/scripts/deploy-back.sh"
```

This script:

* builds the backend Docker image;
* removes the previous backend container if it exists;
* starts the backend container;
* exposes the backend API on `app-01:3000`;
* performs a local health check.

### 6. Deploy the frontend containers on `web-01` and `web-02`

```powershell
vagrant ssh web-01 -c "sudo bash /vagrant/scripts/deploy-front.sh"
vagrant ssh web-02 -c "sudo bash /vagrant/scripts/deploy-front.sh"
```

This script:

* builds the frontend Docker image;
* stops the old host NGINX service if it is running;
* removes the previous frontend container if it exists;
* starts the frontend dashboard container;
* generates `server-info.json` with the current web server name;
* checks local frontend and backend proxy access.

---

## Usage Guide

Open the dashboard in a browser:

```text
http://192.168.56.10
```

Expected behavior:

* the dashboard loads through `lb-01`;
* the responding web server is shown as `web-01` or `web-02`;
* backend metrics are loaded from `app-01`;
* refreshing the page several times shows traffic alternating between `web-01` and `web-02`.

Check load balancing from PowerShell:

```powershell
1..10 | ForEach-Object { curl.exe -s http://192.168.56.10/server-info.json }
```

Expected result: responses should alternate between:

```json
{
  "web_server": "web-01"
}
```

and:

```json
{
  "web_server": "web-02"
}
```

---

## Backend API

The backend runs on `app-01` in a Docker container.

Main endpoint:

```text
GET /metrics
```

Example checks:

```powershell
vagrant ssh app-01 -c "curl -s http://localhost:3000/metrics"
vagrant ssh web-01 -c "curl -s http://app-01:3000/metrics"
vagrant ssh web-02 -c "curl -s http://app-01:3000/metrics"
```

Example response:

```json
{
  "backend_server": "app-01",
  "container_hostname": "743d948dcddb",
  "platform": "linux",
  "os_type": "Linux",
  "os_release": "5.15.0-181-generic",
  "cpu_model": "13th Gen Intel(R) Core(TM) i7-13620H",
  "cpu_cores": 1,
  "memory_total_mb": 705,
  "memory_free_mb": 338,
  "uptime_seconds": 10258,
  "request_count": 499,
  "timestamp": "2026-06-24T00:06:05.773Z"
}
```

Health endpoint:

```text
GET /health
```

---

## Frontend Dashboard

The frontend runs on both web servers in Docker containers.

Each frontend container serves:

```text

```

and proxies backend API requests through:

```text
/api/metrics -> app-01:3000/metrics
/api/health  -> app-01:3000/health
```

Each web server generates its own `server-info.json` file at container startup:

```text
/server-info.json
```

This allows the dashboard to display which web server handled the request.

Validation:

```powershell
vagrant ssh web-01 -c "curl -s http://localhost/server-info.json"
vagrant ssh web-02 -c "curl -s http://localhost/server-info.json"
```

Expected result:

```json
{
  "web_server": "web-01"
}
```

and:

```json
{
  "web_server": "web-02"
}
```

---

## Load Balancer

The load balancer runs NGINX on `lb-01`.

It forwards HTTP traffic to both web servers:

```nginx
upstream web_backend {
    server 192.168.56.11:80;
    server 192.168.56.12:80;
}
```

The host machine should access the application only through:

```text
http://192.168.56.10
```

Round-robin validation:

```powershell
1..10 | ForEach-Object { curl.exe -s http://192.168.56.10/server-info.json }
```

---

## Firewall Configuration

UFW is enabled on all VMs.

Default policy:

```text
deny incoming
allow outgoing
```

Access model:

| Source   | Destination   | Access  |
| -------- | ------------- | ------- |
| Host     | `lb-01:80`    | Allowed |
| Host     | `web-01:80`   | Blocked |
| Host     | `web-02:80`   | Blocked |
| Host     | `app-01:3000` | Blocked |
| `lb-01`  | `web-01:80`   | Allowed |
| `lb-01`  | `web-02:80`   | Allowed |
| `web-01` | `app-01:3000` | Allowed |
| `web-02` | `app-01:3000` | Allowed |

Check firewall status:

```powershell
vagrant ssh lb-01 -c "sudo ufw status numbered"
vagrant ssh web-01 -c "sudo ufw status numbered"
vagrant ssh web-02 -c "sudo ufw status numbered"
vagrant ssh app-01 -c "sudo ufw status numbered"
```

Direct backend access from the host should fail:

```powershell
curl.exe --connect-timeout 5 http://192.168.56.13:3000/metrics
```

The expected result is a timeout or failed connection.

---

## Docker Networking Note

The containers use host networking so that UFW can reliably control access to service ports.

Originally, Docker port publishing with `-p` was considered. However, Docker manages its own iptables rules, which can make services reachable even when UFW rules look restrictive.

Using host networking keeps the firewall behavior easier to reason about:

```text
container service port -> VM network stack -> UFW rules
```

This makes it clear that:

* `app-01:3000` is accessible from `web-01` and `web-02`;
* `app-01:3000` is not directly accessible from the host;
* `web-01:80` and `web-02:80` are accessible from `lb-01`;
* the public HTTP entrypoint remains `lb-01:80`.

---

## Security Features

The infrastructure keeps the security baseline from the previous setup:

* dedicated `devops` user;
* disabled root SSH login;
* disabled SSH password login;
* public-key authentication;
* UFW firewall;
* automatic security updates;
* Fail2Ban for SSH intrusion prevention;
* secure default umask.

During development, both `devops` and `vagrant` are allowed through SSH:

```text
AllowUsers devops vagrant
```

The `vagrant` user is intentionally kept because Vagrant needs SSH access to manage and provision the virtual machines.

For final hardening, the script below can be used:

```powershell
vagrant ssh lb-01 -c "sudo bash /vagrant/scripts/final-hardening.sh"
vagrant ssh web-01 -c "sudo bash /vagrant/scripts/final-hardening.sh"
vagrant ssh web-02 -c "sudo bash /vagrant/scripts/final-hardening.sh"
vagrant ssh app-01 -c "sudo bash /vagrant/scripts/final-hardening.sh"
```

Important: after final hardening, regular `vagrant ssh` and `vagrant provision` may stop working because the `vagrant` user is no longer allowed to log in. This is expected.

---

## Smoke Test

A PowerShell smoke test is available:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/smoke-test.ps1
```

The smoke test checks:

* VM status;
* backend container status;
* frontend container status on both web servers;
* backend `/metrics` locally on `app-01`;
* backend access through both web servers;
* load balancer round-robin behavior;
* dashboard availability through `lb-01`.

---

## Useful Commands

Start all VMs:

```powershell
vagrant up --no-parallel
```

Stop all VMs:

```powershell
vagrant halt
```

Destroy all VMs:

```powershell
vagrant destroy -f
```

Run provisioning again:

```powershell
vagrant provision
```

Deploy backend:

```powershell
vagrant ssh app-01 -c "sudo bash /vagrant/scripts/deploy-back.sh"
```

Deploy frontend:

```powershell
vagrant ssh web-01 -c "sudo bash /vagrant/scripts/deploy-front.sh"
vagrant ssh web-02 -c "sudo bash /vagrant/scripts/deploy-front.sh"
```

Check containers:

```powershell
vagrant ssh app-01 -c "sudo docker ps"
vagrant ssh web-01 -c "sudo docker ps"
vagrant ssh web-02 -c "sudo docker ps"
```

Check load balancing:

```powershell
1..10 | ForEach-Object { curl.exe -s http://192.168.56.10/server-info.json }
```

---

## Troubleshooting

### Docker provisioning fails during `apt install`

Run provisioning again:

```powershell
vagrant provision app-01
vagrant provision web-01
vagrant provision web-02
```

Temporary package manager locks or network timing issues can happen during Docker installation.

### Port 80 is already allocated on a web server

The old host NGINX service may still be running.

Check:

```powershell
vagrant ssh web-01 -c "sudo ss -tulpn | grep ':80'"
```

Stop NGINX and redeploy frontend:

```powershell
vagrant ssh web-01 -c "sudo systemctl stop nginx"
vagrant ssh web-01 -c "sudo bash /vagrant/scripts/deploy-front.sh"
```

Repeat for `web-02` if needed.

### Backend is not reachable from web servers

Check backend container:

```powershell
vagrant ssh app-01 -c "sudo docker ps"
vagrant ssh app-01 -c "curl -s http://localhost:3000/metrics"
```

Check firewall:

```powershell
vagrant ssh app-01 -c "sudo ufw status numbered"
```

`app-01` should allow `3000/tcp` from:

```text
192.168.56.11
192.168.56.12
```

### Backend is directly reachable from the host

This should not happen in the final setup.

Check that the backend container is not using Docker port publishing with `-p 3000:3000`.

The backend should be started with host networking so UFW controls access to port `3000`.

---

## Review Demo Flow

During review, the project can be demonstrated in this order:

1. Show all VMs are running:

```powershell
vagrant status
```

2. Open the dashboard:

```text
http://192.168.56.10
```

3. Refresh the page several times and show that the responding web server changes between `web-01` and `web-02`.

4. Show backend metrics:

```powershell
vagrant ssh app-01 -c "curl -s http://localhost:3000/metrics"
```

5. Show that both web servers can reach the backend:

```powershell
vagrant ssh web-01 -c "curl -s http://localhost/api/metrics"
vagrant ssh web-02 -c "curl -s http://localhost/api/metrics"
```

6. Show load balancer round-robin:

```powershell
1..10 | ForEach-Object { curl.exe -s http://192.168.56.10/server-info.json }
```

7. Show firewall rules:

```powershell
vagrant ssh lb-01 -c "sudo ufw status numbered"
vagrant ssh web-01 -c "sudo ufw status numbered"
vagrant ssh web-02 -c "sudo ufw status numbered"
vagrant ssh app-01 -c "sudo ufw status numbered"
```

8. Show that direct backend access from the host is blocked:

```powershell
curl.exe --connect-timeout 5 http://192.168.56.13:3000/metrics
```

---

## Challenges and Solutions

### Docker and UFW interaction

Docker port publishing can bypass UFW because Docker manages its own iptables rules.

Solution:

* containers use host networking;
* UFW controls VM-level access to ports `80` and `3000`;
* backend access is restricted to the web servers.

### SSH hardening and Vagrant

Strict SSH hardening can conflict with Vagrant because Vagrant needs SSH access to manage machines.

Solution:

* during development, both `devops` and `vagrant` are allowed;
* final hardening can be applied separately with `scripts/final-hardening.sh`.

### Limited RAM

Running four VMs at the same time can use a lot of memory.

Solution:

* lightweight Ubuntu Server VMs;
* reduced RAM allocation;
* sequential startup with `vagrant up --no-parallel`.

---

## Additional Documentation

More detailed documentation is available in:

```text
docs/architecture.md
docs/decisions.md
docs/troubleshooting.md
docs/validation-checklist.md
```
