#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Sambox 2 - Módulo de Gerenciamento de ROMs, BIOS & Emuladores
# Copyright (c) 2026, Sam Moreno
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# -----------------------------------------------------------------------------

DEFAULT_ROM_DIR="${HOME}/RetroROMs"

STANDARD_SYSTEMS=(
    "nes"
    "snes"
    "n64"
    "gamecube"
    "wii"
    "switch"
    "gb"
    "gbc"
    "gba"
    "genesis"
    "mastersystem"
    "saturn"
    "dreamcast"
    "psx"
    "ps2"
    "psp"
    "arcade"
    "bios"
)

KNOWN_BIOS=(
    "scph1001.bin|PSX|PlayStation 1 North America (v4.0)|924e392ed05558ffdb115408c263dccf76f409f1"
    "scph5501.bin|PSX|PlayStation 1 North America (v3.0)|8dd7d5296a650fac7319bce665a6a53c8b424887"
    "scph5500.bin|PSX|PlayStation 1 Japan (v3.0)|ff3eeb8c664c8d8dce5d98503e4096052f06da31"
    "scph39001.bin|PS2|PlayStation 2 NA BIOS|b900593740e53a557b4c6e5a6fefd1c4701ee035"
    "gba_bios.bin|GBA|Game Boy Advance Official BIOS|a860e8c0b6d573d191e4ec7db1b1e4f6d30acf4f"
    "dc_boot.bin|Dreamcast|Sega Dreamcast Boot ROM|e10c53c2f8b90bab96eed2e96717013898c6d123"
    "dc_flash.bin|Dreamcast|Sega Dreamcast Flash NVRAM|0a93f7940c455905ab6e36bfa8093660fb7174A5"
    "bios_CD_U.bin|SegaCD|Sega CD Model 2 US|2efd74e3232ff264e3042e53395974a0477f3b0f"
    "sega_101.bin|Saturn|Sega Saturn Japan BIOS|224b92f8c3da15bae663b82aa294582f3ef7885b"
)

# [1] Função para Inicializar Diretório Padronizado de ROMs
retro_init_dirs() {
    local target_dir="${1:-${DEFAULT_ROM_DIR}}"
    printf "\n${YELLOW}[+]${RST} Inicializando estrutura padrão de ROMs em: ${CYAN}%s${RST}...\n" "${target_dir}"

    for sys in "${STANDARD_SYSTEMS[@]}"; do
        local dir="${target_dir}/${sys}"
        if [[ ! -d "${dir}" ]]; then
            mkdir -p "${dir}"
            printf "    ${GREEN}✔${RST} Criado: %s\n" "${dir}"
        else
            printf "    ${DIM}• Já existe: %s${RST}\n" "${dir}"
        fi
    done

    cat <<EOF > "${target_dir}/LEIAME.txt"
Sambox 2 - Estrutura de Emulação & ROMs
=======================================
Coloque os arquivos de jogos dentro de suas respectivas pastas.
Arquivos de BIOS de consoles devem ficar na pasta 'bios/'.
EOF

    _msg "Estrutura de emulação estruturada com sucesso!"
}

# [2] Função para Auditar Diretórios e Contagem de ROMs
retro_check_dirs() {
    local target_dir="${1:-${DEFAULT_ROM_DIR}}"
    printf "\n${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n"
    printf "  ║     📊  AUDITORIA DE ARQUIVOS DE ROMs     ║\n"
    printf "  ╚═══════════════════════════════════════════╝${RST}\n\n"

    if [[ ! -d "${target_dir}" ]]; then
        _warn "Diretório base não localizado: ${target_dir}"
        printf "  Execute a opção [1] para inicializar a árvore padrão.\n"
        return 0
    fi

    local total_roms=0
    for sys in "${STANDARD_SYSTEMS[@]}"; do
        local dir="${target_dir}/${sys}"
        if [[ -d "${dir}" ]]; then
            local count
            count="$(find "${dir}" -maxdepth 1 -type f 2>/dev/null | wc -l || echo 0)"
            total_roms=$(( total_roms + count ))
            printf "  ${GREEN}[✓]${RST} %-16s : ${BOLD}%4d${RST} arquivos\n" "${sys}" "${count}"
        else
            printf "  ${YELLOW}[✗]${RST} %-16s : ${DIM}Diretório ausente${RST}\n" "${sys}"
        fi
    done

    _sep
    printf "  ${BOLD}Total de arquivos detectados:${RST} ${GREEN}%d${RST}\n" "${total_roms}"
}

# [3] Função para Validar Integridade de BIOS via SHA-1
retro_verify_bios() {
    local bios_dir="${1:-${DEFAULT_ROM_DIR}/bios}"
    printf "\n${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n"
    printf "  ║     🛡️   VALIDAÇÃO CRIPTOGRÁFICA DE BIOS   ║\n"
    printf "  ╚═══════════════════════════════════════════╝${RST}\n\n"

    if [[ ! -d "${bios_dir}" ]]; then
        _warn "Diretório de BIOS não localizado: ${bios_dir}"
        return 0
    fi

    local has_sha1=0
    command -v sha1sum >/dev/null 2>&1 && has_sha1=1

    printf "  ${BOLD}%-16s %-10s %-12s %s${RST}\n" "ARQUIVO" "SISTEMA" "STATUS" "INTEGRIDADE SHA-1"
    _sep

    for item in "${KNOWN_BIOS[@]}"; do
        local file sys desc exp_sha1
        IFS='|' read -r file sys desc exp_sha1 <<< "${item}"
        local fullpath="${bios_dir}/${file}"

        if [[ -f "${fullpath}" ]]; then
            local integrity="${YELLOW}Hash ignorado${RST}"
            if [[ ${has_sha1} -eq 1 ]]; then
                local actual_sha1
                actual_sha1="$(sha1sum "${fullpath}" | awk '{print $1}')"
                if [[ "${actual_sha1,,}" == "${exp_sha1,,}" ]]; then
                    integrity="${GREEN}VÁLIDO (Oficial)${RST}"
                else
                    integrity="${RED}CORROMPIDO / Não-oficial${RST}"
                fi
            fi
            printf "  %-16s %-10s ${GREEN}%-12s${RST} %b\n" "${file}" "${sys}" "Presente" "${integrity}"
        else
            printf "  %-16s %-10s ${DIM}%-12s${RST} %s\n" "${file}" "${sys}" "Ausente" "${DIM}Requerido para ${sys}${RST}"
        fi
    done
}

# [4] Função para Auditar Emuladores Instalados e Configurações
retro_audit_emulators() {
    printf "\n${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n"
    printf "  ║     🎮  EMULADORES & CONFIGURAÇÕES        ║\n"
    printf "  ╚═══════════════════════════════════════════╝${RST}\n\n"

    local emulators=(
        "RetroArch|retroarch|${HOME}/.config/retroarch|retroarch.cfg"
        "PCSX2|pcsx2-qt|${HOME}/.config/PCSX2|inis/PCSX2.ini"
        "RPCS3|rpcs3|${HOME}/.config/rpcs3|config.yml"
        "Dolphin|dolphin-emu|${HOME}/.config/dolphin-emu|Dolphin.ini"
        "DuckStation|duckstation-qt|${HOME}/.config/duckstation|settings.ini"
        "PPSSPP|PPSSPPSDL|${HOME}/.config/ppsspp|PSP/SYSTEM/ppsspp.ini"
        "Ryujinx|Ryujinx|${HOME}/.config/Ryujinx|Config.json"
    )

    printf "  ${BOLD}%-14s %-16s %-18s %s${RST}\n" "EMULADOR" "BINÁRIO" "CONFIGURAÇÃO" "CAMINHO"
    _sep

    for emu in "${emulators[@]}"; do
        local name bin cfg_dir cfg_file
        IFS='|' read -r name bin cfg_dir cfg_file <<< "${emu}"

        local bin_status="${DIM}Não Encontrado${RST}"
        if command -v "${bin}" >/dev/null 2>&1; then
            bin_status="${GREEN}Instalado${RST}"
        fi

        local dir_status="${DIM}Ausente${RST}"
        if [[ -d "${cfg_dir}" ]]; then
            if [[ -f "${cfg_dir}/${cfg_file}" ]]; then
                dir_status="${GREEN}Configurado${RST}"
            else
                dir_status="${YELLOW}Pasta Presente${RST}"
            fi
        fi

        printf "  %-14s %-24b %-26b ${DIM}%s${RST}\n" "${name}" "${bin_status}" "${dir_status}" "${cfg_dir}"
    done
}

# [5] Função para Instalar Emuladores via APT ou Flatpak
retro_install_emulators() {
    # Tabela: Nome|apt_pkg|flatpak_ref
    local catalog=(
        "RetroArch|retroarch|org.libretro.RetroArch"
        "PCSX2|pcsx2|net.pcsx2.PCSX2"
        "RPCS3|(indisponível no APT)|net.rpcs3.RPCS3"
        "Dolphin|dolphin-emu|org.DolphinEmu.dolphin-emu"
        "DuckStation|(indisponível no APT)|org.duckstation.DuckStation"
        "PPSSPP|ppsspp|org.ppsspp.PPSSPP"
        "Ryujinx|(indisponível no APT)|org.ryujinx.Ryujinx"
    )

    local has_apt=0 has_flatpak=0
    command -v apt-get  >/dev/null 2>&1 && has_apt=1
    command -v flatpak  >/dev/null 2>&1 && has_flatpak=1

    if [[ ${has_apt} -eq 0 && ${has_flatpak} -eq 0 ]]; then
        _err "Nem APT nem Flatpak foram encontrados no sistema."
        return 1
    fi

    local i_menu
    while true; do
        clear 2>/dev/null || true
        printf "\n"
        printf "${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n"
        printf "  ║     📦  INSTALAR EMULADORES               ║\n"
        printf "  ╚═══════════════════════════════════════════╝${RST}\n\n"

        local idx=1
        for entry in "${catalog[@]}"; do
            local emu_name apt_pkg flatpak_ref
            IFS='|' read -r emu_name apt_pkg flatpak_ref <<< "${entry}"
            printf "  ${CYAN}[%d]${RST}    %-14s" "${idx}" "${emu_name}"
            if [[ ${has_apt} -eq 1 && "${apt_pkg}" != "(indisponível no APT)" ]]; then
                printf "  ${GREEN}APT:${RST} %-22s" "${apt_pkg}"
            else
                printf "  ${DIM}APT: %-22s${RST}" "${apt_pkg}"
            fi
            if [[ ${has_flatpak} -eq 1 ]]; then
                printf "  ${YELLOW}Flatpak${RST}"
            fi
            printf "\n"
            idx=$(( idx + 1 ))
        done

        printf "  ${DIM}────────────────────────────────────────────────${RST}\n"
        printf "  ${CYAN}[0]${RST}    ⬅️   Voltar\n\n"

        read -rp "  $(printf "${BOLD}")Selecione o emulador [0-${#catalog[@]}]:$(printf "${RST}") " i_menu

        [[ "${i_menu}" == "0" ]] && break

        if [[ "${i_menu}" =~ ^[1-9][0-9]*$ ]] && (( i_menu >= 1 && i_menu <= ${#catalog[@]} )); then
            local chosen="${catalog[$(( i_menu - 1 ))]}"
            local emu_name apt_pkg flatpak_ref
            IFS='|' read -r emu_name apt_pkg flatpak_ref <<< "${chosen}"

            printf "\n${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n"
            printf "  ║     ⚙️   MÉTODO DE INSTALAÇÃO             ║\n"
            printf "  ╚═══════════════════════════════════════════╝${RST}\n\n"
            printf "  Emulador selecionado: ${BOLD}%s${RST}\n\n" "${emu_name}"

            local method=""
            if [[ ${has_apt} -eq 1 && "${apt_pkg}" != "(indisponível no APT)" && ${has_flatpak} -eq 1 ]]; then
                printf "  ${CYAN}[1]${RST}  Instalar via APT      (${apt_pkg})\n"
                printf "  ${CYAN}[2]${RST}  Instalar via Flatpak  (${flatpak_ref})\n"
                printf "  ${CYAN}[0]${RST}  Cancelar\n\n"
                read -rp "  $(printf "${BOLD}")Método [0-2]:$(printf "${RST}") " method
            elif [[ ${has_apt} -eq 1 && "${apt_pkg}" != "(indisponível no APT)" ]]; then
                printf "  ${CYAN}[1]${RST}  Instalar via APT      (${apt_pkg})\n"
                printf "  ${CYAN}[0]${RST}  Cancelar\n\n"
                read -rp "  $(printf "${BOLD}")Método [0-1]:$(printf "${RST}") " method
            elif [[ ${has_flatpak} -eq 1 ]]; then
                printf "  ${CYAN}[1]${RST}  Instalar via Flatpak  (${flatpak_ref})\n"
                printf "  ${CYAN}[0]${RST}  Cancelar\n\n"
                read -rp "  $(printf "${BOLD}")Método [0-1]:$(printf "${RST}") " method
                [[ "${method}" == "1" ]] && method="2"
            fi

            case "${method}" in
                1)
                    _msg "Instalando ${emu_name} via APT: ${apt_pkg}..."
                    if sudo apt-get install -y "${apt_pkg}"; then
                        _msg "${emu_name} instalado com sucesso via APT."
                    else
                        _err "Falha ao instalar ${emu_name} via APT. Verifique os repositórios configurados."
                    fi
                    ;;
                2)
                    _msg "Instalando ${emu_name} via Flatpak: ${flatpak_ref}..."
                    if flatpak install -y flathub "${flatpak_ref}"; then
                        _msg "${emu_name} instalado com sucesso via Flatpak."
                    else
                        _err "Falha ao instalar ${emu_name} via Flatpak. Verifique se o remote 'flathub' está configurado."
                    fi
                    ;;
                0|"") _warn "Instalação cancelada." ;;
                *)    _warn "Opção inválida." ;;
            esac
        else
            _warn "Opção inválida no sub-menu."
        fi

        printf "\n"
        read -rp "  Pressione [ENTER] para continuar..." _
    done
}

# [6] Função para Limpar Configurações Órfãs de Emuladores Removidos
retro_clean_orphan_configs() {
    local emulators=(
        "RetroArch|retroarch|${HOME}/.config/retroarch"
        "PCSX2|pcsx2-qt|${HOME}/.config/PCSX2"
        "RPCS3|rpcs3|${HOME}/.config/rpcs3"
        "Dolphin|dolphin-emu|${HOME}/.config/dolphin-emu"
        "DuckStation|duckstation-qt|${HOME}/.config/duckstation"
        "PPSSPP|PPSSPPSDL|${HOME}/.config/ppsspp"
        "Ryujinx|Ryujinx|${HOME}/.config/Ryujinx"
    )

    printf "\n${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n"
    printf "  ║     🗑️   CONFIGS ÓRFÃS DE EMULADORES     ║\n"
    printf "  ╚═══════════════════════════════════════════╝${RST}\n\n"
    printf "  ${DIM}Verificando emuladores removidos com configs ainda presentes...${RST}\n\n"

    local orphan_names=() orphan_dirs=()

    for emu in "${emulators[@]}"; do
        local name bin cfg_dir
        IFS='|' read -r name bin cfg_dir <<< "${emu}"

        if ! command -v "${bin}" >/dev/null 2>&1 && [[ -d "${cfg_dir}" ]]; then
            local dir_size
            dir_size="$(du -sh "${cfg_dir}" 2>/dev/null | awk '{print $1}' || echo "?")"
            printf "  ${YELLOW}[ÓRFÃ]${RST} %-14s  ${DIM}%s${RST}  ${RED}(%s)${RST}\n" \
                "${name}" "${cfg_dir}" "${dir_size}"
            orphan_names+=("${name}")
            orphan_dirs+=("${cfg_dir}")
        fi
    done

    if [[ ${#orphan_dirs[@]} -eq 0 ]]; then
        _msg "Nenhuma configuração órfã encontrada. Sistema limpo!"
        return 0
    fi

    printf "\n  ${BOLD}%d configuração(ões) órfã(s) encontrada(s).${RST}\n\n" "${#orphan_dirs[@]}"

    local confirm
    read -rp "  $(printf "${YELLOW}${BOLD}")Deseja remover todas as configurações listadas? [s/N]:$(printf "${RST}") " confirm

    if [[ "${confirm,,}" != "s" ]]; then
        _warn "Operação cancelada. Nenhum arquivo foi removido."
        return 0
    fi

    local removed=0
    for i in "${!orphan_dirs[@]}"; do
        local dir="${orphan_dirs[${i}]}"
        local nme="${orphan_names[${i}]}"
        printf "  ${RED}[-]${RST} Removendo config de ${BOLD}%s${RST}: %s\n" "${nme}" "${dir}"
        rm -rf "${dir}"
        removed=$(( removed + 1 ))
    done

    _sep
    _msg "${removed} configuração(ões) órfã(s) removida(s) com sucesso."
}

# ── Despacho Direto via Linha de Comando (CLI) ─────────────────────────────
run_retro_cli() {
    case "${1:-}" in
        init) shift; retro_init_dirs "${1:-${DEFAULT_ROM_DIR}}" ;;
        check|audit) shift; retro_check_dirs "${1:-${DEFAULT_ROM_DIR}}" ;;
        bios) shift; retro_verify_bios "${1:-${DEFAULT_ROM_DIR}/bios}" ;;
        emulators|emus) retro_audit_emulators ;;
        install|install-emus) retro_install_emulators ;;
        clean-configs|orphan) retro_clean_orphan_configs ;;
        *)
            echo "Uso: sambox2 --retro [init|check|bios|emulators|install-emus|clean-configs]"
            ;;
    esac
}

# ── Função Orquestradora Principal do Módulo (Sempre no final) ──────────────
menu_retro_central() {
    local r_menu
    while true; do
        clear 2>/dev/null || true
        printf "\n"
        printf "${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n"
        printf "  ║        🕹️   CENTRAL RETRO & EMULAÇÃO      ║\n"
        printf "  ╚═══════════════════════════════════════════╝${RST}\n\n"
        printf "  ${CYAN}[1]${RST}    📁  Inicializar Árvore Padrão de ROMs (~/RetroROMs)\n"
        printf "  ${CYAN}[2]${RST}    📊  Auditar Diretórios e Contagem de ROMs\n"
        printf "  ${CYAN}[3]${RST}    🛡️   Validar Integridade e Hashes SHA-1 de BIOS\n"
        printf "  ${CYAN}[4]${RST}    🎮  Auditar Emuladores e Configurações Instaladas\n"
        printf "  ${CYAN}[5]${RST}    📦  Instalar Emuladores (APT / Flatpak)\n"
        printf "  ${CYAN}[6]${RST}    🗑️   Limpar Configs Órfãs de Emuladores Removidos\n"
        printf "  ${DIM}────────────────────────────────────────────────${RST}\n"
        printf "  ${CYAN}[0]${RST}    ⬅️   Voltar ao Menu Principal\n\n"

        read -rp "  $(printf "${BOLD}")Selecione [0-6]:$(printf "${RST}") " r_menu

        case "${r_menu}" in
            1) retro_init_dirs "${DEFAULT_ROM_DIR}" ;;
            2) retro_check_dirs "${DEFAULT_ROM_DIR}" ;;
            3) retro_verify_bios "${DEFAULT_ROM_DIR}/bios" ;;
            4) retro_audit_emulators ;;
            5) retro_install_emulators ;;
            6) retro_clean_orphan_configs ;;
            0) break ;;
            *) _warn "Opção inválida no sub-menu." ;;
        esac

        printf "\n"
        read -rp "  Pressione [ENTER] para continuar..." _
    done
}
