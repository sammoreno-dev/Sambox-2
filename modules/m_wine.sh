#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Sambox 2 - Módulo de Orquestração Wine, Proton & Low-Level Gaming
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

# ── Helper Interno: Habilitação de Arquitetura 32-bits (i386) ───────────────
_ensure_i386_arch() {
    if ! dpkg --print-foreign-architectures 2>/dev/null | grep -q "i386"; then
        printf "${YELLOW}[+]${RST} Registrando arquitetura i386 no dpkg...\n"
        sudo dpkg --add-architecture i386
        sudo apt-get update -y
    fi
}

# ── Helper Interno: Checagem de Sincronização FSYNC (Kernel Futex2) ────────
check_fsync_support() {
    local kver major minor
    kver="$(uname -r 2>/dev/null || echo "0.0")"
    major="$(echo "${kver}" | cut -d. -f1)"
    minor="$(echo "${kver}" | cut -d. -f2 | cut -d- -f1)"

    if [[ "${major}" -gt 5 ]] || [[ "${major}" -eq 5 && "${minor}" -ge 16 ]]; then
        return 0
    fi

    if [[ -c /dev/ntsync ]] || [[ -c /dev/winesync ]]; then
        return 0
    fi

    return 1
}

# ── Helper Interno: Detecção Automática de Runners Wine e Proton ───────────
detect_wine_binaries() {
    local found=()

    # 1. Wine Nativo do Sistema
    if command -v wine >/dev/null 2>&1; then
        local wpath wver
        wpath="$(command -v wine)"
        wver="$("${wpath}" --version 2>/dev/null || echo "desconhecido")"
        found+=("system|${wpath}|Wine do Sistema (${wver})")
    fi

    # 2. Localizações Conhecidas do Valve Proton & Lutris
    local proton_dirs=(
        "${HOME}/.steam/root/compatibilitytools.d"
        "${HOME}/.local/share/Steam/compatibilitytools.d"
        "${HOME}/.local/share/Steam/steamapps/common"
        "${HOME}/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d"
        "${HOME}/.var/app/com.valvesoftware.Steam/data/Steam/steamapps/common"
        "${HOME}/.local/share/lutris/runners/wine"
        "${HOME}/.config/heroic/tools/wine"
        "${HOME}/.config/heroic/tools/proton"
    )

    local prev_nullglob
    prev_nullglob="$(shopt -p nullglob || true)"
    shopt -s nullglob

    for pdir in "${proton_dirs[@]}"; do
        [[ -d "${pdir}" ]] || continue
        for wine_exe in "${pdir}"/*/dist/bin/wine "${pdir}"/*/bin/wine "${pdir}"/*/files/bin/wine; do
            if [[ -x "${wine_exe}" ]]; then
                local label
                label="$(basename "$(dirname "$(dirname "${wine_exe}")")")"
                found+=("custom|${wine_exe}|${label}")
            fi
        done
    done
    ${prev_nullglob}

    printf "%s\n" "${found[@]}"
}

get_primary_wine() {
    if [[ -n "${CUSTOM_WINE_BIN:-}" ]] && [[ -x "${CUSTOM_WINE_BIN}" ]]; then
        echo "${CUSTOM_WINE_BIN}"
        return 0
    fi

    local lines
    mapfile -t lines < <(detect_wine_binaries)
    if [[ ${#lines[@]} -gt 0 && -n "${lines[0]}" ]]; then
        local type path label
        IFS='|' read -r type path label <<< "${lines[0]}"
        echo "${path}"
        return 0
    fi

    return 1
}

# ── Helper Interno: Geração Dinâmica de Variáveis de Ambiente Otimizadas ───
build_env_vars() {
    local profile="${1:-maxfps}"
    declare -g -A WINE_ENV=()

    WINE_ENV["WINEDEBUG"]="-all"
    WINE_ENV["WINEESYNC"]="1"

    if check_fsync_support; then
        WINE_ENV["WINEFSYNC"]="1"
    else
        WINE_ENV["WINEFSYNC"]="0"
    fi

    WINE_ENV["DXVK_STATE_CACHE"]="1"
    WINE_ENV["DXVK_ASYNC"]="1"
    WINE_ENV["MESA_GL_THREAD_THROTTLE"]="0"
    WINE_ENV["__GL_THREADED_OPTIMIZATIONS"]="1"
    WINE_ENV["STAGING_SHARED_MEMORY"]="1"
    WINE_ENV["WINE_LARGE_ADDRESS_AWARE"]="1"

    case "${profile}" in
        maxfps|competitive)
            WINE_ENV["DXVK_HUD"]="0"
            ;;
        hud|benchmark)
            WINE_ENV["DXVK_HUD"]="fps,gpuread,version,frametimes"
            ;;
        safe|compatibilidade)
            WINE_ENV["WINEESYNC"]="0"
            WINE_ENV["WINEFSYNC"]="0"
            WINE_ENV["DXVK_ASYNC"]="0"
            WINE_ENV["DXVK_HUD"]="0"
            ;;
        *)
            _warn "Perfil desconhecido '${profile}'. Aplicando 'maxfps'."
            WINE_ENV["DXVK_HUD"]="0"
            ;;
    esac
}

# [1] Função para Executar Jogo/App com Variáveis Tuning
launch_game_optimized() {
    local target_exe=""
    local profile="maxfps"
    local prefix="${WINEPREFIX:-${HOME}/.wine}"
    local dry_run=0
    local wine_bin=""
    local extra_args=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --profile=*)
                profile="${1#*=}"
                shift
                ;;
            --prefix=*)
                prefix="${1#*=}"
                shift
                ;;
            --wine=*)
                wine_bin="${1#*=}"
                shift
                ;;
            --dry-run)
                dry_run=1
                shift
                ;;
            --)
                shift
                extra_args+=("$@")
                break
                ;;
            -*)
                _err "Opção inválida: $1"
                return 1
                ;;
            *)
                if [[ -z "${target_exe}" ]]; then
                    target_exe="$1"
                else
                    extra_args+=("$1")
                fi
                shift
                ;;
        esac
    done

    if [[ -z "${target_exe}" ]]; then
        printf "\n${CYAN}${BOLD}==> LAUNCHER DE JOGOS OPTIMIZADO${RST}\n"
        read -e -rp "  $(printf "${BOLD}")Caminho do executável (.exe):$(printf "${RST}") " target_exe
        [[ -z "${target_exe}" ]] && { _warn "Nenhum arquivo informado."; return 0; }

        printf "  ${CYAN}[1]${RST} Max FPS (Sem HUD, latência mínima)\n"
        printf "  ${CYAN}[2]${RST} Benchmark HUD (FPS, GPU, Frametimes)\n"
        printf "  ${CYAN}[3]${RST} Modo Seguro (Compatibilidade)\n"
        local p_opt
        read -rp "  $(printf "${BOLD}")Selecione o perfil [1-3] (Padrão 1):$(printf "${RST}") " p_opt
        [[ "${p_opt}" == "2" ]] && profile="hud"
        [[ "${p_opt}" == "3" ]] && profile="safe"
    fi

    if [[ ! -f "${target_exe}" ]]; then
        _err "Arquivo executável não encontrado: '${target_exe}'"
        return 1
    fi

    if [[ -z "${wine_bin}" ]]; then
        wine_bin="$(get_primary_wine || true)"
    fi

    if [[ -z "${wine_bin}" || ! -x "${wine_bin}" ]]; then
        _err "Nenhum binário funcional do Wine localizado. Instale o Wine ou aponte via --wine="
        return 1
    fi

    build_env_vars "${profile}"

    local wrappers=()
    if command -v gamemoderun >/dev/null 2>&1; then
        wrappers+=("$(command -v gamemoderun)")
    fi
    if [[ "${profile}" == "hud" ]] && command -v mangohud >/dev/null 2>&1; then
        wrappers+=("$(command -v mangohud)")
    fi

    printf "\n${BLUE}[=]${RST} ${BOLD}Ambiente Preparado:${RST}\n"
    printf "    • Binário Alvo : ${CYAN}%s${RST}\n" "${target_exe}"
    printf "    • Runner Wine  : ${GREEN}%s${RST}\n" "${wine_bin}"
    printf "    • WINEPREFIX   : %s\n" "${prefix}"
    printf "    • Perfil Gaming: ${YELLOW}%s${RST}\n" "${profile}"
    printf "    • Sincronização: ESYNC=%s | FSYNC=%s | DXVK_ASYNC=%s\n" \
        "${WINE_ENV[WINEESYNC]}" "${WINE_ENV[WINEFSYNC]}" "${WINE_ENV[DXVK_ASYNC]}"
    [[ ${#wrappers[@]} -gt 0 ]] && printf "    • Wrappers     : %s\n" "${wrappers[*]}"

    if [[ ${dry_run} -eq 1 ]]; then
        _msg "Modo Dry-run concluído com sucesso."
        return 0
    fi

    export WINEPREFIX="${prefix}"
    for k in "${!WINE_ENV[@]}"; do
        export "${k}=${WINE_ENV[${k}]}"
    done

    local game_dir exe_name
    game_dir="$(cd "$(dirname "${target_exe}")" && pwd -P)"
    exe_name="$(basename "${target_exe}")"

    printf "\n${GREEN}[+]${RST} Disparando aplicação via Wine...\n\n"
    (
        cd "${game_dir}"
        "${wrappers[@]}" "${wine_bin}" "${exe_name}" "${extra_args[@]}"
    )
}

# [2] Função de Diagnóstico do Wine e Sincronização do Kernel
wine_diagnostic() {
    printf "\n${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n"
    printf "  ║     🔍  DIAGNÓSTICO WINE & SUBSISTEMA     ║\n"
    printf "  ╚═══════════════════════════════════════════╝${RST}\n\n"

    local kver
    kver="$(uname -r)"
    printf "  ${BOLD}Kernel Linux:${RST}        %s\n" "${kver}"

    if check_fsync_support; then
        printf "  ${BOLD}FSYNC (Futex2):${RST}       ${GREEN}Suportado${RST} (Sincronização nativa do kernel)\n"
    else
        printf "  ${BOLD}FSYNC (Futex2):${RST}       ${YELLOW}Não Suportado${RST} (Fallback ativo para ESYNC)\n"
    fi

    printf "\n  ${BOLD}Instalações Wine / Proton Localizadas:${RST}\n"
    local count=0
    while IFS='|' read -r type path label; do
        [[ -n "${path}" ]] || continue
        printf "    ${CYAN}•${RST} %-30s ${DIM}(%s)${RST}\n" "${label}" "${path}"
        count=$(( count + 1 ))
    done < <(detect_wine_binaries)

    if [[ ${count} -eq 0 ]]; then
        printf "    ${RED}Nenhum binário do Wine ou Proton localizado no sistema!${RST}\n"
    fi

    printf "\n  ${BOLD}Otimizadores de Performance:${RST}\n"
    if command -v gamemoderun >/dev/null 2>&1; then
        printf "    ${CYAN}•${RST} GameMode:   ${GREEN}Presente${RST} (%s)\n" "$(command -v gamemoderun)"
    else
        printf "    ${CYAN}•${RST} GameMode:   ${DIM}Não Instalado${RST}\n"
    fi

    if command -v mangohud >/dev/null 2>&1; then
        printf "    ${CYAN}•${RST} MangoHud:   ${GREEN}Presente${RST} (%s)\n" "$(command -v mangohud)"
    else
        printf "    ${CYAN}•${RST} MangoHud:   ${DIM}Não Instalado${RST}\n"
    fi

    local prefix="${WINEPREFIX:-${HOME}/.wine}"
    printf "\n  ${BOLD}WINEPREFIX Atual:${RST}    %s" "${prefix}"
    if [[ -d "${prefix}" ]]; then
        printf " ${GREEN}[Presente]${RST}\n"
    else
        printf " ${YELLOW}[Não Inicializado]${RST}\n"
    fi
}

# [3] Função para Configurar WINEPREFIX (winecfg)
wine_configure_prefix() {
    local prefix="${1:-${WINEPREFIX:-${HOME}/.wine}}"
    local wine_bin
    wine_bin="$(get_primary_wine || true)"

    if [[ -z "${wine_bin}" ]]; then
        _err "Wine não encontrado no sistema."
        return 1
    fi

    printf "\n${YELLOW}[+]${RST} Abrindo painel winecfg para: ${CYAN}%s${RST}...\n" "${prefix}"
    export WINEPREFIX="${prefix}"
    "${wine_bin}" winecfg
}

# [4] Função para Matar Processos do Wine Pendurados
wine_kill_server() {
    local wine_bin
    wine_bin="$(get_primary_wine || true)"

    if [[ -n "${wine_bin}" ]]; then
        local wineserver_bin
        wineserver_bin="$(dirname "${wine_bin}")/wineserver"
        [[ ! -x "${wineserver_bin}" ]] && wineserver_bin="$(command -v wineserver || true)"

        if [[ -n "${wineserver_bin}" && -x "${wineserver_bin}" ]]; then
            printf "${YELLOW}[+]${RST} Finalizando instâncias do wineserver (-k)...\n"
            "${wineserver_bin}" -k 2>/dev/null || true
            _msg "wineserver finalizado com sucesso."
            return 0
        fi
    fi

    printf "${YELLOW}[+]${RST} Encerrando processos do Wine diretamente...\n"
    pkill -9 -f "wine" 2>/dev/null || true
    _msg "Processos Wine encerrados."
}

# [5] Instalação Limpa do Wine via APT
install_wine_clean() {
    _ensure_i386_arch
    printf "${YELLOW}[+]${RST} Instalando Wine estável e bibliotecas 32-bit essenciais via APT...\n"
    sudo apt-get install -y wine wine32 wine64 libwine libwine:i386
    _msg "Ambiente Wine nativo estruturado com sucesso."
}

# ── Despacho Direto via Linha de Comando (CLI) ─────────────────────────────
run_wine_cli() {
    case "${1:-}" in
        diag|status) wine_diagnostic ;;
        launch) shift; launch_game_optimized "$@" ;;
        config|cfg|winecfg) shift; wine_configure_prefix "${1:-}" ;;
        kill|stop) wine_kill_server ;;
        install) install_wine_clean ;;
        *)
            echo "Uso: sambox2 --wine [diag|launch <exe>|config|kill|install]"
            ;;
    esac
}

# ── Função Orquestradora Principal do Módulo (Sempre no final) ──────────────
menu_wine_central() {
    local w_menu
    while true; do
        clear 2>/dev/null || true
        printf "\n"
        printf "${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n"
        printf "  ║          🍷  CENTRAL WINE & PROTON        ║\n"
        printf "  ╚═══════════════════════════════════════════╝${RST}\n\n"
        printf "  ${CYAN}[1]${RST}    🚀  Executar Jogo Windows (.exe) com Tuning Máximo\n"
        printf "  ${CYAN}[2]${RST}    🔍  Diagnóstico do Wine, Proton e Sincronização (FSYNC)\n"
        printf "  ${CYAN}[3]${RST}    ⚙️   Configurar WINEPREFIX (winecfg)\n"
        printf "  ${CYAN}[4]${RST}    💀  Encerrar Processos Travados (wineserver -k)\n"
        printf "  ${CYAN}[5]${RST}    📦  Instalar Wine Limpo e Dependências (APT i386)\n"
        printf "  ${DIM}────────────────────────────────────────────────${RST}\n"
        printf "  ${CYAN}[0]${RST}    ⬅️   Voltar ao Menu Principal\n\n"

        read -rp "  $(printf "${BOLD}")Selecione [0-5]:$(printf "${RST}") " w_menu

        case "${w_menu}" in
            1) launch_game_optimized ;;
            2) wine_diagnostic ;;
            3) wine_configure_prefix ;;
            4) wine_kill_server ;;
            5) install_wine_clean ;;
            0) break ;;
            *) _warn "Opção inválida no sub-menu." ;;
        esac

        printf "\n"
        read -rp "  Pressione [ENTER] para continuar..." _
    done
}
# Cole isso na última linha do arquivo:
register_sambox_module "⚙️   Orquestrador de Jogos Wine / Proton" "menu_wine_central"
