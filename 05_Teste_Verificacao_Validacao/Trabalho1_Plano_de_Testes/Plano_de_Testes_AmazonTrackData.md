# PLANO DE TESTES DE SOFTWARE

## AmazonTrackData

**Identificador:** PT-ATD-001  
**Versão:** 1.0  
**Data:** 07 de setembro de 2026  
**Autor e responsável por QA:** João Gabriel da Silva Maciel  
**Instituição:** Universidade Federal do Amazonas — UFAM  
**Projeto:** PIBITI  
**Documento relacionado:** Documento de Requisitos do AmazonTrackData, versão 1.0

---

## Controle do documento

### Histórico de revisões

| Data | Versão | Descrição | Autor |
|---|---:|---|---|
| 07/09/2026 | 1.0 | Emissão inicial do Plano de Testes | João Gabriel da Silva Maciel |

### Aprovações

| Papel | Nome | Data | Assinatura |
|---|---|---|---|
| Responsável pelo produto/projeto | A definir |  |  |
| Gerente de testes/QA | João Gabriel da Silva Maciel |  |  |
| Responsável técnico | João Gabriel da Silva Maciel |  |  |
| Responsável acadêmico | A definir |  |  |

### Lista de distribuição

| Nome/área | Organização | Finalidade |
|---|---|---|
| Responsável pelo produto/projeto | UFAM/PIBITI | Aprovar escopo, riscos e aceite |
| Gerente de testes/QA | UFAM/PIBITI | Executar e controlar a campanha |
| Equipe de desenvolvimento | UFAM/PIBITI | Corrigir defeitos e apoiar os ambientes |
| Orientação/avaliação acadêmica | UFAM | Avaliar conformidade e resultados |
| Usuários de aceitação | Passageiros e barqueiros convidados | Validar as jornadas essenciais |

---

# 1. Introdução

## 1.1 Objetivo

Este plano define a governança, o escopo, a estratégia, os recursos, o orçamento, o cronograma, os ambientes, os critérios de qualidade, a comunicação, os riscos, as ferramentas e os produtos de trabalho necessários para verificar e validar o AmazonTrackData.

O documento orienta:

- planejamento e controle das atividades de teste;
- cobertura rastreável dos requisitos;
- execução de testes funcionais e não funcionais;
- registro, priorização e acompanhamento de defeitos;
- produção de evidências auditáveis;
- decisão de entrada, suspensão, retomada e encerramento;
- recomendação fundamentada de aceite ou rejeição da versão.

## 1.2 Padrões e abordagem adotada

O plano adota:

- **IEEE 829-2008**, na organização da documentação de testes: identificador, itens, funcionalidades incluídas/excluídas, abordagem, critérios de aprovação, suspensão/retomada, entregáveis, tarefas, ambiente, responsabilidades, equipe, cronograma, riscos e aprovações;
- **PMI/PMBOK**, no gerenciamento integrado de escopo, cronograma, custo, qualidade, recursos, comunicação, riscos, aquisições e partes interessadas;
- **QAI**, nos princípios de prevenção de defeitos, processo definido, medição, rastreabilidade, revisão independente sempre que possível, controle de configuração e melhoria contínua;
- **ISO/IEC 25010**, como referência para características de qualidade do produto;
- **LGPD**, para dados pessoais, CPF e localização;
- práticas atuais de teste de software, sem alterar a estrutura documental solicitada pela IEEE 829.

> Nota normativa: a sigla correta é **IEEE**, e a norma IEEE 829 foi substituída internacionalmente pela família ISO/IEC/IEEE 29119. Ela é mantida neste plano porque foi explicitamente requerida e continua adequada como modelo documental.

## 1.3 Referências

| Título | Identificador/local | Autor/origem |
|---|---|---|
| Documento de Requisitos do AmazonTrackData | `docs/entregaveis/`, versão 1.0 | João Gabriel da Silva Maciel |
| Standard for Software and System Test Documentation | IEEE 829-2008 | IEEE |
| A Guide to the Project Management Body of Knowledge | PMBOK Guide | PMI |
| Princípios e práticas de garantia da qualidade | — | Quality Assurance Institute (QAI) |
| Systems and software Quality Requirements and Evaluation | ISO/IEC 25010:2011 | ISO/IEC |
| Requirements engineering | ISO/IEC/IEEE 29148:2018 | ISO/IEC/IEEE |
| Mobile Application Security Verification Standard e MSTG | MASVS/MSTG | OWASP |
| Lei Geral de Proteção de Dados Pessoais | Lei nº 13.709/2018 | Brasil |
| Documentação técnica do projeto | `docs/`, `diagramas/`, `pubspec.yaml` | Equipe do projeto |
| Documentação de Flutter, Firebase, Android e OpenStreetMap | sítios oficiais | Fornecedores |
| Modelo “Plano de Teste de Software” e documento de testes de referência | arquivos fornecidos pelo solicitante | SENAI e terceiros |

## 1.4 Definições, acrônimos e abreviações

| Termo | Definição |
|---|---|
| ADB | Ferramenta de linha de comando para comunicação com dispositivos Android. |
| APK | Pacote de instalação de aplicativo Android. |
| Caso de teste | Conjunto de pré-condições, passos, dados e resultados esperados. |
| Defeito | Não conformidade entre o comportamento observado e o especificado. |
| ETA | Tempo estimado de chegada. |
| Evidência | Registro que comprova a execução e o resultado de um teste. |
| Geofencing | Detecção de entrada, permanência ou saída de área geográfica virtual. |
| p95 | Percentil 95 de uma distribuição de medições. |
| RACI | Matriz de responsabilidades: responsável, aprovador, consultado e informado. |
| Regressão | Reexecução de testes para confirmar que mudanças não introduziram falhas. |
| Smoke test | Verificação rápida de que a versão está apta a ser testada. |
| Store-and-forward | Armazenar localmente e transmitir quando houver conectividade. |
| SUS | System Usability Scale, questionário padronizado de usabilidade. |
| UID | Identificador único do usuário autenticado. |

## 1.5 Contexto e estado inicial

O AmazonTrackData é um aplicativo Flutter para rastreamento fluvial, com perfis de passageiro e barqueiro, GPS, mapas, Firebase, operação offline, geofencing de 13 portos, notificações, calendário, histórico e mensagens.

Há evidências documentais de uma execução em 24/06/2026, incluindo testes unitários e cinco testes de integração em um Moto G54 5G com Android 15. Esses registros serão tratados como **evidência histórica**, não como resultado da nova campanha.

Na revisão aprofundada de 07/09/2026, o código em `lib/` confirmou a implementação de `ForegroundService` Android, persistência SQLite, sessão em `SharedPreferences`, filtro de Kalman, calendário, chat e catálogo de 13 portos. Também foram identificadas divergências de documentação/configuração e cobertura automatizada insuficiente para os serviços críticos. Assim:

- a campanha formal permanece em estado **planejado**;
- a versão candidata precisa ser identificada e todas as suítes devem ser reexecutadas;
- nenhum resultado histórico será contabilizado como aprovação atual sem reexecução;
- as integrações críticas ainda sem automação devem receber novos testes nesta campanha.

---

# 2. Escopo

## 2.1 Itens de teste

| Item | Descrição | Base de teste |
|---|---|---|
| Aplicativo Android | Fluxos dos perfis passageiro e barqueiro | Requisitos, diagramas, APK/build e código Flutter |
| Autenticação | Cadastro, login, sessão, logout e Google Sign-In quando habilitado | RF-AUT e configuração Firebase Auth |
| Embarcações e rotas | Cadastro, consulta, edição, associação e autorização | RF-EMB, RF-ROT e modelos |
| Rastreamento | Permissões, GPS, viagem, captura periódica e mapa | RF-RAS e configuração Android |
| Offline/sincronização | Fila FIFO, persistência, reconexão, retry, lote e deduplicação | RF-OFF e serviço de sincronização |
| Geofencing | Estados, raios, ETA, debounce e notificações | RF-GEO e dados de portos |
| Passageiro | Lista, seleção, mapa, posição e indicadores | RF-PAS |
| Histórico e chat | Viagens, resumos, conversas, mensagens e autorização | RF-HIS e RF-CHAT |
| Calendário | Criação, consulta, classificação e cancelamento de viagens agendadas | RF-AGE e modelo `ScheduledTrip` |
| Backend Firebase | Auth, Firestore, Storage, regras e integridade | RI-01 a RI-03 e RNF-SEG |
| Página web | Conteúdo responsivo e download do APK | RF-DIS |
| Instalação Android | Instalação, atualização, permissões e inicialização | APK candidato e manifesto Android |

## 2.2 Funcionalidades incluídas

- autenticação e gerenciamento de sessão;
- validação de nome, CPF, e-mail, senha e campos numéricos;
- separação de acesso entre passageiro e barqueiro;
- cadastro e edição de embarcações;
- consulta, cadastro e seleção de rotas;
- captura e persistência de pontos GPS;
- início e encerramento de viagem;
- mapa e acompanhamento de embarcação;
- fila offline e sincronização após reconexão;
- geofencing, ETA e notificações locais;
- histórico e resumo de viagens;
- mensagens entre perfis;
- criação, consulta e cancelamento de viagens agendadas;
- tratamento de falhas de GPS, rede, Firebase e mapa;
- segurança de autenticação, autorização e armazenamento;
- desempenho, compatibilidade, estabilidade, usabilidade e acessibilidade;
- instalação e download do APK.

## 2.3 Funcionalidades não testadas nesta campanha

- navegação profissional, precisão hidrográfica ou certificação marítima;
- dispositivos GPS externos;
- comunicação satelital, LoRa, Bluetooth Mesh ou relay DTN entre dispositivos;
- algoritmos de roteamento PRoPHET, Epidemic ou Spray-and-Wait;
- pagamentos e venda de passagens;
- predição por inteligência artificial;
- plataformas iOS, Web e Desktop como produto operacional;
- segurança interna da infraestrutura administrada pelo Google/Firebase;
- disponibilidade global ou SLA contratual dos serviços externos;
- penetração destrutiva contra serviços em produção.

## 2.4 Suposições do escopo

- a versão candidata será identificada por commit, versão, build e hash do APK;
- haverá um projeto Firebase exclusivo para teste ou Firebase Emulator Suite;
- dados utilizados serão sintéticos;
- o dispositivo físico poderá usar localização simulada nos testes controlados;
- testes de campo serão realizados em local seguro e sem interferir na condução de embarcação;
- o responsável pelo produto confirmará qualquer requisito ainda pendente.

## 2.5 Controle de mudanças de escopo

Solicitações de mudança devem registrar:

1. descrição e justificativa;
2. requisitos afetados;
3. impacto em arquitetura, dados e segurança;
4. novos casos de teste;
5. impacto em esforço, custo e cronograma;
6. riscos introduzidos;
7. aprovação do responsável pelo produto e do gerente de testes.

Mudança que afete requisito **Must**, privacidade, autorização ou persistência offline exige nova análise de risco e regressão completa do fluxo crítico.

---

# 3. Estratégia de qualidade

## 3.1 Objetivos da qualidade

| Objetivo | Indicador | Meta |
|---|---|---:|
| Cobrir a baseline | Requisitos com ao menos um teste associado | 100% |
| Proteger fluxos críticos | Requisitos Must críticos aprovados | 100% |
| Obter estabilidade geral | Casos executados aprovados | ≥ 95% |
| Evitar liberação de falhas graves | Defeitos críticos/altos abertos no aceite | 0 |
| Garantir operação offline | Pontos aceitos recuperados e sincronizados | 100%, sem duplicação lógica |
| Controlar regressão | Suíte automatizada aprovada | 100% |
| Controlar retrabalho | Defeitos reabertos | ≤ 10% |
| Garantir usabilidade | SUS médio | ≥ 68 |
| Garantir eficácia de tarefas | Usuários que concluem tarefas essenciais | ≥ 90% |
| Rastrear resultados | Casos executados com evidência | 100% |

## 3.2 Princípios de garantia da qualidade

- revisar requisitos antes da execução para prevenir defeitos;
- testar cedo, por camadas, e repetir automaticamente;
- separar ambiente e dados de teste dos dados reais;
- priorizar por risco;
- testar fluxos positivos, negativos, limites e recuperação;
- exigir rastreabilidade entre requisito, caso, execução e defeito;
- registrar evidência reproduzível;
- preservar versão, configuração e build examinados;
- realizar revisão cruzada dos casos e resultados quando houver segundo avaliador;
- usar métricas para corrigir o processo, não para ocultar falhas.

## 3.3 Níveis de teste

| Nível | Objetivo | Responsável principal | Automação |
|---|---|---|---|
| Revisão estática | Detectar ambiguidades, inconsistências, segredos e problemas de configuração | QA + desenvolvimento | Parcial |
| Unitário | Validar funções, modelos, cálculos, fila e regras isoladas | Desenvolvimento | Alta |
| Widget | Validar formulários, estados e feedback visual isolado | Desenvolvimento/QA | Alta |
| Integração | Validar Firebase, GPS simulado, persistência, serviços e navegação | QA | Alta |
| Sistema | Validar o aplicativo completo em dispositivo e redes variadas | QA | Mista |
| Aceitação | Validar necessidades de passageiro e barqueiro | Produto/usuários | Manual |

### 3.3.1 Características de qualidade a serem testadas

| Característica (ISO/IEC 25010) | Será testada | Como será verificada no AmazonTrackData |
|---|---|---|
| Funcionalidade | Sim | Requisitos funcionais, regras de negócio, autorização e integridade dos dados |
| Confiabilidade | Sim | Operação offline, sincronização, recuperação de falhas e sessão longa |
| Usabilidade | Sim | Tarefas essenciais, clareza de erros, acessibilidade e questionário SUS |
| Eficiência de desempenho | Sim | Inicialização, processamento GPS, atualização remota, carga e estresse |
| Manutenibilidade | Parcial | Análise estática, padronização e cobertura automatizada, sem métrica formal de dívida técnica |
| Portabilidade | Parcial | Matriz Android obrigatória; iOS, Web e Desktop fora do escopo desta campanha |
| Segurança | Sim | Autenticação, menor privilégio, regras Firebase, logs, APK e privacidade |
| Compatibilidade | Sim | Versões Android, resoluções, permissões, redes e instalação/atualização |

### 3.3.2 Ciclo de vida do projeto de teste

| Fase | Atividades principais | Saída |
|---|---|---|
| Iniciação | Confirmar objetivos, partes interessadas, restrições e versão-alvo | Escopo acordado |
| Planejamento | Definir estratégia, recursos, custo, cronograma, ambientes e riscos | Plano aprovado |
| Análise e modelagem | Revisar requisitos, projetar casos, preparar dados e automações | Casos e massa prontos |
| Execução | Executar níveis e tipos de teste, registrar evidências e defeitos | Resultados e defeitos |
| Monitoramento e controle | Medir progresso, cobertura, qualidade, custo e prazo | Relatórios periódicos |
| Controle de mudanças | Avaliar impacto, atualizar casos e rastreabilidade | Baseline atualizada |
| Encerramento | Consolidar métricas, riscos residuais, lições e parecer | Relatório e aceite |

## 3.4 Tipos de teste

### 3.4.1 Teste de banco de dados

**Objetivo:** assegurar integridade, autorização, serialização e consistência dos dados locais e remotos.  
**Técnica:** criar, consultar, atualizar e tentar operações inválidas diretamente em ambiente de teste; verificar coleções, referências, tipos, limites e regras.  
**Critério de finalização:** operações válidas persistem corretamente; inválidas são rejeitadas; nenhum acesso indevido é aceito.  
**Considerações especiais:** exige Firebase de teste ou emulador e acesso ao SQLite local do dispositivo; nunca executar contra a base de produção.

### 3.4.2 Teste funcional

**Objetivo:** verificar cada requisito e fluxo de usuário.  
**Técnica:** caixa-preta com classes de equivalência, valores-limite, tabela de decisão e transição de estados.  
**Critério de finalização:** requisitos Must aprovados e resultados rastreados.  
**Considerações especiais:** alguns fluxos dependem do perfil do usuário e de permissões concedidas no dispositivo.

### 3.4.3 Teste de ciclo de negócio

**Objetivo:** validar jornadas completas de passageiro e barqueiro.  
**Técnica:** cadastro → configuração → viagem → acompanhamento → encerramento → histórico; e captura offline → reconexão → confirmação remota.  
**Critério de finalização:** jornadas completas sem quebra de regra ou inconsistência.  
**Considerações especiais:** requer ao menos duas contas ativas simultâneas, uma de passageiro e uma de barqueiro.

### 3.4.4 Teste da interface e acessibilidade

**Objetivo:** verificar navegação, conteúdo, feedback, responsividade, semântica e facilidade de uso.  
**Técnica:** inspeção heurística, teste em densidades/fontes variadas, leitor de tela e sessão com usuários.  
**Critério de finalização:** tarefas essenciais atingem as metas e não existem bloqueios de acessibilidade críticos.  
**Considerações especiais:** a sessão com usuários deve ocorrer sem treinamento prévio e sem indução do observador.

### 3.4.5 Teste de desempenho

**Objetivo:** medir inicialização, processamento local, atualização remota, sincronização e consumo durante rastreamento.  
**Técnica:** perfil controlado em dispositivo de referência, pelo menos 30 amostras por operação sensível e análise de percentil 95.  
**Critério de finalização:** limites RNF-DES atendidos ou exceções aprovadas.  
**Considerações especiais:** medir com o dispositivo livre de outras cargas relevantes e registrar bateria, temperatura e tipo de rede.

### 3.4.6 Teste de carga

**Objetivo:** avaliar backend e consulta sob volume crescente sem afetar produção.  
**Técnica:** Firebase Emulator Suite ou projeto isolado com volumes de 1, 10, 25 e 50 usuários simulados e históricos crescentes.  
**Critério de finalização:** integridade mantida, ausência de erros funcionais e tempos dentro do orçamento aprovado.  
**Considerações especiais:** acompanhar cota e custo do Firebase e interromper ao atingir o limite orçado.

### 3.4.7 Teste de estresse e estabilidade

**Objetivo:** encontrar limites e observar recuperação.  
**Técnica:** fila volumosa, alternância rápida de conectividade, GPS frequente, sessão longa, memória restrita e indisponibilidade temporária.  
**Critério de finalização:** degradação controlada, sem perda silenciosa e recuperação após normalização.  
**Considerações especiais:** o processo do aplicativo pode ser encerrado pelo sistema; conferir a base local antes e depois de cada ciclo.

### 3.4.8 Teste de segurança e controle de acesso

**Objetivo:** confirmar autenticação, menor privilégio e proteção de dados.  
**Técnica:** testes negativos de regras Firebase, acesso horizontal entre UIDs, sessão expirada, arquivos não autorizados, inspeção de logs e APK.  
**Critério de finalização:** 100% dos controles críticos aprovados e nenhum segredo administrativo incorporado.  
**Considerações especiais:** executar somente em ambiente autorizado, sem ataque a serviços de produção, e sanitizar todas as evidências.

### 3.4.9 Teste de falha e recuperação

**Objetivo:** assegurar recuperação após falha de rede, Firebase, GPS, mapa, processo ou reinício.  
**Técnica:** injeção controlada de falhas antes, durante e depois da persistência; conferência local/remota.  
**Critério de finalização:** estado consistente e dados não confirmados preservados.  
**Considerações especiais:** registrar a quantidade de pontos antes da falha para permitir conferência exata após a recuperação.

### 3.4.10 Teste de compatibilidade e instalação

**Objetivo:** verificar versões Android, resoluções, permissões, instalação e atualização.  
**Técnica:** matriz de emuladores e dispositivo real; instalação limpa; atualização assinada; negação/revogação de permissões.  
**Critério de finalização:** app instala, inicializa e executa fluxos essenciais na matriz obrigatória.  
**Considerações especiais:** builds com assinaturas diferentes exigem desinstalação prévia; a keystore utilizada deve ser controlada e registrada.

## 3.5 Técnicas de projeto de teste

- classes de equivalência;
- análise de valor-limite;
- tabelas de decisão para autorização e conectividade;
- transição de estados para rastreamento, geofencing e fila;
- testes combinatórios por pares para dispositivo/rede/permissão/perfil;
- testes baseados em risco;
- exploração orientada por charters;
- mutação de dados e injeção de falhas controlada;
- comparação entre dados locais, dados remotos e interface.

---

# 4. Catálogo e rastreabilidade dos testes

## 4.1 Conjuntos planejados

| Conjunto | IDs | Quantidade inicial | Requisitos principais |
|---|---|---:|---|
| Autenticação e perfil | CT-AUT-01 a CT-AUT-12 | 12 | RF-AUT, RF-PER, RNF-SEG |
| Embarcações e rotas | CT-EMB-01 a CT-EMB-10 | 10 | RF-EMB, RF-ROT |
| Rastreamento e viagem | CT-RAS-01 a CT-RAS-12 | 12 | RF-RAS, RNF-DES, RNF-CON |
| Offline e sincronização | CT-OFF-01 a CT-OFF-12 | 12 | RF-OFF, RNF-CON |
| Geofencing e alertas | CT-GEO-01 a CT-GEO-10 | 10 | RF-GEO |
| Passageiro e mapa | CT-PAS-01 a CT-PAS-08 | 8 | RF-PAS |
| Histórico e chat | CT-HCH-01 a CT-HCH-10 | 10 | RF-HIS, RF-CHAT |
| Calendário de viagens | CT-AGE-01 a CT-AGE-08 | 8 | RF-AGE |
| Segurança | CT-SEG-01 a CT-SEG-12 | 12 | RNF-SEG, regras Firebase |
| Interface/acessibilidade | CT-UI-01 a CT-UI-08 | 8 | RNF-USA |
| Desempenho/carga/estresse | CT-NF-01 a CT-NF-10 | 10 | RNF-DES, RNF-CON |
| Compatibilidade/instalação/web | CT-COM-01 a CT-COM-08 | 8 | RNF-COM, RF-DIS |
| Aceitação | CT-UAT-01 a CT-UAT-06 | 6 | Jornadas essenciais |
| **Total inicial** |  | **126** |  |

## 4.2 Casos críticos mínimos

| ID | Cenário | Resultado esperado | Criticidade |
|---|---|---|---|
| CT-AUT-01 | Cadastrar passageiro com dados válidos | Conta e perfil únicos são criados | Alta |
| CT-AUT-02 | Cadastrar barqueiro com dados válidos | Conta abre funções de barqueiro | Alta |
| CT-AUT-03 | Informar CPF inválido/repetido | Cadastro é bloqueado com mensagem adequada | Alta |
| CT-AUT-04 | Login válido | Sessão é iniciada e perfil correto é carregado | Crítica |
| CT-AUT-05 | Login inválido e sessão expirada | Acesso é negado sem vazamento de informação | Crítica |
| CT-AUT-06 | Logout | Sessão é encerrada e rota protegida não é acessível | Alta |
| CT-EMB-01 | Barqueiro cadastrar embarcação válida | Registro é vinculado ao proprietário | Alta |
| CT-EMB-02 | Outro UID editar embarcação | Operação é negada | Crítica |
| CT-EMB-05 | Cadastrar/selecionar rota válida | Viagem recebe rota correta | Alta |
| CT-RAS-01 | Conceder localização e iniciar viagem | Rastreamento ativo e `tripId` criado | Crítica |
| CT-RAS-02 | Negar/revogar localização | App orienta usuário e não encerra abruptamente | Alta |
| CT-RAS-03 | Capturar ponto GPS válido | Modelo possui campos e unidades corretos | Crítica |
| CT-RAS-04 | Tentar segunda viagem simultânea | Duplicidade de sessão é impedida | Alta |
| CT-RAS-05 | Encerrar viagem | Captura para, pendências persistem e resumo é consistente | Crítica |
| CT-RAS-06 | Rodar com tela bloqueada/minimizado | Comportamento corresponde ao requisito aprovado | Crítica |
| CT-OFF-01 | Iniciar viagem sem internet | Pontos são armazenados localmente | Crítica |
| CT-OFF-02 | Reiniciar app com fila pendente | Fila é recuperada | Crítica |
| CT-OFF-03 | Reconectar após período offline | Sincronização inicia automaticamente | Crítica |
| CT-OFF-04 | Falha parcial em lote | Confirmados saem; falhos permanecem | Crítica |
| CT-OFF-05 | Repetir envio do mesmo ponto | Não há duplicidade lógica | Crítica |
| CT-OFF-06 | Alternar Wi-Fi/móvel/offline | Viagem continua e fila permanece íntegra | Alta |
| CT-GEO-01 | Posição fora dos raios | Estado é “fora da zona” | Média |
| CT-GEO-02 | Cruzar raio de aproximação | Estado e alerta mudam uma única vez | Alta |
| CT-GEO-03 | Cruzar raio de atracação | Atracação e notificação são registradas | Alta |
| CT-GEO-04 | Oscilar junto ao limite | Debounce impede notificações excessivas | Alta |
| CT-GEO-05 | Velocidade abaixo de 0,5 m/s | ETA é apresentado como indisponível | Média |
| CT-GEO-06 | Distância/velocidade controladas | ETA calculado fica dentro da tolerância | Alta |
| CT-PAS-01 | Passageiro listar e selecionar embarcação | Mapa abre para o item correto | Alta |
| CT-PAS-02 | Receber nova posição | Marcador atualiza dentro do limite | Alta |
| CT-PAS-03 | Receber posição antiga | Interface sinaliza desatualização | Alta |
| CT-HCH-01 | Consultar histórico | Viagens autorizadas são ordenadas | Média |
| CT-HCH-03 | Enviar mensagem | Mensagem aparece uma vez aos participantes | Alta |
| CT-HCH-04 | Terceiro acessar conversa | Operação é negada | Crítica |
| CT-AGE-01 | Barqueiro agendar viagem válida | Evento aparece na data e embarcação corretas | Alta |
| CT-AGE-02 | Terceiro cancelar agenda | Operação é negada | Crítica |
| CT-AGE-03 | Consultar futuras, passadas e canceladas | Classificação e apresentação são consistentes | Média |
| CT-SEG-01 | Usuário A ler/escrever dados privados de B | Regras negam acesso | Crítica |
| CT-SEG-02 | Usuário não autenticado acessar Firestore/Storage | Regras negam acesso | Crítica |
| CT-SEG-03 | Inspecionar logs de produção | Não há token, senha, CPF completo ou coordenada indevida | Crítica |
| CT-SEG-04 | Inspecionar APK/configuração | Não há chave administrativa ou segredo de servidor | Crítica |
| CT-NF-01 | Medir processamento local do GPS | p95 ≤ 2 s | Alta |
| CT-NF-02 | Medir atualização para passageiro | p95 ≤ 10 s em conexão estável | Alta |
| CT-NF-03 | Sessão contínua de duas horas | Sem ANR, perda ou consumo anormal bloqueador | Alta |
| CT-UAT-01 | Jornada completa do barqueiro | Conclusão sem ajuda crítica | Crítica |
| CT-UAT-02 | Jornada completa do passageiro | Conclusão sem ajuda crítica | Crítica |

## 4.3 Estrutura de uma especificação de caso

Cada caso detalhado deve conter:

- identificador e título;
- requisito e risco associados;
- versão/build e ambiente;
- prioridade e severidade potencial;
- pré-condições;
- massa de dados;
- passos numerados;
- resultado esperado por passo;
- pós-condições/limpeza;
- resultado obtido;
- estado: não executado, aprovado, reprovado, bloqueado ou não aplicável;
- evidências;
- defeitos relacionados;
- executor e data.

---

# 5. Critérios de entrada, aprovação, suspensão e encerramento

## 5.1 Critérios de entrada

Uma etapa só pode começar quando:

- baseline de requisitos estiver aprovada ou ressalvada formalmente;
- código-fonte e build identificável estiverem disponíveis;
- dependências forem resolvidas;
- análise estática não apresentar erro que impeça execução;
- ambiente e dados sintéticos estiverem preparados;
- Firebase de teste/emulador estiver acessível;
- casos da etapa estiverem revisados;
- riscos críticos tiverem resposta definida.

## 5.2 Critério de aprovação de caso

Um caso é aprovado quando:

- todas as pré-condições são atendidas;
- passos são executados na versão registrada;
- resultados observados correspondem integralmente aos esperados;
- não ocorre efeito colateral relevante;
- evidência permite reproduzir a conclusão.

## 5.3 Critério de falha

Um caso é reprovado quando:

- resultado esperado não ocorre;
- regra de negócio, autorização ou integridade é violada;
- ocorre encerramento inesperado, perda ou duplicação;
- tempo excede limite obrigatório;
- evidência mostra comportamento inconsistente.

Falha de ambiente torna o caso **bloqueado**, não aprovado.

## 5.4 Critérios de suspensão

A execução será suspensa total ou parcialmente se ocorrer:

- ausência do código-fonte ou build incompatível com os testes;
- ambiente Firebase indisponível por mais de quatro horas úteis;
- mais de 20% dos casos da etapa bloqueados;
- defeito crítico que impeça os fluxos subsequentes;
- perda/corrupção da massa de teste;
- regras permissivas expuserem dados não sintéticos;
- versão do aplicativo mudar sem controle de configuração;
- risco à segurança física em teste de campo.

## 5.5 Critérios de retomada

Retomada exige:

- causa da suspensão corrigida ou contornada com aprovação;
- *smoke test* aprovado;
- ambiente e versão novamente identificados;
- casos afetados redefinidos para “não executado”;
- comunicação às partes interessadas;
- atualização do cronograma e dos riscos, se necessário.

## 5.6 Critérios de saída e recomendação de aceite

- 100% dos casos planejados executados ou formalmente justificados;
- 100% dos requisitos cobertos;
- ≥ 95% de aprovação geral;
- 100% de aprovação dos casos críticos;
- nenhum defeito crítico ou alto aberto;
- regressão automatizada 100% aprovada;
- teste offline aprovado sem perda ou duplicação;
- regras Firebase restritivas aprovadas;
- riscos residuais aceitos pelo responsável pelo produto;
- relatório de resumo e termo de aceite emitidos.

---

# 6. Ambiente de testes

## 6.1 Ambientes lógicos

| Ambiente | Finalidade | Dados | Restrições |
|---|---|---|---|
| Local/DEV | Unidade, widget, análise estática e depuração | Sintéticos | Não vale como homologação final |
| Firebase Emulator | Auth, Firestore e Storage com regras controladas | Sintéticos e descartáveis | Preferido para segurança/carga |
| TEST | Integração com serviços Firebase reais | Contas e dados sintéticos | Projeto separado de produção |
| HOMOLOG | Sistema, aceitação e versão candidata | Massa controlada | Configuração equivalente à produção |
| Campo controlado | GPS, conectividade, geofencing e bateria | Viagens simuladas/autorizadas | Segurança física e consentimento |

## 6.2 Hardware e software

| Recurso | Configuração mínima planejada |
|---|---|
| Estação | Windows 10/11, 8 GB RAM, 20 GB livres, acesso à internet |
| SDK | Flutter 3.x compatível com o projeto; Dart ≥ 3.1 e < 4.0 |
| Java/Android | JDK 17, Android SDK e ferramentas ADB |
| Dispositivo real de referência | Moto G54 5G, Android 15/API 35, ou equivalente documentado |
| Emuladores | Android APIs 30, 33 e 34; ao menos uma tela compacta e uma tela ampla |
| Backend | Projeto Firebase de teste ou Emulator Suite |
| Mapa | Acesso controlado aos blocos OpenStreetMap, respeitando política de uso |
| Rede | Wi-Fi estável, rede móvel, modo avião, latência/perda simuladas |
| GPS | Localização real em campo seguro e rotas simuladas por coordenadas/GPX |

## 6.3 Matriz de compatibilidade

| Plataforma | Tipo | Prioridade | Cobertura |
|---|---|---:|---|
| Android API 30 | Emulador | Obrigatória | instalação, UI, permissões, fluxos essenciais |
| Android API 33 | Emulador | Obrigatória | notificações e mídia |
| Android API 34 | Emulador | Obrigatória | serviço em primeiro plano/localização |
| Android API 35 | Dispositivo real | Obrigatória | sistema, GPS, campo, estabilidade |
| Android `minSdk` resolvido | Emulador | Obrigatória após confirmação | instalação e smoke |
| iOS/Web/Desktop | Variado | Fora da campanha | somente análise estática, sem declaração de suporte |

## 6.4 Perfis de rede

1. online estável por Wi-Fi;
2. online por rede móvel;
3. alta latência;
4. perda intermitente;
5. totalmente offline;
6. mudança Wi-Fi → móvel;
7. mudança móvel → offline → Wi-Fi;
8. conexão indicada pelo sistema, porém backend inacessível.

## 6.5 Dados de teste

- CPFs sintéticos matematicamente válidos, não associados a pessoas reais;
- e-mails de domínio reservado para teste;
- contas separadas para passageiro, barqueiro, usuário inativo e atacante;
- embarcações, rotas e portos fictícios/controlados;
- pontos GPS normais, limites, inválidos e fora de ordem;
- filas com 0, 1, 49, 50, 51, 500 e 5.000 pontos;
- mensagens sem dados pessoais reais;
- imagens inofensivas em formatos e tamanhos permitidos/proibidos.

Ao final, a massa deve ser removida ou anonimizada conforme o procedimento do ambiente.

---

# 7. Ferramentas de teste

| Ferramenta | Uso | Situação |
|---|---|---|
| `flutter_test` | testes unitários e de widget | Já declarado |
| `integration_test` | fluxos de integração em dispositivo/emulador | Já declarado |
| `flutter analyze` / `flutter_lints` | análise estática e conformidade Dart | Já declarado |
| Flutter DevTools | CPU, memória, rede, frames e inspeção | Planejado |
| Android Studio/SDK/ADB | emuladores, instalação, logs e permissões | Planejado |
| Firebase Emulator Suite | testes de Auth, Firestore, Storage e regras | Recomendado |
| Firebase Console | conferência de dados no projeto de teste | Planejado |
| Git | controle de versão e identificação do build | Existente |
| GitHub Issues ou planilha controlada | defeitos, evidências e rastreabilidade | A confirmar |
| DevTools Network Link Conditioner ou emulador Android | latência, perda e alternância de rede | Planejado |
| Accessibility Scanner/TalkBack | acessibilidade Android | Planejado |
| OWASP MASVS/MSTG checklists | segurança móvel | Planejado |
| Planilha/matriz de rastreabilidade | requisitos, testes, defeitos e métricas | Planejado |

Ferramentas adicionais somente serão introduzidas após avaliação de custo, curva de aprendizagem, compatibilidade e benefício.

---

# 8. Recursos humanos

## 8.1 Papéis

| Papel | Responsabilidades | Alocação proposta |
|---|---|---:|
| Responsável pelo produto | priorizar requisitos, esclarecer regras e aceitar riscos | 8 h |
| Gerente de testes/QA | planejar, medir, comunicar, controlar riscos e emitir parecer | 28 h |
| Analista de testes | projetar, executar e registrar casos/evidências | 44 h |
| Desenvolvedor | unidade, correção, suporte ao ambiente e revisão técnica | 36 h |
| Usuários de aceitação | executar jornadas e avaliar usabilidade | 8 h |
| Revisor independente | revisar plano, casos críticos e relatório, quando disponível | 8 h |
| **Total** |  | **132 h** |

No projeto atual, João Gabriel da Silva Maciel poderá acumular as funções técnicas e de QA. Para reduzir viés, recomenda-se que o responsável acadêmico ou um colega realize a revisão independente e que usuários representativos participem do aceite.

## 8.2 Matriz RACI

Legenda: **R** executa; **A** aprova; **C** consultado; **I** informado.

| Atividade | Produto | Gerente QA | Analista QA | Desenvolvimento | Usuário/Revisor |
|---|---|---|---|---|---|
| Aprovar escopo/requisitos | A | C | I | C | C |
| Elaborar plano e casos | C | A | R | C | C |
| Preparar ambiente | I | A | R | R | I |
| Executar unidade | I | C | C | R/A | I |
| Executar integração/sistema | I | A | R | C | I |
| Corrigir defeitos | I | C | C | R/A | I |
| Executar aceitação | A | C | R | I | R |
| Aceitar risco residual | A | C | I | C | I |
| Emitir relatório | C | A/R | C | I | C |

## 8.3 Equipe do projeto de teste

| Nome | Função | E-mail | Telefone |
|---|---|---|---|
| João Gabriel da Silva Maciel | Gerente de testes/QA e responsável técnico | A preencher | A preencher |
| A definir | Responsável pelo produto/projeto | A preencher | A preencher |
| A definir | Revisor independente/orientação acadêmica | A preencher | A preencher |
| A definir | Usuário de aceitação — perfil passageiro | A preencher | A preencher |
| A definir | Usuário de aceitação — perfil barqueiro | A preencher | A preencher |

## 8.4 Necessidade de contratação

| Necessidade | Contratar | Justificativa |
|---|---|---|
| Analista de testes adicional | Não | O escopo acadêmico é absorvido pela equipe atual. |
| Revisor independente | Não, mas recomendado | Pode ser suprido por orientação ou colega, sem custo direto. |
| Usuários de aceitação | Não | Participação voluntária e consentida. |
| Dispositivos Android adicionais | Avaliar | Empréstimo é preferível à aquisição; decidir conforme a matriz de compatibilidade. |
| Serviços pagos de teste em nuvem | Não | Emuladores e Firebase Emulator Suite atendem ao escopo previsto. |

## 8.5 Treinamento necessário

- visão funcional dos perfis passageiro/barqueiro;
- privacidade e tratamento de dados de localização;
- uso do Firebase de teste e Emulator Suite;
- execução de testes Flutter;
- simulação segura de GPS e conectividade;
- classificação e registro de defeitos;
- procedimentos de teste de campo.

---

# 9. Custo

## 9.1 Premissas da estimativa

O orçamento é uma estimativa acadêmica de custo de oportunidade. Considera taxa referencial de **R$ 45,00 por hora**, recursos já existentes e serviços gratuitos dentro das cotas de teste. Não representa proposta comercial nem despesa necessariamente desembolsada.

## 9.2 Estimativa

| Item | Base | Custo estimado |
|---|---:|---:|
| Trabalho especializado | 132 h × R$ 45,00 | R$ 5.940,00 |
| Uso/depreciação de dispositivo e estação | valor alocado | R$ 600,00 |
| Internet/dados móveis para testes | valor alocado | R$ 150,00 |
| Firebase/OSM/ferramentas de código aberto | dentro das cotas previstas | R$ 0,00 |
| **Subtotal** |  | **R$ 6.690,00** |
| Reserva de contingência | 10% do subtotal | R$ 669,00 |
| **Orçamento total de referência** |  | **R$ 7.359,00** |

## 9.3 Esforço e custo por conjunto de casos

Classificação por complexidade: **S** simples, **M** média, **C** complexa. O esforço inclui projeto, execução, registro de evidência e reteste previsto.

| Conjunto | Casos | Classificação predominante | HH estimado | Custo estimado |
|---|---:|---|---:|---:|
| Autenticação e perfil | 12 | M | 10 | R$ 450,00 |
| Embarcações e rotas | 10 | M | 8 | R$ 360,00 |
| Rastreamento e viagem | 12 | C | 16 | R$ 720,00 |
| Offline e sincronização | 12 | C | 16 | R$ 720,00 |
| Geofencing e alertas | 10 | C | 12 | R$ 540,00 |
| Passageiro e mapa | 8 | M | 8 | R$ 360,00 |
| Histórico e chat | 10 | M | 8 | R$ 360,00 |
| Calendário de viagens | 8 | S | 6 | R$ 270,00 |
| Segurança | 12 | C | 14 | R$ 630,00 |
| Interface/acessibilidade | 8 | M | 8 | R$ 360,00 |
| Desempenho/carga/estresse | 10 | C | 12 | R$ 540,00 |
| Compatibilidade/instalação/web | 8 | M | 8 | R$ 360,00 |
| Aceitação | 6 | M | 6 | R$ 270,00 |
| **Subtotal de execução** | **126** |  | **132** | **R$ 5.940,00** |

O total de horas coincide com a alocação da equipe apresentada na seção 8, pois as demais atividades de planejamento, gestão e relatório já estão distribuídas entre os papéis.

## 9.4 Controle de custos

- registrar horas por atividade e semana;
- acompanhar consumo Firebase e dados móveis;
- usar emuladores antes dos serviços reais;
- consumir reserva somente mediante risco materializado;
- submeter desvio superior a 10% à aprovação do responsável pelo produto;
- recalcular o orçamento quando houver mudança de escopo.

---

# 10. Cronograma

## 10.1 Plano de seis semanas

| Semana | Atividades | Entregas/marcos |
|---|---|---|
| S1 | confirmar baseline; identificar versão candidata; revisar requisitos; planejar riscos; preparar ambientes e dados | M1 — plano e baseline aprovados |
| S2 | análise estática; revisão de segurança; unitários de validadores, modelos, cálculos, SQLite/fila, geofencing, calendário e testes de widget | M2 — suíte de componentes estável |
| S3 | integração de autenticação, perfis, embarcações, rotas, calendário, Firestore, Storage e chat | M3 — integrações essenciais aprovadas |
| S4 | sistema em dispositivo: GPS, mapa, offline, reconexão, notificações, background e recuperação | M4 — jornada operacional validada |
| S5 | desempenho, carga, estresse, compatibilidade, segurança, acessibilidade e teste exploratório | M5 — não funcionais concluídos |
| S6 | correções, reteste, regressão, aceitação, métricas, riscos residuais e relatório | M6 — parecer e termo de aceite |

## 10.2 Dependências

- S2 depende da versão candidata identificada e das dependências resolvidas;
- S3 depende do Firebase de teste/emulador e regras instaladas;
- S4 depende de build instalável e dispositivo disponível;
- S5 depende de versão funcional estável;
- S6 depende da resolução dos defeitos críticos/altos.

## 10.3 Marcos de decisão

| Marco | Decisão |
|---|---|
| M1 | Autorizar projeto detalhado e execução |
| M2 | Autorizar integração |
| M3 | Autorizar teste completo em dispositivo |
| M4 | Autorizar não funcionais/aceitação |
| M5 | Autorizar candidato final |
| M6 | Aceitar, aceitar com ressalvas ou rejeitar |

---

# 11. Comunicação

## 11.1 Plano de comunicação

| Comunicação | Público | Frequência | Meio | Responsável |
|---|---|---|---|---|
| Registro de execução e defeitos | QA e desenvolvimento | diária durante execução | ferramenta de defeitos/planilha | Analista QA |
| Situação resumida | produto, QA e desenvolvimento | semanal | relatório curto/reunião | Gerente QA |
| Defeito crítico | produto e desenvolvimento | imediata, até 1 hora útil | mensagem + registro formal | Quem identificar |
| Revisão de marco | partes responsáveis | final de cada semana/marco | reunião e ata | Gerente QA |
| Mudança de escopo | produto, QA e desenvolvimento | sob demanda | solicitação formal | Solicitante |
| Relatório final | todas as partes | encerramento | documento versionado | Gerente QA |

## 11.2 Conteúdo do relatório semanal

- versão/build testado;
- planejado versus executado;
- aprovação, reprovação, bloqueio e não aplicável;
- defeitos por severidade e estado;
- cobertura de requisitos;
- riscos novos/materializados;
- custo e cronograma;
- decisões e ações para a semana seguinte.

## 11.3 Escalonamento

- **Crítico:** comunicar imediatamente; suspender fluxo afetado;
- **Alto:** comunicar no mesmo dia útil;
- **Médio:** incluir no relatório diário/semanal;
- **Baixo:** registrar e priorizar no refinamento.

---

# 12. Gerenciamento de defeitos

## 12.1 Ciclo de vida

`Novo → Triado → Em correção → Pronto para reteste → Aprovado/Fechado`

Estados adicionais: `Bloqueado`, `Duplicado`, `Não reproduzido`, `Não será corrigido` e `Adiado`. Os dois últimos exigem justificativa e aceite do responsável pelo produto quando houver risco.

## 12.2 Severidade

| Severidade | Definição | Exemplo |
|---|---|---|
| Crítica | perda/exposição de dados, acesso indevido, app inutilizável ou risco à segurança | usuário acessa localização de terceiro; fila offline perdida |
| Alta | função essencial indisponível sem contorno aceitável | não inicia/encerra viagem; não sincroniza |
| Média | função secundária falha com contorno | métrica incorreta sem afetar pontos |
| Baixa | problema cosmético ou de texto | alinhamento, ortografia |

## 12.3 Modelo de relatório de defeito

- ID e título curto;
- versão/build;
- ambiente/dispositivo/rede;
- requisito e caso relacionados;
- pré-condições;
- passos para reproduzir;
- resultado esperado;
- resultado obtido;
- frequência;
- severidade e prioridade;
- anexos: captura, vídeo, logs sanitizados e dados sintéticos;
- responsável e estado;
- análise de causa e versão da correção;
- evidência de reteste e regressão.

---

# 13. Riscos

Escalas: probabilidade e impacto de 1 (baixo) a 5 (muito alto). Exposição = probabilidade × impacto.

| ID | Risco | P | I | Exposição | Resposta/contingência | Responsável |
|---|---|---:|---:|---:|---|---|
| R-01 | Cobertura automatizada concentrada em validadores/modelos e fluxos básicos | 4 | 4 | 16 | criar testes de serviços, providers, regras Firebase, chat e calendário | Desenvolvimento/QA |
| R-02 | Regras Firestore permissivas permitem acesso horizontal | 4 | 5 | 20 | criar regras de menor privilégio e testes negativos no emulador | Desenvolvimento/QA |
| R-03 | Background falha com tela bloqueada/fabricantes diferentes | 4 | 5 | 20 | matriz física, ForegroundService e procedimento de recuperação | Desenvolvimento |
| R-04 | SQLite e fila/sessão em SharedPreferences divergem ou perdem estado em encerramento/limite de armazenamento | 3 | 5 | 15 | testes de reinício, reconciliação, lotes e fonte de verdade documentada | Desenvolvimento |
| R-05 | GPS instável produz ETA/geofence incorretos | 4 | 3 | 12 | filtros de precisão, limiar de velocidade, rotas simuladas e tolerância | Desenvolvimento/QA |
| R-06 | Dependência do Firebase/OSM bloqueia execução | 3 | 4 | 12 | emulador, cache, mocks e reprogramação controlada | Gerente QA |
| R-07 | Limites/custos do Firebase durante carga | 3 | 3 | 9 | Emulator Suite, orçamento/alerta de consumo e massa limitada | Gerente QA |
| R-08 | Vazamento de CPF/localização em dados ou evidências | 3 | 5 | 15 | dados sintéticos, sanitização de logs e acesso restrito | QA |
| R-09 | Uma única pessoa acumula desenvolvimento e QA | 5 | 3 | 15 | revisão externa de casos críticos e aceite por usuários | Projeto |
| R-10 | Dispositivo físico indisponível | 3 | 4 | 12 | reserva de agenda, aparelho alternativo e emulador para parte dos testes | Gerente QA |
| R-11 | Cronograma subestima correções críticas | 3 | 4 | 12 | priorização por risco, reserva de 10% e renegociação de escopo/prazo | Produto/QA |
| R-12 | Build `release` usa chave de depuração e pode comprometer autenticidade/atualização | 4 | 4 | 16 | configurar keystore de produção protegida e testar instalação/upgrade | Desenvolvimento |
| R-13 | Código usa Firebase `fir-capdex`, documentos citam `amazon-track-data` e há App IDs provisórios | 4 | 4 | 16 | unificar ambientes, restringir chave cliente e substituir placeholders | Desenvolvimento |
| R-14 | Teste de campo expõe participantes a risco físico | 2 | 5 | 10 | plano de segurança, execução por passageiro e nunca pelo condutor | Projeto |

Riscos com exposição ≥ 15 devem ser revisados em toda reunião semanal e antes de cada marco.

---

# 14. Tarefas, entregáveis e controle de configuração

## 14.1 Tarefas principais

1. aprovar requisitos e plano;
2. restaurar/verificar código e dependências;
3. preparar ambientes, contas e dados;
4. detalhar/revisar casos;
5. executar testes estáticos e automatizados;
6. executar integração, sistema e campo;
7. registrar/triagem de defeitos;
8. corrigir, retestar e regredir;
9. executar aceitação;
10. consolidar métricas, riscos e parecer.

## 14.2 Entregáveis

| Artefato | Descrição | Obrigatório |
|---|---|---|
| Plano de Testes | Este documento, com escopo, estratégia, recursos e critérios | Sim |
| Cronograma do projeto de teste | Semanas, marcos e dependências | Sim |
| Especificações de casos e procedimentos | Passos, dados e resultados esperados | Sim |
| Matriz de rastreabilidade | Requisito, caso, execução e defeito | Sim |
| Registros de execução | Resultado por caso, versão e executor | Sim |
| Relatórios de defeitos | Reprodução, severidade, estado e correção | Sim |
| Relatório de resumo dos testes | Métricas, riscos residuais e parecer | Sim |
| Termo de aceite ou rejeição | Decisão formal da versão | Sim |
| Scripts e suítes automatizadas | Unidade, widget e integração | Sim |
| Evidências sanitizadas | Capturas, vídeos e logs sem dados sensíveis | Sim |
| Massa de dados sintéticos e limpeza | Contas, rotas, pontos e procedimento de remoção | Sim |
| Registro de riscos residuais | Riscos aceitos formalmente | Sim |
| Relatórios semanais de situação | Progresso, defeitos, custo e prazo | Não |
| Roteiros de teste exploratório | Charters e achados | Não |
| Relatório de usabilidade e SUS | Resultados das sessões com usuários | Não |

## 14.3 Identificação da configuração testada

Cada execução deve registrar:

- hash do commit e branch;
- versão do aplicativo e número do build;
- hash/identificação do APK;
- versão Flutter/Dart/Android SDK;
- dispositivo, API, fabricante e modelo;
- projeto Firebase e versão das regras;
- data/hora e perfil de rede;
- dados/seeds utilizados;
- executor.

---

# 15. Métricas e acompanhamento

## 15.1 Métricas

| Métrica | Fórmula |
|---|---|
| Progresso de execução | casos executados ÷ casos planejados × 100 |
| Taxa de aprovação | casos aprovados ÷ casos executados válidos × 100 |
| Cobertura de requisitos | requisitos com teste ÷ requisitos da baseline × 100 |
| Densidade de defeitos | defeitos válidos ÷ requisito, módulo ou mil linhas, conforme dado disponível |
| Taxa de reabertura | defeitos reabertos ÷ defeitos retestados × 100 |
| Eficiência de remoção | defeitos removidos antes do aceite ÷ total conhecido × 100 |
| Tempo médio de correção | soma do tempo até correção ÷ defeitos corrigidos |
| Pass rate crítico | casos críticos aprovados ÷ casos críticos executados × 100 |
| Perda offline | pontos não recuperados ÷ pontos aceitos localmente × 100 |
| Duplicidade | registros lógicos duplicados ÷ registros sincronizados × 100 |

## 15.2 Limites de alerta

- aprovação geral abaixo de 95%;
- qualquer falha crítica;
- cobertura abaixo de 100%;
- mais de 20% bloqueados;
- perda ou duplicidade offline acima de 0%;
- desvio de custo ou cronograma acima de 10%;
- aumento de defeitos reabertos acima de 10%.

---

# 16. Procedimento de execução

1. confirmar build, ambiente e massa;
2. executar *smoke test*;
3. executar suíte automatizada de menor para maior escopo;
4. executar casos manuais priorizados por risco;
5. anexar evidências e registrar resultados no mesmo dia;
6. abrir e triar defeitos;
7. não continuar um fluxo quando a falha puder corromper evidência;
8. após correção, executar o caso reprovado e regressão relacionada;
9. ao final do ciclo, recalcular métricas e riscos;
10. emitir decisão do marco.

## 16.1 Ordem de regressão

1. autenticação e autorização;
2. início/encerramento de viagem;
3. persistência offline e sincronização;
4. integridade de localização;
5. passageiro/mapa;
6. geofencing/notificações;
7. embarcações/rotas;
8. histórico/chat;
9. interface e compatibilidade.

---

# 17. Plano de aceitação

## 17.1 Participantes

Recomenda-se no mínimo:

- dois representantes do perfil passageiro;
- dois representantes do perfil barqueiro/operador;
- um observador/QA;
- responsável pelo produto ou avaliador acadêmico.

## 17.2 Jornadas

- criar conta e autenticar;
- passageiro localizar e acompanhar embarcação;
- barqueiro cadastrar/selecionar embarcação e rota;
- iniciar, manter e encerrar uma viagem;
- operar durante perda e restauração de conexão;
- receber alerta de porto;
- consultar histórico;
- trocar mensagem;
- responder questionário SUS.

## 17.3 Decisão

O produto será:

- **aceito**, se todos os critérios de saída forem atendidos;
- **aceito com ressalvas**, se somente defeitos médios/baixos e riscos residuais explicitamente aceitos permanecerem;
- **rejeitado**, se houver defeito crítico/alto, perda/exposição de dados ou falha em requisito Must.

---

# 18. Pendências e limitações do plano

| ID | Pendência | Consequência |
|---|---|---|
| PP-01 | Confirmar responsáveis e aprovadores | Impede conclusão formal |
| PP-02 | Confirmar `minSdk` e matriz final | Pode alterar compatibilidade |
| PP-03 | Disponibilizar projeto Firebase de teste | Bloqueia integrações |
| PP-04 | Endurecer regras Firestore/Storage | Bloqueia recomendação de produção |
| PP-05 | Definir política LGPD de retenção/exclusão | Bloqueia uso com dados reais |
| PP-06 | Unificar o projeto Firebase e substituir App IDs provisórios | Pode direcionar testes ao ambiente errado |
| PP-07 | Configurar assinatura própria para o build de produção | Bloqueia distribuição oficial segura |
| PP-08 | Implementar testes para serviços, providers, regras, chat e calendário | Mantém risco elevado de regressão |

---

# 19. Aprovação do plano

A assinatura indica concordância com escopo, abordagem, recursos, custo referencial, cronograma, riscos e critérios de decisão.

| Nome | Papel | Decisão | Data | Assinatura |
|---|---|---|---|---|
|  | Responsável pelo produto/projeto | ( ) Aprovado ( ) Ressalvas ( ) Reprovado |  |  |
| João Gabriel da Silva Maciel | Gerente de testes/QA | ( ) Aprovado ( ) Ressalvas ( ) Reprovado |  |  |
|  | Responsável acadêmico/revisor | ( ) Aprovado ( ) Ressalvas ( ) Reprovado |  |  |

---

*Itacoatiara — Amazonas, 07 de setembro de 2026.*
