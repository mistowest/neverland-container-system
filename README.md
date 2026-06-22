# neverland-container-system

> Ambiente Ubuntu isolado via Docker, voltado a trabalhos de investigação, OSINT e análise técnica. Funciona em qualquer host com Docker: Linux, macOS ou Windows.

---

## O que é isso

O **neverland-container-system** provisiona um container Ubuntu dedicado e persistente, acessível via SSH ou `docker exec`, que serve como estação de trabalho isolada para atividades investigativas.

O ambiente é separado do sistema host por design: bibliotecas, ferramentas e dados sensíveis ficam confinados ao container e ao seu volume Docker, sem interferir no restante do sistema.

---

## Para quem é

Investigadores, analistas e profissionais que trabalham com:

- **OSINT** — coleta e correlação de informações de fontes abertas
- **Reconhecimento e enumeração** — levantamento passivo e ativo de alvos
- **Análise técnica** — scripts Python, automações, processamento de dados
- **Segurança ofensiva/defensiva** — ambientes isolados para testes e simulações

---

## Arquitetura

```
[Host: Linux / macOS / Windows]
        │
        └── Docker
              └── ubuntu-<usuario>       ← container principal
                    ├── SSH :2222        ← acesso remoto
                    ├── /home/<usuario>  ← volume persistente (ubuntu_data)
                    └── venvs/osint/     ← ambiente Python isolado para OSINT
```

O container é configurado via `.env` e construído com `docker compose`. O volume `ubuntu_data` garante que dados, configs e ferramentas instaladas sobrevivam a restarts e rebuilds (a menos que o volume seja destruído explicitamente).

---

## Acesso

**Via SSH:**
```sh
ssh <usuario>@localhost -p 2222
```

**Via Docker diretamente:**
```sh
docker exec -it ubuntu-<usuario> su - <usuario>
```

---

## Ambiente Python para OSINT

O container traz um virtualenv Python isolado em `/home/<usuario>/venvs/osint`, pré-configurado com bibliotecas investigativas. Dois aliases estão disponíveis sem precisar ativar o venv manualmente:

| Alias | Função |
|---|---|
| `osint-python script.py` | Executa scripts com o Python do venv |
| `osint-pip install <lib>` | Instala pacotes no venv isolado |

A biblioteca `google-search-results` (SerpApi) já vem pré-instalada. Novas bibliotecas instaladas com `osint-pip` persistem no volume Docker.

Para instalar permanentemente (sobrevive a rebuilds), adicione ao `Dockerfile` e rode `docker compose up -d --build`.

---

## Configuração

Copie `.env.example` para `.env` e preencha:

```env
SYSTEM_USER=      # usuário dentro do container
SYSTEM_PASSWORD=  # senha do usuário
SYSTEM_HOSTNAME=  # hostname do container
SSH_PORT=         # porta SSH exposta no host (ex: 2222)
MEM_LIMIT=2g      # limite de RAM
MEM_SWAP_LIMIT=2g # limite de swap
CPU_LIMIT=2       # limite de CPUs
```

---

## Inicialização

```sh
# Primeira vez (ou após mudanças no Dockerfile)
docker compose up -d --build

# Uso normal
docker compose up -d

# Parar sem destruir dados
docker compose down

# Destruir tudo, incluindo dados persistentes
docker compose down -v
```

---

## Persistência de dados

Tudo em `/home/<usuario>` é armazenado no volume Docker `ubuntu_data`. Isso inclui:

- Scripts e ferramentas instaladas
- Pacotes Python do venv OSINT
- Dados coletados, notas e artefatos de investigação

Os dados **não se perdem** em restarts ou rebuilds normais. Só são apagados com `docker compose down -v`.

---

## Recursos

- `USAGE.md` — guia detalhado do ambiente Python OSINT
- `docker-compose.yml` — definição do serviço
- `Dockerfile` — imagem Ubuntu customizada
- `.env.example` — template de configuração
