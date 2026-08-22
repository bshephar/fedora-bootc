# Installing a bootc Asahi Linux image on a M1 Macbook Pro

**There be dragons here. Proceed only if willing to slay them**

## Preparation

You can build an image using this Containerfile in this directory. Modify to your liking,
or the base images are at: https://quay.io/organization/fedora-asahi-remix-atomic-desktops

Remove anything you love and/or care about from the filesystem.


## Process I used
I followed the steps here: https://github.com/fedora-asahi-remix-atomic-desktops/images/issues/1#issuecomment-2651553233

To clarify points of ambiguity:

### Get root karg

Once you have finished the steps in the above Github comment. We can find the root karg option by verifying the root
UUID with what the system has currently booted from:

```
    ❯ blkid --match-token LABEL=fedora
/dev/nvme0n1p7: LABEL="fedora" UUID="4344a275-2eac-4b47-b7b5-5056ce6ed810" UUID_SUB="19bf063c-59e3-4968-a5ff-8b03615cda92" BLOCK_SIZE="4096" TYPE="btrfs" PARTUUID="f7efde10-a432-4ac4-bdc1-3385971e0ec2"
```

We can see here, that my root partitions UUID is 4344a275-2eac-4b47-b7b5-5056ce6ed810. We can verify this matches what
we currently have as the booted root from `/proc/cmdline`. 

```
    ❯ cat /proc/cmdline
BOOT_IMAGE=(hd0,gpt6)/ostree/fedora-7896dd60f6dd4a914ac54dba0f3d25f0ed846108899d8b82d191c45422e81e6d/vmlinuz-6.14.8-400.asahi.fc42.aarch64+16k root=UUID=4344a275-2eac-4b47-b7b5-5056ce6ed810 rootflags=subvol=root rw ostree=/ostree/boot.1/fedora/7896dd60f6dd4a914ac54dba0f3d25f0ed846108899d8b82d191c45422e81e6d/0
```

So, with this information, we can build our `ostree container image deploy`:
```
    ostree container image deploy --imgref ostree-unverified-image:ghcr.io/bshephar/fedora-asahi-bootc:42 --target-imgref ostree-unverified-image:registry:ghcr.io/bshephar/fedora-asahi-bootc:42 --stateroot fedora --sysroot / --karg root=UUID="4344a275-2eac-4b47-b7b5-5056ce6ed810" --karg rw --karg rootflags=subvol=root
```

### Copy over files

```
cp /etc/passwd /etc/shadow /etc/group /etc/gshadow /etc/fstab /etc/subuid /etc/subgid /ostree/deploy/fedora/deploy/36a29634947adb59e6d086139d36ff2a0cd16551a3254b92e0a109b0c425a425.0/etc/
```

Edit `/etc/passwd` in the new ostree deployment to change home directory to `/var/home` instead of `/home`

```
❯ grep myuser /ostree/deploy/fedora/deploy/36a29634947adb59e6d086139d36ff2a0cd16551a3254b92e0a109b0c425a425.0/etc/passwd
myuser:x:1000:1000:myuser:/var/home/myuser:/usr/bin/zsh
```

Update `/etc/fstab` to mount `/home` at `/var/home` instead:
```
❯ grep home /ostree/deploy/fedora/deploy/36a29634947adb59e6d086139d36ff2a0cd16551a3254b92e0a109b0c425a425.0/etc/fstab
UUID=4344a275-2eac-4b47-b7b5-5056ce6ed810 /var/home btrfs x-systemd.growfs,compress=zstd:1,subvol=home 0 0
```

Fix SELinux contexts:
```
chcon --reference=/etc/passwd /ostree/deploy/fedora/deploy/36a29634947adb59e6d086139d36ff2a0cd16551a3254b92e0a109b0c425a425.0/etc/passwd
chcon --reference=/etc/fstab /ostree/deploy/fedora/deploy/36a29634947adb59e6d086139d36ff2a0cd16551a3254b92e0a109b0c425a425.0/etc/fstab
```

## Reboot
```
systemctl reboot
```

If it drops you into an emergency shell, I'm truly sorry, but refer to dragon warning above. In my case,
I missed the `root=` from my `--karg`. So I was able to fix this by editing the loader file in:
```
❯ rg 4344a /boot
/boot/loader.1/entries/ostree-1.conf
3:options root=UUID=4344a275-2eac-4b47-b7b5-5056ce6ed810 rootflags=subvol=root rw ostree=/ostree/boot.1/fedora/7896dd60f6dd4a914ac54dba0f3d25f0ed846108899d8b82d191c45422e81e6d/0
```

After fixing this, I was able to boot into the system and it all works nicely.
```
❯ sudo bootc status
● Booted image: ghcr.io/bshephar/fedora-asahi-bootc:42
        Digest: sha256:e84087ee1f421f05541851435ef2de01f6700d5c92d6ef64846e9e2be70d5413 (arm64)
       Version: 42.20250820.0 (2025-08-20T23:57:23Z)
```
