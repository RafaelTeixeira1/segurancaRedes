# 🔰 Projeto Final — Segurança da Informação

**Diagnóstico e Mitigação de Vulnerabilidades em Laboratórios Educacionais**

**Curso:** Bacharelado em Sistemas de Informação (6º período)  
**Disciplina:** Segurança da Informação  
**Entrega:** 03/11/2025  
**Versão:** 1.0

---

## 🧭 Sumário

- Introdução e Propósito  
- Arquitetura e Estrutura do Projeto  
- Cenário Simulado  
- Vulnerabilidades Investigadas  
- Configuração e Preparação do Ambiente  
- Execução e Procedimentos  
- Análise Prática e Resultados  
- Documentos e Relatórios Complementares  
- Equipe Responsável  
- Aspectos Éticos e Conformidade  
- Direitos, Licença e Uso

---

## 🧩 Introdução e Propósito

Este projeto tem como foco a análise, demonstração e mitigação de vulnerabilidades reais encontradas em laboratórios de informática acadêmicos. A simulação reproduz um acesso indevido via SSH provocado por falhas humanas e técnicas, e demonstra boas práticas de *hardening* e governança.

**Objetivos principais:**

- Identificar falhas de configuração e comportamento inseguro de usuários;  
- Demonstrar ataques em ambiente controlado (máquinas virtuais isoladas);  
- Coletar evidências técnicas e elaborar relatório de auditoria;  
- Propor medidas de mitigação e políticas de segurança para ambientes educacionais.

---

## 🧱 Arquitetura e Estrutura do Projeto

```
segurancaRedes/
├── README.md                        # Documentação principal
├── scripts/                         # Scripts de ataque e mitigação
│   ├── nmap_enum.sh                 # Enumeração de portas/serviços
│   ├── ssh_bruteforce.sh            # Ataque SSH por força bruta
│   ├── simula_usb_and_execute.sh    # Execução via pendrive malicioso
│   ├── demo_web_unfiltered.sh       # Navegação sem filtragem
│   ├── create_restricted_user.sh    # Restrição de privilégios
│   ├── capture_ssh_traffic.sh       # Captura de tráfego SSH
│   └── coleta_evidencias.sh         # Coleta padronizada de evidências
├── wordlists/                       # Wordlists (minhaLista.txt)
├── evidencias/                      # Saídas dos experimentos (pcap, logs, hashes)
├── docs/                            # Relatórios e políticas
│   ├── RELATORIO_AUDITORIA.md
│   ├── politicas/POLITICA_SEGURANCA.md
│   └── diagramas/
```

---

## 💡 Cenário Simulado

Um aluno observou a senha SSH de um professor e a utilizou para acessar remotamente o sistema do docente. O cenário serve para demonstrar riscos humanos e técnicos em laboratórios compartilhados.

**Impactos observados:**

- Comprometimento da confidencialidade de dados docentes;  
- Alteração não autorizada de arquivos institucionais;  
- Exposição de falhas na política de autenticação;  
- Fragilidade do ambiente usado por múltiplos perfis.

---

## 🧨 Vulnerabilidades Investigadas

| ID  | Categoria              | Descrição                                            | Severidade | Script / Ferramenta                         |
|-----|------------------------|------------------------------------------------------|------------|---------------------------------------------|
| V#1 | Autenticação           | Senhas fracas e ausência de MFA em SSH               | Crítica    | `ssh_bruteforce.sh`                          |
| V#2 | Exposição de serviços  | Portas abertas e serviços desnecessários             | Alta       | `nmap_enum.sh`                               |
| V#3 | Privilégios            | Contas locais com privilégios indevidos              | Crítica    | `create_restricted_user.sh`                  |
| V#4 | Forense / Evidência    | Ausência de procedimentos de coleta de evidências    | Alta       | `coleta_evidencias.sh`                       |
| V#5 | Dispositivos removíveis| Execução automática via pendrive                      | Alta       | `simula_usb_and_execute.sh`                  |
| V#6 | Conteúdo não filtrado  | Acesso a sites sem filtragem (uso indevido)          | Média      | `demo_web_unfiltered.sh`                     |

---

## ⚙️ Configuração e Preparação do Ambiente

**Plataforma:** VirtualBox (recomendado) — ambientes isolados Host-Only / Internal Network.

**Topologia sugerida (Host-Only / labnet):**

| Função    | SO         | IP             | Usuário     | Senha      |
|-----------|------------|----------------|-------------|------------|
| Atacante  | Kali/Ubuntu|`192.168.56.100`| `kalilinux` | `kalilinux`|
| Vítima    | Linux Mint |`192.168.56.101`  | `linuxmint` | `linuxmint`|

> **Importante:** mantenha a rede isolada (sem rota para a Internet) durante os testes. Use um adaptador NAT **temporariamente** para instalar pacotes e remova-o depois.

### Instalação e dependências (ambas as VMs)

```bash
sudo apt update
sudo apt install -y nmap hydra sshpass tcpdump curl dosfstools git build-essential
```

### Clonagem do repositório

```bash
git clone https://github.com/<usuario>/segurancaRedes.git
cd segurancaRedes
chmod +x scripts/*.sh
```

### IP estático (exemplo — Netplan no Ubuntu/Mint)

Crie `/etc/netplan/01-lab.yaml`:

```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      addresses: [192.168.56.101/24]
      dhcp4: false
```

Aplique:

```bash
sudo netplan apply
```

---

## 🧪 Execução e Procedimentos

> Coloque todas as saídas em pastas de evidências com timestamp: `evidencias/2025-11-03_120000_acao/`

### V#1 — Ataque SSH por força bruta (exemplo)

```bash
# Na VM atacante
bash scripts/ssh_bruteforce.sh 192.168.56.101 linuxmint wordlists/minhaLista.txt evidencias
```

**Resultado esperado:** descoberta de senha fraca e autenticação indevida.

---

### V#2 — Enumeração de portas e serviços

```bash
# Na VM atacante
bash scripts/nmap_enum.sh 192.168.56.101 evidencias
```

**Resultado esperado:** lista de portas (ex.: 22) e serviços que podem ser vetores.

---

### V#3 — Pendrive malicioso (simulação)

```bash
# Na VM vítima
sudo bash scripts/simula_usb_and_execute.sh evidencias
```

**Resultado:** script foi executado automaticamente (simulação), demonstrando risco.

---

### V#4 — Navegação sem filtro

```bash
# Na VM atacante (ou vítima, dependendo do teste)
bash scripts/demo_web_unfiltered.sh http://example.com 30
```

**Resultado:** captura de tráfego web / páginas acessadas.

---

### V#5 — Restrição de privilégios (mitigação)

```bash
# Na VM vítima (após análise)
sudo bash scripts/create_restricted_user.sh novo_usuario
```

**Resultado:** usuário com shell restrito, sem sudo nem acesso a dispositivos removíveis.

---

### Coleta padronizada de evidências

```bash
# Na VM vítima (após o incidente)
sudo bash scripts/coleta_evidencias.sh evidencias
# Gera: cópias de /var/log/auth.log, sshd_config, inventário, checksums (SHA256)
```

**Boas práticas:** não alterar logs originais; copiar e calcular hashes; documentar cadeia de custódia.

---

## 📊 Análise Prática e Resultados

**Antes do hardening**

- SSH acessível por senha simples;  
- Múltiplos serviços desnecessários expostos;  
- Contas com privilégios excessivos;  
- Políticas de mídia removível e monitoramento ausentes.

**Após mitigação**

- Autenticação SSH reforçada (chaves + desabilitar `PasswordAuthentication`);  
- `fail2ban` implementado;  
- Serviços desnecessários desativados;  
- Privilégios revisados;  
- Política de uso de USB e bloqueio de execução automática.


---

## 🧾 Documentos e Relatórios Complementares

| Documento | Descrição |
|---|---|
| `docs/RELATORIO_AUDITORIA.md` | Relatório completo de auditoria e evidências forenses |
| `docs/politicas/POLITICA_SEGURANCA.md` | Política de uso e boas práticas laboratoriais |
| `docs/diagramas/rede.png` | Diagrama de rede e fluxo de ataque/mitigação |
| `apresentacao/SLIDES_APRESENTACAO.md` | Material para defesa e arguição |

---

## 👥 Equipe Responsável

| Nome | Função | Contribuição |
|---:|---|---|
| Rafael Teixeira | Estudante | Scripts, ambiente e evidências |
| Jhannyfer Biângulo | Estudante | Relatórios, mitigação e documentação |

---

## 🧩 Aspectos Éticos e Conformidade

Este trabalho foi desenvolvido em ambiente controlado com finalidade educacional. Demonstrações seguiram princípios de ética digital.

**Boas práticas adotadas:**

- Isolamento das VMs (Host-Only / Internal);  
- Senhas e dados substituídos por valores fictícios;  
- Nenhum sistema externo foi impactado.

**Aviso legal:** uso inadequado fora do ambiente controlado pode configurar crime previsto na Lei nº 12.737/2012 (Lei Carolina Dieckmann) e no Art. 154-A do Código Penal.

---

---

## 📅 Finalização

**Data de Conclusão (estimada):** Novembro/2025  
**Instituição:** Instituto Federal Goiano - Campus Ceres;  
**Professor Orientador:** Roitier Campos Goncalves

---

