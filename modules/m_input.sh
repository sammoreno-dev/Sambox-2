#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Sambox 2 - Módulo de Diagnóstico de Controles, Gamepads & Input
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

# [1] Função para Inspecionar Permissões de Usuário e Grupos
input_check_permissions() {
    printf "\n${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n"
    printf "  ║     🛡️   PERMISSÕES DE ACESSO A INPUT      ║\n"
    printf "  ╚═══════════════════════════════════════════╝${RST}\n\n"

    local user groups_str
    user="$(whoami)"
    groups_str="$(id -Gn "${user}" 2>/dev/null || echo "")"

    printf "  ${BOLD}Usuário Atual:${RST}   %s\n" "${user}"
    printf "  ${BOLD}Grupos:${RST}          %s\n" "${groups_str}"

    if [[ " ${groups_str} " =~ [[:space:]]input[[:space:]] ]]; then
        printf "  ${BOLD}Grupo 'input':${RST}   ${GREEN}Membro ativo${RST}\n"
    else
        printf "  ${BOLD}Grupo 'input':${RST}   ${YELLOW}Não pertence${RST} (Recomenda-se: 'sudo usermod -aG input ${user}')\n"
    fi

    if [[ -d /dev/input ]]; then
        local readable_nodes=0
        local total_nodes=0
        for node in /dev/input/event* /dev/input/js*; do
            [[ -e "${node}" ]] || continue
            total_nodes=$(( total_nodes + 1 ))
            if [[ -r "${node}" ]]; then
                readable_nodes=$(( readable_nodes + 1 ))
            fi
        done
        printf "  ${BOLD}Nós de Entrada:${RST}  %d de %d acessíveis sem sudo\n" "${readable_nodes}" "${total_nodes}"
    else
        _err "Diretório /dev/input não localizado!"
    fi

    if [[ -e /dev/uinput ]]; then
        if [[ -w /dev/uinput ]]; then
            printf "  ${BOLD}/dev/uinput:${RST}     ${GREEN}Gravável${RST} (Emulação virtual de gamepads habilitada)\n"
        else
            printf "  ${BOLD}/dev/uinput:${RST}     ${DIM}Acesso restrito a root${RST}\n"
        fi
    fi
}

# [2] Função para Escanear Controles e Gamepads Conectados
input_list_devices() {
    printf "\n${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n"
    printf "  ║     🎮  CONTROLES E GAMEPADS DETECTADOS   ║\n"
    printf "  ╚═══════════════════════════════════════════╝${RST}\n\n"

    local dev_file="/proc/bus/input/devices"
    if [[ ! -f "${dev_file}" ]]; then
        _err "Interface do kernel ${dev_file} inacessível."
        return 1
    fi

    local name="" bus="" vendor="" product="" handlers="" phys=""
    local found=0

    while IFS= read -r line || [[ -n "${line}" ]]; do
        if [[ -z "${line}" ]]; then
            if [[ "${handlers}" =~ (js[0-9]+) ]] || [[ "${name,,}" =~ (gamepad|joystick|controller|pad|wheel|xbox|playstation|nintendo|dualshock|dualsense) ]]; then
                found=$(( found + 1 ))
                printf "  ${CYAN}[%d]${RST} ${BOLD}%s${RST}\n" "${found}" "${name:-Dispositivo Genérico}"
                printf "      ${DIM}Barramento:${RST} %s | ${DIM}Vendor:${RST} %s | ${DIM}Product:${RST} %s\n" "${bus}" "${vendor}" "${product}"
                printf "      ${DIM}Handlers:${RST}   ${GREEN}%s${RST}\n" "${handlers}"
                [[ -n "${phys}" ]] && printf "      ${DIM}Físico:${RST}     %s\n" "${phys}"
                printf "\n"
            fi
            name="" bus="" vendor="" product="" handlers="" phys=""
            continue
        fi

        case "${line}" in
            I:\ Bus=*)
                bus="$(echo "${line}" | awk -F'Bus=' '{print $2}' | awk '{print $1}')"
                vendor="$(echo "${line}" | awk -F'Vendor=' '{print $2}' | awk '{print $1}')"
                product="$(echo "${line}" | awk -F'Product=' '{print $2}' | awk '{print $1}')"
                ;;
            N:\ Name=*)
                name="$(echo "${line}" | sed 's/^N: Name="//;s/"$//')"
                ;;
            P:\ Phys=*)
                phys="$(echo "${line}" | sed 's/^P: Phys=//')"
                ;;
            H:\ Handlers=*)
                handlers="$(echo "${line}" | sed 's/^H: Handlers=//')"
                ;;
        esac
    done < "${dev_file}"

    if [[ ${found} -eq 0 ]]; then
        _warn "Nenhum controle dedicado detectado no momento."
        printf "  Conecte seu controle USB ou emparelhe via Bluetooth e repita a busca.\n\n"
    else
        _msg "Total de ${found} controle(s) de jogo conectado(s)."
    fi
}

# [3] Função para Testar Eventos do Controle em Tempo Real
input_test_device() {
    local target_node="${1:-}"

    if [[ -z "${target_node}" ]]; then
        for node in /dev/input/js* /dev/input/event*; do
            if [[ -r "${node}" ]]; then
                target_node="${node}"
                break
            fi
        done
    fi

    if [[ -z "${target_node}" || ! -e "${target_node}" ]]; then
        _err "Nenhum nó de controle detectado em /dev/input/."
        return 1
    fi

    if [[ ! -r "${target_node}" ]]; then
        _err "Sem permissão de leitura em '${target_node}'."
        printf "  Execute a opção [2] para auditar permissões de usuário.\n"
        return 1
    fi

    printf "\n${YELLOW}[+]${RST} ${BOLD}Iniciando monitoramento de eventos em:${RST} ${CYAN}%s${RST}\n" "${target_node}"
    printf "  Pressione botões ou movimente os analógicos. ${DIM}(Ctrl+C para encerrar)${RST}\n\n"

    if command -v evtest >/dev/null 2>&1; then
        evtest "${target_node}"
        return 0
    fi

    if [[ "${target_node}" =~ /dev/input/js ]] && command -v jstest >/dev/null 2>&1; then
        jstest --normal "${target_node}"
        return 0
    fi

    printf "${BLUE}[i]${RST} Leitor de fluxo bare-metal nativo ativo:\n"
    if command -v hexdump >/dev/null 2>&1; then
        hexdump -C "${target_node}"
    elif command -v od >/dev/null 2>&1; then
        od -tx1 -w16 "${target_node}"
    else
        local count=0
        while IFS= read -r -n 16 -d '' chunk 2>/dev/null; do
            count=$(( count + 1 ))
            printf "\r[EVENTO #%04d] Pacote de entrada recebido (%d bytes)" "${count}" "${#chunk}"
        done < "${target_node}"
        printf "\n"
    fi
}

# ── Despacho Direto via Linha de Comando (CLI) ─────────────────────────────
run_input_cli() {
    case "${1:-}" in
        list|devices) input_list_devices ;;
        perms|permissions) input_check_permissions ;;
        test|poll) shift; input_test_device "${1:-}" ;;
        *)
            echo "Uso: sambox2 --input [list|perms|test [no]]"
            ;;
    esac
}

# ── Função Orquestradora Principal do Módulo (Sempre no final) ──────────────
menu_input_central() {
    local i_menu
    while true; do
        clear 2>/dev/null || true
        printf "\n"
        printf "${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n"
        printf "  ║       🎮  CENTRAL HARDWARE & GAMEPADS     ║\n"
        printf "  ╚═══════════════════════════════════════════╝${RST}\n\n"
        printf "  ${CYAN}[1]${RST}    📋  Listar Controles e Gamepads Conectados\n"
        printf "  ${CYAN}[2]${RST}    🛡️   Auditar Permissões de Usuário (/dev/input & uinput)\n"
        printf "  ${CYAN}[3]${RST}    ⚡  Monitorar Eventos de Entrada em Tempo Real\n"
        printf "  ${DIM}────────────────────────────────────────────────${RST}\n"
        printf "  ${CYAN}[0]${RST}    ⬅️   Voltar ao Menu Principal\n\n"

        read -rp "  $(printf "${BOLD}")Selecione [0-3]:$(printf "${RST}") " i_menu

        case "${i_menu}" in
            1) input_list_devices ;;
            2) input_check_permissions ;;
            3)
                printf "\n"
                read -rp "  Informe o nó do controle [Vazio para auto-detectar]: " target_n
                input_test_device "${target_n}" || true
                ;;
            0) break ;;
            *) _warn "Opção inválida no sub-menu." ;;
        esac

        printf "\n"
        read -rp "  Pressione [ENTER] para continuar..." _
    done
}
