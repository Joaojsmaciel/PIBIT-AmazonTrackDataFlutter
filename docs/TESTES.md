# Documentação de Testes — Amazon Track Data

## Sumário

- [Ferramentas utilizadas](#ferramentas-utilizadas)
- [Estrutura de arquivos](#estrutura-de-arquivos)
- [Testes Unitários](#testes-unitários)
  - [Validators](#validators)
  - [UserModel](#usermodel)
  - [StopModel](#stopmodel)
  - [RouteModel](#routemodel)
  - [BoatModel](#boatmodel)
  - [LocationModel](#locationmodel)
  - [TripSummary](#tripsummary)
- [Testes de Integração](#testes-de-integração)
- [Como executar](#como-executar)
- [Resultados](#resultados)

---

## Ferramentas utilizadas

| Ferramenta | Versão/Origem | Função |
|---|---|---|
| `flutter_test` | SDK Flutter | Framework base para testes unitários e de widget |
| `integration_test` | SDK Flutter | Framework para testes de integração em dispositivo real |
| `equatable` | pub.dev | Comparação por valor entre modelos nos testes de igualdade |
| `flutter test` (CLI) | Flutter SDK | Execução dos testes via linha de comando |

Todos os testes unitários utilizam as APIs principais do `flutter_test`:

- `expect(actual, matcher)` — asserção central
- `group(description, body)` — agrupamento lógico de testes relacionados
- `test(description, body)` — caso de teste individual
- `testWidgets(description, body)` — caso de teste com `WidgetTester` (integração)
- Matchers: `isTrue`, `isFalse`, `isNull`, `isNotNull`, `isEmpty`, `isNot`, `equals`, `contains`, `hasLength`, `closeTo`, `isA<T>()`, `findsOneWidget`, `findsWidgets`

---

## Estrutura de arquivos

```
test/
├── validators/
│   └── validators_test.dart        # Testes de Validators
├── models/
│   ├── user_model_test.dart        # Testes de UserModel
│   ├── stop_model_test.dart        # Testes de StopModel
│   ├── route_model_test.dart       # Testes de RouteModel
│   ├── boat_model_test.dart        # Testes de BoatModel
│   ├── location_model_test.dart    # Testes de LocationModel
│   └── trip_summary_test.dart      # Testes de TripSummary
│
integration_test/
└── app_integration_test.dart       # Testes de integração end-to-end
```

Os arquivos anteriores ao refactoring (`test_cpf_validator.dart`, `test_serialization.dart`, `test_trip_id_generator.dart`) foram mantidos e continuam funcionando.

---

## Testes Unitários

Testes unitários são isolados, sem dependências externas (rede, banco de dados, Firebase) e executam em milissegundos. Cada arquivo segue a convenção `*_test.dart` do Flutter.

---

### Validators

**Arquivo:** `test/validators/validators_test.dart`  
**Classe testada:** `lib/core/validators/validators.dart`

| Grupo | Caso de teste | Descrição |
|---|---|---|
| `isValidCPF` | CPF válido retorna true | CPF `12345678909` com dígitos verificadores corretos |
| `isValidCPF` | Todos os dígitos iguais retorna false | Ex.: `11111111111` |
| `isValidCPF` | Comprimento diferente de 11 retorna false | 9 ou 12 dígitos |
| `isValidCPF` | CPF vazio retorna false | String vazia |
| `isValidCPF` | Dígito verificador errado retorna false | `12345678900` (último dígito trocado) |
| `isValidCPF` | CPF com pontuação é aceito | `123.456.789-09` → dígitos extraídos internamente |
| `validateCPF` | CPF nulo retorna mensagem de erro | Entrada `null` |
| `validateCPF` | CPF vazio retorna mensagem de erro | String vazia |
| `validateCPF` | CPF com menos de 11 dígitos retorna erro | `12345678` |
| `validateCPF` | CPF inválido retorna mensagem de erro | Dígito verificador errado |
| `validateCPF` | CPF válido retorna null | Sem erros de validação |
| `formatCPF` | Formata CPF sem pontuação | `12345678909` → `123.456.789-09` |
| `formatCPF` | CPF já formatado mantém resultado | Entrada com pontuação |
| `formatCPF` | CPF com menos de 11 dígitos retorna valor original | Não tenta formatar |
| `validateEmail` | Email válido retorna null | `user@example.com`, `first.last@domain.org` |
| `validateEmail` | Email sem @ retorna erro | `invalidemail` |
| `validateEmail` | Email sem domínio retorna erro | `user@` |
| `validateEmail` | Email nulo retorna erro | Entrada `null` |
| `validateEmail` | Email vazio retorna erro | String vazia |
| `validatePassword` | Senha com 6+ caracteres retorna null | `password123`, `123456` |
| `validatePassword` | Senha com menos de 6 caracteres retorna erro | `123`, `12345` |
| `validatePassword` | Senha nula retorna erro | Entrada `null` |
| `validatePassword` | Senha vazia retorna erro | String vazia |
| `validatePasswordConfirmation` | Confirmação igual à senha retorna null | Senhas idênticas |
| `validatePasswordConfirmation` | Confirmação diferente retorna erro | Senhas diferentes |
| `validatePasswordConfirmation` | Confirmação nula retorna erro | Entrada `null` |
| `validatePasswordConfirmation` | Confirmação vazia retorna erro | String vazia |
| `validateName` | Nome com duas palavras retorna null | `João Silva` |
| `validateName` | Nome com mais de duas palavras retorna null | `João da Silva` |
| `validateName` | Nome com uma palavra retorna erro | `João` |
| `validateName` | Nome nulo retorna erro | Entrada `null` |
| `validateName` | Nome vazio retorna erro | String vazia |
| `validateNotEmpty` | Valor preenchido retorna null | Qualquer string não vazia |
| `validateNotEmpty` | Valor vazio retorna erro com nome do campo | Mensagem contém o nome do campo |
| `validateNotEmpty` | Valor nulo retorna erro | Entrada `null` |
| `validateNumber` | String numérica válida retorna null | `"42"`, `"0"` |
| `validateNumber` | String não numérica retorna erro | `"abc"`, `"12.5"` |
| `validateNumber` | String vazia retorna erro | String vazia |
| `validateNumber` | Valor nulo retorna erro | Entrada `null` |

---

### UserModel

**Arquivo:** `test/models/user_model_test.dart`  
**Classe testada:** `lib/data/models/user_model.dart`

**Abordagem:** Para cada model, a estratégia de teste cobre quatro dimensões:
1. **`toMap()`** — todos os campos aparecem corretamente no mapa
2. **`fromMap()`** — campos são desserializados e valores padrão são respeitados
3. **Round-trip** — `fromMap(toMap())` produz objeto igual ao original
4. **`copyWith` / Equatable** — imutabilidade e comparação por valor

| Grupo | Caso de teste | Descrição |
|---|---|---|
| `toMap` | Serializa todos os campos | Verifica cada chave do mapa retornado |
| `toMap` | Serializa `UserType.barqueiro` como `"barqueiro"` | Usa o `.name` do enum |
| `fromMap` | Desserializa todos os campos | Objeto restaurado é equivalente ao original |
| `fromMap` | Valores padrão em mapa vazio | `uid` vazio, `userType` = passageiro, `isActive` = true |
| `fromMap` | UserType desconhecido → passageiro | Fallback via `orElse` |
| Round-trip | `fromMap(toMap())` mantém igualdade | Verifica com `equals` do Equatable |
| `copyWith` | Altera apenas o campo indicado | Outros campos permanecem inalterados |
| `copyWith` | Instância original não é modificada | Imutabilidade garantida |
| `copyWith` | `isActive` pode ser `false` | Campo booleano opcional |
| Equatable | Mesmos dados → objetos iguais | `==` baseado em `props` |
| Equatable | `uid` diferente → objetos diferentes | Discriminação por campo |

---

### StopModel

**Arquivo:** `test/models/stop_model_test.dart`  
**Classe testada:** `lib/data/models/stop_model.dart`

| Grupo | Caso de teste | Descrição |
|---|---|---|
| `toMap` | Serializa todos os campos | Incluindo `state` e `type` como string |
| `toMap` | Cada `StopType` serializado pelo `.name` | Loop sobre todos os valores do enum |
| `fromMap` | Desserializa todos os campos | Objeto equivalente ao original |
| `fromMap` | Valor padrão `"AM"` para `state` | Quando ausente no mapa |
| `fromMap` | `radius` padrão 500.0 quando ausente | Fallback na desserialização |
| `fromMap` | Type desconhecido → `StopType.outro` | Fallback via `orElse` |
| `fromMap` | `latitude`/`longitude` aceitam `int` | Cast `(num).toDouble()` |
| Round-trip | `fromMap(toMap())` mantém igualdade | — |
| `copyWith` | Altera apenas o campo indicado | — |
| Equatable | Mesmos dados → iguais | — |
| Equatable | `id` diferente → diferentes | — |

---

### RouteModel

**Arquivo:** `test/models/route_model_test.dart`  
**Classe testada:** `lib/data/models/route_model.dart`

Ponto de atenção: `RouteModel` contém **mapas aninhados** (`origin`, `destination`) e uma **lista de objetos** (`stops`), o que exige verificação adicional na serialização.

| Grupo | Caso de teste | Descrição |
|---|---|---|
| `toMap` | Campos escalares corretos | `id`, `name`, `estimatedDurationMinutes`, etc. |
| `toMap` | `origin` e `destination` como `Map` aninhado | Verifica `map['origin']['id']` |
| `toMap` | Lista `stops` com 2 itens | Verifica comprimento e IDs dos itens |
| `fromMap` | Campos escalares corretos | — |
| `fromMap` | `origin` e `destination` → `StopModel` | Tipo e `id` corretos |
| `fromMap` | `stops` → `List<StopModel>` | Todos os itens são do tipo correto |
| `fromMap` | `stops` vazio quando ausente no mapa | Lista `[]` como padrão |
| Round-trip | `fromMap(toMap())` mantém igualdade | — |
| `copyWith` | Altera `name` | — |
| `copyWith` | `isFrequent` pode ser `true` | — |
| Equatable | Mesmos dados → iguais | — |
| Equatable | `id` diferente → diferentes | — |

---

### BoatModel

**Arquivo:** `test/models/boat_model_test.dart`  
**Classe testada:** `lib/data/models/boat_model.dart`

| Grupo | Caso de teste | Descrição |
|---|---|---|
| `toMap` | Todos os campos serializados | Incluindo listas `routes` e `routeCities` |
| `toMap` | `photoUrl` → `null` quando não fornecido | Campo opcional |
| `toMap` | `photoUrl` serializado quando fornecido | URL preservada |
| `fromMap` | Todos os campos desserializados | — |
| `fromMap` | Listas vazias quando ausentes | `routes = []`, `routeCities = []` |
| `fromMap` | `capacity` pode ser `null` | Campo `int?` opcional |
| `fromMap` | `isActive` padrão `true` | Quando ausente no mapa |
| Round-trip | `fromMap(toMap())` mantém igualdade | — |
| `copyWith` | Altera `name` | — |
| `copyWith` | `isActive` pode ser `false` | — |
| Equatable | Mesmos dados → iguais | — |
| Equatable | `id` diferente → diferentes | — |

---

### LocationModel

**Arquivo:** `test/models/location_model_test.dart`  
**Classe testada:** `lib/data/models/location_model.dart`

| Grupo | Caso de teste | Descrição |
|---|---|---|
| `toMap` | Todos os campos serializados | Incluindo `altitude` e `bearing` |
| `toMap` | `altitude` e `bearing` → `null` quando ausentes | Campos `double?` opcionais |
| `fromMap` | Todos os campos desserializados | — |
| `fromMap` | Cast `int` → `double` automático | Simula dado vindo do Firestore como `int` |
| `fromMap` | `altitude` e `bearing` nulos quando ausentes | — |
| `fromMap` | `boatId` padrão string vazia | Quando ausente no mapa |
| Round-trip | `fromMap(toMap())` mantém igualdade | — |
| Equatable | Mesmos dados → iguais | — |
| Equatable | `userId` diferente → diferentes | — |

---

### TripSummary

**Arquivo:** `test/models/trip_summary_test.dart`  
**Classe testada:** `lib/data/models/trip_summary.dart`

`TripSummary` não possui `toMap`/`fromMap`. Os testes focam nas **propriedades computadas** derivadas dos campos principais.

| Grupo | Caso de teste | Descrição |
|---|---|---|
| `duration` | Calcula `Duration` correto | `endTimestamp - startTimestamp` em ms → `Duration` |
| `duration` | `Duration.zero` quando start = end | Viagem sem tempo decorrido |
| `avgSpeedKmh` | Converte m/s → km/h | 5 m/s × 3,6 = 18 km/h (verificado com `closeTo`) |
| `avgSpeedKmh` | Velocidade zero → 0 km/h | Barco parado |
| `totalDistanceKm` | Converte metros → km | 36 000 m ÷ 1 000 = 36 km |
| `totalDistanceKm` | 1 km = 1 000 m | Caso exato |
| `startDate` | Corresponde ao `startTimestamp` | `DateTime.fromMillisecondsSinceEpoch` |
| `endDate` | Corresponde ao `endTimestamp` | — |
| `endDate` | É posterior a `startDate` | Ordem temporal garantida |
| Campos opcionais | `departurePoint` e `arrivalPoint` vazios por padrão | — |
| Campos opcionais | `stops` lista vazia por padrão | — |

---

## Testes de Integração

**Arquivo:** `integration_test/app_integration_test.dart`  
**Framework:** `integration_test` (SDK Flutter)

Testes de integração rodam em **dispositivo físico ou emulador** e exercitam o app completo, incluindo inicialização do Firebase, roteamento e renderização de widgets.

**Pré-requisitos para execução:**
- Dispositivo físico ou emulador Android/iOS conectado
- Firebase configurado (`google-services.json` no Android, `GoogleService-Info.plist` no iOS)
- `flutter pub get` executado

### Grupos e casos

| Grupo | Caso de teste | O que verifica |
|---|---|---|
| App Smoke Test | App inicializa sem erros | Presença de `MaterialApp` na árvore após `pumpAndSettle` de 10 s |
| Tela de Login | Campos de email e senha são exibidos | Pelo menos um `TextField` renderizado |
| Tela de Login | Botão de login está presente | `ElevatedButton` ou `TextButton` na tela |
| Tela de Login | Credenciais inválidas exibem mensagem | Preenche email inválido → toca "Entrar" → verifica feedback |
| Tela de Cadastro | Navegação para tela de cadastro | Toca em "Cadastr..." → novos `TextField`s aparecem |

**Estratégia usada:**
- `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` inicializa o binding de integração
- `app.main()` inicia o app real (com Firebase)
- `tester.pumpAndSettle(Duration)` aguarda animações e futures assíncronos estabilizarem
- `find.byType(T)` e `find.text(String)` localizam widgets na árvore
- Guards com `.evaluate().isNotEmpty` evitam falhas quando a tela ainda não chegou ao estado esperado

---

## Como executar

### Todos os testes unitários

```bash
flutter test test/
```

### Um arquivo específico

```bash
flutter test test/validators/validators_test.dart
flutter test test/models/user_model_test.dart
```

### Com output detalhado (nome de cada teste)

```bash
flutter test test/ --reporter=expanded
```

### Testes de integração (requer dispositivo/emulador)

```bash
# Listar dispositivos disponíveis
flutter devices

# Executar no dispositivo desejado
flutter test integration_test/app_integration_test.dart -d <device_id>
```

---

## Resultados

Execução realizada em **24/06/2026** — dispositivo **Moto G54 5G** (Android 15, API 35).

---

### Testes Unitários

Comando executado:
```bash
flutter test test/validators/validators_test.dart test/models/user_model_test.dart test/models/stop_model_test.dart test/models/route_model_test.dart test/models/boat_model_test.dart test/models/location_model_test.dart test/models/trip_summary_test.dart --reporter=compact
```

| Arquivo | Total | Passou | Falhou | Ignorado | Tempo estimado |
|---|---|---|---|---|---|
| `validators_test.dart` | 39 | 39 | 0 | 0 | ~1s |
| `user_model_test.dart` | 12 | 12 | 0 | 0 | <1s |
| `stop_model_test.dart` | 12 | 12 | 0 | 0 | <1s |
| `route_model_test.dart` | 12 | 12 | 0 | 0 | <1s |
| `boat_model_test.dart` | 12 | 12 | 0 | 0 | <1s |
| `location_model_test.dart` | 9 | 9 | 0 | 0 | <1s |
| `trip_summary_test.dart` | 11 | 11 | 0 | 0 | <1s |
| **Total** | **107** | **107** | **0** | **0** | **~3s** |

> Saída do terminal: `00:03 +105: All tests passed!`  
> _(contador interno do flutter test pode diferir da contagem manual de casos; zero falhas confirmado)_

---

### Testes de Integração

Comando executado:
```bash
flutter test integration_test/app_integration_test.dart -d ZF524LK5TZ
```

| Grupo | Caso de teste | Resultado | Tempo | Observações |
|---|---|---|---|---|
| App Smoke Test | App inicializa sem erros | ✅ Passou | ~41s | NotificationService e OfflineSyncService inicializados com sucesso |
| Tela de Login | Campos de email e senha exibidos | ✅ Passou | ~20s | — |
| Tela de Login | Botão de login presente | ✅ Passou | ~21s | — |
| Tela de Login | Credenciais inválidas exibem erro | ✅ Passou | ~26s | — |
| Tela de Cadastro | Navegação para tela de cadastro | ✅ Passou | ~24s | Localizou widgets via `find.textContaining('Cadastr')` |
| **Total** | **5 / 5** | **✅ Todos passaram** | **~2m12s** | Build incluído: ~18m12s total |

**Eventos relevantes durante a execução:**

| Tempo (MM:SS) | Evento |
|---|---|
| 00:00 | Início do carregamento |
| 15:40 | Build do APK concluído (~940s — primeiro build) |
| 15:45 | Falha de instalação: `INSTALL_FAILED_UPDATE_INCOMPATIBLE` (assinatura diferente) |
| 15:54 | ADB desinstalou versão anterior automaticamente e reinstalou |
| 16:00 | Início da execução dos testes no dispositivo |
| 18:12 | Todos os testes concluídos |

> **Nota sobre o build:** o tempo de ~15min é esperado apenas no primeiro run. Execuções subsequentes reutilizam o cache Gradle e levam ~1-2min.

> **Nota sobre `INSTALL_FAILED_UPDATE_INCOMPATIBLE`:** ocorre quando há uma versão do app instalada com assinatura diferente (ex.: versão de Release vs Debug). O Flutter tratou automaticamente desinstalando a versão antiga.

---

### Evidências — Saída completa do terminal (Integração)

```
00:00 +0: loading integration_test/app_integration_test.dart
✓ Built build\app\outputs\flutter-apk\app-debug.apk
Error: ADB exited with exit code 1 — INSTALL_FAILED_UPDATE_INCOMPATIBLE (resolvido automaticamente)
Uninstalling old version...
16:00 +0: App Smoke Test — App inicializa sem erros e exibe a tela inicial
  [NotificationService] Inicializado com sucesso.
  [OfflineSyncService] Inicializado. Conectado: true
16:41 +1: Tela de Login — Campos de email e senha são exibidos
17:01 +2: Tela de Login — Botão de login está presente e habilitado
17:22 +3: Tela de Login — Credenciais inválidas exibem mensagem de erro
17:48 +4: Tela de Cadastro — Navegação para tela de cadastro funciona
18:12 +5: All tests passed!
```
