# homeserver
Professional Home Lab Infrastructure as Code

## 🖥️ Hardware Speds
- **CPU:** Intel i7-4770
- **RAM:** 16GB DDR3
- **System Drive:** 120GB SSD
- **Data Drive:** 1TB HDD

## 1. Storage Strategy & Configuration
To optimize performance, the OS and Docker configurations live on the SSD while, the 1TB HDD is used for data storage.

- **Device:** `/dev/sda1`
- **UUID:** `4250e634-f248-4591-b2b0-6d12919f6c8e`
- **Mount Point:** `/mnt/storage`
- **Filesystem:** `ext4`

### 1.1 How It Was Configured:
1. Created Mount Point: `sudo mkdir -p /mnt/storage`
2. Added to `/etc/fstab` for persistence: `UUID=4250e634-f248-4591-b2b0-6d12919f6c8e  /mnt/storage  ext4  defaults  0  2`
3. Set Ownership: `sudo chown -R pratikserver:pratikserver /mnt/storage`

## 2. Container Environment
- **Engine:** Docker Engine
- **Orchestration:** Docker Compose
= **User Permissions:** `pratikserver` added to `docker` group.

### 2.1 Installation verification:
-`docker --version`
-`docker compose version`

