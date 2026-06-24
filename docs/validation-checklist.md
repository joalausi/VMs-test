# Validation Checklist

Use this before submitting the project.

## 1. VM status

```powershell
vagrant status
```

Expected:

```text
lb-01     running
web-01    running
web-02    running
app-01    running
```

## 2. Docker status

```powershell
vagrant ssh app-01 -c "docker --version && sudo systemctl is-active docker"
vagrant ssh web-01 -c "docker --version && sudo systemctl is-active docker"
vagrant ssh web-02 -c "docker --version && sudo systemctl is-active docker"
```

Expected:

```text
active
```

## 3. Backend container

```powershell
vagrant ssh app-01 -c "sudo docker ps --filter name=infrastructure-insight-backend"
vagrant ssh app-01 -c "curl -s http://localhost:3000/metrics"
```

Expected:

```text
backend_server":"app-01
```

## 4. Frontend containers

```powershell
vagrant ssh web-01 -c "sudo docker ps --filter name=infrastructure-insight-frontend"
vagrant ssh web-02 -c "sudo docker ps --filter name=infrastructure-insight-frontend"
```

Expected: both containers are `Up`.

## 5. Web server identity

```powershell
vagrant ssh web-01 -c "curl -s http://localhost/server-info.json"
vagrant ssh web-02 -c "curl -s http://localhost/server-info.json"
```

Expected:

```text
web-01
web-02
```

## 6. Frontend to backend

```powershell
vagrant ssh web-01 -c "curl -s http://localhost/api/metrics"
vagrant ssh web-02 -c "curl -s http://localhost/api/metrics"
```

Expected:

```text
backend_server":"app-01
```

## 7. Load balancer

```powershell
curl.exe -I http://192.168.56.10
```

Expected:

```text
HTTP/1.1 200 OK
```

Round-robin check:

```powershell
1..10 | ForEach-Object { curl.exe -s http://192.168.56.10/server-info.json }
```

Expected: both `web-01` and `web-02` appear.

## 8. Browser check

Open:

```text
http://192.168.56.10
```

Expected:

* dashboard loads;
* backend metrics are visible;
* responding web server is visible;
* refresh switches between `web-01` and `web-02`.

## 9. Firewall status

```powershell
vagrant ssh lb-01 -c "sudo ufw status numbered"
vagrant ssh web-01 -c "sudo ufw status numbered"
vagrant ssh web-02 -c "sudo ufw status numbered"
vagrant ssh app-01 -c "sudo ufw status numbered"
```

Expected:

* `lb-01` allows `80/tcp`;
* `web-01` allows `80/tcp` from `192.168.56.10`;
* `web-02` allows `80/tcp` from `192.168.56.10`;
* `app-01` allows `3000/tcp` from `192.168.56.11` and `192.168.56.12`.

## 10. Negative access tests

Backend should be blocked from host:

```powershell
curl.exe --connect-timeout 5 http://192.168.56.13:3000/metrics
```

Web servers should be blocked from host:

```powershell
curl.exe --connect-timeout 5 http://192.168.56.11/server-info.json
curl.exe --connect-timeout 5 http://192.168.56.12/server-info.json
```

Expected: timeout or failed connection.

## 11. Smoke test

```powershell
powershell -ExecutionPolicy Bypass -File scripts/smoke-test.ps1
```
