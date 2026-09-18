#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Sambox 2 - Módulo de Gerenciamento de ROMs, BIOS & Emuladores
# Copyright (c) 2026, Sam Moreno. All rights reserved.
# Distribuído sob os termos estáveis da licença BSD 2-Clause.
# -----------------------------------------------------------------------------

DEFAULT_ROM_DIR="${HOME}/RetroROMs"
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
    local target_dir="${1:-${DEFAULT_ROM_DIR}}" 
    local total_roms=0
    
    printf "\n${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n  ║     📊  AUDITORIA DE ARQUIVOS DE ROMs     ║\n  ╚═══════════════════════════════════════════╝${RST}\n\n"
    
    [[ ! -d "${target_dir}" ]] && _warn "Diretório base ausente: ${target_dir}" && return 0
    
    for sys in "${STANDARD_SYSTEMS[@]}"; do
        local dir="${target_dir}/${sys}"
        if [[ -d "${dir}" ]]; then
            local count
            count=$(find "${dir}" -maxdepth 1 -type f -printf '.' 2>/dev/null | wc -c | tr -d ' ')
            count=${count:-0}
            total_roms=$(( total_roms + count ))
            printf "  ${GREEN}[✓]${RST} %-16s : ${BOLD}%4d${RST} arquivos\n" "${sys}" "${count}"
        else
            printf "  ${YELLOW}[✗]${RST} %-16s : ${DIM}Diretório ausente${RST}\n" "${sys}"
        fi
    done
    _sep
    printf "  ${BOLD}Total de arquivos detectados:${RST} ${GREEN}%d${RST}\n" "${total_roms}"
}

# [3] Validar Integridade de BIOS via SHA-1
retro_verify_bios() {
    local bios_dir="${1:-${DEFAULT_ROM_DIR}/bios}" 
    local has_sha1=0
    
    printf "\n${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n  ║     🛡️   VALIDAÇÃO CRIPTOGRÁFICA DE BIOS   ║\n  ╚═══════════════════════════════════════════╝${RST}\n\n"
    
    [[ ! -d "${bios_dir}" ]] && _warn "Diretório de BIOS ausente: ${bios_dir}" && return 0
    command -v sha1sum >/dev/null 2>&1 && has_sha1=1
    
    printf "  ${BOLD}%-16s %-10s %-12s %s${RST}\n" "ARQUIVO" "SISTEMA" "STATUS" "INTEGRIDADE SHA-1"
    _sep
    
    for item in "${KNOWN_BIOS[@]}"; do
        local file sys desc exp_sha1
        IFS='|' read -r file sys desc exp_sha1 <<< "${item}"
        local fullpath="${bios_dir}/${file}"
        
        if [[ -f "${fullpath}" ]]; then
            local integrity
            if [[ ${has_sha1} -eq 1 ]]; then
                local current_sha1
                current_sha1=$(sha1sum "${fullpath}" 2>/dev/null | awk '{print $1}')
                if [[ "${current_sha1,,}" == "${exp_sha1,,}" ]]; then
                    integrity="${GREEN}VÁLIDO (Oficial)${RST}"
                else
                    integrity="${RED}CORROMPIDO${RST}"
                fi
            else
                integrity="${YELLOW}Hash ignorado (Falta sha1sum)${RST}"
            fi
            printf "  %-16s %-10s ${GREEN}%-12s${RST} %b\n" "${file}" "${sys}" "Presente" "${integrity}"
        else
            printf "  %-16s %-10s ${DIM}%-12s${RST} %b\n" "${file}" "${sys}" "Ausente" "${DIM}Requerido para ${sys}${RST}"
        fi
    done
}

# [4] Auditar Emuladores Instalados e Configurações
retro_audit_emulators() {
    printf "\n${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n  ║     🎮  EMULADORES & CONFIGURAÇÕES        ║\n  ╚═══════════════════════════════════════════╝${RST}\n\n"
    printf "  ${BOLD}%-14s %-16s %-18s %s${RST}\n" "EMULADOR" "STATUS" "CONFIGURAÇÃO" "CAMINHO DE CONFIG"
    _sep
    
    for emu in "${EMU_CATALOG[@]}"; do
        local name bin cfg_rel flpk status_info st_code st_txt cfg_dir dir_status="${DIM}Ausente${RST}"
        IFS='|' read -r name bin cfg_rel flpk <<< "$emu"
        IFS='|' read -r st_code st_txt <<< "$(_check_emu_status "$bin" "$flpk")"
        
        cfg_dir="${HOME}/${cfg_rel}"
        [[ "$st_code" == "2" ]] && cfg_dir="${HOME}/.var/app/${flpk}/config/${cfg_rel##*/}"
        [[ -d "$cfg_dir" ]] && dir_status="${GREEN}Configurado${RST}"
        
        # Correção da lógica de cores: remove o bloco condicional falho de dentro do printf
        local formatted_status
        if [[ $st_code -eq 0 ]]; then
            formatted_status="${DIM}${st_txt}${RST}"
        else
            formatted_status="${GREEN}${st_txt}${RST}"
        fi
        
        printf "  %-14s %-24b %-26b ${DIM}%s${RST}\n" "${name}" "${formatted_status}" "${dir_status}" "${cfg_dir}"
    done
}
