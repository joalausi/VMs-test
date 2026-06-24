# Architecture

## VM layout

| VM       |              IP | Role                |
| -------- | --------------: | ------------------- |
| `lb-01`  | `192.168.56.10` | NGINX load balancer |
| `web-01` | `192.168.56.11` | frontend container  |
| `web-02` | `192.168.56.12` | frontend container  |
| `app-01` | `192.168.56.13` | backend container   |

## Traffic flow

```text
Host browser
    |
    v
lb-01:80
    |
    +--> web-01:80
    |
    +--> web-02:80
             |
             v
          app-01:3000
```

The host machine should use only:

```text
http://192.168.56.10
```

The backend is internal. It should not be accessed directly from the host.

## Containers

### app-01

Runs backend container:

```text
infrastructure-insight-backend
```

Endpoints:

```text
GET /health
GET /metrics
```

The backend returns hostname, OS, CPU, memory, uptime, timestamp and request counter.

### web-01 / web-02

Run frontend container:

```text
infrastructure-insight-frontend
```

Frontend routes:

```text
/
server-info.json
/api/metrics
/api/health
```

`server-info.json` shows which web server handled the request.

`/api/metrics` is proxied to:

```text
app-01:3000/metrics
```

## Load balancing

`lb-01` uses NGINX and forwards traffic to both web servers.

Check:

```powershell
1..10 | ForEach-Object { curl.exe -s http://192.168.56.10/server-info.json }
```

Expected: responses alternate between `web-01` and `web-02`.

## Firewall model

| Source   | Destination   | Status  |
| -------- | ------------- | ------- |
| Host     | `lb-01:80`    | allowed |
| Host     | `web-01:80`   | blocked |
| Host     | `web-02:80`   | blocked |
| Host     | `app-01:3000` | blocked |
| `lb-01`  | `web-01:80`   | allowed |
| `lb-01`  | `web-02:80`   | allowed |
| `web-01` | `app-01:3000` | allowed |
| `web-02` | `app-01:3000` | allowed |

## Docker networking note

Containers use host networking.

Reason: Docker port publishing with `-p` can expose ports through Docker-managed iptables rules and bypass expected UFW behavior.

With host networking, UFW controls the VM ports directly.
