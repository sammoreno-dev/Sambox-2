#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Sambox 2 - Motor Isolado de Rastreamento Bare-Metal de Joysticks
# Copyright (c) 2026, Sam Moreno. Todos os direitos reservados.
# Distribuído sob os termos estáveis da licença BSD 2-Clause.
# -----------------------------------------------------------------------------

input_check_permissions() {
    printf "\n${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n"
    printf "  ║     🛡️   PERMISSÕES DE ACESSO A INPUT      ║\n"
    printf "  ╚═══════════════════════════════════════════╝${RST}\n\n"

    # Consome as variáveis de memória nativas do Bash de forma extremamente veloz
    local current_user="${USER:-$(whoami)}"
    local groups_str="" node="" readable_nodes=0 total_nodes=0
    groups_str="$(id -Gn "${current_user}" 2>/dev/null || echo "")"

    printf "  ${BOLD}Jogador Atual:${RST}   %s\n" "${current_user}"
    printf "  ${BOLD}Grupos Locais:${RST}   %s\n" "${groups_str}"

    _sep
    if [[ " ${groups_str} " =~ [[:space:]]input[[:space:]] ]]; then
        printf "  • ${BOLD}Grupo 'input':${RST}   ${GREEN}Membro ativo! Acesso direto liberado. ツ${RST}\n"
    else
        _warn "Seu usuário não pertence ao grupo 'input'."
        printf "        Dica Gamer: Execute '${BOLD}sudo usermod -aG input ${current_user}${RST}' para mapear gamepads sem root.\n"
    fi

    if [[ -d /dev/input ]]; then
        # Varredura defensiva rápida baseada em expansão de caminhos
        for node in /dev/input/event* /dev/input/js*; do
            [[ -e "${node}" ]] || continue
            total_nodes=$(( total_nodes + 1 ))
            [[ -r "${node}" ]] && readable_nodes=$(( readable_nodes + 1 ))
        done
        printf "  • ${BOLD}Nós de Entrada:${RST}  %d de %d barramentos acessíveis em espaço de usuário\n" "${readable_nodes}" "${total_nodes}"
    else
        _err "Diretório vital /dev/input não foi localizado no sistema hospedeiro!"
    fi

    if [[ -e /dev/uinput ]]; then
        if [[ -w /dev/uinput ]]; then
            printf "  • ${BOLD}/dev/uinput:${RST}     ${GREEN}Gravável${RST} (Emulação virtual de gamepads e driver pronta! 🚀)\n"
        else
            printf "  • ${BOLD}/dev/uinput:${RST}     ${DIM}Acesso restrito a root (MangoHud/Steam Input podem limitar)${RST}\n"
        fi
    fi
    printf "\n  ${GREEN}[✓] Auditoria de privilégios de input finalizada! (ツ)${RST}\n"
}

input_list_devices() {
    printf "\n${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n"
    printf "  ║     🎮  CONTROLES E GAMEPADS DETECTADOS   ║\n"
    printf "  ╚═══════════════════════════════════════════╝${RST}\n\n"

    local dev_file="/proc/bus/input/devices"
    if [[ ! -f "${dev_file}" ]]; then
        _err "Interface direta do kernel ${dev_file} inacessível."
        return 1
    fi

    printf "    ${DIM}Escaneando o barramento do kernel e aplicando filtros moleculares... 🔬${RST}\n\n"
    
    # Proteção de escopo local: impede quebra de memória global ou corrupção no Hot-Reload
    local line="" name="" handlers="" is_gamepad=0 count=0

    # Função auxiliar interna para renderizar o dispositivo e evitar repetição de código
    _print_device_if_valid() {
        if [[ ${is_gamepad} -eq 1 && -n "${name}" ]]; then
            count=$(( count + 1 ))
            printf "  ${CYAN}[Controle #%d]${RST} ${BOLD}%s${RST}\n" "${count}" "${name}"
            printf "                 ${DIM}Barramentos lógicos atribuídos: [ %s ]${RST}\n\n" "${handlers}"
        fi
    }

    # Laço blindado: O '|| [[ -n "${line}" ]]' garante a leitura do último bloco caso o arquivo não tenha linha vazia no fim
    while IFS= read -r line || [[ -n "${line}" ]]; do
        # Captura o nome comercial de forma robusta e inicializa string segura
        if [[ "${line}" =~ ^N:[[:space:]]*Name=\"(.*)\" ]]; then
            name="${BASH_REMATCH[1]:-}"
        fi
        
        # Captura os nós lógicos assinalados (eventos/js)
        if [[ "${line}" =~ ^H:[[:space:]]*Handlers=(.*) ]]; then
            handlers="${BASH_REMATCH[1]:-}"
            
            # FILTRO SELETIVO: Valida subsistema 'js' ou padrões conhecidos de controles
            if [[ "${handlers}" =~ js[0-9] ]] || [[ "${name,,}" =~ (pad|joystick|controller|gamepad|wheel|xbox|dualshock|dualsense|nintendo) ]]; then
                is_gamepad=1
            fi
            
            # FILTRO DE EXPURGO: Remove falsos positivos comuns do barramento de hardware
            if [[ "${name,,}" =~ (button|speaker|hdmi|mic|line|headphone|mouse|keyboard) ]]; then
                is_gamepad=0
            fi
        fi
        
        # Fim da ficha do dispositivo (linha em branco do /proc)
        if [[ -z "${line}" ]]; then
            _print_device_if_valid
            # Reseta os gatilhos garantindo compatibilidade estrita com o set -u do Sambox 2
            is_gamepad=0; name=""; handlers=""
        fi
    done < "${dev_file}"

    # Dispara uma checagem extra final para o último dispositivo (proteção contra arquivos truncados)
    _print_device_if_valid

    _sep
    if [[ ${count} -gt 0 ]]; then
        _msg "Escaneamento de barramentos concluído! Encontrado(s): ${BOLD}${count}${RST} dispositivo(s) gamer ativo(s). ツ"
    else
        _warn "Nenhum controle físico ou emulado foi localizado no barramento do kernel atual."
        printf "        Dica: Ligue o Bluetooth ou espete o cabo USB do seu joystick e dê um Hot-Reload! 🎮\n"
    fi
}

menu_input_central() {
    local i_menu=""
    while true; do
        clear 2>/dev/null || true
        printf "\n${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n"
        printf "  ║       🎮  CENTRAL DE INPUTS & GAMEPADS    ║\n"
        printf "  ╚═══════════════════════════════════════════╝${RST}\n\n"
        printf "  ${CYAN}[1]${RST}  🛡️   Auditar Permissões e Nós (/dev/input)\n"
        printf "  ${CYAN}[2]${RST}  🎮  Listar Controles Ativos no Kernel\n"
        printf "  ${DIM}─────────────────────────────────────────────────────────────────${RST}\n"
        printf "  ${CYAN}[0]${RST}  ⬅️   Voltar ao Menu Principal\n\n"

        read -rp "  Selecione a ação [0-2]: " i_menu
        [[ "${i_menu}" == "0" || -z "${i_menu}" ]] && break

        case "${i_menu}" in
            1) input_check_permissions ;;
            2) input_list_devices ;;
            *) _warn "Opção inválida para a central de inputs." ;;
        esac
        printf "\n"; read -rp "  Pressione [ENTER] para continuar..." _
    done
}

# Auto-registro independente no barramento de módulos do Sambox 2
register_sambox_module "🎮  Input & Gamepads (Diagnóstico de Controles e Permissões)" "menu_input_central"

