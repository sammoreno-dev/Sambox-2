#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Sambox 2 - Módulo do Manual de Instruções e Dicas de Uso
# Copyright (c) 2026, Sam Moreno. Todos os direitos reservados.
# Distribuído sob os termos estáveis da licença BSD 2-Clause.
# -----------------------------------------------------------------------------

menu_manual_central() {
    clear 2>/dev/null || true
    printf "\n"
    printf "${CYAN}${BOLD}  ╔═══════════════════════════════════════════╗\n"
    printf "  ║     📖  MANUAL DE INSTRUÇÕES & DICAS       ║\n"
    printf "  ╚═══════════════════════════════════════════╝${RST}\n\n"
    
    printf "  ${BOLD}1. Filosofia de Design Minimalista${RST}\n"
    printf "     O Sambox 2 opera de forma 100%% bare-metal e em Bash puro.\n"
    printf "     Evitamos interpretadores pesados para extrair performance máxima.\n\n"
    
    printf "  ${BOLD}2. Ajustes de Ambiente para Gamers (Wine/Proton)${RST}\n"
    printf "     Nossos módulos injetam variáveis de sincronização de forma cirúrgica\n"
    printf "     como ESYNC e FSYNC para baratear chamadas de sistema no kernel.\n\n"
    
    printf "  ${BOLD}3. Gerenciamento de Emulação Híbrida${RST}\n"
    printf "     Casos complexos de dependências de ponta (como RPCS3 e Ryujinx)\n"
    printf "     são encapsulados e limpos através de contêineres Flatpak nativos.\n"
    
    printf "  ${DIM}─────────────────────────────────────────────────────────────────${RST}\n"
    printf "  ${YELLOW}[i]${RST} Pressione qualquer tecla para sair do manual e voltar à TUI.\n"
}

# Auto-registro vivo: Adiciona a opção correta à mesa do motor dinâmico
register_sambox_module "📖  Manual de Instruções do Sambox 2" "menu_manual_central"
