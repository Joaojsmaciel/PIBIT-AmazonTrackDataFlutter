# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e versionamento semântico.

## [Não lançado]

### Adicionado
- Fluxo GitFlow (`main`, `release`, `develop`, `feature/*`, `hotfix/*`), conexão do projeto `amazon-track-web` da Vercel a este repositório e ambientes por branch (MUD-06).
- Pipeline de CI/CD no GitHub Actions: análise estática, testes, build do APK e do site, tag e GitHub Release (MUD-07).
- Modelos de Issue (defeito e mudança) e de Pull Request (MUD-08).
- Plano de Gerenciamento de Configuração (MUD-09).
- Suíte de testes de integração em `integration_test/` (MUD-05).

### Defeitos conhecidos
- DEF-01 a DEF-24, registrados no Relatório RRT-ATD-001 e no PGC.

## [1.0.0] - 2026-08-11

### Adicionado
- Site institucional React/Vite com download do APK, publicado em https://amazon-track-web.vercel.app (MUD-03).
- Novos modelos de dados e telas de barqueiro e passageiro (MUD-02).
- Estrutura inicial do app Flutter (MUD-01).

### Alterado
- Melhorias no rastreamento, na UI de barcos e nas telas do passageiro (MUD-04).
