#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "==> [common] $*"
}

export DEBIAN_FRONTEND=noninteractive

log "Updating package index"
apt-get update -y

log "Installing base packages"
apt-get install -y \
  curl \
  vim \
  ufw \
  unattended-upgrades

log "Creating devops user if missing"
if ! id -u devops >/dev/null 2>&1; then
  useradd -m -s /bin/bash devops
fi

log "Adding devops user to sudo group"
usermod -aG sudo devops

log "Configuring passwordless sudo for devops"
cat >/etc/sudoers.d/devops <<'EOF'
devops ALL=(ALL) NOPASSWD:ALL
EOF
chmod 440 /etc/sudoers.d/devops

log "Copying Vagrant SSH authorized key to devops user"
mkdir -p /home/devops/.ssh

if [ -f /home/vagrant/.ssh/authorized_keys ]; then
  cp /home/vagrant/.ssh/authorized_keys /home/devops/.ssh/authorized_keys
fi

chown -R devops:devops /home/devops/.ssh
chmod 700 /home/devops/.ssh

if [ -f /home/devops/.ssh/authorized_keys ]; then
  chmod 600 /home/devops/.ssh/authorized_keys
fi

log "Applying SSH hardening"
cat >/etc/ssh/sshd_config.d/99-server-sorcery.conf <<'EOF'
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AllowUsers devops vagrant
EOF

sshd -t

if systemctl list-unit-files | grep -q '^ssh.service'; then
  systemctl reload ssh
else
  systemctl reload sshd
fi

log "Configuring secure umask"
cat >/etc/profile.d/99-secure-umask.sh <<'EOF'
# Server Sorcery 101 secure default permissions
umask 027
EOF

chmod 644 /etc/profile.d/99-secure-umask.sh

if grep -q '^UMASK' /etc/login.defs; then
  sed -i 's/^UMASK.*/UMASK 027/' /etc/login.defs
else
  echo 'UMASK 027' >> /etc/login.defs
fi

log "Enabling automatic security updates"
cat >/etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

systemctl enable --now unattended-upgrades

log "Common provisioning completed"