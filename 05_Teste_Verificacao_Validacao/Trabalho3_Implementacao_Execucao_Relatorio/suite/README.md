# Suíte de testes — AmazonTrackData (RRT-ATD-001 v3.0)

Implementa os casos de teste do EAPT-ATD-001 que podem ser executados sem dispositivo (níveis U, W, R e E).
Cada teste é nomeado com o identificador do caso (`CT-xxx-nn`).

| Pasta | Conteúdo | Testes |
|---|---|---:|
| `gqs/` | Testes herdados de Gestão da Qualidade de Software (modelos e validadores) | 105 |
| `unit/` | Validadores, modelos, geofencing, SQLite, repositórios e sincronização offline | 105 |
| `widget/` | Telas de login, cadastro e embarcação; diretrizes de acessibilidade | 16 |
| `static/` | Inspeção de código e configuração (logs, segredos, assinatura, TLS, regras, web) | 8 |
| `firebase_rules/` | Regras Firestore/Storage no Firebase Emulator (vigentes de `docs/`; `RULES=proposta` avalia a proposta da v2.0, mantida como registro) | 27 |
| `helpers/` | Ambiente de host (`test_env.dart`) e dublês de Firebase/GPS (`fakes.dart`) | — |

## Pré-requisitos

- Flutter 3.47 ou superior (`flutter pub get` na raiz do repositório; usa `sqflite_common_ffi` de `dev_dependencies`).
- Para as regras: Node.js 20 ou superior e JDK 21 (exigido pelo `firebase-tools` 14).

## Execução

Na raiz do repositório (PowerShell):

```powershell
$S = "Teste Verificação e validação/Trabalho3_Implementacao_Execucao_Relatorio"

# Flutter (unitários, widget e inspeção)
flutter test "$S/suite/gqs" "$S/suite/unit" "$S/suite/widget" "$S/suite/static" --reporter expanded
flutter test "$S/suite/gqs" "$S/suite/unit" "$S/suite/widget" "$S/suite/static" --reporter json > "$S/resultados/flutter_test_resultado.json"

# Regras Firebase
cd "$S/suite/firebase_rules"
npm install
npm test                           # regras vigentes de docs/*.txt
$env:RULES = "proposta"; npm test  # regras propostas desta pasta
```

Para consolidar: `resultados/resumir.ps1` (por arquivo) e `node resultados/consolidar_por_caso.mjs` (por caso; lê o JSON do Flutter e o JUnit das regras, que deve ser copiado de `firebase_rules/resultado-regras.xml` para `resultados/regras_<vigente|proposta>_junit.xml`).

## Observações

- No Windows, `flutter analyze` falha em caminhos com acentos (Dart 3.13). Use uma unidade temporária: `subst T: <repositório>` e analise `T:\<nome curto da pasta>\...`.
- Na versão 1.0.0+1 (v2.0 do relatório) havia 23 falhas em Flutter e 8 nas regras, todas ligadas a DEF-01 a DEF-18. Com as correções da branch `fix/aceite-v1.1` (v3.0), a suíte inteira é aprovada: 234 testes Flutter e 27 de regras.
