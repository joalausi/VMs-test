# Architecture

## Overview

This project creates a small production-like virtual infrastructure using Vagrant and VirtualBox.

The infrastructure consists of four Ubuntu Server virtual machines:

| VM | Role | IP Address |
|---|---|---:|
| `lb-01` | Load Balancer | `192.168.56.10` |
| `web-01` | Web Server 1 | `192.168.56.11` |
| `web-02` | Web Server 2 | `192.168.56.12` |
| `app-01` | Application Server | `192.168.56.13` |

## Architecture Diagram

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

## Network Design

All VMs are connected through a private network:

```text
192.168.56.0/24
```

Static IPs are used to make communication predictable and stable.

The main private network interface inside the VMs is usually:

```text
enp0s8
```

The NAT interface is usually:

```text
enp0s3
```

The NAT interface is used by Vagrant and the VM for internet access, package installation, and SSH management.

## Traffic Flow

The intended HTTP traffic flow is:

```text
Host machine
    -> lb-01
        -> web-01 or web-02
            -> app-01
```

The host machine should access only the load balancer directly.

The web servers should be reached through the load balancer.

The application server should not be directly exposed to the host or to the load balancer.

## Roles

### lb-01

`lb-01` runs Nginx as a load balancer.

It listens on port `80` and forwards requests to:

```text
192.168.56.11:80
192.168.56.12:80
```

### web-01 and web-02

`web-01` and `web-02` run Nginx and serve simple HTML pages.

Each page identifies which server responded.

This makes it possible to verify that load balancing works.

### app-01

`app-01` runs a simple diagnostic Nginx page.

It represents the application layer and is reachable only from the web servers.

## Security Boundaries

The infrastructure uses UFW firewall rules to reduce the attack surface.

| Source | Destination | Access |
|---|---|---|
| Host | `lb-01:80` | Allowed |
| Host | `web-01:80` | Blocked |
| Host | `web-02:80` | Blocked |
| Host | `app-01:80` | Blocked |
| `lb-01` | `web-01:80` | Allowed |
| `lb-01` | `web-02:80` | Allowed |
| `lb-01` | `app-01:80` | Blocked |
| `web-01` | `app-01:80` | Allowed |
| `web-02` | `app-01:80` | Allowed |

SSH is allowed for administration and Vagrant management.

## Summary

The final result is a small layered infrastructure:

- one public entry point;
- two web servers behind a load balancer;
- one isolated application server;
- static private networking;
- basic Linux security hardening;
- firewall-based traffic restrictions.