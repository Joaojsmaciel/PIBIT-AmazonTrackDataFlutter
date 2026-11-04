# Gera PGC_AmazonTrackData.docx a partir do modelo da disciplina.
# Uso (na raiz do repositório): powershell -ExecutionPolicy Bypass -File "Gerencia de configuração\scripts\gerar_pgc.ps1"
$ErrorActionPreference = 'Stop'
$W   = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
$W14 = 'http://schemas.microsoft.com/office/word/2010/wordml'
$gcDir   = Split-Path $PSScriptRoot -Parent
$tplDocx = Join-Path $gcDir 'Plano-de-gerenciamento-de-configuração-2025-2d.docx'
$outDocx = Join-Path $gcDir 'PGC_AmazonTrackData.docx'
$outDir  = Join-Path $env:TEMP 'pgc_out'

Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
if (Test-Path $outDir) { Remove-Item $outDir -Recurse -Force }
[IO.Compression.ZipFile]::ExtractToDirectory($tplDocx, $outDir)

$x = New-Object Xml.XmlDocument
$x.PreserveWhitespace = $true
$x.Load((Join-Path $outDir 'word\document.xml'))
$ns = New-Object Xml.XmlNamespaceManager $x.NameTable
$ns.AddNamespace('w', $W)
$body = $x.SelectSingleNode('/w:document/w:body', $ns)
$tbls = @($body.SelectNodes('w:tbl', $ns))

# ---------------- helpers ----------------
function Get-Text($n) { (@($n.SelectNodes('.//w:t', $ns)) | ForEach-Object { $_.InnerText }) -join '' }

function Strip-Ids($n) {
  foreach ($e in @($n.SelectNodes('descendant-or-self::*', $ns))) {
    foreach ($a in @($e.Attributes)) { if ($a.NamespaceURI -eq $W14) { [void]$e.Attributes.Remove($a) } }
  }
}

function New-WEl([string]$name, [string]$val) {
  $e = $x.CreateElement('w', $name, $W)
  $a = $x.CreateAttribute('w', 'val', $W); $a.Value = $val; [void]$e.Attributes.Append($a)
  return $e
}

function Set-Bold($rPr, [bool]$bold) {
  foreach ($old in @($rPr.SelectNodes('w:b|w:bCs', $ns))) { [void]$rPr.RemoveChild($old) }
  $v = if ($bold) { '1' } else { '0' }
  $b = New-WEl 'b' $v
  $bc = New-WEl 'bCs' $v
  $anchor = $rPr.SelectSingleNode('w:rFonts', $ns)
  if (-not $anchor) { $anchor = $rPr.SelectSingleNode('w:rStyle', $ns) }
  if ($anchor) { [void]$rPr.InsertAfter($bc, $anchor); [void]$rPr.InsertAfter($b, $anchor) }
  else { [void]$rPr.PrependChild($bc); [void]$rPr.PrependChild($b) }
}

function Get-BaseRPr($p) {
  $r = $p.SelectSingleNode('.//w:r[w:t]/w:rPr', $ns)
  if ($r) { return $r.CloneNode($true) }
  $pr = $p.SelectSingleNode('w:pPr/w:rPr', $ns)
  if ($pr) { return $pr.CloneNode($true) }
  return $x.CreateElement('w', 'rPr', $W)
}

# segments: array of @(text, bold) ; bold = $null keeps the base formatting
function Set-ParaRich($p, $segments) {
  $base = Get-BaseRPr $p
  foreach ($c in @($p.ChildNodes)) {
    if ($c.LocalName -in @('r', 'hyperlink', 'proofErr', 'smartTag', 'ins', 'del', 'fldSimple')) { [void]$p.RemoveChild($c) }
  }
  foreach ($seg in $segments) {
    $r = $x.CreateElement('w', 'r', $W)
    $rp = $base.CloneNode($true)
    if ($null -ne $seg[1]) { Set-Bold $rp ([bool]$seg[1]) }
    [void]$r.AppendChild($rp)
    $t = $x.CreateElement('w', 't', $W)
    $sa = $x.CreateAttribute('xml', 'space', 'http://www.w3.org/XML/1998/namespace'); $sa.Value = 'preserve'; [void]$t.Attributes.Append($sa)
    $t.InnerText = [string]$seg[0]
    [void]$r.AppendChild($t)
    [void]$p.AppendChild($r)
  }
}
function Set-ParaText($p, [string]$text, $bold = $null) { Set-ParaRich $p @(, @($text, $bold)) }

# "Rótulo: texto" -> rótulo em negrito
function Set-ParaLabel($p, [string]$label, [string]$text) { Set-ParaRich $p @(@($label, $true), @($text, $false)) }

function Find-P([string]$text, [int]$nth = 1, [switch]$Starts) {
  $k = 0
  foreach ($p in @($body.SelectNodes('w:p', $ns))) {
    $t = (Get-Text $p).Trim()
    if (($Starts -and $t.StartsWith($text)) -or ((-not $Starts) -and $t -eq $text)) { $k++; if ($k -eq $nth) { return $p } }
  }
  throw "Parágrafo não encontrado: $text"
}

function New-ParaAfter($ref, $tpl, $content, $bold = $null) {
  $n = $tpl.CloneNode($true); Strip-Ids $n
  if ($content -is [array]) { Set-ParaRich $n $content } else { Set-ParaText $n $content $bold }
  [void]$ref.ParentNode.InsertAfter($n, $ref)
  return $n
}

function Remove-Node($n) { [void]$n.ParentNode.RemoveChild($n) }

function Set-Cell($tc, $lines) {
  $lines = @($lines)
  $ps = @($tc.SelectNodes('w:p', $ns))
  $first = $ps[0]
  for ($i = 1; $i -lt $ps.Count; $i++) { Remove-Node $ps[$i] }
  Set-ParaText $first ([string]$lines[0])
  $prev = $first
  for ($i = 1; $i -lt $lines.Count; $i++) { $prev = New-ParaAfter $prev $first ([string]$lines[$i]) }
}

function Set-RowCells($tr, $cells) {
  $tcs = @($tr.SelectNodes('w:tc', $ns))
  for ($i = 0; $i -lt $cells.Count; $i++) { Set-Cell $tcs[$i] $cells[$i] }
}

# Replaces all data rows (after header) with $rows. $tplIdx: row index used as template (per row optional)
function Set-Rows($tbl, $rows, $tplIdx = 1) {
  $trs = @($tbl.SelectNodes('w:tr', $ns))
  $tpls = @{}
  foreach ($i in 1..($trs.Count - 1)) { $tpls[$i] = $trs[$i].CloneNode($true) }
  for ($i = 1; $i -lt $trs.Count; $i++) { Remove-Node $trs[$i] }
  $idx = 0
  foreach ($row in $rows) {
    $ti = if ($tplIdx -is [array]) { $tplIdx[$idx] } else { $tplIdx }
    $n = $tpls[$ti].CloneNode($true); Strip-Ids $n
    Set-RowCells $n $row
    [void]$tbl.AppendChild($n)
    $idx++
  }
}

# ---------------- Capa ----------------
Set-RowCells @($tbls[0].SelectNodes('w:tr', $ns))[0] @('Projeto', 'AmazonTrackData (Amazon Track) – Rastreamento de embarcações na Amazônia')
Set-Rows $tbls[0] @(
  @('Gerente de Projetos', 'João Gabriel da Silva Maciel'),
  @('Fábrica de Software', 'Equipe AmazonTrackData – UFAM / PIBITI – NUPEC/LAMAP'),
  @('Repositório', 'https://github.com/Joaojsmaciel/PIBIT-AmazonTrackDataFlutter'),
  @('Produção (Vercel)', 'https://amazon-track-web.vercel.app')
) @(1, 2, 1, 2)

Set-Rows $tbls[1] @(
  @('03/11/2026', '1.0', 'Elaboração do documento a partir do modelo da disciplina e adaptação ao projeto AmazonTrackData.', 'João Gabriel da Silva Maciel'),
  @('03/11/2026', '1.1', 'Definição do fluxo GitFlow (main, release, develop, feature/*, hotfix/*) e dos ambientes na Vercel.', 'João Gabriel da Silva Maciel'),
  @('03/11/2026', '1.2', 'Pipeline de CI/CD (GitHub Actions + Vercel), registro de defeitos DEF-01 a DEF-24 e da tabela de mudanças.', 'João Gabriel da Silva Maciel'),
  @('03/11/2026', '1.3', 'Ajuste ao projeto amazon-track-web da Vercel (URLs reais), inclusão da coautora e do orientador e do protótipo Android (MUD-00).', 'João Gabriel da Silva Maciel')
)

# ---------------- 1. Introdução ----------------
Set-ParaText (Find-P 'Este Plano de Gerenciamento de Configuração é destinado' -Starts) 'Este Plano de Gerenciamento de Configuração é destinado a todos os integrantes da equipe AmazonTrackData (UFAM / PIBITI) e abrange o controle e o gerenciamento da configuração do projeto AmazonTrackData: o aplicativo móvel em Flutter (rastreamento de embarcações fluviais para barqueiros e passageiros), o site institucional em React/Vite publicado na Vercel (com o download do APK), as regras do Firebase, os diagramas e toda a documentação versionada no repositório GitHub Joaojsmaciel/PIBIT-AmazonTrackDataFlutter.'

Set-Rows $tbls[2] @(
  @('IC', 'Item de Configuração. Qualquer artefato (código, documento, configuração, build) colocado sob controle de versão e mudança.'),
  @('Baseline', 'Linha de base. Conjunto de versões de itens de configuração aprovados, identificado por uma tag Git (ex.: v1.0.0). Serve de base para a fase seguinte e só muda por processo formal.'),
  @('Release', 'Versão candidata à produção. No projeto é a branch release, publicada no ambiente de homologação da Vercel.'),
  @('GitFlow', 'Modelo de ramificação com branches de longa duração (main, release, develop) e de curta duração (feature/*, hotfix/*).'),
  @('PR', 'Pull Request. Solicitação de integração de uma branch em outra, com revisão e verificações automáticas (CI).'),
  @('CI', 'Continuous Integration (Integração Contínua). Build, análise estática e testes executados automaticamente a cada push/PR (GitHub Actions).'),
  @('CD', 'Continuous Delivery/Deployment (Entrega/Implantação Contínua). Publicação automática de cada branch no seu ambiente da Vercel e geração da release do APK.'),
  @('Preview Deployment', 'Implantação de pré-visualização da Vercel, gerada para qualquer branch diferente da de produção, com URL própria.'),
  @('SemVer', 'Versionamento Semântico MAJOR.MINOR.PATCH (+build), usado em pubspec.yaml e nas tags Git.'),
  @('APK', 'Android Package. Pacote instalável do aplicativo Android, distribuído pelo site.'),
  @('CCB', 'Change Control Board (Comitê de Controle de Mudanças).'),
  @('PO', 'Product Owner.'),
  @('RUP', 'Rational Unified Process. Processo de engenharia de software da IBM, origem do modelo deste plano.')
)

$ref1 = Find-P 'Template do Plano de Gerenciamento de Configuração, RUP 7.0, IBM.'
Set-ParaText $ref1 'Modelo do Plano de Gerenciamento de Configuração 2025-2 (disciplina) e Template do PGC, RUP 7.0, IBM.'
$ref2 = Find-P 'Cronograma do Projeto https://trello.com'
Set-ParaText $ref2 'Repositório do projeto: https://github.com/Joaojsmaciel/PIBIT-AmazonTrackDataFlutter'
$r = New-ParaAfter $ref2 $ref2 'Vercel – Environments e Git integration: https://vercel.com/docs/deployments/environments'
$r = New-ParaAfter $r $ref2 'GitHub Actions: https://docs.github.com/actions'
$r = New-ParaAfter $r $ref2 'Documento de Requisitos, Plano de Testes PT-ATD-001, Especificação EAPT-ATD-001 e Relatório RRT-ATD-001 (pasta docs/entregaveis).'
$r = New-ParaAfter $r $ref2 'Documento de Arquitetura de Software ISO/IEC/IEEE 42010 (pasta Arquitetura).'

$ev = Find-P 'Mudança no padrão de versionamento;'
$e1 = New-ParaAfter $ev $ev 'Mudança nos ambientes da Vercel ou no pipeline de CI/CD;'
$e2 = New-ParaAfter $e1 $ev 'Entrada ou saída de membros da equipe (redistribuição de papéis).'

# ---------------- 2. GCS – Papéis ----------------
Set-Rows $tbls[3] @(
  @('Gerente de Projeto (João Gabriel da Silva Maciel)', 'Prioriza o backlog (GitHub Issues/Projects), autoriza Requisições de Mudança, aprova a promoção release → main, gera as baselines (tags) junto com o Gerente de Configuração e acompanha a resolução dos defeitos.'),
  @('Gerente de Configuração (João Gabriel da Silva Maciel)', 'Mantém este PGC, define o fluxo GitFlow, as convenções de nomes, commits e tags, configura a proteção das branches main e release e os ambientes da Vercel.'),
  @('Analista de Configuração / DevOps (João Gabriel da Silva Maciel)', 'Mantém os workflows do GitHub Actions (.github/workflows), o projeto na Vercel (Root Directory website/, domínios por branch), audita a execução do processo, cria as branches de release/hotfix e publica as releases do APK.'),
  @('Comitê de Mudanças – CCB', 'Gerente de Projeto, Gerente de Configuração e orientador do projeto (Prof. Dr. Hidelbrando Ferreira Rodriguez). Avalia impacto, custo e risco das mudanças registradas como Issues com o rótulo mudanca.'),
  @('Colaboradores da Equipe (João Gabriel da Silva Maciel e Alica de Souza Miranda)', 'Trabalham em branches feature/* ou hotfix/*, seguem o padrão de commits (Conventional Commits), abrem PRs para develop, mantêm o CI verde e corrigem os defeitos apontados nas revisões.'),
  @('Envolvidos Interessados', 'Coautora Alica de Souza Miranda, orientador (Prof. Dr. Hidelbrando Ferreira Rodriguez), docente da disciplina (Prof. Walter Jonas de Sousa Viana), barqueiros, passageiros e comunidades ribeirinhas atendidas.'),
  @('Banco de Dados', 'Configuração do Firebase (Authentication, Cloud Firestore, Storage) e das regras de segurança versionadas em docs/FIRESTORE_RULES.txt e docs/STORAGE_RULES.txt; banco local SQLite (sqflite) para operação offline.'),
  @('Teste / QA', 'Executa o Plano de Testes PT-ATD-001 (testes unitários, de widget, de integração em integration_test/ e em dispositivo real), registra defeitos DEF-xx como Issues e valida a release no ambiente de homologação.'),
  @('Infraestrutura', 'Serviços em nuvem: GitHub (repositório, Actions, Releases), Vercel (hospedagem do site e ambientes) e Firebase (backend do app).'),
  @('UX Designer', 'Pesquisa com barqueiros e passageiros, protótipos das telas, acessibilidade (contraste WCAG AA, rótulos semânticos) e validação da experiência nas pré-visualizações da Vercel.')
)

# ---------------- Ferramentas ----------------
Set-Rows $tbls[4] @(
  @('Git', '2.56.0', 'Controle de versão distribuído. https://git-scm.com/'),
  @('GitHub', '—', 'Hospedagem do repositório, branches, Pull Requests, Issues (bugs e mudanças), Projects e Releases. https://github.com/Joaojsmaciel/PIBIT-AmazonTrackDataFlutter'),
  @('GitHub Actions', '—', 'Integração contínua: análise estática, testes e build do app e do site a cada push/PR; geração da release do APK. Arquivo .github/workflows/ci.yml.'),
  @('Vercel', 'Hobby', 'Hospedagem do site (website/) com implantação automática por branch: main (produção), release (homologação), develop (desenvolvimento) e pré-visualizações de PR. https://vercel.com'),
  @('Flutter SDK / Dart', '3.x (stable) / Dart ≥ 3.1', 'Framework do aplicativo móvel. https://flutter.dev'),
  @('Android Studio / Android SDK', '—', 'Emulador, SDK e assinatura do APK; testes em dispositivo real (Moto G54 5G, Android 15).'),
  @('Visual Studio Code / Cursor', '—', 'Editores de código com extensões Flutter/Dart e Git.'),
  @('Firebase', '—', 'Authentication, Cloud Firestore e Storage (backend do app) e Firebase Emulator para testes de regras.'),
  @('Node.js / npm', '22 LTS', 'Execução do build do site (Vite 8, React 19).'),
  @('React / Vite', '19 / 8', 'Biblioteca e empacotador do site institucional publicado na Vercel.'),
  @('PlantUML', '—', 'Diagramas de casos de uso, classes e banco de dados (pasta diagramas/).'),
  @('Microsoft Word / Google Documentos', '—', 'Elaboração da documentação (.docx/.md/.pdf) versionada em docs/.')
)

# ---------------- Ambientes ----------------
Set-ParaText (Find-P 'O ambiente que será entregue à equipe de desenvolvimento' -Starts) 'O AmazonTrackData possui duas partes implantáveis: o aplicativo móvel em Flutter, distribuído como APK, e o site institucional (React + Vite, pasta website/), hospedado na Vercel no projeto amazon-track-web (produção em https://amazon-track-web.vercel.app). O projeto da Vercel é ligado a este repositório do GitHub com Root Directory = website, e cada branch de longa duração tem seu próprio ambiente e URL fixa. As IDEs são de livre escolha (VS Code, Cursor ou Android Studio), desde que usem o Flutter estável e os lints definidos em analysis_options.yaml.'
Set-ParaText (Find-P 'Ambiente de Desenvolvimento: inclui a IDE' -Starts) 'Ambiente de Desenvolvimento: IDE local + emulador/dispositivo Android e a branch develop, publicada pela Vercel em https://amazon-track-web-develop.vercel.app.'
Set-ParaText (Find-P 'Ambiente de Teste/Homologação' -Starts) 'Ambiente de Homologação: branch release, publicada em https://amazon-track-web-release.vercel.app, onde QA valida a versão candidata (site + APK gerado pelo CI).'
Set-ParaText (Find-P 'Ambiente de Produção: onde o sistema' -Starts) 'Ambiente de Produção: branch main (Production Branch na Vercel), publicada em https://amazon-track-web.vercel.app, com o APK oficial disponível para download.'
Set-ParaText (Find-P 'O conceito “ambiente” envolve' -Starts) 'Pré-visualização: cada Pull Request (feature/*, hotfix/*) recebe automaticamente uma URL de Preview da Vercel, usada na revisão antes do merge.'

Set-ParaText (Find-P 'Ambiente destinado à implementação e testes iniciais' -Starts) 'Ambiente de integração contínua das funcionalidades. Todo merge de feature/* em develop dispara o CI no GitHub Actions e uma nova implantação de Preview na Vercel, associada ao domínio fixo do desenvolvimento.'
Set-ParaText (Find-P 'Ambiente intermediário usado para validação' -Starts) 'Ambiente intermediário de validação (Entrega Contínua). A branch release recebe o conteúdo de develop quando uma versão é congelada; a Vercel publica a versão candidata e o CI gera o APK de teste, que QA valida antes da promoção para produção.'
Set-ParaText (Find-P 'Treinamento') 'Pré-visualização de Pull Requests'
Set-ParaText (Find-P 'Ambiente criado para demonstrações' -Starts) 'Implantações efêmeras criadas pela Vercel para cada Pull Request aberto. A URL aparece como comentário/check no próprio PR do GitHub e permite revisar visualmente a mudança antes do merge, sem afetar desenvolvimento, homologação ou produção.'
Set-ParaText (Find-P 'Ambiente onde o sistema está disponível' -Starts) 'Ambiente onde o site e o APK oficial ficam disponíveis para barqueiros e passageiros. Contém a versão estável e aprovada, correspondente à branch main (Production Branch da Vercel) e à última tag vX.Y.Z.'

$localPath = 'C:\Users\joaog\OneDrive\Documents\amazontrackdata\website'
function Fill-Env($tbl, $hostName, $branch) {
  $trs = @($tbl.SelectNodes('w:tr', $ns))
  Set-RowCells $trs[1] @('DNS', 'Tipo', 'Nome', 'Dados')
  Set-RowCells $trs[2] @('', 'A', '@ (vercel.app)', '76.76.21.21 (anycast Vercel)')
  Set-RowCells $trs[3] @('', 'CNAME', $hostName.Split('.')[0], 'cname.vercel-dns.com')
  Set-RowCells $trs[4] @('', 'NS', 'vercel.app', 'ns1.vercel-dns.com / ns2.vercel-dns.com')
  Set-RowCells $trs[5] @('', 'Branch Git', $branch, $hostName)
  Set-RowCells $trs[6] @('Porta', '443 (HTTPS com certificado automático da Vercel)')
  Set-RowCells $trs[7] @('Caminho Físico', @("https://$hostName", 'ou', $localPath))
}
Fill-Env $tbls[5] 'amazon-track-web-develop.vercel.app' 'develop'
Fill-Env $tbls[6] 'amazon-track-web-release.vercel.app' 'release'
Fill-Env $tbls[7] 'amazon-track-web-git-<branch>-<conta>.vercel.app' 'feature/*, hotfix/* (PR)'
Set-Rows $tbls[8] @(
  @('DNS', 'amazon-track-web.vercel.app'),
  @('Registrant Country', 'Estados Unidos (US)'),
  @('IP-Address', '76.76.21.21'),
  @('Caminho Físico', @('https://amazon-track-web.vercel.app', 'ou', $localPath)),
  @('Provedor', 'Vercel Inc. (site) / GitHub Releases (APK) / Google Firebase (backend)')
) @(1, 2, 3, 4, 5)

# ---------------- 3. Identificação ----------------
Set-ParaText (Find-P 'Os itens de configuração serão identificados' -Starts) 'Os itens de configuração são identificados por siglas e por um identificador no formato <SIGLA>-ATD-<nnn> (ex.: PT-ATD-001). Arquivos de documentos seguem o padrão <Nome>_AmazonTrackData.<ext>; o código segue a estrutura de pastas do Flutter; versões do software seguem SemVer (pubspec.yaml: version: 1.0.0+1) e são marcadas com tags vX.Y.Z. A tabela a seguir apresenta as siglas adotadas.'
Set-Rows $tbls[9] @(
  @('PGC', 'Plano de Gerenciamento de Configuração (este documento)'),
  @('DRQ', 'Documento de Requisitos (Documento_de_Requisitos_AmazonTrackData)'),
  @('ARQ', 'Documento de Arquitetura de Software ISO/IEC/IEEE 42010'),
  @('DIA', 'Diagramas UML em PlantUML (casos de uso, classes, banco de dados)'),
  @('PT', 'Plano de Testes (PT-ATD-001)'),
  @('EAPT', 'Especificação de Análise e Projeto de Testes (EAPT-ATD-001)'),
  @('RRT', 'Relatório de Implementação, Execução e Resumo de Testes (RRT-ATD-001)'),
  @('GQS', 'Documento de Garantia da Qualidade de Software'),
  @('RFS', 'Regras de segurança do Firebase (Firestore e Storage)'),
  @('SRC', 'Código-fonte do aplicativo Flutter (lib/)'),
  @('WEB', 'Site institucional (website/)'),
  @('APK', 'Pacote de instalação Android gerado pelo build release'),
  @('CI', 'Workflow de integração/entrega contínua (.github/workflows/ci.yml)'),
  @('DEF', 'Registro de defeito (DEF-01 … DEF-nn), espelhado em Issue com rótulo bug'),
  @('MUD', 'Solicitação de mudança (MUD-nn), espelhada em Issue com rótulo mudanca'),
  @('BR', 'Branch'),
  @('REL', 'Release / versão (tag vX.Y.Z)')
)

$hIdent = Find-P 'Os itens de configuração são identificados' -Starts
$bulletTpl = Find-P 'Git - Ferramenta de controle de versão.'
$n = New-ParaAfter $tbls[9] $hIdent 'Convenções complementares:'
$n = New-ParaAfter $n $bulletTpl @(@('Branches: ', $true), @('feature/<nº-issue>-descricao-curta (ex.: feature/42-agendamento-vagas), hotfix/DEF-xx-descricao, além de main, release e develop.', $false))
$n = New-ParaAfter $n $bulletTpl @(@('Commits: ', $true), @('Conventional Commits – feat:, fix:, docs:, test:, ci:, refactor:, chore: – citando a issue (ex.: fix: impede vagas negativas no agendamento (#23)).', $false))
$n = New-ParaAfter $n $bulletTpl @(@('Tags: ', $true), @('vMAJOR.MINOR.PATCH criadas em main a cada liberação (baseline), coerentes com a versão do pubspec.yaml.', $false))
$n = New-ParaAfter $n $bulletTpl @(@('Documentos: ', $true), @('versão interna no histórico de revisões (1.0, 1.1, …) e versão do arquivo controlada pelo Git.', $false))

Set-Rows $tbls[10] @(
  @('Fase 1 – Requisitos (BL-1)', 'Documento de Requisitos (DRQ)'),
  @('', 'Diagramas de casos de uso (barqueiro e passageiro)'),
  @('', 'Plano de Gerenciamento de Configuração (PGC)'),
  @('Fase 2 – Arquitetura (BL-2)', 'Documento de Arquitetura ISO 42010 (ARQ)'),
  @('', 'Diagrama de classes'),
  @('', 'Diagrama do banco de dados (Firestore + SQLite)'),
  @('Fase 3 – Implementação (BL-3, tag v1.0.0)', 'Código-fonte do app Flutter (lib/) – versão 1.0.0+1'),
  @('', 'Regras do Firebase (Firestore e Storage)'),
  @('', 'Site institucional (website/)'),
  @('Fase 4 – Verificação e Validação (BL-4)', 'Plano de Testes PT-ATD-001 e EAPT-ATD-001'),
  @('', 'Testes automatizados (unitários, widget, integração)'),
  @('', 'Relatório de Resumo de Testes RRT-ATD-001'),
  @('Fase 5 – Implantação (BL-5, tag v1.1.0)', 'Workflow de CI/CD (.github/workflows/ci.yml)'),
  @('', 'APK release publicado em GitHub Releases e no site'),
  @('', 'Site em produção na Vercel (branch main)'),
  @('Encerramento', 'Todos os itens de configuração das fases anteriores'),
  @('', 'Relatório Final PIBITI e Resumo Expandido CONIC')
) @(1, 2, 3, 1, 2, 3, 1, 2, 3, 1, 2, 3, 1, 2, 3, 1, 2)

Set-ParaText (Find-P 'A estrutura do repositório define' -Starts) 'A estrutura do repositório https://github.com/Joaojsmaciel/PIBIT-AmazonTrackDataFlutter define como os artefatos estão organizados e versionados, incluindo as branches do GitFlow e os diretórios principais. Essa organização facilita o controle de versão, a rastreabilidade (issue → branch → commit → PR → deploy) e a colaboração.'

Set-Rows $tbls[11] @(
  @('main', 'Versão estável em produção (Production Branch da Vercel). Protegida: só recebe merge via PR de release ou hotfix/*, com CI aprovado. Cada merge gera uma tag vX.Y.Z.', 'Gerente de Projeto'),
  @('release', 'Versão candidata (homologação). Recebe develop quando a versão é congelada; aceita apenas correções. Publicada em amazon-track-web-release.vercel.app.', 'DevOps / QA'),
  @('develop', 'Integração contínua das novas features. Publicada em amazon-track-web-develop.vercel.app.', 'Equipe de desenvolvimento'),
  @('feature/*', 'Novas funcionalidades, correções não urgentes, testes e documentação. Criada a partir de develop e integrada via PR.', 'Desenvolvedor responsável'),
  @('hotfix/*', 'Correções urgentes de produção. Criada a partir de main, integrada em main e depois em develop.', 'DevOps / Desenvolvedor')
)

Set-Rows $tbls[12] @(
  @('lib/', 'Código-fonte do app Flutter (main.dart, rotas, configuração).', 'Desenvolvedores'),
  @('lib/core/', 'Constantes, serviços (GPS, geofence, sincronização offline), validadores e utilitários.', 'Desenvolvedores'),
  @('lib/data/', 'Modelos, datasources (Firebase e SQLite) e repositórios.', 'Desenvolvedores'),
  @('lib/presentation/', 'Telas, widgets, diálogos e providers Riverpod.', 'Desenvolvedores / UX'),
  @('assets/', 'Imagens e ícones do aplicativo.', 'Desenvolvedores / UX'),
  @('integration_test/', 'Testes de integração (app, barqueiro, passageiro).', 'QA / Dev'),
  @('android/ e ios/', 'Projetos nativos, google-services.json e configuração de assinatura.', 'DevOps'),
  @('website/', 'Site React + Vite publicado na Vercel (vercel.json, APK em public/downloads).', 'DevOps'),
  @('docs/', 'Documentação: requisitos, testes, GQS, entregáveis e regras do Firebase.', 'Analista de Requisitos / QA'),
  @('diagramas/ e Arquitetura/', 'Diagramas UML (PlantUML) e Documento de Arquitetura.', 'Arquiteto'),
  @('Gerencia de configuração/', 'PGC e roteiro de configuração de ambientes e CI/CD.', 'Gerente de Configuração'),
  @('.github/', 'Workflow de CI/CD, modelos de Issue (bug e mudança) e de Pull Request.', 'DevOps / Líder Técnico'),
  @('pubspec.yaml / pubspec.lock', 'Dependências e versão do app (version: 1.0.0+1).', 'Líder Técnico'),
  @('analysis_options.yaml', 'Regras de lint aplicadas no CI (flutter analyze).', 'Líder Técnico'),
  @('build/', 'Artefatos gerados pelo build (ignorado pelo Git).', 'DevOps'),
  @('.gitignore', 'Arquivos e pastas ignorados pelo Git.', 'Desenvolvedores / Líder Técnico'),
  @('README.md / CHANGELOG.md', 'Visão geral do projeto e histórico de versões.', 'Líder Técnico')
)

# ---------------- Mudanças ----------------
Set-ParaText (Find-P 'O processo de solicitação de mudança ocorre da seguinte maneira:') 'O processo de solicitação de mudança é executado no GitHub, garantindo rastreabilidade entre a solicitação (Issue), a implementação (branch e commits), a revisão (Pull Request) e a publicação (deploy na Vercel e tag):'
Set-ParaLabel (Find-P 'Submissão:' -Starts) 'Submissão: ' 'o solicitante abre uma Issue usando o modelo "Solicitação de mudança" ou "Relato de defeito", descrevendo o problema, a justificativa e os itens afetados.'
Set-ParaLabel (Find-P 'Avaliação:' -Starts) 'Avaliação: ' 'o CCB analisa impacto, prioridade e risco; a Issue recebe rótulos (mudanca/bug, prioridade-alta/media/baixa) e o status aprovado ou rejeitado.'
Set-ParaLabel (Find-P 'Planejamento:' -Starts) 'Planejamento: ' 'a Issue aprovada é associada a um marco (milestone) da próxima versão e a um responsável no GitHub Projects.'
Set-ParaLabel (Find-P 'Implementação:' -Starts) 'Implementação: ' 'o desenvolvedor cria feature/<nº>-descricao a partir de develop (ou hotfix/* a partir de main), com commits no padrão Conventional Commits.'
Set-ParaLabel (Find-P 'Aprovação:' -Starts) 'Aprovação: ' 'abre-se um PR para develop citando "Closes #nº"; o merge só ocorre com o CI aprovado, a revisão concluída e a Preview da Vercel verificada.'
Set-ParaLabel (Find-P 'Monitoramento:' -Starts) 'Monitoramento: ' 'a mudança segue para release (homologação) e, após validação de QA, para main (produção); a equipe acompanha o deploy e os logs.'
Set-ParaLabel (Find-P 'Documentação:' -Starts) 'Documentação: ' 'a Issue é fechada automaticamente pelo merge; a mudança é registrada no CHANGELOG.md, na tabela de mudanças deste plano e nas notas da release.'

Set-ParaText (Find-P 'É importante que o CCB tenha procedimentos' -Starts) 'O CCB avalia as solicitações semanalmente (ou de imediato para hotfix de produção) e comunica as decisões nos comentários da Issue. Seus membros são:'
Set-ParaText (Find-P 'Gerente de Mudanças:' -Starts) 'Gerente de Mudanças / Gerente de Projeto: João Gabriel da Silva Maciel (lidera o CCB e decide prioridades); Gerente de Configuração/DevOps: João Gabriel da Silva Maciel (avalia impacto nos ambientes e no pipeline); Orientador: Prof. Dr. Hidelbrando Ferreira Rodriguez (aprova mudanças de escopo e requisitos).'

# ---------------- Estimativa do status ----------------
$bodyTpl = Find-P 'O Plano de Gerenciamento de Configuração descreve todas' -Starts
$hStatus = Find-P 'Estimativa do Status de Configuração'
$s = New-ParaAfter $hStatus $bodyTpl 'O status de cada item de configuração é acompanhado diretamente nas ferramentas, que funcionam como registro oficial:'
$s = New-ParaAfter $s $bulletTpl @(@('Issues e GitHub Projects: ', $true), @('situação das solicitações (A fazer, Em andamento, Em revisão, Concluído) e dos defeitos DEF-xx.', $false))
$s = New-ParaAfter $s $bulletTpl @(@('Pull Requests: ', $true), @('aberto, aprovado, com CI aprovado/reprovado, mesclado.', $false))
$s = New-ParaAfter $s $bulletTpl @(@('GitHub Actions: ', $true), @('histórico de execuções do workflow CI por branch e commit.', $false))
$s = New-ParaAfter $s $bulletTpl @(@('Vercel – Deployments: ', $true), @('status (Ready, Error, Canceled) e ambiente de cada implantação.', $false))
$s = New-ParaAfter $s $bulletTpl @(@('Tags, Releases e CHANGELOG.md: ', $true), @('baselines liberadas e conteúdo de cada versão.', $false))

# ---------------- Armazenamento e liberação ----------------
Set-ParaText (Find-P 'O processo de armazenamento e liberação do projeto inclui' -Starts) 'O processo de armazenamento e liberação define onde os itens de configuração ficam guardados, como são protegidos e como cada versão chega à produção.'
Remove-Node (Find-P 'A política de retenção é baseada no ciclo de vida' -Starts)
Remove-Node (Find-P 'O plano de backup baseia-se em uma cópia' -Starts)
Remove-Node (Find-P 'O processo de liberação ocorre da seguinte maneira' -Starts)
Remove-Node (Find-P 'O que se espera conter nesse tópico:')
Set-ParaText (Find-P 'Onde os artefatos são guardados' -Starts) 'Código, documentação, diagramas e configurações ficam no repositório GitHub (origem oficial). Builds do APK ficam como artefatos do GitHub Actions e anexos das GitHub Releases; o site publicado fica na Vercel; dados do app ficam no Firebase.' $false
Set-ParaText (Find-P 'Como são organizados e protegidos' -Starts) 'Organização pela estrutura de pastas da seção 3.1.3. As branches main e release são protegidas (merge apenas por PR com CI aprovado); segredos (chaves, tokens) ficam em GitHub Secrets e nas Environment Variables da Vercel, nunca no código.' $false
Set-ParaText (Find-P 'Frequência e forma de backup' -Starts) 'Cada push é uma cópia completa e distribuída do repositório (GitHub + clones locais). O diretório local também é sincronizado com o OneDrive; a cada release é feita exportação do Firestore e cópia do APK assinado e da keystore em mídia separada.' $false
Set-ParaText (Find-P 'Por quanto tempo os dados' -Starts) 'Histórico Git, tags e releases: por todo o ciclo de vida do projeto e após o encerramento (repositório arquivado). Artefatos de CI: 30 dias. Implantações da Vercel: mantidas conforme a política do plano Hobby, sendo possível reverter para qualquer deploy anterior.' $false
Set-ParaText (Find-P 'Quem autoriza a liberação' -Starts) 'Homologação: Gerente de Configuração, ao mesclar develop em release. Produção: Gerente de Projeto, ao aprovar o PR release → main, após o aceite de QA.' $false
Set-ParaText (Find-P 'Como as versões são disponibilizadas' -Starts) 'develop (testes internos) → release (homologação em amazon-track-web-release.vercel.app + APK de teste do CI) → main (produção em amazon-track-web.vercel.app + tag vX.Y.Z + GitHub Release com o APK).' $false
Set-ParaText (Find-P 'Finalidade: validar antes' -Starts) 'Finalidade: validar cada versão em um ambiente idêntico ao de produção antes da entrega, reduzindo o risco para barqueiros e passageiros e permitindo rollback imediato pela Vercel (Instant Rollback) em caso de falha.' $false

# ---------------- Relatórios e auditorias ----------------
Set-ParaText (Find-P 'Os relatórios podem ser gerados em diferentes formatos' -Starts) 'No projeto são usados relatórios baseados em períodos, que mostram há quanto tempo cada defeito está pendente e o tempo de retardo entre a detecção e a correção. Cada defeito é registrado como Issue no GitHub (rótulo bug, título "DEF-xx: …"), corrigido em uma branch hotfix/DEF-xx ou feature/DEF-xx e fechado pelo PR que contém a correção ("Closes #nº"), deixando a evidência no repositório.'
Set-ParaText (Find-P 'A seguir pode-se observar uma tabela de relatório' -Starts) 'A tabela a seguir registra os defeitos encontrados na campanha de testes de 10/10/2026 (Relatório RRT-ATD-001, versão 1.0.0+1). Defeitos ainda não corrigidos aparecem como "Em aberto", com o retardo contado até 03/11/2026.'

$defs = @(
  @('DEF-01', 'Regras do Firestore permitem acesso horizontal entre usuários', 'Crítica'),
  @('DEF-02', 'Upload de foto negado: app usa boat_images/, regra libera imagens_embarcacoes/', 'Média'),
  @('DEF-03', 'Ponto salvo durante uma sincronização é sobrescrito na fila OfflineSyncService', 'Média'),
  @('DEF-04', 'Indicador de pendentes do mapa lê uma fila que nunca é alimentada', 'Alta'),
  @('DEF-05', 'Debounce único por porto suprime alertas de atracação e saída', 'Média'),
  @('DEF-06', 'Estado de geofence alterna a cada leitura com ruído de ±5 m no limite', 'Média'),
  @('DEF-07', 'Coordenadas e precisão inválidas aceitas na fila local', 'Média'),
  @('DEF-08', 'LocationModel.copyWith descarta boatId; igualdade ignora boatId', 'Baixa'),
  @('DEF-09', 'Cadastro aceita CPF já usado por outra conta', 'Alta'),
  @('DEF-10', 'Conta inativa (isActive=false) autentica normalmente', 'Alta'),
  @('DEF-11', 'Perfil completo com CPF registrado em log', 'Alta'),
  @('DEF-12', 'Build release assinado com a chave de depuração', 'Alta'),
  @('DEF-13', 'Erro de login exibe a estrutura interna Failure(message, code)', 'Média'),
  @('DEF-14', 'Contraste de texto 4,22:1 abaixo do mínimo WCAG AA (4,5:1)', 'Média'),
  @('DEF-15', 'Botão de mostrar/ocultar senha sem rótulo semântico', 'Média'),
  @('DEF-16', 'Overflow de 182 px no cadastro em tela de 320 dp com fonte 1,5×', 'Média'),
  @('DEF-17', 'Capacidade "abc" ou "-5" aceita no cadastro de embarcação', 'Média'),
  @('DEF-18', 'Números formatados com ponto decimal ("1.5 km")', 'Baixa'),
  @('DEF-19', 'CPF exibido completo na tela de perfil', 'Baixa'),
  @('DEF-20', 'Posição desatualizada é ocultada sem aviso ao passageiro', 'Baixa'),
  @('DEF-21', 'Embarcação desativada continua na lista "Minhas Embarcações"', 'Média'),
  @('DEF-22', 'Formulário de agendamento sem campo de chegada estimada', 'Média'),
  @('DEF-23', 'Agendamento aceita número negativo de vagas', 'Média'),
  @('DEF-24', 'Diálogo de início de viagem usa context depois de fechado', 'Média')
)
$defRows = foreach ($d in $defs) { , @($d[0], $d[1], $d[2], 'João Gabriel da Silva Maciel', '10/10/2026', 'Em aberto', '24 (em aberto)') }
Set-Rows $tbls[13] $defRows

Set-Rows $tbls[14] @(
  @('MUD-00', 'Protótipo Android nativo com autenticação Firebase e coleta de localização (repositório Joaojsmaciel/AmazonTrackData, commits bcb17a8 a cb858a5).', 'Alta', 'João Gabriel da Silva Maciel e Alica de Souza Miranda', '30/12/2025', '05/01/2026'),
  @('MUD-01', 'Estrutura inicial do app Flutter (commit 69f286a – Initial commit).', 'Alta', 'João Gabriel da Silva Maciel', '20/04/2026', '20/04/2026'),
  @('MUD-02', 'Novos modelos de dados e telas de barqueiro e passageiro (commit 1298910).', 'Alta', 'João Gabriel da Silva Maciel', '21/04/2026', '08/07/2026'),
  @('MUD-03', 'Site institucional React/Vite (website/) com download do APK, publicado na Vercel no projeto amazon-track-web (commit b51fa66).', 'Alta', 'João Gabriel da Silva Maciel', '09/07/2026', '16/07/2026'),
  @('MUD-04', 'Melhorias no rastreamento, UI de barcos e telas do passageiro (commit c9f1978).', 'Média', 'João Gabriel da Silva Maciel', '17/07/2026', '11/08/2026'),
  @('MUD-05', 'Suíte de testes de integração (integration_test/), sqflite_common_ffi e exclusões de lint.', 'Média', 'João Gabriel da Silva Maciel', '12/08/2026', '10/10/2026'),
  @('MUD-06', 'Adoção do GitFlow (develop, release, main), conexão do projeto amazon-track-web da Vercel a este repositório e ambientes por branch.', 'Alta', 'João Gabriel da Silva Maciel', '03/11/2026', 'Em andamento'),
  @('MUD-07', 'Pipeline de CI/CD no GitHub Actions (analyze, testes, build do app e do site, release do APK).', 'Alta', 'João Gabriel da Silva Maciel', '03/11/2026', '03/11/2026'),
  @('MUD-08', 'Modelos de Issue (bug, mudança), de Pull Request e CHANGELOG.md.', 'Média', 'João Gabriel da Silva Maciel', '03/11/2026', '03/11/2026'),
  @('MUD-09', 'Elaboração do Plano de Gerenciamento de Configuração (este documento).', 'Média', 'João Gabriel da Silva Maciel', '03/11/2026', '03/11/2026')
)

$aud = Find-P 'As auditorias de configuração são usadas' -Starts
Set-ParaText $aud 'As auditorias de configuração verificam se os procedimentos deste plano estão sendo seguidos e se os registros estão precisos e completos. São realizadas pela equipe interna antes de cada promoção para produção (release → main) e ao final de cada fase, usando o checklist abaixo; o resultado é registrado como comentário no PR de release.'
$a = New-ParaAfter $aud $bulletTpl @(@('Auditoria funcional (FCA): ', $true), @('todos os itens da release têm Issue fechada, PR mesclado e testes aprovados no CI.', $false))
$a = New-ParaAfter $a $bulletTpl @(@('Auditoria física (PCA): ', $true), @('a tag vX.Y.Z, a versão do pubspec.yaml, o APK da GitHub Release e o deploy de produção na Vercel correspondem ao mesmo commit.', $false))
$a = New-ParaAfter $a $bulletTpl @(@('Auditoria de processo: ', $true), @('nenhum commit direto em main/release; branches e commits seguem as convenções; CHANGELOG.md e as tabelas de defeitos e mudanças deste plano foram atualizados.', $false))

# ---------------- Marcos ----------------
$m = @(
  @('Integração contínua (merge de feature/* em develop com CI aprovado): ', 'Marco de Integração (CI).'),
  @('Build e testes automáticos no GitHub Actions (flutter analyze, flutter test, build do APK e do site): ', 'Artefato de software verificado.'),
  @('Merge de develop em release e deploy automático em amazon-track-web-release.vercel.app: ', 'Marco de Entrega Contínua (CD – homologação).'),
  @('Validação da release por QA e auditoria de configuração: ', 'Marco de verificação / aprovação.'),
  @('Merge de release em main, deploy em produção, tag vX.Y.Z e GitHub Release com o APK: ', 'Marco de Implantação Contínua (CD – produção).'),
  @('Monitoramento (Vercel Deployments, Firebase, feedback de barqueiros e passageiros): ', 'Marco de melhoria contínua / operação (Ops).')
)
$starts = @('Integração contínua de artefatos', 'Geração automática de build', 'Criação da release e deploy', 'Validação da release pela equipe', 'Deploy automático da release aprovada', 'Monitoramento e feedback')
for ($i = 0; $i -lt 6; $i++) { Set-ParaRich (Find-P $starts[$i] -Starts) @(@($m[$i][0], $null), @($m[$i][1], $true)) }

# ---------------- Treinamento e recursos ----------------
$g = Find-P 'Git - Ferramenta de controle de versão.'
Set-ParaText $g 'Git e GitHub – controle de versão, Pull Requests, Issues e Releases.'
Set-ParaText (Find-P 'Visual Studio Code - Ferramenta para criação e edição de códigos.') 'GitHub Actions e Vercel – integração, entrega e implantação contínuas.'
Set-ParaText (Find-P 'Trello - Ferramenta de gerenciamento de trabalho.') 'Flutter SDK, Android Studio e VS Code/Cursor – desenvolvimento e testes do app.'
Set-ParaText (Find-P 'Treinamento de Git') 'Git e GitFlow (branches, PR, resolução de conflitos, tags).'
Set-ParaText (Find-P 'Treinamento de Trello') 'GitHub Actions e Vercel (material de DevOps disponibilizado no Classroom e documentação oficial).'
$t2 = Find-P 'GitHub Actions e Vercel (material de DevOps' -Starts
[void](New-ParaAfter $t2 $t2 'Testes automatizados em Flutter (flutter_test, integration_test) e Firebase Emulator.')
Set-ParaText (Find-P 'Equipe de desenvolvimento: responsável por desenvolver' -Starts) 'Equipe de desenvolvimento e QA: responsável por desenvolver, testar e integrar os itens de configuração seguindo o fluxo de branches e PRs.'

Set-ParaText (Find-P 'No projeto não será preciso incorporar' -Starts) 'O projeto não incorpora desenvolvimento de software subcontratado. Os serviços de terceiros (GitHub, Vercel e Google Firebase) são usados como plataformas, com configuração versionada no repositório (vercel.json, regras do Firebase, workflows). As bibliotecas externas (pacotes pub.dev e npm) são controladas por versões declaradas em pubspec.yaml e package.json e fixadas em pubspec.lock e package-lock.json; atualizações seguem o processo de solicitação de mudança.'

# ---------------- save ----------------
$settings = New-Object Xml.XmlDocument; $settings.PreserveWhitespace = $true
$sp = Join-Path $outDir 'word\settings.xml'; $settings.Load($sp)
$sns = New-Object Xml.XmlNamespaceManager $settings.NameTable; $sns.AddNamespace('w', $W)
if (-not $settings.SelectSingleNode('//w:updateFields', $sns)) {
  $uf = $settings.CreateElement('w', 'updateFields', $W)
  $ufa = $settings.CreateAttribute('w', 'val', $W); $ufa.Value = 'true'; [void]$uf.Attributes.Append($ufa)
  $before = $null
  foreach ($nm in 'hdrShapeDefaults', 'footnotePr', 'endnotePr', 'compat', 'docVars', 'rsids', 'mathPr', 'themeFontLang', 'clrSchemeMapping', 'decimalSymbol', 'listSeparator') {
    $before = $settings.DocumentElement.SelectSingleNode("w:$nm", $sns); if ($before) { break }
  }
  if ($before) { [void]$settings.DocumentElement.InsertBefore($uf, $before) } else { [void]$settings.DocumentElement.AppendChild($uf) }
}
$enc = New-Object Text.UTF8Encoding $false
$wr = New-Object IO.StreamWriter($sp, $false, $enc); $settings.Save($wr); $wr.Close()
$wr = New-Object IO.StreamWriter((Join-Path $outDir 'word\document.xml'), $false, $enc); $x.Save($wr); $wr.Close()

foreach ($hf in @(@('header2.xml', '> logo da empresa<', '>UFAM – PIBITI | AmazonTrackData<'), @('footer3.xml', '>PO– Gerenciamento de Configuração<', '>AmazonTrackData – Plano de Gerenciamento de Configuração<'))) {
  $hp = Join-Path $outDir "word\$($hf[0])"
  $c = [IO.File]::ReadAllText($hp, [Text.Encoding]::UTF8).Replace($hf[1], $hf[2])
  [IO.File]::WriteAllText($hp, $c, $enc)
}

if (Test-Path $outDocx) { Remove-Item $outDocx -Force }
$zip = [IO.Compression.ZipFile]::Open($outDocx, 'Create')
$files = Get-ChildItem $outDir -Recurse -File | Sort-Object { if ($_.Name -eq '[Content_Types].xml') { 0 } else { 1 } }
foreach ($f in $files) {
  $entry = $f.FullName.Substring($outDir.Length + 1).Replace('\', '/')
  [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $f.FullName, $entry, 'Optimal')
}
$zip.Dispose()
"OK -> $outDocx"
