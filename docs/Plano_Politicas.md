# 🧭 Plano e Políticas de Segurança da Informação

## 📋 Objetivo
Estabelecer diretrizes e boas práticas para garantir a **confidencialidade**, **integridade** e **disponibilidade** das informações nos ambientes de rede do laboratório.

## 🧩 Escopo
Aplica-se a todos os **usuários, docentes e discentes** que utilizam as máquinas físicas e virtuais do laboratório. Inclui:
- Políticas de autenticação e controle de acesso;
- Manuseio de dispositivos externos (USB, mídias removíveis);
- Procedimentos de atualização e monitoramento;
- Política de coleta e armazenamento de evidências digitais.

## 🔐 Diretrizes Gerais
### 1. Controle de Acesso
- Cada usuário deve possuir credenciais únicas e intransferíveis;
- Senhas fracas ou compartilhadas são proibidas;
- Acesso root/sudo é restrito a administradores.

### 2. Gestão de Vulnerabilidades
- Atualizações semanais obrigatórias;
- Logs mantidos por 90 dias;
- Execução de scripts de verificação automatizada.

### 3. Uso de Mídias Removíveis
- Proibido conectar dispositivos USB pessoais;
- Simulações controladas via `simula_usb_and_execute.sh`.

### 4. Monitoramento e Incidentes
- Eventos suspeitos devem ser reportados imediatamente;
- Logs de SSH, autenticação e sudo revisados semanalmente.

## 🧱 Conformidade Legal e Ética
Conformidade com **LGPD (Lei 13.709/2018)**, **ISO/IEC 27002** e normas internas da instituição.
