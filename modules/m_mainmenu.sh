#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Sambox 2 - Submódulo Isolado de Interface Visual e Navegação Principal
# Copyright (c) 2026, Sam Moreno. Todos os direitos reservados.
# Distribuído sob os termos estáveis da licença BSD 2-Clause.
# -----------------------------------------------------------------------------

_render_banner() {
    clear 2>/dev/null || true
    printf "\n"
    printf "${CYAN}${BOLD}  ██████╗  █████╗ ███╗   ███╗██████╗  ██████╗ ██╗  ██╗██████╗ \n"
    printf "  ██╔════╝ ██╔══██╗████╗ ████║██╔══██╗██╔═══██╗╚██╗██╔╝╚════██╗\n"
    printf "  ███████╗ ███████║██╔████╔██║██████╔╝██║   ██║ ╚███╔╝  █████╔╝\n"
    printf "  ╚════██║ ██╔══██║██║╚██╔╝██║██╔══██╗██║   ██║ ██╔██╗ ██╔═══╝ \n"
    printf "  ███████║ ██║  ██║██║ ╚═╝ ██║██████╔╝╚██████╔╝██╔╝ ██╗███████╗\n"
    printf "  ╚══════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝${RST}\n"
    printf "        ${DIM}Toolbox Gamer Minimalista • 100%% Bash Puro • v2.0${RST}\n\n"
}

menu_principal_tui() {
    local choice="" idx=1 target_func="" total_funcs=0

    while true; do
        _render_banner
        total_funcs=${#SAMBOX_MODULE_FUNCS[@]}

        if [[ ${total_funcs} -gt 0 ]]; then
            idx=1
            for i in "${!SAMBOX_MODULE_NAMES[@]}"; do
                printf "  ${CYAN}[%d]${RST}    %s\n" "${idx}" "${SAMBOX_MODULE_NAMES[$i]}"
                idx=$(( idx + 1 ))
            done
        else
            _warn "Nenhum submódulo ativo indexado na memória."
        fi

        printf "  ${DIM}─────────────────────────────────────────────────────────────────${RST}\n"
        printf "  ${CYAN}[0]${RST}    ⬅️   Sair do Sambox 2\n\n"

        read -rp "  $(printf "${BOLD}")Selecione a central [0-${total_funcs}]:$(printf "${RST}") " choice

        [[ "${choice}" == "0" || -z "${choice}" ]] && { printf "\n  Até logo!\n\n"; break; }

        if [[ "${choice}" =~ ^[1-9][0-9]*$ ]] && (( choice <= total_funcs )); then
            target_func="${SAMBOX_MODULE_FUNCS[$(( choice - 1 ))]}"
            if declare -f "${target_func}" >/dev/null 2>&1; then
                # Executa a função. Quando ela terminar de rodar, o controle volta para cá.
                ${target_func}
            else
                # CORREÇÃO CRÍTICA: Remove o '_err' e printa o erro de forma passiva.
                # Isso impede que o motor feche e retém o usuário na interface do Sambox 2!
                printf "\n  ${RED}[✗] Erro de barramento: A rotina '${target_func}' não responde em memória.${RST}\n"
                printf "      Verifique se o arquivo correspondente possui erros de sintaxe ou colchetes abertos.\n"
            fi
        else
            _warn "Opção inválida."
        fi
        printf "\n"; read -rp "  Pressione [ENTER] para continuar..." _
    done
}

