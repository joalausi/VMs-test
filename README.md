# Server Sorcery 101

## Project Overview

Server Sorcery 101 is a small production-like virtual infrastructure project built with **Vagrant**, **VirtualBox**, and **Ubuntu Server** virtual machines.

The infrastructure consists of four virtual machines:

| VM       | Role               |      IP Address | Main Service         |
| -------- | ------------------ | --------------: | -------------------- |
| `lb-01`  | Load Balancer      | `192.168.56.10` | Nginx Load Balancer  |
| `web-01` | Web Server 1       | `192.168.56.11` | Nginx                |
| `web-02` | Web Server 2       | `192.168.56.12` | Nginx                |
| `app-01` | Application Server | `192.168.56.13` | Nginx diagnostic app |

The goal of this project is to practice:

* creating and managing multiple virtual machines;
* configuring static private networking;
* setting up a basic load-balanced web infrastructure;
* applying Linux administration and security practices;
* configuring SSH hardening;
* configuring firewall rules with UFW;
* enabling automatic security updates;
* installing intrusion prevention software;
* documenting infrastructure setup and validation.

---

## Architecture

```text
Host machine
    |
    | HTTP
    v
lb-01 / 192.168.56.10
Nginx Load Balancer
    |
    +--> web-01 / 192.168.56.11
    |    Nginx Web Server
    |
    +--> web-02 / 192.168.56.12
         Nginx Web Server
              |
              v
         app-01 / 192.168.56.13
         Application Server
```

Only the load balancer is intended to be directly accessed from the host machine over HTTP.
The web servers are reachable by the load balancer, and the application server is reachable by the web servers.

---

## Technologies Used

* VirtualBox
* Vagrant
* Ubuntu Server 22.04
* Nginx
* UFW
* Fail2Ban
* unattended-upgrades
* Shell provisioning scripts

---

## Project Structure

```text
server-sorcery-101/
├── Vagrantfile
├── README.md
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
    ├── fail2ban.sh
    ├── firewall.sh
    ├── lb.sh
    └── web.sh
```

---

## Requirements

Before running the project, install:

* VirtualBox
* Vagrant
* Git
* PowerShell

This project was tested on Windows using PowerShell with VirtualBox as the Vagrant provider.

---

## Setup Instructions

Clone or open the project directory:

```powershell
cd C:\Users\joell\server-sorcery-101
```

Validate the Vagrantfile:

```powershell
vagrant validate
```

Start all virtual machines:

```powershell
vagrant up --no-parallel
```

The `--no-parallel` flag is useful on machines with limited RAM because it starts VMs one by one instead of all at once.

Check VM status:

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

---

## VM Inventory

| VM                 | Hostname |      IP Address |    RAM | CPU |
| ------------------ | -------- | --------------: | -----: | --: |
| Load Balancer      | `lb-01`  | `192.168.56.10` | 768 MB |   1 |
| Web Server 1       | `web-01` | `192.168.56.11` | 512 MB |   1 |
| Web Server 2       | `web-02` | `192.168.56.12` | 512 MB |   1 |
| Application Server | `app-01` | `192.168.56.13` | 768 MB |   1 |

The RAM values were intentionally kept low to make the project runnable on a laptop with limited available memory.

---

## Network Configuration

Each VM has a static private IP address in the `192.168.56.0/24` subnet.

The main project network interface is usually `enp0s8`.

Example validation command:

```powershell
vagrant ssh lb-01 -c "hostname && ip -4 addr show enp0s8"
vagrant ssh web-01 -c "hostname && ip -4 addr show enp0s8"
vagrant ssh web-02 -c "hostname && ip -4 addr show enp0s8"
vagrant ssh app-01 -c "hostname && ip -4 addr show enp0s8"
```

Expected IP addresses:

```text
lb-01   -> 192.168.56.10
web-01  -> 192.168.56.11
web-02  -> 192.168.56.12
app-01  -> 192.168.56.13
```

---

## Load Balancer

The load balancer runs Nginx and forwards HTTP traffic to both web servers.

Nginx upstream configuration:

```nginx
upstream web_backend {
    server 192.168.56.11:80;
    server 192.168.56.12:80;
}
```

The load balancer is accessible from the host machine:

```powershell
curl.exe http://192.168.56.10
```

Repeated requests should show responses from both web servers:

```powershell
1..8 | ForEach-Object { curl.exe -s http://192.168.56.10 | Select-String "Hello from" }
```

Expected result:

```text
<h1>Hello from web-01</h1>
<h1>Hello from web-02</h1>
```

---

## Web Servers

Both `web-01` and `web-02` run Nginx.

Each web server serves a simple HTML page identifying itself:

```text
Hello from web-01
Hello from web-02
```

Health checks:

```powershell
vagrant ssh lb-01 -c "curl -s http://192.168.56.11/health"
vagrant ssh lb-01 -c "curl -s http://192.168.56.12/health"
```

Expected result:

```text
ok web-01
ok web-02
```

---

## Application Server

The application server runs a simple diagnostic Nginx page.

Health check from the web servers:

```powershell
vagrant ssh web-01 -c "curl -s http://192.168.56.13/health"
vagrant ssh web-02 -c "curl -s http://192.168.56.13/health"
```

Expected result:

```text
ok app-01
ok app-01
```

The application server is not directly reachable from the load balancer over HTTP due to firewall rules.

Validation:

```powershell
vagrant ssh lb-01 -c "timeout 3 curl -s http://192.168.56.13/health || echo blocked"
```

Expected result:

```text
blocked
```

---

## Linux Administration

A dedicated administrative user named `devops` is created on each VM.

Validation:

```powershell
vagrant ssh lb-01 -c "id devops && groups devops"
```

Expected result: the `devops` user exists and belongs to the `sudo` group.

Passwordless sudo is configured for the `devops` user for easier automation and review.

---

## SSH Hardening

The SSH configuration applies the following hardening rules:

```text
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AllowUsers devops vagrant
```

Validation:

```powershell
vagrant ssh lb-01 -c "sudo sshd -T | grep -E 'permitrootlogin|passwordauthentication|pubkeyauthentication|allowusers'"
```

Expected result:

```text
permitrootlogin no
passwordauthentication no
pubkeyauthentication yes
allowusers devops vagrant
```

The `vagrant` user is intentionally kept allowed so that Vagrant can continue managing the machines during provisioning and review.

---

## Firewall Configuration

UFW is enabled on all VMs.

Default policies:

```text
deny incoming
allow outgoing
```

Firewall access model:

| Source   | Destination | Access  |
| -------- | ----------- | ------- |
| Host     | `lb-01:80`  | Allowed |
| Host     | `web-01:80` | Blocked |
| Host     | `web-02:80` | Blocked |
| Host     | `app-01:80` | Blocked |
| `lb-01`  | `web-01:80` | Allowed |
| `lb-01`  | `web-02:80` | Allowed |
| `lb-01`  | `app-01:80` | Blocked |
| `web-01` | `app-01:80` | Allowed |
| `web-02` | `app-01:80` | Allowed |

Check UFW status:

```powershell
vagrant ssh lb-01 -c "sudo ufw status verbose"
vagrant ssh web-01 -c "sudo ufw status verbose"
vagrant ssh web-02 -c "sudo ufw status verbose"
vagrant ssh app-01 -c "sudo ufw status verbose"
```

Direct access from the host to web servers should fail:

```powershell
curl.exe --connect-timeout 3 http://192.168.56.11
curl.exe --connect-timeout 3 http://192.168.56.12
```

Expected result: connection timeout or connection failure.

---

## Secure Umask

A secure umask is configured:

```text
umask 027
```

This prevents newly created files and directories from being world-readable or world-writable by default.

Validation:

```powershell
vagrant ssh lb-01 -c "cat /etc/profile.d/99-secure-umask.sh && grep '^UMASK' /etc/login.defs"
```

Expected result:

```text
umask 027
UMASK 027
```

---

## Automatic Security Updates

Automatic security updates are enabled with `unattended-upgrades`.

Validation:

```powershell
vagrant ssh lb-01 -c "systemctl is-active unattended-upgrades"
vagrant ssh web-01 -c "systemctl is-active unattended-upgrades"
vagrant ssh web-02 -c "systemctl is-active unattended-upgrades"
vagrant ssh app-01 -c "systemctl is-active unattended-upgrades"
```

Expected result:

```text
active
```

---

## Intrusion Prevention Bonus: Fail2Ban

Fail2Ban is installed and configured as a bonus security feature.

It monitors SSH login attempts and can ban suspicious IP addresses after repeated failed authentication attempts.

Validation:

```powershell
vagrant ssh lb-01 -c "sudo systemctl is-active fail2ban"
vagrant ssh lb-01 -c "sudo fail2ban-client status"
vagrant ssh lb-01 -c "sudo fail2ban-client status sshd"
```

Expected result:

```text
active
```

and:

```text
Jail list: sshd
```

It is normal for the number of banned IPs to be `0` if there were no failed SSH attempts.

---

## Validation Checklist

A detailed validation checklist is available in:

```text
docs/validation-checklist.md
```

Recommended quick validation commands:

```powershell
vagrant status
curl.exe http://192.168.56.10
1..8 | ForEach-Object { curl.exe -s http://192.168.56.10 | Select-String "Hello from" }
vagrant ssh lb-01 -c "sudo ufw status verbose"
vagrant ssh lb-01 -c "sudo fail2ban-client status"
vagrant ssh lb-01 -c "sudo sshd -T | grep -E 'permitrootlogin|passwordauthentication|pubkeyauthentication|allowusers'"
```

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

SSH into a VM:

```powershell
vagrant ssh lb-01
vagrant ssh web-01
vagrant ssh web-02
vagrant ssh app-01
```

---

## Challenges and Solutions

### Limited RAM

Running four VMs at the same time used a lot of memory.

Solution:

* reduced RAM allocation for each VM;
* used lightweight Ubuntu Server images;
* started machines sequentially with `vagrant up --no-parallel`;
* stopped unnecessary background services before starting the environment.

### SSH Hardening and Vagrant Access

Disabling password login and root login is required for security.
However, Vagrant needs SSH access to manage the VMs.

Solution:

```text
AllowUsers devops vagrant
```

This keeps SSH access restricted while still allowing Vagrant to provision and manage the machines.

### Firewall Rules

The firewall had to be strict without breaking internal communication.

Solution:

* only `lb-01` accepts HTTP from the host;
* `web-01` and `web-02` accept HTTP only from `lb-01`;
* `app-01` accepts HTTP only from `web-01` and `web-02`;
* SSH remains available for administration.

---

## Review Notes

During the review, I can demonstrate:

* all four VMs running;
* static IP configuration;
* internal network connectivity;
* load balancing between `web-01` and `web-02`;
* restricted direct access to web servers;
* restricted access to the application server;
* SSH hardening;
* UFW firewall rules;
* automatic security updates;
* Fail2Ban intrusion prevention.
