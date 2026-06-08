# Troubleshooting

This document describes problems encountered during the project and how they were solved.

## VirtualBox Python Bindings Warning

During VirtualBox installation, a warning appeared about missing Python Core and win32api dependencies.

This warning was not critical for this project.

Reason:

- Python bindings are only needed for VirtualBox SDK usage;
- this project uses VirtualBox through Vagrant;
- no Python automation against the VirtualBox SDK is required.

Solution:

- continued VirtualBox installation without installing Python bindings.

## Virtualization Detection Confusion

Windows PowerShell showed:

```text
VirtualizationFirmwareEnabled : False
```

However, BIOS showed:

```text
Intel Virtualization Technology: Enabled
VT-d: Enabled
```

WSL2 was also working.

Conclusion:

- hardware virtualization was enabled in BIOS;
- Windows Hypervisor was active;
- the PowerShell output was misleading in this environment.

Solution:

- verified BIOS settings;
- verified that WSL2 was running;
- tested VirtualBox and Vagrant directly by creating a test VM.

## Vagrant Box `base` Error

An error occurred:

```text
Couldn't open file C:/Users/joell/server-sorcery-101/base
```

Cause:

The Vagrantfile used:

```ruby
config.vm.box = "base"
```

Vagrant tried to find a local or remote box named `base`.

Solution:

Changed the box to:

```ruby
config.vm.box = "ubuntu/jammy64"
```

## VM Boot Timeout

During `vagrant up`, Vagrant timed out while waiting for a VM to boot.

The host machine was using around 95% RAM.

Cause:

The VMs were too heavy for the available memory, and Ubuntu booted too slowly.

Solution:

- reduced VM memory allocation;
- increased boot timeout;
- disabled VirtualBox GUI windows;
- used sequential startup:

```powershell
vagrant up --no-parallel
```

Final memory allocation:

| VM | RAM |
|---|---:|
| `lb-01` | 768 MB |
| `web-01` | 512 MB |
| `web-02` | 512 MB |
| `app-01` | 768 MB |

## VirtualBox VM Console Asking for Login

A VirtualBox VM window showed an Ubuntu login prompt.

This was expected.

The project does not require logging in through the VirtualBox GUI console.

Correct way to access a VM:

```powershell
vagrant ssh lb-01
```

If the VM captures the mouse or keyboard, press:

```text
Right Ctrl
```

to release it.

## Shell Script Line Endings

Because the project was edited on Windows, shell scripts could accidentally use CRLF line endings.

Linux scripts should use LF line endings.

Solution:

In VS Code:

```text
Bottom right corner -> CRLF -> LF -> Save
```

This was checked for all `.sh` scripts.

## Fail2Ban Socket Error

During Fail2Ban provisioning, this error appeared:

```text
Failed to access socket path: /var/run/fail2ban/fail2ban.sock. Is fail2ban running?
```

Cause:

Fail2Ban was installed, but the service did not start correctly before `fail2ban-client status` was executed.

Solution:

- installed `python3-systemd`;
- simplified the Fail2Ban jail config;
- added configuration test:

```bash
fail2ban-client -t
```

- added a short wait loop before checking status:

```bash
for i in {1..10}; do
  if fail2ban-client ping >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
```

After this change, Fail2Ban started correctly.

## Direct Access to Web Servers Times Out

After enabling UFW, direct access from the host to web servers timed out:

```powershell
curl.exe --connect-timeout 3 http://192.168.56.11
curl.exe --connect-timeout 3 http://192.168.56.12
```

This is expected behavior.

Reason:

The web servers allow HTTP only from the load balancer:

```text
192.168.56.10
```

Correct access path:

```text
Host -> lb-01 -> web-01/web-02
```

## Load Balancer Cannot Access app-01

This command returns `blocked`:

```powershell
vagrant ssh lb-01 -c "timeout 3 curl -s http://192.168.56.13/health || echo blocked"
```

This is expected behavior.

Reason:

The application server accepts HTTP only from:

```text
web-01
web-02
```

The load balancer should not directly access the application server.

## Useful Recovery Commands

Stop all VMs:

```powershell
vagrant halt
```

Destroy all VMs:

```powershell
vagrant destroy -f
```

Start all VMs one by one:

```powershell
vagrant up --no-parallel
```

Run provisioning again:

```powershell
vagrant provision
```

Check VM status:

```powershell
vagrant status
```