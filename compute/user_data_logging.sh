#!/bin/bash
set -e

S3_BUCKET="${s3_bucket_name}"
AWS_REGION="${aws_region}"
LOG_GROUP="${log_group_name}"
LOG_STREAM="$(hostname)-$(date +%Y%m%d)"

apt-get update
apt-get upgrade -y
apt-get install -y awscli amazon-cloudwatch-agent jq

curl -fsSL https://tailscale.com/install.sh | sh

echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

mkdir -p /var/log/tailscale
chown root:root /var/log/tailscale
chmod 755 /var/log/tailscale

cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/tailscale/tailscaled.log",
            "log_group_name": "$LOG_GROUP",
            "log_stream_name": "$LOG_STREAM-tailscaled",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/tailscale/tailscale.log",
            "log_group_name": "$LOG_GROUP",
            "log_stream_name": "$LOG_STREAM-tailscale",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json

tailscale up --authkey=${tailscale_auth_key} --advertise-exit-node --accept-routes 2>&1 | tee /var/log/tailscale/tailscale.log

cat > /usr/local/bin/sync-tailscale-logs.sh <<'SCRIPT'
#!/bin/bash
S3_BUCKET="$S3_BUCKET"
LOG_DIR="/var/log/tailscale"
DATE=$(date +%Y/%m/%d)

journalctl -u tailscaled --since "1 minute ago" >> $LOG_DIR/tailscaled.log

aws s3 sync $LOG_DIR s3://$S3_BUCKET/logs/$DATE/ \
  --region $AWS_REGION \
  --storage-class STANDARD_IA \
  --exclude "*" \
  --include "*.log"

find $LOG_DIR -name "*.log" -size +100M -exec sh -c 'mv "$1" "$1.$(date +%Y%m%d%H%M%S)"' _ {} \;
SCRIPT

chmod +x /usr/local/bin/sync-tailscale-logs.sh

cat > /etc/systemd/system/tailscale-log-sync.service <<EOF
[Unit]
Description=Sync Tailscale logs to S3
After=network.target

[Service]
Type=oneshot
Environment="S3_BUCKET=$S3_BUCKET"
Environment="AWS_REGION=$AWS_REGION"
ExecStart=/usr/local/bin/sync-tailscale-logs.sh
User=root

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/tailscale-log-sync.timer <<EOF
[Unit]
Description=Sync Tailscale logs every 5 minutes

[Timer]
OnBootSec=5min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable tailscale-log-sync.timer
systemctl start tailscale-log-sync.timer

/usr/local/bin/sync-tailscale-logs.sh

echo "Tailscale with logging setup complete"