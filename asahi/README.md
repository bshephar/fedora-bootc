# Installing a bootc Asahi Linux image

> **Warning:** This is an advanced, potentially destructive procedure. Back up any data you need before continuing.

## Preparation

Build the image with the `Containerfile` in this directory, adapting it to your own system. Base images are available from <https://quay.io/organization/fedora-asahi-remix-atomic-desktops>.

Follow the upstream process described in <https://github.com/fedora-asahi-remix-atomic-desktops/images/issues/1#issuecomment-2651553233>.

## Find the root kernel argument

After following the upstream preparation steps, identify the filesystem that will be the deployed root and use **your own** UUID. For example:

```console
$ blkid --match-token LABEL=fedora
/dev/<root-partition>: LABEL="fedora" UUID="<ROOT_UUID>" UUID_SUB="<BTRFS_SUBVOLUME_UUID>" TYPE="btrfs" PARTUUID="<PARTITION_UUID>"
```

Confirm that the UUID matches the currently booted root:

```console
$ cat /proc/cmdline
BOOT_IMAGE=(<boot-device>)/ostree/<deployment>/vmlinuz-<kernel> root=UUID=<ROOT_UUID> rootflags=subvol=root rw ostree=<ostree-deployment>
```

Use that UUID in the deployment command. Replace the image reference, stateroot, and kernel arguments to match your environment:

```console
ostree container image deploy \
  --imgref ostree-unverified-image:ghcr.io/<GHCR_OWNER>/fedora-asahi-bootc:<TAG> \
  --target-imgref ostree-unverified-image:registry:ghcr.io/<GHCR_OWNER>/fedora-asahi-bootc:<TAG> \
  --stateroot <STATEROOT> \
  --sysroot / \
  --karg root=UUID=<ROOT_UUID> \
  --karg rw \
  --karg rootflags=subvol=root
```

## Copy required system configuration

Copy the required account and mount configuration into the new deployment. Deployment paths are specific to the installed system, so substitute `<DEPLOYMENT_CHECKSUM>` with the result from your own deployment:

```console
DEPLOYMENT=/ostree/deploy/<STATEROOT>/deploy/<DEPLOYMENT_CHECKSUM>.0/etc
sudo cp /etc/passwd /etc/shadow /etc/group /etc/gshadow /etc/fstab /etc/subuid /etc/subgid "$DEPLOYMENT/"
```

Update the copied account configuration as needed. For example, an account home can live below `/var/home`:

```text
<USERNAME>:x:<UID>:<GID>:<DESCRIPTION>:/var/home/<USERNAME>:/usr/bin/zsh
```

If `/home` is mounted at `/var/home`, use your own root filesystem UUID in the copied `fstab`:

```text
UUID=<ROOT_UUID> /var/home btrfs x-systemd.growfs,compress=zstd:1,subvol=home 0 0
```

Restore SELinux contexts after copying files:

```console
sudo chcon --reference=/etc/passwd "$DEPLOYMENT/passwd"
sudo chcon --reference=/etc/fstab "$DEPLOYMENT/fstab"
```

## Reboot and troubleshoot

```console
systemctl reboot
```

If the system drops into an emergency shell, verify the boot-loader entry contains the correct `root=UUID=<ROOT_UUID>` and OSTree deployment path for **your** installation. Then inspect the deployed image with:

```console
sudo bootc status
```
