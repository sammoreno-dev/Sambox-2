#!/usr/bin/env bash
# Sambox 2 - Banco de Dados e Análise de Runners Wine/Proton
# Copyright (c) 2026, Sam Moreno. Licença BSD 2-Clause.

check_fsync_support() {
    local kver major minor
    kver="$(uname -r 2>/dev/null || echo "0.0")"
    major="$(echo "${kver}" | cut -d. -f1)"
    minor="$(echo "${kver}" | cut -d. -f2 | cut -d- -f1)"

    if [[ "${major}" -gt 5 ]] || [[ "${major}" -eq 5 && "${minor}" -ge 16 ]]; then
        return 0
    fi
    [[ -c /dev/ntsync || -c /dev/winesync ]] && return 0
    return 1
}

detect_wine_binaries() {
    local found=() pdir="" wine_exe="" label=""
    local prev_nullglob

    if command -v wine >/dev/null 2>&1; then
        local wpath wver
        wpath="$(command -v wine)"
        wver="$("${wpath}" --version 2>/dev/null || echo "desconhecido")"
        found+=("system|${wpath}|Wine do Sistema (${wver})")
    fi

    local proton_dirs=(
        "${HOME}/.steam/root/compatibilitytools.d"
        "${HOME}/.local/share/Steam/compatibilitytools.d"
        "${HOME}/.local/share/Steam/steamapps/common"
        "${HOME}/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d"
        "${HOME}/.var/app/com.valvesoftware.Steam/data/Steam/steamapps/common"
        "${HOME}/.local/share/lutris/runners/wine"
        "${HOME}/.config/heroic/tools/wine"
        "${HOME}/.config/heroic/tools/proton"
    )

    prev_nullglob="$(shopt -p nullglob || true)"
    shopt -s nullglob

    for pdir in "${proton_dirs[@]}"; do
        [[ -d "${pdir}" ]] || continue
        for wine_exe in "${pdir}"/*/dist/bin/wine "${pdir}"/*/bin/wine "${pdir}"/*/files/bin/wine; do
            if [[ -x "${wine_exe}" ]]; then
                label="$(basename "$(dirname "$(dirname "${wine_exe}")")")"
                found+=("custom|${wine_exe}|${label}")
            fi
        done
    done
    eval "${prev_nullglob}"

    printf "%s\n" "${found[@]}"
}
