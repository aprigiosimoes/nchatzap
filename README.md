# nchatzap

Kit pessoal de instalação para usar o WhatsApp via terminal em servidores RHEL 10. Junta duas ferramentas de terceiros já prontas com um script próprio de conveniência:

- **[wacli](https://wacli.sh)** — CLI orientada a scripts/automação (saída em JSON, busca, envio de mensagem via linha de comando).
- **[nchat](https://github.com/d99kris/nchat)** — cliente TUI com interface ncurses de 3 painéis (lista de conversas, mensagens, status), navegação por teclado.
- **`wa-chat`** — script auxiliar incluso aqui (original deste projeto): menu interativo simples pra ver conversas não lidas e responder, sem precisar decorar sintaxe de CLI.

Ambos usam a biblioteca [whatsmeow](https://github.com/tulir/whatsmeow), que implementa o protocolo **oficial de "dispositivo vinculado"** (o mesmo mecanismo do WhatsApp Web/Desktop) — mais seguro do que ferramentas que emulam o app mobile diretamente.

## Créditos

`nchatzap` é só o instalador/wrapper — todo o trabalho pesado é de terceiros:
- `nchat` é criado e mantido por [Kristofer Berggren](https://github.com/d99kris), licenciado GPLv3. Este projeto **não** modifica ou redistribui o código do `nchat` — o `install.sh` só clona e compila a versão oficial upstream.
- `wacli` é criado e mantido pelo projeto [openclaw/wacli](https://github.com/openclaw/wacli).

Só `install.sh`, `README.md`, `RELEASENOTES.md` e `scripts/wa-chat` são deste projeto (`nchatzap`).

> ⚠️ **Aviso**: `wacli` e `nchat` são ferramentas de terceiros, não afiliadas ao WhatsApp/Meta. O uso viola tecnicamente os Termos de Serviço do WhatsApp. O risco de restrição de conta é baixo (usa o canal oficial de dispositivo vinculado), mas não é zero. Use por sua conta e risco.

## Modelo de segurança

- Roda sob um **usuário de sistema dedicado, sem privilégios** (`wacli` por padrão), não como root.
- O histórico de mensagens e a sessão autenticada ficam isolados na home desse usuário (`chmod 700`).
- O(s) usuário(s) humano(s) que podem operar a ferramenta recebem uma **regra de sudo mínima**, restrita aos três binários exatos (`wacli`, `wa-chat`, `nchat`) — não ganham shell nem qualquer outro acesso como o usuário de serviço.

## Pré-requisitos

- RHEL 10 (x86_64), com acesso à internet (repositórios padrão, GitHub, Go modules).
- Acesso root/sudo pra instalar.
- Um celular com WhatsApp instalado, pra parear via QR code.

## Instalação

```bash
git clone https://github.com/aprigiosimoes/nchatzap.git
cd nchatzap
sudo ./install.sh <seu_usuario>
```

`<seu_usuario>` é o usuário do sistema que vai poder rodar as ferramentas (via sudo, sem senha, restrito aos 3 binários). Se omitido, usa quem chamou o `sudo`.

O script instala Go, ferramentas de build, compila `libmagic` do zero (o RHEL10 ainda não tem o pacote `-devel` disponível), compila `wacli` e `nchat` (sem suporte a Telegram, só WhatsApp — build mais rápido), cria o usuário de serviço, e configura a regra de sudo.

## Pareamento (uma vez, por dispositivo)

WhatsApp permite múltiplos dispositivos vinculados simultâneos — `wacli` e `nchat` pareiam **separadamente**, cada um ocupa um "slot" de dispositivo vinculado.

```bash
# wacli (necessário pra usar wa-chat e comandos de script)
sudo -u wacli wacli auth

# nchat (interface TUI)
sudo -u wacli nchat -s
# escolha "1" (WhatsAppMd), escaneie o QR
```

No celular: **WhatsApp → Configurações → Dispositivos conectados → Conectar dispositivo**.

## Uso do dia a dia

```bash
# TUI completa (recomendado pra uso interativo)
sudo -u wacli nchat

# menu simples: lista não-lidas, escolhe, responde
sudo -u wacli wa-chat
```

> ⚠️ **Não use `nchat -s` no dia a dia** — essa flag é só pra configurar/reconfigurar conta. Rodar sempre com `-s` faz parecer que ele está "sincronizando do zero" a cada abertura. Pro uso normal, `nchat` sem flags.

### Alias de conveniência

```bash
echo "alias wa='sudo -u wacli nchat'" >> ~/.bashrc
source ~/.bashrc
```

## Comandos úteis do wacli

```bash
wacli chats list                                  # lista conversas
wacli chats list --unread                         # só não lidas
wacli contacts search "nome"                       # busca contato
wacli messages list --chat "<jid>" --limit 20      # histórico de uma conversa
wacli send text --to "<numero-ou-nome>" --message "texto"
```

## Atalhos de teclado do nchat

| Tecla | Ação |
|---|---|
| `Tab` | próxima conversa (desce na lista) |
| `Shift-Tab` | conversa anterior (**sobe** na lista) |
| `Ctrl-x` | enviar mensagem digitada |
| `Ctrl-t` | enviar arquivo |
| `Ctrl-s` | inserir emoji |
| `Alt-.` / `Alt-,` | aumentar / diminuir largura da lista de conversas |
| `Ctrl-l` | mostrar/ocultar lista de conversas |
| `Ctrl-q` | sair |
| `PageUp` / `PageDown` | navegar histórico de mensagens |

Lista completa: `nchat --help`.

### ⚠️ Nota conhecida: remapeamento de teclas não persiste

O arquivo `~/.config/nchat/key.conf` é **regravado com os valores padrão a cada vez que o `nchat` inicia** nesta versão — qualquer customização manual desse arquivo é perdida no próximo lançamento. Por isso, **use os atalhos padrão** (`Tab`/`Shift-Tab` pra navegar a lista) em vez de tentar remapear pra setas. Já `~/.config/nchat/ui.conf` (ex: `list_width`) **persiste normalmente** entre execuções.

## Estrutura deste repositório

```
.
├── README.md
├── RELEASENOTES.md
├── install.sh          # script de instalação completo
└── scripts/
    └── wa-chat          # menu interativo de conversas
```

## Desinstalação

```bash
sudo rm -f /usr/local/bin/{wacli,nchat,wa-chat}
sudo rm -f /etc/sudoers.d/wacli
sudo userdel -r wacli   # remove o usuário e TODO o histórico/sessão do WhatsApp
```
