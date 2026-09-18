#!/usr/bin/env bash
# Sambox 2 - Central Unificada de Limpeza e Purga de Caches Gamer
# Copyright (c) 2026, Sam Moreno. Licença BSD 2-Clause.

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

        case "${c_choice:-$c_opt}" in
            1) cleanup_scan 0 ;; # Apenas varredura analítica visual
            2) cleanup_scan 1 ;; # Purga física molecular profunda de caches
            *) _warn "Opção inválida para o barramento de debloat." ;;
        esac
        printf "\n"; read -rp "  Pressione [ENTER] para retornar ao painel de limpeza..." _
    done
}

# Auto-registro independente no motor mestre do Sambox 2
register_sambox_module "🧹  Cleanup & Debloat (Purga de Shaders e Caches)" "menu_cleanup_central"
