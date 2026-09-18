#!/usr/bin/env bash
# Sambox 2 - Módulo de Orquestração Wine, Proton & Low-Level Gaming
# Copyright (c) 2026, Sam Moreno. Licença BSD 2-Clause.

# Importa os analisadores estáticos sob demanda de forma segura
[[ -f "${MODULES_DIR}/m_wine_data.sh" ]] && source "${MODULES_DIR}/m_wine_data.sh"

get_primary_wine() {
    if [[ -n "${CUSTOM_WINE_BIN:-}" ]] && [[ -x "${CUSTOM_WINE_BIN}" ]]; then
        echo "${CUSTOM_WINE_BIN}"
        return 0
    fi

    local lines=()
    mapfile -t lines < <(detect_wine_binaries)
    if [[ ${#lines[@]} -gt 0 && -n "${lines[0]}" ]]; then
        local type path label
        IFS='|' read -r type path label <<< "${lines[0]}"
        echo "${path}"
        return 0
    fi
    return 1
}

build_env_vars() {
    local profile="${1:-maxfps}"
    declare -g -A WINE_ENV=()

    WINE_ENV["WINEDEBUG"]="-all"
    WINE_ENV["WINEESYNC"]="1"
    WINE_ENV["WINEFSYNC"]="$(check_fsync_support && echo "1" || echo "0")"
    WINE_ENV["DXVK_STATE_CACHE"]="1"
    WINE_ENV["DXVK_ASYNC"]="1"
    WINE_ENV["MESA_GL_THREAD_THROTTLE"]="0"
    WINE_ENV["__GL_THREADED_OPTIMIZATIONS"]="1"
    WINE_ENV["STAGING_SHARED_MEMORY"]="1"
    WINE_ENV["WINE_LARGE_ADDRESS_AWARE"]="1"

    case "${profile}" in
        maxfps|competitive) WINE_ENV["DXVK_HUD"]="0" ;;
        hud|benchmark)     WINE_ENV["DXVK_HUD"]="fps,gpuread,version,frametimes" ;;
        safe|compatibilidade)
            WINE_ENV["WINEESYNC"]="0"
            WINE_ENV["WINEFSYNC"]="0"
            WINE_ENV["DXVK_ASYNC"]="0"
            WINE_ENV["DXVK_HUD"]="0"
         ;;
    esac
}

launch_game_optimized() {
    local target_exe="" profile="maxfps" prefix="${WINEPREFIX:-${HOME}/.wine}"
    local dry_run=0 wine_bin="" extra_args=() p_opt=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --profile=*) profile="${1#*=}"; shift ;;
            --prefix=*)  prefix="${1#*=}"; shift ;;
            --wine=*)    wine_bin="${1#*=}"; shift ;;
            --dry-run)   dry_run=1; shift ;;
            --)          shift; extra_args+=("$@"); break ;;
            -*)          _err "Opção inválida: $1"; return 1 ;;
            *)           [[ -z "${target_exe}" ]] && target_exe="$1" || extra_args+=("$1"); shift ;;
        esac
    done

    if [[ -z "${target_exe}" ]]; then
        printf "\n${CYAN}${BOLD}==> LAUNCHER DE JOGOS OPTIMIZADO${RST}\n"
        read -e -rp "  $(printf "${BOLD}")Caminho do executável (.exe):$(printf "${RST}") " target_exe
        [[ -z "${target_exe}" ]] && { _warn "Nenhum arquivo informado."; return 0; }

        printf "  ${CYAN}[1]${RST} Max FPS (Sem HUD, latência mínima)\n"
        printf "  ${CYAN}[2]${RST} Benchmark HUD (FPS, GPU, Frametimes)\n"
        printf "  ${CYAN}[3]${RST} Modo Seguro (Compatibilidade)\n"
        read -rp "  $(printf "${BOLD}")Selecione o perfil [1-3] (Padrão 1):$(printf "${RST}") " p_opt
        [[ "${p_opt}" == "2" ]] && profile="hud"
        [[ "${p_opt}" == "3" ]] && profile="safe"
    fi

    [[ ! -f "${target_exe}" ]] && { _err "Arquivo executável não encontrado: '${target_exe}'"; return 1; }
    [[ -z "${wine_bin}" ]] && wine_bin="$(get_primary_wine || true)"
    [[ -z "${wine_bin}" || ! -x "${wine_bin}" ]] && { _err "Nenhum binário funcional do Wine localizado."; return 1; }

    build_env_vars "${profile}"

    local wrappers=()
    command -v gamemoderun >/dev/null 2>&1 && wrappers+=("$(command -v gamemoderun)")
    [[ "${profile}" == "hud" ]] && command -v mangohud >/dev/null 2>&1 && wrappers+=("$(command -v mangohud)")

    # Exporta dinamicamente o dicionário WINE_ENV montado
    local k=""
    for k in "${!WINE_ENV[@]}"; do
        export "${k}=${WINE_ENV[$k]}"
    done
    export WINEPREFIX="${prefix}"

    if [[ "${dry_run}" -eq 1 ]]; then
        _msg "Modo Dry-Run: Comando que seria disparado:"
        echo "    WINEPREFIX=${WINEPREFIX} ${wrappers[*]} ${wine_bin} ${target_exe} ${extra_args[*]}"
        return 0
    fi

    _msg "Disparando processo gamer bare-metal..."
    cd "$(dirname "${target_exe}")" || return 1
    ${wrappers[*]} "${wine_bin}" "$(basename "${target_exe}")" "${extra_args[@]}" &
    _msg "Processo enviado para segundo plano com sucesso! ツ"
}

menu_wine_central() {
    local w_menu=""
    while true; do
        clear 2>/dev/null
        printf "\n${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n"
        printf "  ║        🍷  CENTRAL WINE & LOW-LEVEL       ║\n"
        printf "  ╚═══════════════════════════════════════════╝${RST}\n\n"
        printf "  ${CYAN}[1]${RST}    🎮  Lançar Jogo Otimizado (.exe)\n"
        printf "  ${CYAN}[2]${RST}    🔍  Listar Runners Wine/Proton Detectados\n"
        printf "  ${DIM}────────────────────────────────────────────────${RST}\n"
        printf "  ${CYAN}[0]${RST}    ⬅️   Voltar ao Menu Principal\n\n"
        read -rp "  Selecione [0-2]: " w_menu
        case "$w_menu" in
            1) launch_game_optimized ;;
            2) printf "\n${YELLOW}[+] Runners localizados:${RST}\n"; detect_wine_binaries | sed 's/^/  • /' ;;
            0) break ;;
            *) _warn "Opção inválida." ;;
        esac
        printf "\n"; read -rp "  Pressione [ENTER] para continuar..." _
    done
}

register_sambox_module "⚙️   Orquestrador de Jogos Wine / Proton" "menu_wine_central"

