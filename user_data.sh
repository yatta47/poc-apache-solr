#!/bin/bash
set -eux

# DNF-based package update and install with Amazon Corretto
DNF_OPTS="-y"
dnf update ${DNF_OPTS}
dnf install ${DNF_OPTS} java-11-amazon-corretto-devel wget

# Device and mount directory
DEVICE=/dev/xvdf
MOUNT_DIR=/mnt/solr_data

# Only format if no filesystem present (preserves snapshot data)
if ! blkid ${DEVICE}; then
  mkfs.ext4 ${DEVICE}
fi

# Mount the data volume
mkdir -p ${MOUNT_DIR}
mount ${DEVICE} ${MOUNT_DIR}
echo "${DEVICE} ${MOUNT_DIR} ext4 defaults,nofail 0 2" >> /etc/fstab

# Download and install Solr
SOLR_VERSION=8.11.4
TMP_TGZ="/tmp/solr-${SOLR_VERSION}.tgz"
wget https://downloads.apache.org/lucene/solr/${SOLR_VERSION}/solr-${SOLR_VERSION}.tgz -O ${TMP_TGZ}
tar zxvf ${TMP_TGZ} -C /opt

# Register Solr as a service, pointing data directory to the mounted volume
bash /opt/solr-${SOLR_VERSION}/bin/install_solr_service.sh ${TMP_TGZ} \
  -i /opt \
  -d ${MOUNT_DIR} \
  -u solr \
  -s solr \
  -p 8983

# Enable and start Solr service
systemctl enable solr
systemctl start solr
