ARG FEDORA_MAJOR_VERSION=rawhide
ARG FEDORA_DE=silverblue

FROM quay.io/fedora-ostree-desktops/${FEDORA_DE}:${FEDORA_MAJOR_VERSION}

COPY --from=docker.io/mikefarah/yq /usr/bin/yq /usr/bin/yq

RUN curl -s -o /etc/yum.repos.d/tailscale.repo https://pkgs.tailscale.com/stable/centos/9/tailscale.repo

RUN dnf remove -y firefox tcl

RUN dnf in -y alacritty \
              gdb \
              glib \
              krb5-workstation \
              libvirt \
              libvirt-client \
              lld \
              lua5.1-lpeg \
              make \
              neovim \
              pre-commit \
	      python3-pip \
              qemu \
              qemu-kvm \
              ripgrep \
              tmux \
              virt-install \
              zsh \
              tailscale && \

    dnf clean all
