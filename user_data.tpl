#!/bin/bash
set -eux

# SSM Agent のインストール
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl start amazon-ssm-agent

# DNF-based package update and install with Amazon Corretto
dnf update -y
dnf install -y java-11-amazon-corretto-devel wget

# Device and mount directory
DEVICE=${device_name}
MOUNT_DIR=/mnt/solr_data

# ── ファイルシステム作成（未作成時のみ） ──
if ! blkid "$DEVICE" >/dev/null 2>&1; then
  mkfs.ext4 "$DEVICE"
fi

# ── マウントディレクトリ作成 ──
mkdir -p "$MOUNT_DIR"

# ── 既にマウントされていなければマウント ──
if ! mountpoint -q "$MOUNT_DIR"; then
  mount "$DEVICE" "$MOUNT_DIR"
fi

# ── /etc/fstab へ追記（エントリが無ければのみ） ──
FSTAB_ENTRY="$DEVICE $MOUNT_DIR ext4 defaults,nofail 0 2"
if ! grep -Fxq "$FSTAB_ENTRY" /etc/fstab; then
  echo "$FSTAB_ENTRY" >> /etc/fstab
fi

# # Download and install Solr
SOLR_VERSION=8.11.4
TMP_TGZ="/tmp/solr-$SOLR_VERSION.tgz"
wget https://downloads.apache.org/lucene/solr/$SOLR_VERSION/solr-$SOLR_VERSION.tgz -O $TMP_TGZ
tar zxvf $TMP_TGZ -C /opt

# Register Solr as a service, pointing data directory to the mounted volume
bash /opt/solr-$SOLR_VERSION/bin/install_solr_service.sh $TMP_TGZ \
  -i /opt \
  -d $MOUNT_DIR \
  -u solr \
  -s solr \
  -p 8983

# Enable and start Solr service
systemctl enable solr
systemctl start solr
