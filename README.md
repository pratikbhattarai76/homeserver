# homeserver
Professional Home Lab Infrastructure as Code

## Storage Configuration
The 1TB HDD is used for persistent data storage.

- **Device:** `/dev/sda1`
- **UUID:** `4250e634-f248-4591-b2b0-6d12919f6c8e`
- **Mount Point:** `/mnt/storage`
- **Filesystem:** `ext4`

### How It Was Configured:
1. Created Mount Point: `sudo mkdir -p /mnt/storage`
2. Added to `/etc/fstab` for persistence: `UUID=4250e634-f248-4591-b2b0-6d12919f6c8e  /mnt/storage  ext4  defaults  0  2`
3. Set Ownership: `sudo chown -R pratikserver:pratikserver /mnt/storage`

