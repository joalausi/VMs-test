# Technical Decisions

This document explains the main technical decisions made during the Server Sorcery 101 project.

## Vagrant and VirtualBox

I used Vagrant with VirtualBox because this combination makes it possible to create and manage virtual machines in a reproducible way.

Instead of manually creating VMs through the VirtualBox GUI, the infrastructure is described in a `Vagrantfile`.

This makes the project easier to:

- reproduce;
- review;
- destroy and recreate;
- document;
- version control.

## Ubuntu Server 22.04

The project uses the `ubuntu/jammy64` Vagrant box.

Ubuntu Server 22.04 was chosen because:

- it is stable;
- it is widely used;
- it has good package availability;
- it is suitable for basic Linux administration practice.

## Four Separate VMs

The task requires a production-like setup with separate roles.

Therefore, the infrastructure is split into four machines:

| VM | Reason |
|---|---|
| `lb-01` | Separates traffic entry point from web servers |
| `web-01` | First web backend |
| `web-02` | Second web backend for load balancing |
| `app-01` | Separate application layer |

This makes the architecture more realistic than running everything on one machine.

## Static IP Addresses

Static IPs are used because the machines need to communicate with predictable addresses.

Without static IPs, the load balancer and firewall rules could break after VM restarts.

Chosen IP plan:

| VM | IP |
|---|---:|
| `lb-01` | `192.168.56.10` |
| `web-01` | `192.168.56.11` |
| `web-02` | `192.168.56.12` |
| `app-01` | `192.168.56.13` |

## Low RAM Allocation

The VM memory allocation was kept low because the host machine had limited available RAM during development.

Final allocation:

| VM | RAM |
|---|---:|
| `lb-01` | 768 MB |
| `web-01` | 512 MB |
| `web-02` | 512 MB |
| `app-01` | 768 MB |

This is enough for SSH, Nginx, UFW, Fail2Ban, and basic testing.

The project is started with:

```powershell
vagrant up --no-parallel
```

This avoids starting all VMs at the same time and reduces memory pressure.

## Nginx

Nginx was used for both the load balancer and the web/application diagnostic pages.

Reasons:

- lightweight;
- easy to configure;
- suitable for reverse proxying;
- commonly used in production environments.

## UFW Firewall

UFW was chosen because it is simple and suitable for basic Linux firewall configuration.

The default policy is:

```text
deny incoming
allow outgoing
```

Only required traffic is explicitly allowed.

## SSH Hardening

SSH was hardened with the following settings:

```text
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AllowUsers devops vagrant
```

Root SSH login is disabled.

Password login is disabled.

Public key authentication is enabled.

The `vagrant` user is still allowed because Vagrant needs it for provisioning and review.

The `devops` user is created as the dedicated administrative user.

## Automatic Security Updates

`unattended-upgrades` is enabled to automatically apply security updates.

This helps keep the system protected against known vulnerabilities.

## Fail2Ban

Fail2Ban was implemented as a bonus intrusion prevention tool.

It monitors SSH login attempts and can ban suspicious IPs after repeated failed login attempts.

This improves protection against brute-force attacks.

## Keeping the Project Simple

Some possible bonus features, such as VPN or full monitoring, were not implemented in the base version.

The priority was to first complete a stable and understandable infrastructure with:

- VM creation;
- networking;
- SSH hardening;
- firewall rules;
- load balancing;
- documentation;
- one security bonus.

This keeps the project focused and easier to review.