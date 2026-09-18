#!/usr/bin/env bash
# Sambox 2 - Catálogo Isolado sob Demanda de Alvos de Cache Gamer
# Copyright (c) 2026, Sam Moreno. Licença BSD 2-Clause.

_get_cache_targets_catalog() {
    cat << EOF
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
