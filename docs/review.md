# Review Demo Flow

This document contains a short review demonstration flow for the Server Sorcery 101 project.

## 1. Show Project Structure

```powershell
tree /F
```

Explanation:

```text
This project uses Vagrant and VirtualBox to create a small production-like infrastructure.
The Vagrantfile defines the VMs, scripts/ contains provisioning scripts, configs/ contains Nginx configuration, and docs/ contains documentation.
```

## 2. Show VM Status

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

Explanation:

```text
There are four running virtual machines: one load balancer, two web servers, and one application server.
```

## 3. Show Static IPs

```powershell
vagrant ssh lb-01 -c "hostname && ip -4 addr show enp0s8"
vagrant ssh web-01 -c "hostname && ip -4 addr show enp0s8"
vagrant ssh web-02 -c "hostname && ip -4 addr show enp0s8"
vagrant ssh app-01 -c "hostname && ip -4 addr show enp0s8"
```

Explanation:

```text
Each VM has a descriptive hostname and a static private IP address.
```

## 4. Show Load Balancing

```powershell
1..8 | ForEach-Object { curl.exe -s http://192.168.56.10 | Select-String "Hello from" }
```

Expected result:

```text
Hello from web-01
Hello from web-02
```

Explanation:

```text
The load balancer receives HTTP traffic and distributes it between web-01 and web-02.
```

## 5. Show Health Checks

```powershell
vagrant ssh lb-01 -c "curl -s http://192.168.56.11/health"
vagrant ssh lb-01 -c "curl -s http://192.168.56.12/health"
```

Expected result:

```text
ok web-01
ok web-02
```

Then:

```powershell
vagrant ssh web-01 -c "curl -s http://192.168.56.13/health"
vagrant ssh web-02 -c "curl -s http://192.168.56.13/health"
```

Expected result:

```text
ok app-01
ok app-01
```

Explanation:

```text
The load balancer can reach both web servers, and the web servers can reach the application server.
```

## 6. Show Firewall Restrictions

Direct access from host to web servers should fail:

```powershell
curl.exe --connect-timeout 3 http://192.168.56.11
curl.exe --connect-timeout 3 http://192.168.56.12
```

Expected result:

```text
Connection timed out
```

Direct access from load balancer to app server should also fail:

```powershell
vagrant ssh lb-01 -c "timeout 3 curl -s http://192.168.56.13/health || echo blocked"
```

Expected result:

```text
blocked
```

Explanation:

```text
The firewall allows only the required traffic.
The host accesses only the load balancer.
The load balancer accesses only web servers.
The application server is reachable only from the web servers.
```

## 7. Show UFW Status

```powershell
vagrant ssh lb-01 -c "sudo ufw status verbose"
vagrant ssh web-01 -c "sudo ufw status verbose"
vagrant ssh web-02 -c "sudo ufw status verbose"
vagrant ssh app-01 -c "sudo ufw status verbose"
```

Explanation:

```text
UFW is active on all machines.
Incoming traffic is denied by default.
Only required ports and sources are allowed.
```

## 8. Show SSH Hardening

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

Explanation:

```text
Root SSH login is disabled, password authentication is disabled, and public key authentication is enabled.
The vagrant user is kept to allow Vagrant to manage the machines.
```

## 9. Show DevOps User

```powershell
vagrant ssh lb-01 -c "id devops && groups devops"
```

Explanation:

```text
A dedicated devops user exists and has sudo privileges.
```

## 10. Show Automatic Security Updates

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

Explanation:

```text
Automatic security updates are enabled on all machines.
```

## 11. Show Fail2Ban Bonus

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

Explanation:

```text
Fail2Ban is installed as a bonus intrusion prevention tool for SSH protection.
```

## 12. Final Summary

```text
This project demonstrates a small but structured server infrastructure.

I used Vagrant and VirtualBox to automate VM creation.
Each VM has a clear role, hostname, and static IP address.
The load balancer distributes traffic between two web servers.
The application server is isolated and reachable only from the web layer.
SSH access is hardened.
UFW is enabled.
Automatic security updates are configured.
Fail2Ban is installed as a bonus security feature.
```