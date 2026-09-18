#!/usr/bin/env bash
<<<<<<< HEAD
# -----------------------------------------------------------------------------
# Sambox 2 - Módulo de Gerenciamento de ROMs, BIOS & Emuladores
# Copyright (c) 2026, Sam Moreno. All rights reserved.
# Distribuído sob os termos estáveis da licença BSD 2-Clause.
# -----------------------------------------------------------------------------
=======
# Sambox 2 - Menu Central de Emulação (Leve & Pragmático)
# Copyright (c) 2026, Sam Moreno. Licença BSD 2-Clause.
>>>>>>> 06e09fd (Refatora tabelas ANSI e otimiza auditoria criptográfica de BIOS)

DEFAULT_ROM_DIR="${HOME}/RetroROMs"
STANDARD_SYSTEMS=(nes snes n64 gamecube wii switch gb gbc gba genesis mastersystem saturn dreamcast psx ps2 psp arcade bios)

<<<<<<< HEAD
STANDARD_SYSTEMS=(nes snes n64 gamecube wii switch gb gbc gba genesis mastersystem saturn dreamcast psx ps2 psp arcade bios)

KNOWN_BIOS=(
    "scph1001.bin|PSX|PlayStation 1 North America (v4.0)|924e392ed05558ffdb115408c263dccf76f409f1"
    "scph5501.bin|PSX|PlayStation 1 North America (v3.0)|8dd7d5296a650fac7319bce665a6a53c8b424887"
    "scph5500.bin|PSX|PlayStation 1 Japan (v3.0)|ff3eeb8c664c8d8dce5d98503e4096052f06da31"
    "scph39001.bin|PS2|PlayStation 2 NA BIOS|b900593740e53a557b4c6e5a6fefd1c4701ee035"
    "gba_bios.bin|GBA|Game Boy Advance Official BIOS|a860e8c0b6d573d191e4ec7db1b1e4f6d30acf4f"
    "dc_boot.bin|Dreamcast|Sega Dreamcast Boot ROM|e10c53c2f8b90bab96eed2e96717013898c6d123"
    "dc_flash.bin|Dreamcast|Sega Dreamcast Flash NVRAM|0a93f7940c455905ab6e36bfa8093660fb7174a5"
    "bios_CD_U.bin|SegaCD|Sega CD Model 2 US|2efd74e3232ff264e3042e53395974a0477f3b0f"
    "sega_101.bin|Saturn|Sega Saturn Japan BIOS|224b92f8c3da15bae663b82aa294582f3ef7885b"
)

# Catálogo Único de Emuladores (Unifica Binário, Config Nativa, Referência Flatpak e Nome Comercial)
EMU_CATALOG=(
    "RetroArch|retroarch|.config/retroarch|org.libretro.RetroArch"
    "PCSX2|pcsx2-qt|.config/PCSX2|net.pcsx2.PCSX2"
    "RPCS3|rpcs3|.config/rpcs3|net.rpcs3.RPCS3"
    "Dolphin|dolphin-emu|.config/dolphin-emu|org.DolphinEmu.dolphin-emu"
    "DuckStation|duckstation-qt|.config/duckstation|org.duckstation.DuckStation"
    "PPSSPP|PPSSPPSDL|.config/ppsspp|org.ppsspp.PPSSPP"
    "Ryujinx|Ryujinx|.config/Ryujinx|org.ryujinx.Ryujinx"
)

# Auxiliar para checar se o emulador está instalado (Nativo ou Flatpak)
_check_emu_status() {
    local bin="$1" flpk="$2"
    command -v "$bin" >/dev/null 2>&1 && { echo "1|Nativo (APT)"; return; }
    command -v flatpak >/dev/null 2>&1 && flatpak info "$flpk" >/dev/null 2>&1 && { echo "2|Flatpak"; return; }
    echo "0|Não Encontrado"
}

# [1] Inicializar Diretório Padronizado de ROMs
retro_init_dirs() {
    local target_dir="${1:-${DEFAULT_ROM_DIR}}"
    printf "\n${YELLOW}[+]${RST} Inicializando estrutura padrão em: ${CYAN}%s${RST}...\n" "${target_dir}"
    for sys in "${STANDARD_SYSTEMS[@]}"; do
        local dir="${target_dir}/${sys}"
        [[ ! -d "${dir}" ]] && mkdir -p "${dir}" && printf "    ${GREEN}✔${RST} Criado: %s\n" "${dir}" || printf "    ${DIM}• Já existe: %s${RST}\n" "${dir}"
    done
    cat <<EOF > "${target_dir}/LEIAME.txt"
Sambox 2 - Estrutura de Emulação & ROMs
Coloque os jogos nas pastas correspondentes e as BIOS na pasta 'bios/'.
EOF
    _msg "Estrutura de emulação organizada com sucesso!"
}

# [2] Auditar Diretórios e Contagem de ROMs
retro_check_dirs() {
    local target_dir="${1:-${DEFAULT_ROM_DIR}}" total_roms=0
    printf "\n${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n  ║     📊  AUDITORIA DE ARQUIVOS DE ROMs     ║\n  ╚═══════════════════════════════════════════╝${RST}\n\n"
    [[ ! -d "${target_dir}" ]] && _warn "Diretório base ausente: ${target_dir}" && return 0
    for sys in "${STANDARD_SYSTEMS[@]}"; do
        local dir="${target_dir}/${sys}"
        if [[ -d "${dir}" ]]; then
            local count=$(find "${dir}" -maxdepth 1 -type f 2>/dev/null | wc -l)
=======
retro_init_dirs() {
    local target_dir="${1:-${DEFAULT_ROM_DIR}}"
    printf "\n${YELLOW}[+]${RST} Inicializando estrutura padrão em: ${CYAN}%s${RST}...\n" "${target_dir}"
    for sys in "${STANDARD_SYSTEMS[@]}"; do
        local dir="${target_dir}/${sys}"
        [[ ! -d "${dir}" ]] && mkdir -p "${dir}" && printf "    ${GREEN}✔${RST} Criado: %s\n" "${dir}"
    done
    cat <<EOF > "${target_dir}/LEIAME.txt"
Sambox 2 - Estrutura de Emulação & ROMs
Coloque os jogos nas pastas correspondentes e as BIOS na pasta 'bios/'.
EOF
    _msg "Estrutura de emulação organizada com sucesso!"
}

retro_check_dirs() {
    local target_dir="${1:-${DEFAULT_ROM_DIR}}" 
    local total_roms=0
    
    printf "\n${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n  ║     📊  AUDITORIA DE ARQUIVOS DE ROMs     ║\n  ╚═══════════════════════════════════════════╝${RST}\n\n"
    
    [[ ! -d "${target_dir}" ]] && _warn "Diretório base ausente: ${target_dir}" && return 0
    
    for sys in "${STANDARD_SYSTEMS[@]}"; do
        local dir="${target_dir}/${sys}"
        if [[ -d "${dir}" ]]; then
            # Otimizado: conta de forma robusta e limpa espaços extras gerados pelo wc em alguns Unix
            local count
            count=$(find "${dir}" -maxdepth 1 -type f -printf '.' 2>/dev/null | wc -c | tr -d ' ')
            count=${count:-0}
>>>>>>> 06e09fd (Refatora tabelas ANSI e otimiza auditoria criptográfica de BIOS)
            total_roms=$(( total_roms + count ))
            printf "  ${GREEN}[✓]${RST} %-16s : ${BOLD}%4d${RST} arquivos\n" "${sys}" "${count}"
        else
            printf "  ${YELLOW}[✗]${RST} %-16s : ${DIM}Diretório ausente${RST}\n" "${sys}"
        fi
    done
<<<<<<< HEAD
    _sep; printf "  ${BOLD}Total de arquivos detectados:${RST} ${GREEN}%d${RST}\n" "${total_roms}"
}

# [3] Validar Integridade de BIOS via SHA-1
retro_verify_bios() {
    local bios_dir="${1:-${DEFAULT_ROM_DIR}/bios}" has_sha1=0
    printf "\n${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n  ║     🛡️   VALIDAÇÃO CRIPTOGRÁFICA DE BIOS   ║\n  ╚═══════════════════════════════════════════╝${RST}\n\n"
    [[ ! -d "${bios_dir}" ]] && _warn "Diretório de BIOS ausente: ${bios_dir}" && return 0
    command -v sha1sum >/dev/null 2>&1 && has_sha1=1
    printf "  ${BOLD}%-16s %-10s %-12s %s${RST}\n" "ARQUIVO" "SISTEMA" "STATUS" "INTEGRIDADE SHA-1"; _sep
    for item in "${KNOWN_BIOS[@]}"; do
        local file sys desc exp_sha1; IFS='|' read -r file sys desc exp_sha1 <<< "${item}"
        local fullpath="${bios_dir}/${file}"
        if [[ -f "${fullpath}" ]]; then
            local integrity="${YELLOW}Hash ignorado${RST}"
            [[ $has_sha1 -eq 1 ]] && [[ "$((sha1sum "${fullpath}" || echo "err") | awk '{print $1}')" == "${exp_sha1,,}" ]] && integrity="${GREEN}VÁLIDO (Oficial)${RST}" || integrity="${RED}CORROMPIDO${RST}"
            printf "  %-16s %-10s ${GREEN}%-12s${RST} %b\n" "${file}" "${sys}" "Presente" "${integrity}"
        else
            printf "  %-16s %-10s ${DIM}%-12s${RST} %s\n" "${file}" "${sys}" "Ausente" "${DIM}Requerido para ${sys}${RST}"
        fi
    done
}

# [4] Auditar Emuladores Instalados e Configurações
retro_audit_emulators() {
    printf "\n${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n  ║     🎮  EMULADORES & CONFIGURAÇÕES        ║\n  ╚═══════════════════════════════════════════╝${RST}\n\n"
    printf "  ${BOLD}%-14s %-16s %-18s %s${RST}\n" "EMULADOR" "STATUS" "CONFIGURAÇÃO" "CAMINHO DE CONFIG"; _sep
    for emu in "${EMU_CATALOG[@]}"; do
        local name bin cfg_rel flpk status_info st_code st_txt cfg_dir dir_status="${DIM}Ausente${RST}"
        IFS='|' read -r name bin cfg_rel flpk <<< "$emu"
        IFS='|' read -r st_code st_txt <<< "$(_check_emu_status "$bin" "$flpk")"
        
        cfg_dir="${HOME}/${cfg_rel}"
        [[ "$st_code" == "2" ]] && cfg_dir="${HOME}/.var/app/${flpk}/config/${cfg_rel##*/}"
        [[ -d "$cfg_dir" ]] && dir_status="${GREEN}Configurado${RST}"
        
        printf "  %-14s %-24b %-26b ${DIM}%s${RST}\n" "${name}" "$([[ $st_code -eq 0 ], echo "${DIM}${st_txt}${RST}" || echo "${GREEN}${st_txt}${RST}")" "${dir_status}" "${cfg_dir}"
    done
}

# [5] Instalar Emuladores via APT ou Flatpak
retro_install_emulators() {
    local has_apt=0 has_flatpak=0 i_menu; command -v apt-get >/dev/null 2>&1 && has_apt=1; command -v flatpak >/dev/null 2>&1 && has_flatpak=1
    [[ ${has_apt} -eq 0 && ${has_flatpak} -eq 0 ]] && { _err "Gerenciadores APT/Flatpak ausentes."; return 1; }
    while true; do
        clear 2>/dev/null; printf "\n${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n  ║     📦  INSTALAR EMULADORES               ║\n  ╚═══════════════════════════════════════════╝${RST}\n\n"
        local idx=1; for entry in "${EMU_CATALOG[@]}"; do
            local name bin cfg flpk; IFS='|' read -r name bin cfg flpk <<< "${entry}"
            printf "  ${CYAN}[%d]${RST}    %-14s  " "$idx" "$name"
            [[ $has_apt -eq 1 && "$bin" != "rpcs3" && "$bin" != "duckstation-qt" && "$bin" != "Ryujinx" ]] && printf "${GREEN}APT:${RST} %-16s" "$bin" || printf "${DIM}APT: (Flatpak apenas)${RST}  "
            [[ $has_flatpak -eq 1 ]] && printf "${YELLOW}Flatpak${RST}\n" || printf "\n"; idx=$(( idx + 1 ))
        done
        printf "  ${DIM}────────────────────────────────────────────────${RST}\n  ${CYAN}[0]${RST}    ⬅️   Voltar\n\n"
        read -rp "  $(printf "${BOLD}")Selecione o emulador [0-${#EMU_CATALOG[@]}]:$(printf "${RST}") " i_menu
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
                1) _msg "Instalando via APT..."; sudo apt-get install -y "$bin" && _msg "Sucesso!" || _err "Falha.";;
                2) _msg "Instalando via Flatpak..."; flatpak install -y flathub "$flpk" && _msg "Sucesso!" || _err "Falha.";;
                *) _warn "Cancelado.";;
            esac
        fi
=======
    _sep
    printf "  ${BOLD}Total de arquivos detectados:${RST} ${GREEN}%d${RST}\n" "${total_roms}"
}

menu_retro_central() {
    local r_menu
    while true; do
        clear 2>/dev/null
        printf "\n${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n  ║        🕹️   CENTRAL RETRO & EMULAÇÃO      ║\n  ╚═══════════════════════════════════════════╝${RST}\n\n"
        printf "  ${CYAN}[1]${RST}    📁  Inicializar Árvore Padrão de ROMs (~/RetroROMs)\n"
        printf "  ${CYAN}[2]${RST}    📊  Auditar Diretórios e Contagem de ROMs\n"
        printf "  ${CYAN}[3]${RST}    🛡️   Validar Hashes SHA-1 de BIOS (Módulo Isolado)\n"
        printf "  ${CYAN}[4]${RST}    🎮  Auditar Emuladores e Configurações Instaladas\n"
        printf "  ${CYAN}[5]${RST}    📦  Instalar Emuladores (APT / Flatpak híbrido)\n"
        printf "  ${CYAN}[6]${RST}    🗑️   Limpar Configs Órfãs (Varredura de Sandboxes)\n"
        printf "  ${DIM}────────────────────────────────────────────────${RST}\n"
        printf "  ${CYAN}[0]${RST}    ⬅️   Voltar ao Menu Principal\n\n"
        
        read -rp "  Selecione [0-6]: " r_menu
        case "$r_menu" in
            1) retro_init_dirs "${DEFAULT_ROM_DIR}" ;;
            2) retro_check_dirs "${DEFAULT_ROM_DIR}" ;;
            3) retro_verify_bios "${DEFAULT_ROM_DIR}/bios" ;; # Função do m_retro_bios.sh
            4) retro_audit_emulators ;;                       # Função do m_retro_apps.sh
            5) retro_install_emulators ;;                     # Função do m_retro_apps.sh
            6) retro_clean_orphan_configs ;;                  # Função do m_retro_apps.sh
            0) break ;;
            *) _warn "Opção inválida." ;;
        esac
>>>>>>> 06e09fd (Refatora tabelas ANSI e otimiza auditoria criptográfica de BIOS)
        printf "\n"; read -rp "  Pressione [ENTER] para continuar..." _
    done
}

<<<<<<< HEAD
# [6] Limpar Configurações Órfãs de Emuladores Removidos (APT e Flatpak de uma vez só)
retro_clean_orphan_configs() {
    printf "\n${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n  ║     🗑️   CONFIGS ÓRFÃS DE EMULADORES     ║\n  ╚═══════════════════════════════════════════╝${RST}\n\n"
    local orphan_dirs=() orphan_labels=()
    for emu in "${EMU_CATALOG[@]}"; do
        local name bin cfg_rel flpk; IFS='|' read -r name bin cfg_rel flpk <<< "$emu"
        local st_code=$(command -v "$bin" >/dev/null 2>&1 && echo "1" || { command -v flatpak >/dev/null 2>&1 && flatpak info "$flpk" >/dev/null 2>&1 && echo "1" || echo "0"; })
        if [[ "$st_code" == "0" ]]; then
            for path in "${HOME}/${cfg_rel}" "${HOME}/.var/app/${flpk}"; do
                if [[ -d "$path" ]]; then
                    local size=$(du -sh "$path" 2>/dev/null | awk '{print $1}')
                    printf "  ${YELLOW}[ÓRFÃ]${RST} %-12s %-40s ${RED}(%s)${RST}\n" "$name" "$path" "$size"
                    orphan_dirs+=("$path"); orphan_labels+=("$name")
                fi
            done
        fi
    done
    [[ ${#orphan_dirs[@]} -eq 0 ]] && { _msg "Nenhum lixo órfão detectado."; return 0; }
printf "\n"; read -rp "  Remover as ${#orphan_dirs[@]} pastas listadas? [s/N]: " confirm[[ "${confirm,,}" != "s" ]] && { _warn "Cancelado."; return 0; }for i in "${!orphan_dirs[@]}"; doprintf "  ${RED}[-]${RST} Expurgando: %s\n" "${orphan_dirs[$i]}"rm -rf "${orphan_dirs[$i]}"done_msg "Limpeza profunda concluída!"}Despacho CLI e Orquestrador Menu Principalrun_retro_cli() {case "${1:-}" ininit) shift; retro_init_dirs "$@" ;; check|audit) shift; retro_check_dirs "$@" ;; bios) shift; retro_verify_bios "$@" ;;emulators|emus) retro_audit_emulators ;; install|install-emus) retro_install_emulators ;; clean-configs|orphan) retro_clean_orphan_configs ;;*) echo "Uso: sambox2 --retro [init|check|bios|emulators|install-emus|clean-configs]" ;;esac}menu_retro_central() {local r_menuwhile true; doclear 2>/dev/null; printf "\n${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n  ║        🕹️   CENTRAL RETRO & EMULAÇÃO      ║\n  ╚═══════════════════════════════════════════╝${RST}\n\n"printf "  ${CYAN}[1]${RST}    📁  Inicializar Árvore Padrão de ROMs (~/RetroROMs)\n  ${CYAN}[2]${RST}    📊  Auditar Diretórios e Contagem de ROMs\n  ${CYAN}[3]${RST}    🛡️   Validar Integridade e Hashes SHA-1 de BIOS\n"printf "  ${CYAN}[4]${RST}    🎮  Auditar Emuladores e Configurações Instaladas\n  ${CYAN}[5]${RST}    📦  Instalar Emuladores (APT / Flatpak)\n  ${CYAN}[6]${RST}    🗑️   Limpar Configs Órfãs de Emuladores Removidos\n"printf "  ${DIM}────────────────────────────────────────────────${RST}\n  ${CYAN}[0]${RST}    ⬅️   Voltar ao Menu Principal\n\n"read -rp "  Selecione [0-6]: " r_menucase "$r_menu" in1) retro_init_dirs "${DEFAULT_ROM_DIR}" ;; 2) retro_check_dirs "${DEFAULT_ROM_DIR}" ;; 3) retro_verify_bios "${DEFAULT_ROM_DIR}/bios" ;;4) retro_audit_emulators ;; 5) retro_install_emulators ;; 6) retro_clean_orphan_configs ;; 0) break ;; *) _warn "Opção inválida." ;;esacprintf "\n"; read -rp "  Pressione [ENTER] para continuar..." _done}
=======
register_sambox_module "🕹️   Central Retro & Emulação" "menu_retro_central"
>>>>>>> 06e09fd (Refatora tabelas ANSI e otimiza auditoria criptográfica de BIOS)
