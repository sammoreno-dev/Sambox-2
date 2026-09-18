#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Sambox 2 - Módulo Modelo (Blueprint para Novos Módulos)
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

# [1] Função de Demonstração
template_sample_action() {
    printf "\n${YELLOW}[+]${RST} Executando rotina de exemplo...\n"
    _msg "Ambiente nominal e validado com sucesso."
}

# ── Despacho Direto via Linha de Comando (CLI) ─────────────────────────────
run_template_cli() {
    case "${1:-}" in
        action) template_sample_action ;;
        *) echo "Uso: sambox2 --template [action]" ;;
    esac
}

# ── Função Orquestradora Principal do Módulo (Sempre no final) ──────────────
menu_template_central() {
    local t_menu
    while true; do
        clear 2>/dev/null || true
        printf "\n"
        printf "${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n"
        printf "  ║          🛠️   MÓDULO DE EXEMPLO           ║\n"
        printf "  ╚═══════════════════════════════════════════╝${RST}\n\n"
        printf "  ${CYAN}[1]${RST}    ⚡  Executar Ação Demonstrativa\n"
        printf "  ${DIM}────────────────────────────────────────────────${RST}\n"
        printf "  ${CYAN}[0]${RST}    ⬅️   Voltar ao Menu Principal\n\n"

        read -rp "  $(printf "${BOLD}")Selecione [0-1]:$(printf "${RST}") " t_menu

        case "${t_menu}" in
            1) template_sample_action ;;
            0) break ;;
            *) _warn "Opção inválida no sub-menu." ;;
        esac

        printf "\n"
        read -rp "  Pressione [ENTER] para continuar..." _
    done
}
