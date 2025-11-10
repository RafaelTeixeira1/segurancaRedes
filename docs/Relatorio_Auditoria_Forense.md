# 🧾 Relatório de Auditoria e Análise Forense

## 🕵️‍♂️ Introdução
Relatório referente à auditoria e análise forense realizadas nas máquinas:
- **Atacante (Kali Linux)** — 192.168.56.100  
- **Vítima (Linux Mint Vulnerável)** — 192.168.56.101  
- **Vítima Hardened (Linux Mint Segura)** — 192.168.56.102  

## ⚙️ Metodologia
1. **Mapeamento** — `enumerar_rede.sh`, `explorar_vulnerabilidades.sh`  
2. **Ataques controlados** — `ssh_bruteforce.sh`  
3. **Análise forense** — `coleta_evidencias.sh`

## 📁 Evidências Coletadas
Evidências armazenadas em `/home/kalilinux/Desktop/segurancaRedes/evidencias`, incluindo:
- `/var/log/auth.log`
- Metadados de arquivos alterados
- Histórico de comandos

## 🧩 Principais Vulnerabilidades
| Vulnerabilidade | Impacto | Evidência |
|------------------|----------|-----------|
| Senhas fracas e repetidas | Alta | 03_SSH_BRUTEFORCE_*.log |
| Usuário com privilégios administrativos | Alta | sudoers_conf.txt |
| Diretórios world-writable | Média | world_writable_dirs.txt |
| Falta de patching | Média | apt_list_outdated.txt |

## 🧰 Medidas de Mitigação
- Políticas de senha forte;  
- Restrição de privilégios administrativos;  
- Atualizações automáticas semanais;  
- Autenticação SSH via chave pública.

## 📜 Conclusão
O ambiente vulnerável comprovou seu papel didático, e a versão “hardened” apresentou mitigação eficaz das falhas encontradas.
