# Troubleshooting

## Docker install fails during provisioning

Usually temporary apt/network issue.

Retry:

```powershell
vagrant provision app-01
vagrant provision web-01
vagrant provision web-02
```

## Port 80 is already used on web server

Old host NGINX may still be running.

Check:

```powershell
vagrant ssh web-01 -c "sudo ss -tulpn | grep ':80'"
```

Fix:

```powershell
vagrant ssh web-01 -c "sudo systemctl stop nginx"
vagrant ssh web-01 -c "sudo bash /vagrant/scripts/deploy-front.sh"
```

Repeat for `web-02` if needed.

## Backend works on app-01 but not from web servers

Check backend:

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

## Dashboard loads but metrics fail

Check frontend proxy:

```powershell
vagrant ssh web-01 -c "curl -s http://localhost/api/metrics"
vagrant ssh web-02 -c "curl -s http://localhost/api/metrics"
```

Check frontend logs:

```powershell
vagrant ssh web-01 -c "sudo docker logs infrastructure-insight-frontend"
```

## Load balancer does not switch servers

Check both web servers directly from `lb-01`:

```powershell
vagrant ssh lb-01 -c "curl -s http://192.168.56.11/server-info.json"
vagrant ssh lb-01 -c "curl -s http://192.168.56.12/server-info.json"
```

Reload NGINX on `lb-01`:

```powershell
vagrant ssh lb-01 -c "sudo nginx -t && sudo systemctl reload nginx"
```

Test again:

```powershell
1..10 | ForEach-Object { curl.exe -s http://192.168.56.10/server-info.json }
```

## Backend is reachable directly from host

This is wrong for final setup.

Test:

```powershell
curl.exe --connect-timeout 5 http://192.168.56.13:3000/metrics
```

Expected: timeout or failed connection.

Check backend deploy script. It should use:

```bash
--network host
```

Not:

```bash
-p 3000:3000
```

Redeploy:

```powershell
vagrant ssh app-01 -c "sudo bash /vagrant/scripts/deploy-back.sh"
```

## Vagrant breaks after final-hardening.sh

Expected if final hardening was applied.

`final-hardening.sh` changes SSH to `devops` only. Vagrant normally logs in as `vagrant`, so `vagrant ssh` and `vagrant provision` may stop working.

Use it only at the very end.
