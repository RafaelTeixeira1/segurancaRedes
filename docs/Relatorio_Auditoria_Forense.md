# Relatório de Auditoria e Análise Forense


## 1. Análise de Vulnerabilidades e Vetores de Ataque
### 1.1 Vulnerabilidades Identificadas
- Senha fraca/previsível (SSH)
- Ausência de MFA
- Permissividade de rede/serviços expostos
- World-writable / permissões frágeis
- Usuários com privilégio excessivo
- Sistemas desatualizados


### 1.2 Vetores de Ataque
- Engenharia social / observação de credenciais
- Acesso remoto via SSH mal configurado
- Execução local (USB/mídia removível)


### 1.3 Mapeamento de Vulnerabilidades
- Diagrama de rede + tabela de serviços expostos


## 2. Análise Forense Digital e Resposta a Incidentes
### 2.1 Cadeia de Custódia
- Procedimento de coleta
- Hashes, timestamps, cópias forenses


### 2.2 Análise de Logs
- `auth.log`, `secure`, `journalctl -u ssh`
- IP de origem, horários, usuário comprometido


## 3. Análise de Riscos e Impactos
### 3.1 Impacto na Instituição
- Reputação, custos, políticas


### 3.2 Impacto Humano
- Privacidade, exposição, ética


## 4. Evidências
- Lista de arquivos, localizações, hashes
