# Roteiro – Gerência de Configuração e DevOps (AmazonTrackData)

Este roteiro acompanha o `PGC_AmazonTrackData.docx` e explica como deixar o repositório e a Vercel no estado descrito no plano e como apresentar cada item avaliado.

## 0. Antes de começar

- A pasta `website/` (site publicado na Vercel) e a pasta `testes/` aparecem como **apagadas** no diretório local, mas ainda existem no último commit. Se a exclusão não foi intencional, restaure antes de commitar:

```powershell
git restore website testes web
```

- Sem a pasta `website/`, a Vercel e o job "Site (build Vite)" do CI falham.
- O site já está no ar no projeto `amazon-track-web` da Vercel (https://amazon-track-web.vercel.app). Porém o repositório Git ligado a ele (`Joaojsmaciel/AmazonTrackData`) é o protótipo Android antigo e não contém o código do site, que está em `website/` neste repositório. Por isso, a seção 3 reconecta o projeto a este repositório.

## 1. Branches do GitFlow

```powershell
git checkout main
git add .github CHANGELOG.md "Gerencia de configuração"
git commit -m "ci: adiciona pipeline CI/CD, modelos de issue/PR e PGC"
git push origin main

git checkout -b develop
git push -u origin develop
git checkout -b release
git push -u origin release
git checkout develop
```

## 2. GitHub

1. **Proteção de branches** (Settings → Branches → Add rule), para `main` e `release`:
   - Require a pull request before merging.
   - Require status checks to pass: `App Flutter (analyze, test, build)` e `Site (build Vite)`.
2. **Rótulos** (Issues → Labels): `bug`, `mudanca`, `prioridade-alta`, `prioridade-media`, `prioridade-baixa`.
3. **Issues**: cadastre os defeitos da tabela 3.2.2.1 com o modelo "Relato de defeito" (pelo menos DEF-01, DEF-12 e DEF-23, que serão usados na demonstração) e as mudanças MUD-06 a MUD-09 com o modelo "Solicitação de mudança".
4. (Opcional) **Projects**: quadro com as colunas A fazer / Em andamento / Em revisão / Concluído.

## 3. Vercel

1. Abra o projeto `amazon-track-web` → Settings → **Git** → *Disconnect* de `Joaojsmaciel/AmazonTrackData` → *Connect* a `Joaojsmaciel/PIBIT-AmazonTrackDataFlutter`.
2. Settings → Build and Deployment → **Root Directory**: `website` (framework Vite; build e saída já estão em `website/vercel.json`).
3. **Production Branch**: `main` (Settings → Environments → Production → Branch Tracking). O próximo push em `main` substitui o deploy atual, mantendo a URL https://amazon-track-web.vercel.app.
4. **Domínios por branch** (Settings → Domains → Add):
   - `amazon-track-web-develop.vercel.app` → *Connect to an environment: Preview* → Git Branch `develop`.
   - `amazon-track-web-release.vercel.app` → Preview → Git Branch `release`.
   - Se algum nome estiver ocupado, escolha outro e troque no `scripts/gerar_pgc.ps1` (seção 6).
5. Cada PR passa a receber automaticamente uma URL de Preview, comentada no próprio PR.

Resultado esperado no painel: `main` (Production), `release` e `develop` (Preview) listadas com deploys "Ready", como na Figura 1 do enunciado.

## 4. Fluxo completo para demonstrar (exemplo: corrigir o DEF-23)

```powershell
# 1. branch a partir de develop, ligada à issue
git checkout develop
git pull
git checkout -b feature/23-vagas-negativas

# 2. corrigir o código e commitar no padrão Conventional Commits
git commit -am "fix: impede número negativo de vagas no agendamento (#23)"
git push -u origin feature/23-vagas-negativas
```

3. Abra o PR `feature/23-vagas-negativas → develop` com "Closes #23". Mostre o CI rodando e o link de Preview da Vercel.
4. Faça o merge: a Vercel publica em `amazon-track-web-develop.vercel.app`.
5. Abra o PR `develop → release`: deploy em `amazon-track-web-release.vercel.app` e o CI gera o artefato `amazon-track-apk-release` (APK de homologação).
6. Atualize a versão em `pubspec.yaml` (ex.: `1.0.1+2`) e o `CHANGELOG.md`, depois abra o PR `release → main`.
7. Merge em `main`: deploy de produção em `amazon-track-web.vercel.app`, o job "Tag e GitHub Release" cria a tag `v1.0.1` e publica o APK.
8. Atualize a tabela de defeitos do PGC (data de correção do DEF-23) e gere o documento de novo.

Hotfix: o mesmo fluxo, com `hotfix/DEF-xx-descricao` criada a partir de `main`, PR para `main` e depois merge de `main` em `develop`.

## 5. Roteiro da apresentação (5 critérios)

| Critério | O que mostrar | Onde |
|---|---|---|
| PGC | Plano preenchido e sua ligação com o repositório (branches, pastas, siglas, baselines) | `PGC_AmazonTrackData.docx` + GitHub |
| Ambientes | develop, release e produção com URLs próprias | Vercel → Deployments / Domains |
| Versionamento e colaboração | Histórico de commits, branches e PRs com revisão | GitHub → Commits, Branches, Pull requests |
| Auditorias | Tabelas de defeitos e mudanças no plano, Issues `bug`/`mudanca`, PR que fecha uma issue, CHANGELOG | PGC seção 3.2.2 + GitHub Issues |
| DevOps (CI/CD) | Execução do workflow (analyze, testes, build), artefato APK, deploy automático, tag e Release | GitHub → Actions / Releases + Vercel |

## 6. Atualizar o PGC

Os textos e as tabelas do plano ficam em `scripts/gerar_pgc.ps1`. Depois de editar (por exemplo, preencher a data de correção de um defeito), gere o documento de novo a partir da raiz do repositório:

```powershell
powershell -ExecutionPolicy Bypass -File "Gerencia de configuração\scripts\gerar_pgc.ps1"
```

Ao abrir o `.docx`, o Word pergunta se deve atualizar os campos: responda **Sim** para atualizar o sumário.
