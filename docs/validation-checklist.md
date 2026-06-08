# Validation Checklist

This document contains commands used to validate the Server Sorcery 101 infrastructure.

## 1. VM Status

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

## 2. Hostnames and Static IPs

```powershell
vagrant ssh lb-01 -c "hostname && ip -4 addr show enp0s8"
vagrant ssh web-01 -c "hostname && ip -4 addr show enp0s8"
vagrant ssh web-02 -c "hostname && ip -4 addr show enp0s8"
vagrant ssh app-01 -c "hostname && ip -4 addr show enp0s8"
```

Expected IPs:

| VM | IP |
|---|---:|
| `lb-01` | `192.168.56.10` |
| `web-01` | `192.168.56.11` |
| `web-02` | `192.168.56.12` |
| `app-01` | `192.168.56.13` |

## 3. Network Connectivity

```powershell
vagrant ssh lb-01 -c "ping -c 3 192.168.56.11"
vagrant ssh lb-01 -c "ping -c 3 192.168.56.12"
vagrant ssh lb-01 -c "ping -c 3 192.168.56.13"
```

Expected result:

```text
0% packet loss
```

## 4. Web Server Health Checks

```powershell
vagrant ssh lb-01 -c "curl -s http://192.168.56.11/health"
vagrant ssh lb-01 -c "curl -s http://192.168.56.12/health"
```

Expected result:

```text
ok web-01
ok web-02
```

## 5. Application Server Health Check

```powershell
vagrant ssh web-01 -c "curl -s http://192.168.56.13/health"
vagrant ssh web-02 -c "curl -s http://192.168.56.13/health"
```

Expected result:

```text
ok app-01
ok app-01
```

## 6. Load Balancer

```powershell
curl.exe http://192.168.56.10
```

Expected result:

```text
Hello from web-01
```

or:

```text
Hello from web-02
```

Repeated test:

```powershell
1..8 | ForEach-Object { curl.exe -s http://192.168.56.10 | Select-String "Hello from" }
```

Expected result: responses from both `web-01` and `web-02`.

## 7. Firewall Status

```powershell
vagrant ssh lb-01 -c "sudo ufw status verbose"
vagrant ssh web-01 -c "sudo ufw status verbose"
vagrant ssh web-02 -c "sudo ufw status verbose"
vagrant ssh app-01 -c "sudo ufw status verbose"
```

Expected result:

```text
Status: active
Default: deny (incoming), allow (outgoing), disabled (routed)
```

Expected firewall model:

| Source | Destination | Expected |
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

## 8. Direct Web Access Should Be Blocked

```powershell
curl.exe --connect-timeout 3 http://192.168.56.11
curl.exe --connect-timeout 3 http://192.168.56.12
```

Expected result:

```text
Connection timed out
```

## 9. Load Balancer Should Not Access app-01 Directly

```powershell
vagrant ssh lb-01 -c "timeout 3 curl -s http://192.168.56.13/health || echo blocked"
```

Expected result:

```text
blocked
```

## 10. SSH Hardening

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

## 11. DevOps User

```powershell
vagrant ssh lb-01 -c "id devops && groups devops"
```

Expected result:

```text
devops
sudo
```

Optional login test:

```powershell
vagrant ssh lb-01 -- -l devops
```

Inside the VM:

```bash
whoami
sudo whoami
exit
```

Expected result:

```text
devops
root
```

## 12. Secure Umask

```powershell
vagrant ssh lb-01 -c "cat /etc/profile.d/99-secure-umask.sh && grep '^UMASK' /etc/login.defs"
```

Expected result:

```text
umask 027
UMASK 027
```

## 13. Automatic Security Updates

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

## 14. Fail2Ban

```powershell
vagrant ssh lb-01 -c "sudo systemctl is-active fail2ban"
vagrant ssh lb-01 -c "sudo fail2ban-client status"
vagrant ssh lb-01 -c "sudo fail2ban-client status sshd"
```

Expected result:

```text
active
Jail list: sshd
```

It is normal if the number of banned IPs is `0`.

## 15. Final Quick Check

```powershell
vagrant status
curl.exe http://192.168.56.10
1..8 | ForEach-Object { curl.exe -s http://192.168.56.10 | Select-String "Hello from" }
vagrant ssh lb-01 -c "sudo ufw status verbose"
vagrant ssh lb-01 -c "sudo fail2ban-client status"
```