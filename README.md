# 🔥 🛡️ Laboratório de Vulnerabilidades em Rede (VMs + Scripts)  

:triangular_flag_on_post: **Aviso:** Este repositório é para uso em ambiente controlado e rede isolada.


Projeto prático para a disciplina **Segurança da Informação** (6º período). Este repositório demonstra um cenário com duas VMs em rede isolada (atacante e vítima), exploração de vulnerabilidades (ex.: senha fraca/SSH), coleta de evidências, e hardening. Contém instruções passo a passo para criar as VMs, configurar a rede, executar os scripts e gerar os artefatos exigidos no trabalho.

> **Alerta ético/legal:** todo o conteúdo é destinado a **ambiente controlado** e **rede isolada**. Não execute fora do laboratório.

---

## 📚 Sumário
- [Arquitetura do laboratório](#arquitetura-do-laboratório)
- [Pré‑requisitos](#pré-requisitos)
- [Topologia e Rede Isolada](#topologia-e-rede-isolada)
- [Criação das VMs (VirtualBox)](#criação-das-vms-virtualbox)
  - [VM Vítima](#vm-vítima)
  - [VM Atacante](#vm-atacante)
  - [IPs estáticos](#ips-estáticos)
  - [Notas importantes](#notas-importantes)
- [Provisionamento das VMs](#provisionamento-das-vms)
- [Scripts e Execução](#scripts-e-execução)
  - [1) Enumeração de Rede — `nmap_enum.sh`](#1-enumeração-de-rede--nmap_enumsh)
  - [2) Ataque SSH (bruteforce) — `ssh_bruteforce.sh` e `ssh_try_sequential.sh`](#2-ataque-ssh-bruteforce--ssh_bruteforcesh-e-ssh_try_sequentialsh)
  - [3) Captura de Tráfego SSH — `capture_ssh_traffic.sh`](#3-captura-de-tráfego-ssh--capture_ssh_trafficsh)
  - [4) Coleta de Evidências — `coleta_evidencias.sh`](#4-coleta-de-evidências--coleta_evidenciassh)
  - [5) Simulação de USB e Execução — `simula_usb_and_execute.sh`](#5-simulação-de-usb-e-execução--simula_usb_and_executesh)
- [Padrão de Evidências e Reprodutibilidade](#padrão-de-evidências-e-reprodutibilidade)
- [Hardening (mitigações)](#hardening-mitigações)
- [Estrutura do Repositório](#estrutura-do-repositório)
- [Modelos de Documentos (docs/)](#modelos-de-documentos-docs)
- [FAQ / Troubleshooting](#faq--troubleshooting)
- [Licença](#licença)

---

## Arquitetura do laboratório

```
┌────────────────────┐        Rede Isolada (Host-Only/Internal)
│  VM Atacante       │        Sub-rede: 192.168.56.0/24
│  (Kali/Ubuntu)     │  ─────────────── vboxnet1 / "labnet" ───────────────▶  (Sem acesso à Internet)
│  IP: 192.168.56.10 │
└────────────────────┘                                             
┌────────────────────┐
│  VM Vítima         │
│  (Ubuntu/Mint)     │
│  IP: 192.168.56.23 │
└────────────────────┘
```

- **Isolamento**: a rede do laboratório **não** deve ter rota para a Internet.
- **Objetivo**: demonstrar exploração de vulnerabilidades (ex.: senha fraca via SSH) e posterior **hardening** (chaves SSH, MFA, fail2ban, etc.).

## Pré‑requisitos

- VirtualBox 7.x (ou equivalente)
- ISOs das distribuições desejadas (ex.: Ubuntu/Mint p/ vítima; Kali/Ubuntu p/ atacante)
- 30–40 GB livres de disco; 8 GB RAM (recomendado)
- Acesso de administrador no host

## Topologia e Rede Isolada

Escolha **um** modo de rede VirtualBox para **isolar** o laboratório:

1. **Host‑Only (recomendado)**
   - Crie/adapte a interface `vboxnet1` com faixa `192.168.56.0/24`.
   - As VMs comunicam entre si e com o host, **sem** Internet.
2. **Internal Network** (nome sugerido: `labnet`)
   - Comunicação **apenas** entre VMs no mesmo rótulo de rede interna.

> Para baixar pacotes em instalação/provisionamento, use **temporariamente** um segundo adaptador `NAT` e **desative** após a configuração.

### Criando/adaptando a `vboxnet1` (opcional)

```bash
# Em sistemas com VBoxManage disponível
VBoxManage hostonlyif create || true
VBoxManage hostonlyif ipconfig vboxnet1 --ip 192.168.56.1 --netmask 255.255.255.0
```

## Criação das VMs (VirtualBox)

### VM Vítima
- **Nome**: `vitima`
- **SO**: Ubuntu/Mint 64‑bit
- **CPU/RAM**: 2 vCPUs / 2–4 GB RAM
- **Disco**: 40 GB (dinâmico)
- **Rede**:
  - Adaptador 1: **Host‑Only** (`vboxnet1`) ou **Internal Network** (`labnet`)
  - (Opcional) Adaptador 2: **NAT** apenas para instalação de pacotes (remover ao final)
- **Serviços**: OpenSSH Server instalado

### VM Atacante
- **Nome**: `atacante`
- **SO**: Kali Linux/Ubuntu 64‑bit
- **CPU/RAM**: 2 vCPUs / 2–4 GB RAM
- **Disco**: 40 GB
- **Rede**: Idêntica à vítima (Host‑Only/Internal Network) + NAT temporário se necessário
- **Ferramentas**: `nmap`, `hydra`, `tcpdump`, `wireshark-cli`, `netcat`, etc.

### IPs estáticos

Configure IPs **estáticos** nas VMs (exemplo para `192.168.56.0/24`):

- Atacante: `192.168.56.10/24`, gateway vazio, DNS vazio
- Vítima: `192.168.56.23/24`, gateway vazio, DNS vazio

> Em Ubuntu/Mint (Netplan), arquivo típico em `/etc/netplan/01-lab.yaml`:
```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      addresses: [192.168.56.23/24]
      dhcp4: false
```

### Notas importantes
- **Erro de virtualização/KVM** em hosts Linux: certifique-se de que **somente o VirtualBox** use VT‑x/AMD‑V; desative módulos KVM no host antes de iniciar as VMs se necessário.
- Mantenha snapshots: `base` (antes da exploração), `explotado`, `hardened`.

## Provisionamento das VMs

Copie os scripts deste repositório para cada VM e torne executáveis:

```bash
chmod +x attacker_provision.sh victim_provision.sh
```

### Vítima
Na VM **vítima**:
```bash
sudo ./victim_provision.sh
# Confirme que o SSH está ativo e (intencionalmente) com configurações frágeis para o cenário inicial.
```

### Atacante
Na VM **atacante**:
```bash
sudo ./attacker_provision.sh
# Instala ferramentas necessárias (nmap, hydra, tcpdump etc.)
```

> Reaplique provisionamento quando restaurar snapshots ou trocar adaptadores de rede.

## 🧰 Scripts e Execução

> Todos os scripts devem estar com `chmod +x` e, quando necessário, executados com `sudo`.

### 1) 🔎 Enumeração de Rede — `nmap_enum.sh`

**Objetivo:** descobrir hosts, portas e serviços na sub-rede do laboratório.

Uso típico (na VM **atacante**):
```bash
./nmap_enum.sh 192.168.56.0/24 /home/$(whoami)/evidencias
```
Saídas esperadas: relatórios `nmap_*.txt` em `/home/<user>/evidencias`.

### 2) 🧨 Ataque SSH (bruteforce) — `ssh_bruteforce.sh` e `ssh_try_sequential.sh`

**Objetivo:** demonstrar risco de **senhas fracas**.

Crie/valide a wordlist (ex.: `minhaLista.txt` neste repo ou sua lista em `~/wordlists/passwords_mylist.txt`).

Execução (na VM **atacante**):
```bash
# Hydra (paralelo):
./ssh_bruteforce.sh 192.168.56.23 usuario_da_vitima /home/$(whoami)/wordlists/minhaLista.txt /home/$(whoami)/evidencias 4

# Sequencial (script simples):
./ssh_try_sequential.sh 192.168.56.23 usuario_da_vitima /home/$(whoami)/wordlists/minhaLista.txt /home/$(whoami)/evidencias 5
```
Saídas esperadas: logs/relatórios com tentativas e (se houver) credenciais válidas.

> **Dica:** ajuste `TIMEOUT`, threads (Hydra) e duração de captura para não sobrecarregar a VM vítima.

### 3) 🕵️ Captura de Tráfego SSH — `capture_ssh_traffic.sh`

**Objetivo:** registrar tráfego da sessão SSH (metadados) enquanto ocorrem ataques/autenticações para fins de evidência.

Uso:
```bash
sudo ./capture_ssh_traffic.sh enp0s3 60 /home/$(whoami)/evidencias
# Captura pcap de 60s; ajuste a interface conforme a VM (ex.: enp0s3)
```
Saída: `web_capture_*.pcap` ou `ssh_capture_*.pcap` em evidências.

### 4) 📁 Coleta de Evidências — `coleta_evidencias.sh`

**Objetivo:** padronizar a **cadeia de custódia**: coletar logs (`auth.log`), configs SSH (`/etc/ssh/sshd_config`), permissões, usuários, etc., de forma **não-destrutiva**.

Na VM **vítima** (pós-ataque):
```bash
sudo ./coleta_evidencias.sh /home/$(whoami)/evidencias
```
Saídas: diretório com timestamp contendo cópias de logs, checksums e inventário do sistema.

### 5) 💾 Simulação de USB e Execução — `simula_usb_and_execute.sh`

**Objetivo:** simular introdução de mídia removível e execução automática de binário/script para demonstrar risco de políticas frágeis de mídia removível.

Uso (na **vítima**):
```bash
sudo ./simula_usb_and_execute.sh /home/$(whoami)/evidencias
```
Saídas: evidências e logs de execução simulada.

## Padrão de Evidências e Reprodutibilidade

- Nomeie pastas de evidência com **timestamp**: `evidencias/AAAA-MM-DD_HHMMSS_acao`.
- Gere **hashes (SHA256)** para arquivos de interesse.
- Exporte relatórios (`.txt`, `.pcap`, `.log`) e mantenha um `README_EVIDENCIAS.md` dentro de cada pasta explicando **quando**, **como** e **por quê** foram coletadas.
- **Snapshots**: mantenha `base`, `explorado` e `hardened` para repetibilidade.

## Hardening (mitigações)

Após comprovar a exploração, aplique mitigação na **vítima**:

- SSH: desativar `PasswordAuthentication yes` → usar **chaves**; considerar **MFA** (PAM/Authenticator)
- Senhas: política de complexidade + expiração
- Bloqueios: `fail2ban`/`pam_tally2` para tentativas
- Privilégios: remover `sudo` indevido; aplicar **least privilege**
- Atualizações: manter sistema e pacotes atualizados
- Permissões: remover **world-writable** em diretórios sensíveis
- USB: bloquear automount e execução automática (udev/políticas)

> Re-execute os testes para comprovar que as vulnerabilidades foram mitigadas.

## Estrutura do Repositório

```
.
├── scripts/
│   ├── attacker_provision.sh
│   ├── victim_provision.sh
│   ├── nmap_enum.sh
│   ├── ssh_bruteforce.sh
│   ├── ssh_try_sequential.sh
│   ├── capture_ssh_traffic.sh
│   └── coleta_evidencias.sh
├── wordlists/
│   └── minhaLista.txt
├── evidencias/              # (gerado em execução)
├── docs/
│   ├── Relatorio_Auditoria_Forense.md
│   ├── Plano_Politicas.md
│   ├── Treinamento_Professores.md
│   ├── Treinamento_Alunos.md
│   └── Apresentacao.md
└── README.md
```

## FAQ / Troubleshooting

- **Sem conectividade entre VMs**: verifique se ambas estão na **mesma rede** Host‑Only/Internal, e se os IPs estão no **mesmo /24**.
- **Não consegue instalar pacotes**: habilite temporariamente Adaptador 2: **NAT**; depois **remova** para manter o isolamento.
- **Erro de virtualização (KVM/VMX)**: em hosts Linux, descarregue módulos `kvm_intel`/`kvm_amd` antes de usar VirtualBox.
- **Hydra lento**: reduza threads, aumente TIMEOUT ou use o modo sequencial para logs mais legíveis.

## Licença

Uso acadêmico/educacional. Ajuste conforme a política da instituição.
