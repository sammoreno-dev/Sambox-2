#!/usr/bin/env bash
# Sambox 2 - Central Unificada de Limpeza e Purga de Caches Gamer
# Copyright (c) 2026, Sam Moreno. Licença BSD 2-Clause.

# Catálogo estrito de alvos de cache baseados no padrão XDG e estruturas conhecidas de jogos
CACHE_TARGETS=(
    "Mesa (AMD/Intel Shader Cache)|${HOME}/.cache/mesa_shader_cache"
    "NVIDIA GL Cache|${HOME}/.nv/GLCache"
    "NVIDIA Compute Cache|${HOME}/.nv/ComputeCache"
    "Steam Shader Pre-Cache|${HOME}/.steam/steam/steamapps/shadercache"
    "Wine/Proton Global Temp Dir|${HOME}/.wine/drive_c/users/${USER}/Temp"
)

cleanup_scan() {
    local purge_mode="$1" # 0 = Dry-Run, 1 = Purga Real
    local total_bytes=0 target_name target_path
    
    if [[ "${purge_mode}" -eq 1 ]]; then
        printf "\n${RED}${BOLD}[!] INICIANDO PURGA MOLECULAR PROFUNDA...${RST}\n\n"
    else
        printf "\n${CYAN}${BOLD}[🔍] INICIANDO VARREDURA ANALÍTICA VISUAL (DRY-RUN)...${RST}\n\n"
    fi

    printf "  ${BOLD}%-32s %-12s %s${RST}\n" "ALVO DE CACHE" "TAMANHO" "STATUS"
    _sep 2>/dev/null || printf "  ─────────────────────────────────────────────────────────────────\n"

    for target in "${CACHE_TARGETS[@]}"; do
        IFS='|' read -r target_name target_path <<< "${target}"
        
        if [[ -d "${target_path}" ]]; then
            # Calcula o tamanho do diretório em Bytes de forma extremamente leve via du
            local size_bytes
            size_bytes=$(du -sb "${target_path}" 2>/dev/null | awk '{print $1}')
            size_bytes=${size_bytes:-0}
            total_bytes=$(( total_bytes + size_bytes ))
            
            # Converte bytes para formato legível humanizado (MB) de forma puramente matemática no Bash
            local size_mb=$(( size_bytes / 1024 / 1024 ))
            
            if [[ "${purge_mode}" -eq 1 ]]; then
                # Purga cirúrgica: limpa o conteúdo sem deletar a pasta base do sistema
                find "${target_path}" -mindepth 1 -delete 2>/dev/null
                printf "  %-32s ${YELLOW}%4d MB${RST}   ${GREEN}[PURGADO]${RST}\n" "${target_name}" "${size_mb}"
            else
                printf "  %-32s ${CYAN}%4d MB${RST}   ${YELLOW}[Detectado]${RST}\n" "${target_name}" "${size_mb}"
            fi
        else
            printf "  %-32s ${DIM}%4s MB${RST}   ${DIM}[Ausente]${RST}\n" "${target_name}" "0"
        fi
    done

    local total_mb=$(( total_bytes / 1024 / 1024 ))
    _sep 2>/dev/null || printf "  ─────────────────────────────────────────────────────────────────\n"
    
    if [[ "${purge_mode}" -eq 1 ]]; then
        printf "  ${BOLD}Espaço bare-metal recuperado com sucesso:${RST} ${GREEN}%d MB${RST}\n" "${total_mb}"
    else
        printf "  ${BOLD}Total de lixo acumulado passível de debloat:${RST} ${YELLOW}%d MB${RST}\n" "${total_mb}"
    fi
}

menu_cleanup_central() {
    local c_opt=""
    while true; do
        clear 2>/dev/null || true
        printf "\n${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n"
        printf "  ║        🧹  CENTRAL DE LIMPEZA & DEBLOAT   ║\n"
        printf "  ╚═══════════════════════════════════════════╝${RST}\n\n"
        printf "  ${CYAN}[1]${RST}  🔍  Escanear Caches de Shaders & Temporários (Dry-Run)\n"
        printf "  ${CYAN}[2]${RST}  🔥  Purgar Caches Obsoletos & Liberar Espaço Bare-Metal\n"
        printf "  ${DIM}─────────────────────────────────────────────────────────────────${RST}\n"
        printf "  ${CYAN}[0]${RST}  ⬅️   Voltar ao Menu Principal\n\n"

        read -rp "  $(printf "${BOLD}")Selecione a ação de faxina [0-2]:$(printf "${RST}") " c_opt
        [[ "${c_opt}" == "0" || -z "${c_opt}" ]] && break

        # Corrigido: avalia diretamente c_opt impedindo vazamento de escopo global
        case "${c_opt}" in
            1) cleanup_scan 0 ;; # Apenas varredura analítica visual
            2) cleanup_scan 1 ;; # Purga física molecular profunda de caches
            *) _warn "Opção inválida para o barramento de debloat." 2>/dev/null || printf "  [!] Opção inválida.\n" ;;
        esac
        printf "\n"; read -rp "  Pressione [ENTER] para retornar ao painel de limpeza..." _
    done
}

# Auto-registro independente no motor mestre do Sambox 2
register_sambox_module "🧹  Cleanup & Debloat (Purga de Shaders e Caches)" "menu_cleanup_central"
