# Release Notes — nchatzap

## v1.0.1

### Documentação
- **Use o nchat 5.21.13 ou mais novo.** Builds antigos (ex.: 5.19.5, de 23/08/2026) trazem uma versão antiga da biblioteca whatsmeow e podem deixar de receber as confirmações de entrega/leitura em conversas 1:1 depois que o WhatsApp passa o contato pro formato de ID `@lid`. O nchat 5.21.13 traz o whatsmeow de 16/11/2026.
- README: nova seção "Atualizar o nchat", com instruções pra recompilar a partir do upstream, fazer backup e voltar à versão anterior.

## v1.0.0

Primeira versão do kit.

### Incluso
- `install.sh`: instalação completa e idempotente pra RHEL 10 — dependências de build, `libmagic` compilada do zero, `wacli`, `nchat` (sem Telegram), usuário de serviço dedicado, regra de sudo mínima.
- `scripts/wa-chat`: menu interativo (conversas não lidas → escolher → responder), sem precisar decorar sintaxe de CLI.
- `README.md`: instalação, pareamento, uso, atalhos de teclado, modelo de segurança, desinstalação.

### Decisões de design
- Usuário de serviço dedicado sem privilégios (não roda como root), com regra de `sudo` restrita aos 3 binários exatos — princípio de menor privilégio.
- `nchat` compilado sem suporte a Telegram (`HAS_TELEGRAM=OFF`) — só o necessário, build mais rápido, menos superfície de dependências.
- `libmagic` compilada a partir do código-fonte oficial, já que o RHEL 10 (no momento desta versão) não disponibiliza o pacote `-devel` correspondente em nenhum repositório padrão (BaseOS/AppStream/CRB).

### Limitações conhecidas
- **`~/.config/nchat/key.conf` não persiste customizações** — o `nchat` regrava os valores padrão a cada inicialização nesta versão. Navegação da lista de conversas fica em `Tab`/`Shift-Tab` (não é possível remapear pra setas de forma confiável). `ui.conf` (ex: largura da lista) persiste normalmente.
- `wacli` e `nchat` pareiam como dispositivos vinculados **separados** — não compartilham sessão entre si.
- Ferramentas de terceiros, não oficiais — sujeitas a quebrar com mudanças no protocolo do WhatsApp.

### Requisitos
- RHEL 10 x86_64, acesso à internet, Go 1.26.6+ (auto-baixado via `GOTOOLCHAIN=auto` se o pacote do sistema for mais antigo).
