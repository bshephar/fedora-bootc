#!/bin/bash

if [[ ! -f /proc/driver/nvidia/suspend ]]; then
    exit 0
fi

RUN_DIR=/run/nvidia-sleep
VT_FILE=${RUN_DIR}/active-vt
PATH=/usr/bin:/bin

restore_vt() {
    if [[ -f ${VT_FILE} ]]; then
        vt=$(<"${VT_FILE}")
        rm -f "${VT_FILE}"
        chvt "${vt}"
    fi
}

case "${1:-}" in
    is-suspend-then-hibernate-supported)
        systemd_version=$(systemctl --version | awk 'NR == 1 { print $2 }')
        [[ ${systemd_version} -gt 247 ]]
        ;;
    suspend|hibernate)
        install -d -m 0755 "${RUN_DIR}"
        fgconsole > "${VT_FILE}"
        if ! chvt 63; then
            restore_vt
            exit 1
        fi
        if ! printf '%s\n' "$1" > /proc/driver/nvidia/suspend; then
            restore_vt
            exit 1
        fi
        ;;
    resume)
        printf 'resume\n' > /proc/driver/nvidia/suspend || true
        restore_vt
        ;;
    *)
        exit 1
        ;;
esac
