---
title: Restic Backups with Systemd Timers
draft: false
date: 2024-07-29
tags:
    - linux
    - backup
    - systemd
---

Backing up with Restic using systemd timers.
Using SFTP with key login as the backend.

## Prerequisites

```bash
mkdir /opt/restic
mkdir /opt/restic/.ssh
mkdir /opt/restic/.cache
touch /opt/restic/restic.env 
touch /opt/restic/.restic-password # put in place
touch /opt/restic/.ssh/config # fill as necessary
chmod 600 /opt/restic/.restic-password

ssh-keygen -t ed25519 -f /opt/restic/.ssh/restic
chmod 600 /opt/restic/.ssh/restic

ssh-keyscan -H host >> /opt/restic/.ssh/known_hosts

cat <<EOF > /opt/restic/restic.env
RESTIC_REPOSITORY=sftp:user@host:/path/to/repo
RESTIC_PASSWORD_FILE=/opt/restic/.restic-password
RESTIC_CACHE_DIR=/opt/restic/.cache
EOF
```

## Service

```bash
# /etc/systemd/system/restic-backup.service
[Unit]
Description=Restic Backup
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
WorkingDirectory=/opt/restic
EnvironmentFile=/opt/restic/restic.env
# run restic with sftp.command to use the separate ssh config and known_hosts
ExecStart=/usr/bin/restic -o sftp.command="ssh user@host -F /opt/restic/.ssh/config -o UserKnownHostsFile=/opt/restic/.ssh/known_hosts -s sftp" backup /mnt/disk --verbose
Nice=19
IOSchedulingClass=best-effort
IOSchedulingPriority=7
ProtectSystem=full
ProtectHome=yes
PrivateTmp=yes

[Install]
WantedBy=multi-user.target
```

## Timer

```bash
# /etc/systemd/system/restic-backup.timer
[Unit]
Description=Run Restic backup monthly

[Timer]
OnCalendar=*-*-01 00:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

## Testing

```bash
# Enable and start the timer
systemctl start restic-backup.service

# Check the status
systemctl status restic-backup.service

# Check the logs
journalctl -u restic-backup.service
```

## TODOs

- Separate user and group for the service.
- Adding the user to the required groups to have read access to all files
(no need for `sudo`).