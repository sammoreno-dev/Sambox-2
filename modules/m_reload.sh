#!/usr/bin/env bash
# Sambox 2 - Submódulo Dedicado a Hot-Reload de Ambiente
# Copyright (c) 2026, Sam Moreno. Licença BSD 2-Clause.

exec_hot_reload() {
    printf "\n  ${YELLOW}[+] Resetando barramento e re-escaneando 'modules/'...${RST}\n"
    
    # Limpa as tabelas do motor principal
    SAMBOX_MODULE_NAMES=()
    SAMBOX_MODULE_FUNCS=()
    
    # Re-executa o loop de carregamento do arquivo mestre
    if [[ -d "${MODULES_DIR}" ]]; then
        for module in "${MODULES_DIR}"/m_*.sh; do
            local mod_name="${module##*/}"
            # Evita loops infinitos ignorando o menu e o próprio reload
            [[ -f "${module}" && "${mod_name}" != "m_main_menu.sh" && "${mod_name}" != "m_reload.sh" ]] && source "${module}"
        done
    fi
    
    _msg "Módulos recarregados com sucesso a quente!"
    sleep 1
}

# Auto-registro: Ele injeta a si mesmo como uma opção comum no menu!
register_sambox_module "🔄  Recarregar Módulos (Hot-Reload)" "exec_hot_reload"
