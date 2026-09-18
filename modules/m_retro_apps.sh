#!/usr/bin/env bash
# Sambox 2 - Sub-módulo de Orquestração de Aplicativos e Sandboxes
# Copyright (c) 2026, Sam Moreno. Licença BSD 2-Clause.

EMU_CATALOG=(
    "RetroArch|retroarch|.config/retroarch|org.libretro.RetroArch"
    "PCSX2|pcsx2-qt|.config/PCSX2|net.pcsx2.PCSX2"
    "RPCS3|rpcs3|.config/rpcs3|net.rpcs3.RPCS3"
    "Dolphin|dolphin-emu|.config/dolphin-emu|org.DolphinEmu.dolphin-emu"
    "DuckStation|duckstation-qt|.config/duckstation|org.duckstation.DuckStation"
    "PPSSPP|PPSSPPSDL|.config/ppsspp|org.ppsspp.PPSSPP"
    "Ryujinx|Ryujinx|.config/Ryujinx|org.ryujinx.Ryujinx"
)

_check_emu_status() {
    local bin="$1" flpk="$2"
    command -v "$bin" >/dev/null 2>&1 && { echo "1|Nativo (APT)"; return; }
    command -v flatpak >/dev/null 2>&1 && flatpak info "$flpk" >/dev/null 2>&1 && { echo "2|Flatpak"; return; }
    echo "0|Não Encontrado"
}

retro_audit_emulators() {
    printf "\n${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n  ║     🎮  EMULADORES & CONFIGURAÇÕES        ║\n  ╚═══════════════════════════════════════════╝${RST}\n\n"
    printf "  ${BOLD}%-14s %-16s %-18s %s${RST}\n" "EMULADOR" "STATUS" "CONFIGURAÇÃO" "CAMINHO DE CONFIG"; _sep
    for emu in "${EMU_CATALOG[@]}"; do
        local name bin cfg_rel flpk st_code st_txt cfg_dir dir_status="${DIM}Ausente${RST}" color=""
        IFS='|' read -r name bin cfg_rel flpk <<< "$emu"
        IFS='|' read -r st_code st_txt <<< "$(_check_emu_status "$bin" "$flpk")"
        cfg_dir="${HOME}/${cfg_rel}"
        [[ "$st_code" == "2" ]] && cfg_dir="${HOME}/.var/app/${flpk}/config/${cfg_rel##*/}"
        [[ -d "$cfg_dir" ]] && dir_status="${GREEN}Configurado${RST}"
        [[ "$st_code" == "0" ]] && color="${DIM}" || color="${GREEN}"
        printf "  %-14s %-24b %-26b ${DIM}%s${RST}\n" "${name}" "${color}${st_txt}${RST}" "${dir_status}" "${cfg_dir}"
    done
}

retro_install_emulators() {
    local has_apt=0 has_flatpak=0 i_menu
    command -v apt-get >/dev/null 2>&1 && has_apt=1; command -v flatpak >/dev/null 2>&1 && has_flatpak=1
    [[ ${has_apt} -eq 0 && ${has_flatpak} -eq 0 ]] && { _err "Gerenciadores APT/Flatpak ausentes."; return 1; }
    while true; do
        clear 2>/dev/null
        printf "\n${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n  ║     📦  INSTALAR EMULADORES               ║\n  ╚═══════════════════════════════════════════╝${RST}\n\n"
        local idx=1; for entry in "${EMU_CATALOG[@]}"; do
            local name bin cfg flpk; IFS='|' read -r name bin cfg flpk <<< "${entry}"
            printf "  ${CYAN}[%d]${RST}    %-14s  " "$idx" "$name"
            [[ $has_apt -eq 1 && "$bin" != "rpcs3" && "$bin" != "duckstation-qt" && "$bin" != "Ryujinx" ]] && printf "${GREEN}APT:${RST} %-16s" "$bin" || printf "${DIM}APT: (Flatpak apenas)${RST}  "
            [[ $has_flatpak -eq 1 ]] && printf "${YELLOW}Flatpak${RST}\n" || printf "\n"; idx=$(( idx + 1 ))
        done
        printf "  ${DIM}────────────────────────────────────────────────${RST}\n  ${CYAN}[0]${RST}    ⬅️   Voltar\n\n"
        read -rp "  Selecione o emulador [0-${#EMU_CATALOG[@]}]: " i_menu
        [[ "${i_menu}" == "0" || -z "${i_menu}" ]] && break
        if [[ "${i_menu}" =~ ^[1-9][0-9]*$ ]] && (( i_menu <= ${#EMU_CATALOG[@]} )); then
            local name bin cfg flpk method=""; IFS='|' read -r name bin cfg flpk <<< "${EMU_CATALOG[$((i_menu-1))]}"
            printf "\n  Método para %s:\n" "$name"
            if [[ $has_apt -eq 1 && "$bin" != "rpcs3" && "$bin" != "duckstation-qt" && "$bin" != "Ryujinx" && $has_flatpak -eq 1 ]]; then
                printf "  [1] APT  [2] Flatpak  [0] Cancelar\n"; read -rp "  Opção: " method
            else
                method="2"; [[ "$bin" != "rpcs3" && "$bin" != "duckstation-qt" && "$bin" != "Ryujinx" ]] && method="1"
            fi
            case "$method" in
                1) _msg "Instalando via APT..."; sudo apt-get install -y "$bin" ;;
                2) _msg "Instalando via Flatpak..."; flatpak install -y flathub "$flpk" ;;
                *) _warn "Cancelado." ;;
            esac
        fi
        printf "\n"; read -rp "  Pressione [ENTER] para continuar..." _
    done
}

retro_clean_orphan_configs() {
    printf "\n${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n  ║     🗑️   CONFIGS ÓRFÃS DE EMULADORES     ║\n  ╚═══════════════════════════════════════════╝${RST}\n\n"
    local orphan_dirs=()
    for emu in "${EMU_CATALOG[@]}"; do
        local name bin cfg_rel flpk st_code
        IFS='|' read -r name bin cfg_rel flpk <<< "$emu"
        st_code=$(command -v "$bin" >/dev/null 2>&1 && echo "1" || { command -v flatpak >/dev/null 2>&1 && flatpak info "$flpk" >/dev/null 2>&1 && echo "1" || echo "0"; })
        if [[ "$st_code" == "0" ]]; then
            for path in "${HOME}/${cfg_rel}" "${HOME}/.var/app/${flpk}"; do
                if [[ -d "$path" ]]; then
                    local size=$(du -sh "$path" 2>/dev/null | awk '{print $1}')
                    printf "  ${YELLOW}[ÓRFÃ]${RST} %-12s %-40s ${RED}(%s)${RST}\n" "$name" "$path" "$size"
                    orphan_dirs+=("$path")
                fi
            done
        fi
    done
    [[ ${#orphan_dirs[@]} -eq 0 ]] && { _msg "Nenhum lixo órfão detectado."; return 0; }
    printf "\n"; read -rp "  Remover as ${#orphan_dirs[@]} pastas listadas? [s/N]: " confirm
    [[ "${confirm,,}" != "s" ]] && { _warn "Cancelado."; return 0; }
    for i in "${!orphan_dirs[@]}"; do
        printf "  ${RED}[-]${RST} Expurgando: %s\n" "${orphan_dirs[$i]}"
        rm -rf "${orphan_dirs[$i]}"
    done
    _msg "Limpeza profunda concluída!"
}
