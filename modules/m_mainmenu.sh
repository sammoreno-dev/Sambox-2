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
    local choice="" target_func="" total_funcs=0 i=0

    while true; do
        _render_banner
        
        # Garante a leitura dinâmica e em tempo real do tamanho atual do barramento
        total_funcs=${#SAMBOX_MODULE_FUNCS[@]}

        if [[ ${total_funcs} -gt 0 ]]; then
            # Renderização sequencial e amarrada perfeitamente aos índices reais do vetor
            for ((i = 0; i < total_funcs; i++)); do
                printf "  ${CYAN}[%d]${RST}    %s\n" $((i + 1)) "${SAMBOX_MODULE_NAMES[i]}"
            done
        else
            _warn "Nenhum submódulo ativo indexado na memória." 2>/dev/null || printf "  [!] Sem módulos ativos.\n"
        fi

        printf "  ${DIM}─────────────────────────────────────────────────────────────────${RST}\n"
        printf "  ${CYAN}[0]${RST}    ⬅️   Sair do Sambox 2\n\n"

        read -rp "  $(printf "${BOLD}")Selecione a central [0-${total_funcs}]:$(printf "${RST}") " choice

        # Sanitização imediata de saída: se for 0, vazio ou espaço em branco, interrompe o laço
        [[ "${choice}" == "0" || -z "${choice}" || "${choice}" =~ ^[[:space:]]+$ ]] && {
            printf "\n  Até logo, amigo! Operação bare-metal finalizada.\n\n"
            break
        }

        # Validação matemática ultra-leve de entrada numérica segura dentro do escopo do catálogo
        if [[ "${choice}" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= total_funcs )); then
            # Mapeamento cirúrgico de índice baseado em zero para extração da função alvo
            target_func="${SAMBOX_MODULE_FUNCS[$(( choice - 1 ))]}"
            
            # Reflexão nativa do Bash para inspecionar se a função de fato existe na tabela de símbolos
            if declare -f "${target_func}" >/dev/null 2>&1; then
                # Execução direta em espaço de usuário (controle retorna pra cá após o break/exit do submódulo)
                ${target_func}
            else
                # Barramento resiliente de falhas passivas: impede o crash do motor mestre
                printf "\n  ${RED}[✗] Erro de barramento: A rotina '${target_func}' não responde em memória.${RST}\n"
                printf "      Verifique se o arquivo correspondente possui erros de sintaxe ou colchetes abertos.\n"
                printf "\n"; read -rp "  Pressione [ENTER] para depurar e continuar..." _
                continue
            fi
        else
            _warn "Opção inválida para o escopo do Sambox 2." 2>/dev/null || printf "  [!] Opção inválida.\n"
        fi
        
        printf "\n"; read -rp "  Pressione [ENTER] para continuar..." _
    done
}

