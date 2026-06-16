$ErrorActionPreference = "Stop"

$Key = ".\.ssh\devops_key"
$SudoPassword = "DevOps123!"

$VMs = @{
  "lb-01"  = "192.168.56.10"
  "web-01" = "192.168.56.11"
  "web-02" = "192.168.56.12"
  "app-01" = "192.168.56.13"
}

function Run-SSH {
  param (
    [string]$Ip,
    [string]$Command
  )

  ssh `
    -i $Key `
    -o StrictHostKeyChecking=no `
    -o UserKnownHostsFile=NUL `
    "devops@$Ip" `
    $Command
}

function Run-Sudo {
  param (
    [string]$Ip,
    [string]$Command
  )

  Run-SSH $Ip "echo '$SudoPassword' | sudo -S -p '' $Command"
}

Write-Host "`n== VM hostnames =="

foreach ($name in $VMs.Keys) {
  $ip = $VMs[$name]
  Write-Host "`n[$name / $ip]"
  Run-SSH $ip "hostname && ip -4 addr show enp0s8"
}

Write-Host "`n== Hostname resolution from lb-01 =="

Run-SSH $VMs["lb-01"] "ping -c 2 web-01 && ping -c 2 web-02 && ping -c 2 app-01"

Write-Host "`n== Load balancer =="

curl.exe http://192.168.56.10

Write-Host "`n== Load balancing repeated test =="

1..8 | ForEach-Object {
  curl.exe -s http://192.168.56.10 | Select-String "Hello from"
}

Write-Host "`n== Web health checks from lb-01 =="

Run-SSH $VMs["lb-01"] "curl -s http://web-01/health && echo && curl -s http://web-02/health"

Write-Host "`n== App health checks from web servers =="

Run-SSH $VMs["web-01"] "curl -s http://app-01/health"
Run-SSH $VMs["web-02"] "curl -s http://app-01/health"

Write-Host "`n== Firewall negative checks =="

curl.exe --connect-timeout 3 http://192.168.56.11
curl.exe --connect-timeout 3 http://192.168.56.12

Run-SSH $VMs["lb-01"] "timeout 3 curl -s http://app-01/health || echo blocked"

Write-Host "`n== UFW status =="

foreach ($name in $VMs.Keys) {
  $ip = $VMs[$name]
  Write-Host "`n[$name]"
  Run-Sudo $ip "ufw status verbose"
}

Write-Host "`n== SSH hardening =="

Run-Sudo $VMs["lb-01"] "sshd -T | grep -E 'permitrootlogin|passwordauthentication|pubkeyauthentication|allowusers'"

Write-Host "`n== devops user and sudo group =="

foreach ($name in $VMs.Keys) {
  $ip = $VMs[$name]
  Write-Host "`n[$name]"
  Run-SSH $ip "id devops && groups devops"
}

Write-Host "`n== sudo must require password =="

Run-SSH $VMs["lb-01"] "sudo -n true 2>/dev/null && echo 'ERROR: sudo does not require password' || echo 'OK: sudo requires password'"

Write-Host "`n== Automatic security updates =="

foreach ($name in $VMs.Keys) {
  $ip = $VMs[$name]
  Write-Host "`n[$name]"
  Run-SSH $ip "systemctl is-active unattended-upgrades"
}

Write-Host "`n== Fail2Ban =="

Run-Sudo $VMs["lb-01"] "systemctl is-active fail2ban"
Run-Sudo $VMs["lb-01"] "fail2ban-client status"
Run-Sudo $VMs["lb-01"] "fail2ban-client status sshd"

Write-Host "`n== Upgradable packages =="

foreach ($name in $VMs.Keys) {
  $ip = $VMs[$name]
  Write-Host "`n[$name]"
  Run-Sudo $ip "apt update >/dev/null && apt list --upgradable"
}

Write-Host "`nValidation completed."