#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Sambox 2 - Módulo de Limpeza, Shaders Cache & Debloat Gaming
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

# ── Helper Interno: Lista de Alvos de Caches e Arquivos Transitórios ─────────
get_cache_targets() {
    cat <<EOF
mesa|Cache de Shaders Mesa (AMD/Intel)|${HOME}/.cache/mesa_shader_cache
nvidia|Cache OpenGL NVIDIA|${HOME}/.nv/GLCache
nvidia|Cache Compute NVIDIA|${HOME}/.nv/ComputeCache
steam|Cache Nativo de Shaders Steam|${HOME}/.local/share/Steam/steamapps/shadercache
steam|Cache Alternativo Steam|${HOME}/.steam/steam/steamapps/shadercache
steam|Cache Flatpak Steam|${HOME}/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/shadercache
wine|Temporários do Wine (Windows)|${HOME}/.wine/drive_c/windows/temp
wine|Temporários do Usuário Wine|${HOME}/.wine/drive_c/users/${USER}/AppData/Local/Temp
lutris|Cache do Lutris|${HOME}/.cache/lutris
heroic|Cache do Heroic Games Launcher|${HOME}/.config/heroic/store_cache
EOF
}

format_bytes() {
    local b="${1:-0}"
    awk -v bytes="${b}" 'BEGIN {
        split("B KB MB GB TB", units, " ");
        idx = 1;
        val = bytes;
        while (val >= 1024 && idx < 5) {
            val /= 1024;
            idx++;
        }
        if (idx == 1) {
            printf "%d %s", val, units[idx];
        } else {
            printf "%.2f %s", val, units[idx];
        }
    }'
}

get_path_size_bytes() {
    local path="$1"
    if [[ -d "${path}" || -f "${path}" ]]; then
        du -sb "${path}" 2>/dev/null | awk '{print $1}' || echo 0
    else
        echo 0
    fi
}

# [1] Função para Escanear Caches de Shaders e Arquivos Transitórios (Dry-Run)
cleanup_scan() {
    printf "\n${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n"
    printf "  ║     🔍  VARREDURA DE SHADERS & CACHES     ║\n"
    printf "  ╚═══════════════════════════════════════════╝${RST}\n\n"

    printf "  ${BOLD}%-38s %-12s %s${RST}\n" "ALVO DE CACHE" "TAMANHO" "STATUS"
    _sep

    local total_bytes=0
    local found_count=0

    while IFS='|' read -r type label path; do
        [[ -n "${path}" ]] || continue

        if [[ -e "${path}" ]]; then
            local bytes
            bytes="$(get_path_size_bytes "${path}")"
            total_bytes=$(( total_bytes + bytes ))
            found_count=$(( found_count + 1 ))
            local readable
            readable="$(format_bytes "${bytes}")"

            printf "  %-38s ${YELLOW}%-12s${RST} ${GREEN}Presente${RST} ${DIM}(%s)${RST}\n" \
                "${label}" "${readable}" "${path}"
        else
            printf "  %-38s ${DIM}%-12s Ausente${RST}\n" \
                "${label}" "0 B"
        fi
    done < <(get_cache_targets)

    # Varredura de caches de pipeline DXVK em pastas de jogos
    local dxvk_bytes=0
    local dxvk_files=()
    while IFS= read -r f; do
        [[ -f "${f}" ]] || continue
        dxvk_files+=("${f}")
        local b
        b="$(get_path_size_bytes "${f}")"
        dxvk_bytes=$(( dxvk_bytes + b ))
    done < <(find "${HOME}/.wine" -name "*.dxvk-cache" -type f 2>/dev/null || true)

    if [[ ${#dxvk_files[@]} -gt 0 ]]; then
        total_bytes=$(( total_bytes + dxvk_bytes ))
        found_count=$(( found_count + ${#dxvk_files[@]} ))
        printf "  %-38s ${YELLOW}%-12s${RST} ${GREEN}%d arquivos localizados${RST}\n" \
            "Caches de Estado DXVK (*.dxvk-cache)" "$(format_bytes "${dxvk_bytes}")" "${#dxvk_files[@]}"
    fi

    _sep
    local total_formatted
    total_formatted="$(format_bytes "${total_bytes}")"
    printf "  ${BOLD}Espaço em Disco Recuperável:${RST} ${GREEN}${BOLD}%s${RST} em %d local(is)\n\n" \
        "${total_formatted}" "${found_count}"

    CLEANUP_TOTAL_BYTES="${total_bytes}"
}

# [2] Função para Purgar Caches de Shaders e Debloat Gaming
purge_gaming_bloat() {
    local force=0
    if [[ "${1:-}" == "--force" || "${1:-}" == "-f" || "${1:-}" == "-y" ]]; then
        force=1
    fi

    cleanup_scan
    local total_bytes="${CLEANUP_TOTAL_BYTES:-0}"

    if [[ "${total_bytes}" -eq 0 ]]; then
        _msg "Os caches de jogos e shaders já estão limpos. Nada a remover."
        return 0
    fi

    if [[ "${force}" -ne 1 ]]; then
        printf "${YELLOW}[?]${RST} Confirmar a exclusão dos caches listados acima? [s/N]: "
        local confirm=""
        read -r confirm || true
        if [[ ! "${confirm}" =~ ^[SsYy]$ ]]; then
            _warn "Operação cancelada pelo usuário."
            return 0
        fi
    fi

    printf "\n${RED}[+]${RST} ${BOLD}Iniciando purga cirúrgica de caches de shaders...${RST}\n"

    while IFS='|' read -r type label path; do
        [[ -n "${path}" ]] || continue

        if [[ -e "${path}" ]]; then
            printf "    ${DIM}• Limpando:${RST} %s...\n" "${label}"
            if [[ -d "${path}" ]]; then
                rm -rf "${path:?}"/* 2>/dev/null || true
            else
                rm -f "${path}" 2>/dev/null || true
            fi
        fi
    done < <(get_cache_targets)

    while IFS= read -r f; do
        [[ -f "${f}" ]] || continue
        rm -f "${f}" 2>/dev/null || true
    done < <(find "${HOME}/.wine" -name "*.dxvk-cache" -type f 2>/dev/null || true)

    _msg "Caches de shaders da GPU e temporários purgados com sucesso!"
}

# ── Despacho Direto via Linha de Comando (CLI) ─────────────────────────────
run_cleanup_cli() {
    case "${1:-}" in
        scan|--dry-run|dry-run) cleanup_scan ;;
        purge|clean) shift; purge_gaming_bloat "$@" ;;
        *)
            echo "Uso: sambox2 --clean [scan|purge [--force]]"
            ;;
    esac
}

# ── Função Orquestradora Principal do Módulo (Sempre no final) ──────────────
menu_cleanup_central() {
    local c_menu
    while true; do
        clear 2>/dev/null || true
        printf "\n"
        printf "${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n"
        printf "  ║       🧹  CENTRAL DE LIMPEZA & DEBLOAT    ║\n"
        printf "  ╚═══════════════════════════════════════════╝${RST}\n\n"
        printf "  ${CYAN}[1]${RST}    🔍  Escanear Caches de Shaders (Modo Dry-Run)\n"
        printf "  ${CYAN}[2]${RST}    ⚡  Purgar Shaders, DXVK State & Temporários do Wine\n"
        printf "  ${DIM}────────────────────────────────────────────────${RST}\n"
        printf "  ${CYAN}[0]${RST}    ⬅️   Voltar ao Menu Principal\n\n"

        read -rp "  $(printf "${BOLD}")Selecione [0-2]:$(printf "${RST}") " c_menu

        case "${c_menu}" in
            1) cleanup_scan ;;
            2) purge_gaming_bloat ;;
            0) break ;;
            *) _warn "Opção inválida no sub-menu." ;;
        esac

        printf "\n"
        read -rp "  Pressione [ENTER] para continuar..." _
    done
}
