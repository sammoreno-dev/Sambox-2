# Sambox 2

![License](https://img.shields.io/badge/License-BSD%202--Clause-blue) ![Language](https://img.shields.io/badge/Language-Shell-green)

**Toolbox para gamers, administradores e entusiastas do minimalismo, feita 100% em Bash puro.**

Uma central modular, leve e de alta eficiência para orquestração de jogos (Wine/Proton), emulação retrô, calibração de controles e debloat cirúrgico de caches em sistemas Linux — desenvolvida sem amarras ideológicas e focada em performance bruta.

---

# 🏷️ Origem do Nome (Sambox 2)

O nome **Sambox** reflete a união entre autoria, utilidade prática e arquitetura limpa:

- **Sam:** A minha assinatura de propriedade técnica e minha responsabilidade como criador (**Sam** Moreno).
- **Box:** O conceito vem de uma caixa de ferramentas minimalista e cirúrgica (*Tool**box***), projetada para atuar como uma central de controle ou painel de controle enxuto, sem o inchaço (*bloatware*) e os atritos que poluem os utilitários e launchers do mercado.
- **2:** A evolução natural voltada para alto rendimento em jogos, emulação sem firulas e extração da máxima performance do hardware bare-metal.

---

## ⚙️ Filosofia do Sambox 2

- **Bash Puro:** Sem Python, C++, ou interpretadores externos redundantes.
- **Zero Dependências de Interface:** Apenas comandos internos do Bash (`builtins`) + utilitários POSIX fundamentais (`grep`, `awk`, `sed`, `cat`, `lspci`, `tput`). Zero dependência de `zenity`, `yad`, `whiptail`, `dialog` ou interfaces gráficas (GUI).
- **Universalidade CLI/TUI:** Interface limpa e minimalista renderizada via códigos de escape ANSI nativos e `tput`. Funciona instantaneamente em qualquer terminal mínimo, console tty ou sessão remota via SSH.
- **Arquitetura Modular:** Cada funcionalidade reside em seu próprio módulo isolado (`modules/m_*.sh`), carregado dinamicamente via `source` na inicialização do motor.
- **Performance Gamer Sem Frescura:** Ajuste cirúrgico de variáveis de sincronização de baixo nível (ESYNC, FSYNC, futex2), otimizações DXVK e eliminação de telemetria desnecessária.

---

## 🚀 Instalação & Uso

Clone o repositório e configure as permissões de execução do motor principal:

```bash
git clone https://github.com/sammoreno-dev/Sambox-2.git && cd Sambox-2 && chmod +x sambox2 modules/*.sh
```

Execute a ferramenta diretamente:

```bash
./sambox2
```

## Opcional: Instalação no Sistema

Para invocar o Sambox 2 de qualquer lugar do terminal, crie um link simplificado no seu `$PATH`:

```bash
sudo ln -s "$(pwd)/sambox2" /usr/local/bin/sambox2
sambox2
```

---

## 📦 Módulos Disponíveis

| **Contexto**         | **Arquivo**            | **Função Principal**   | **Descrição**                                                                                                                                                                                                           |
| -------------------- | ---------------------- | ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Wine/Proton**      | `modules/m_wine.sh`    | `menu_wine_central`    | Orquestrador de alto desempenho para aplicações e jogos Windows: injeção dinâmica de ESYNC, FSYNC (kernel futex2), DXVK_ASYNC, isolamento de WINEPREFIX, diagnóstico de drivers e execução com GameMode/MangoHud.       |
| **Retro/Emulação**   | `modules/m_retro.sh`   | `menu_retro_central`   | Central de emulação: padronização e estruturação automatizada de diretórios de ROMs (17 consoles), auditoria de emuladores instalados e verificação criptográfica de integridade de arquivos de BIOS via SHA-1.         |
| **Hardware/Input**   | `modules/m_input.sh`   | `menu_input_central`   | Central de diagnósticos de gamepads e controles USB/Bluetooth: enumeração precisa via `/proc/bus/input/devices`, auditoria de permissões de `/dev/input` e teste de eventos em tempo real com leitor bare-metal nativo. |
| **Clean-up/Debloat** | `modules/m_cleanup.sh` | `menu_cleanup_central` | Purga cirúrgica de caches inflados: detecção e eliminação segura de caches de shaders da GPU (Mesa, NVIDIA, DXVK), diretórios temporários do Wine e pre-caches pesados da Steam (com suporte a modo Dry-Run).           |
| **Manual**           | `modules/m_manual.sh`  | `menu_manual`          | Manual técnico e guia de consulta rápida integrado ao terminal: documentação de variáveis de ambiente de alto rendimento, atalhos de execução CLI e boas práticas de arquitetura.                                       |

### (Nota: Launchers pesados, interfaces em Electron devoradoras de RAM e telemetria invasiva foram cirurgicamente banidos do Sambox 2. Aqui é só terminal, leveza e velocidade pura).

---

## 📂 Estrutura do Projeto:

```
Sambox-2/
├── sambox2                 # Entry-point principal (Orquestrador modular)
├── modules/
│   ├── m_wine.sh           # Central de jogos Wine/Proton e sintonia de ENV
│   ├── m_retro.sh          # Central de ROMs, verificação de BIOS e emuladores
│   ├── m_input.sh          # Diagnóstico de gamepads e monitoramento de eventos
│   ├── m_cleanup.sh        # Limpeza e debloat de shader caches e arquivos temporários
│   ├── m_manual.sh         # Manual interativo e guia técnico do Sambox 2
│   └── template.sh         # Blueprint para criação de novos módulos
├── LICENSE                 # Termos da licença BSD-2-Clause
└── README.md               # Este arquivo de documentação
```

---

## 🛠️ Requisitos Mínimos:

> **Interpretador: Bash** >= 4.0 (O Sambox 2 roda em qualquer "batata eletrônica", console portátil como Steam Deck, ou máquina gamer de ponta, consumindo quase zero de RAM).

> **Utilitários:** Ferramentas POSIX padrão do ecossistema Linux (`grep`, `awk`, `sed`, `cat`, `lspci`, `tput`, `find`).

> **Terminal:** Suporte a codificação UTF-8 (para renderização correta de caixas de texto e símbolos) e cores ANSI.

> **Privilégios:** Acesso de usuário normal para a grande maioria das tarefas. Privilégios de superusuário (`sudo`) são requeridos exclusivamente para ajuste de permissões de nós de input ou links em `/usr/local/bin`.

---

## ⚖️ Licença

Distribuído sob os termos estáveis da **BSD 2-Clause License (Simplified)** — veja o arquivo [LICENSE](LICENSE) para detalhes técnicos. Uma licença pacífica, pragmática, comercialmente livre e sem atritos ou policiamentos ideológicos.

Copyright (c) 2026, Sam Moreno. Todos os direitos reservados.
