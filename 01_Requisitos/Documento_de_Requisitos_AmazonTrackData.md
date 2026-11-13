# DOCUMENTO DE REQUISITOS DO SISTEMA

## AmazonTrackData

**Versão:** 1.0  
**Data:** 07 de setembro de 2026  
**Autor:** João Gabriel da Silva Maciel  
**Instituição:** Universidade Federal do Amazonas — UFAM  
**Projeto:** Programa Institucional de Bolsas de Iniciação em Desenvolvimento Tecnológico e Inovação — PIBITI  
**Classificação:** Documento de baseline para desenvolvimento, validação e aceite

---

## Controle do documento

### Histórico de revisões

| Data | Versão | Descrição | Autor |
|---|---:|---|---|
| 07/09/2026 | 1.0 | Emissão inicial do Documento de Requisitos do AmazonTrackData | João Gabriel da Silva Maciel |

### Aprovações

| Papel | Nome | Data | Assinatura |
|---|---|---|---|
| Responsável pelo produto/projeto | A definir |  |  |
| Responsável técnico | João Gabriel da Silva Maciel |  |  |
| Responsável pela qualidade | João Gabriel da Silva Maciel |  |  |
| Responsável acadêmico | A definir |  |  |

---

# 1. Introdução

## 1.1 Objetivo

Este documento especifica os requisitos funcionais e não funcionais do **AmazonTrackData**, estabelecendo uma baseline verificável para projeto, desenvolvimento, testes, homologação e aceite. O documento descreve o comportamento esperado do aplicativo móvel, seus atores, regras de negócio, interfaces externas, dados, restrições, critérios de aceitação e rastreabilidade.

## 1.2 Escopo do produto

O AmazonTrackData é uma plataforma móvel de apoio à mobilidade fluvial na Amazônia. O sistema permite que barqueiros cadastrem embarcações e rotas, iniciem viagens e compartilhem posições geográficas; passageiros acompanhem embarcações e indicadores da viagem; e ambos se comuniquem por mensagens. O produto também prevê captura de GPS, visualização em mapa, geofencing de portos, notificações de aproximação e uma fila local *store-and-forward* para operar em conectividade intermitente.

O sistema é composto, no escopo desta especificação, pelos seguintes elementos:

- aplicativo Flutter para Android, com base multiplataforma;
- autenticação e persistência em serviços Firebase;
- mapas baseados em OpenStreetMap;
- aquisição de localização pelo GPS do dispositivo;
- armazenamento local e sincronização posterior;
- notificações locais associadas a eventos de geofencing;
- histórico de pontos e resumos de viagens;
- comunicação entre passageiro e barqueiro;
- calendário de viagens agendadas;
- página web de divulgação e distribuição do APK, considerada interface de apoio.

## 1.3 Fora do escopo

Não fazem parte da baseline da versão 1.0:

- rastreamento por equipamento GPS dedicado instalado na embarcação;
- comunicação satelital ou por rádio;
- retransmissão ponto a ponto entre dispositivos por Bluetooth, Wi-Fi Direct ou LoRa;
- implementação integral do Bundle Protocol de Redes Tolerantes a Atrasos;
- previsão de chegada por inteligência artificial;
- venda de passagens, pagamentos ou reservas;
- despacho de emergência e integração com autoridades;
- garantia de operação em iOS, Web ou Desktop antes de homologação específica;
- administração avançada por portal web;
- precisão cartográfica ou hidrográfica para navegação profissional.

## 1.4 Público-alvo

- passageiros do transporte fluvial;
- barqueiros e operadores de embarcações;
- pesquisadores e equipe do projeto PIBITI/UFAM;
- equipe de desenvolvimento e qualidade;
- avaliadores acadêmicos e partes interessadas no monitoramento fluvial.

## 1.5 Referências

- PMI. *A Guide to the Project Management Body of Knowledge — PMBOK Guide*.
- ISO/IEC/IEEE 29148:2018. *Systems and software engineering — Life cycle processes — Requirements engineering*.
- IEEE 829-2008. *Standard for Software and System Test Documentation*.
- ISO/IEC 25010:2011. *Systems and software Quality Requirements and Evaluation — Quality models*.
- Lei nº 13.709/2018 — Lei Geral de Proteção de Dados Pessoais (LGPD).
- Documentação técnica do Flutter, Firebase, OpenStreetMap e pacotes declarados no `pubspec.yaml`.
- Diagramas de casos de uso e de banco de dados mantidos no diretório `diagramas/`.
- Documentação interna `docs/GQS_AmazonTrackData.md`, `docs/TESTES.md` e `docs/RELATORIO_ARTIGO_DTN.md`.

## 1.6 Convenções

Os requisitos utilizam a forma **“O sistema deve...”** e identificadores únicos:

- `RF`: requisito funcional;
- `RNF`: requisito não funcional;
- `RN`: regra de negócio;
- `RI`: requisito de interface;
- `RD`: requisito de dados.

Prioridades seguem o método MoSCoW:

- **Must:** obrigatório para aceite da versão;
- **Should:** importante, podendo ser postergado mediante aprovação;
- **Could:** desejável;
- **Won't:** não previsto nesta versão.

## 1.7 Glossário

| Termo | Definição |
|---|---|
| APK | Pacote de instalação de aplicativo Android. |
| Barqueiro | Usuário responsável por cadastrar/operar embarcação e compartilhar sua viagem. |
| DTN | Rede tolerante a atrasos; neste projeto, inspiração para o mecanismo local *store-and-forward*. |
| ETA | Tempo estimado de chegada. |
| Firebase | Plataforma utilizada para autenticação, banco de dados e armazenamento de arquivos. |
| Geofencing | Detecção da entrada, permanência ou saída de uma área geográfica virtual. |
| GPS | Sistema de posicionamento utilizado para obter latitude, longitude, velocidade e demais dados. |
| OSM | OpenStreetMap, provedor de dados cartográficos. |
| Passageiro | Usuário que consulta e acompanha embarcações e viagens. |
| Ponto GPS | Registro geográfico associado a usuário, embarcação, viagem e instante. |
| Sincronização | Envio dos dados locais pendentes para o backend quando existe conectividade. |
| Viagem | Intervalo entre o início e o encerramento de um rastreamento associado a uma embarcação. |

---

# 2. Visão geral do sistema

## 2.1 Contexto e problema

Trechos fluviais amazônicos apresentam longas distâncias e conectividade móvel instável. Soluções que dependem de conexão contínua produzem lacunas de rastreamento. O AmazonTrackData busca reduzir essa lacuna ao coletar posições no dispositivo, armazená-las temporariamente e transmiti-las ao backend quando a rede estiver disponível.

## 2.2 Objetivos do produto

- coletar e registrar coordenadas de viagens fluviais;
- permitir acompanhamento de embarcações em mapa;
- informar aproximação e atracação em portos monitorados;
- preservar dados coletados durante indisponibilidade da rede;
- consolidar histórico e indicadores de viagem;
- organizar viagens futuras em calendário;
- aproximar passageiros e barqueiros por um canal de comunicação;
- fornecer uma base tecnológica extensível para pesquisa em mobilidade e redes intermitentes.

## 2.3 Atores

| Ator | Responsabilidades e permissões principais |
|---|---|
| Visitante | Criar conta e autenticar-se. |
| Passageiro | Consultar embarcações, acompanhar viagens, receber alertas, consultar histórico aplicável e enviar mensagens. |
| Barqueiro | Gerenciar suas embarcações e rotas, iniciar/encerrar rastreamento, acompanhar a fila de sincronização, consultar histórico e responder mensagens. |
| Serviço de localização | Fornecer posição, precisão, velocidade, altitude e direção, quando disponíveis. |
| Firebase | Autenticar usuários, armazenar dados e fornecer atualização remota. |
| Serviço de mapas | Fornecer blocos cartográficos para visualização. |
| Sistema operacional | Controlar permissões, execução em primeiro/segundo plano e notificações. |

## 2.4 Premissas e dependências

- o dispositivo possui Android compatível e sensor/serviço de localização operacional;
- o usuário concede as permissões necessárias de localização e notificação;
- uma conta e um projeto Firebase válidos estão configurados;
- a visualização do mapa e a sincronização remota dependem de conectividade;
- o barqueiro associa o rastreamento à embarcação correta;
- a precisão do ETA depende da qualidade do GPS e da velocidade recebida;
- os serviços Firebase e OpenStreetMap podem ter indisponibilidades ou limites próprios;
- os requisitos desta versão consideram dois perfis persistidos: `passageiro` e `barqueiro`.

## 2.5 Restrições conhecidas da baseline

1. O rastreamento em *background* está implementado com `ForegroundService` Android, persistência de sessão e captura em *isolate*, mas ainda requer homologação em diferentes fabricantes, versões Android, tela bloqueada e encerramento do processo.
2. A persistência offline usa SQLite (`sqflite`) para pontos GPS e `SharedPreferences` para parâmetros de sessão e fila complementar; a documentação antiga que menciona Drift está desatualizada.
3. O mecanismo inspirado em DTN envia dados ao Firebase após reconexão; não existe retransmissão entre dispositivos.
4. As regras Firestore presentes em `docs/FIRESTORE_RULES.txt` permitem leitura e escrita globais a qualquer usuário autenticado. Elas são adequadas somente a desenvolvimento e devem ser endurecidas antes de produção.
5. A configuração do código usa o projeto Firebase `fir-capdex`, enquanto documentos de instalação citam `amazon-track-data`; configurações Web/iOS/macOS contêm identificadores provisórios e precisam ser regularizadas antes de declarar suporte.
6. O `build.gradle.kts` assina o tipo `release` com chave de depuração; uma chave de produção controlada deve ser configurada antes da distribuição oficial.
7. Os testes automatizados existentes concentram-se em validadores/modelos e em cinco fluxos básicos de interface; serviços críticos de background, sincronização, geofencing, chat, calendário e regras Firebase exigem expansão da cobertura.

---

# 3. Requisitos funcionais

## 3.1 Autenticação e perfil

| ID | Requisito | Prioridade | Critério de aceitação resumido |
|---|---|---|---|
| RF-AUT-01 | O sistema deve permitir a criação de conta com nome completo, CPF, e-mail, senha, confirmação de senha e perfil de usuário. | Must | Uma conta válida é criada no Firebase Auth e seu perfil correspondente é persistido. |
| RF-AUT-02 | O sistema deve permitir selecionar exatamente um perfil entre passageiro e barqueiro durante o cadastro. | Must | O perfil escolhido é persistido e direciona as funções disponibilizadas. |
| RF-AUT-03 | O sistema deve validar campos obrigatórios, formato de e-mail, CPF, nome e confirmação da senha antes do envio. | Must | Dados inválidos não são enviados e uma mensagem específica é exibida. |
| RF-AUT-04 | O sistema deve autenticar usuário por e-mail e senha. | Must | Credenciais válidas iniciam uma sessão; inválidas não concedem acesso. |
| RF-AUT-05 | O sistema deve permitir autenticação com conta Google quando o provedor estiver configurado. | Should | Login Google válido cria/recupera o perfil sem duplicação de usuário. |
| RF-AUT-06 | O sistema deve manter a sessão autenticada de forma compatível com o Firebase Auth. | Must | Ao reabrir o app, usuário autenticado é direcionado à área correspondente. |
| RF-AUT-07 | O sistema deve permitir encerrar a sessão. | Must | Tokens locais são invalidados/removidos e o usuário retorna à autenticação. |
| RF-PER-01 | O sistema deve permitir ao usuário consultar seus dados de perfil e tipo de conta. | Should | Os dados persistidos são exibidos sem expor credenciais. |

## 3.2 Embarcações e rotas

| ID | Requisito | Prioridade | Critério de aceitação resumido |
|---|---|---|---|
| RF-EMB-01 | O sistema deve permitir ao barqueiro cadastrar uma embarcação com nome, tipo, capacidade e dados complementares. | Must | Embarcação válida é vinculada ao UID do proprietário. |
| RF-EMB-02 | O sistema deve permitir ao barqueiro listar suas embarcações. | Must | Apenas embarcações autorizadas são gerenciáveis pelo proprietário. |
| RF-EMB-03 | O sistema deve permitir ao barqueiro editar os dados de sua embarcação. | Must | Alterações válidas são persistidas; terceiros não podem editar. |
| RF-EMB-04 | O sistema deve permitir anexar ou substituir foto da embarcação. | Should | Arquivo aceito é armazenado e sua URL é vinculada ao registro. |
| RF-ROT-01 | O sistema deve permitir ao barqueiro consultar rotas disponíveis. | Must | Rotas ativas são exibidas com origem, destino e paradas. |
| RF-ROT-02 | O sistema deve permitir cadastrar rota com nome, origem, destino, paradas e duração estimada. | Should | Uma rota válida pode ser posteriormente selecionada para viagem. |
| RF-ROT-03 | O sistema deve permitir selecionar embarcação e rota antes do início de uma viagem do barqueiro. | Must | A viagem criada registra os identificadores corretos. |

## 3.3 Rastreamento e viagem

| ID | Requisito | Prioridade | Critério de aceitação resumido |
|---|---|---|---|
| RF-RAS-01 | O sistema deve solicitar e tratar as permissões de localização exigidas pela versão do Android. | Must | Concessão inicia o fluxo; negação produz orientação e não causa falha. |
| RF-RAS-02 | O sistema deve permitir ao barqueiro iniciar rastreamento associado a uma viagem e embarcação. | Must | É criado um identificador de viagem e o estado muda para rastreamento ativo. |
| RF-RAS-03 | O sistema deve coletar pontos GPS periodicamente, incluindo usuário, viagem, embarcação, latitude, longitude, velocidade, precisão e instante; altitude e direção são opcionais. | Must | Registros produzidos respeitam o modelo de dados e a ordenação temporal. |
| RF-RAS-04 | O sistema deve exibir a posição atual e a rota em mapa interativo. | Must | O marcador e o trajeto refletem os dados recebidos sem bloquear a interface. |
| RF-RAS-05 | O sistema deve permitir encerrar o rastreamento. | Must | A coleta é interrompida, o estado é atualizado e dados pendentes permanecem recuperáveis. |
| RF-RAS-06 | O sistema deve gerar ou recuperar resumo de viagem contendo duração, distância e velocidade média. | Should | Métricas são consistentes com os pontos válidos da viagem. |
| RF-RAS-07 | O sistema deve evitar duas sessões de rastreamento concorrentes para o mesmo usuário no mesmo dispositivo. | Must | Uma segunda tentativa é rejeitada ou redirecionada à sessão ativa. |
| RF-RAS-08 | O sistema deve manter a captura no Android por serviço em primeiro plano quando o aplicativo estiver minimizado ou a tela estiver bloqueada, conforme permissões concedidas. | Must | A notificação persistente permanece visível e os pontos continuam sendo gravados. |
| RF-RAS-09 | O sistema deve restaurar uma sessão de rastreamento ativa após recriação da interface ou reinício recuperável do serviço. | Must | Usuário, viagem, embarcação e estado ativo são recuperados sem iniciar uma viagem duplicada. |

## 3.4 Operação offline e sincronização

| ID | Requisito | Prioridade | Critério de aceitação resumido |
|---|---|---|---|
| RF-OFF-01 | O sistema deve manter os pontos capturados localmente quando o backend não estiver acessível. | Must | Pontos coletados offline permanecem disponíveis após interrupção controlada do app. |
| RF-OFF-02 | O sistema deve organizar a fila local de forma FIFO e identificar unicamente cada ponto. | Must | A ordem é preservada e o mesmo ponto não é duplicado na fila. |
| RF-OFF-03 | O sistema deve detectar restauração de conectividade e iniciar a sincronização dos pontos pendentes. | Must | O envio começa automaticamente, sem intervenção do usuário. |
| RF-OFF-04 | O sistema deve reenviar pontos com falha sem remover dados não confirmados. | Must | Somente pontos confirmados são retirados da fila. |
| RF-OFF-05 | O sistema deve sincronizar em lotes limitados, atualmente planejados em até 50 pontos por ciclo. | Should | O lote não excede o limite e a fila remanescente é processada em ciclos posteriores. |
| RF-OFF-06 | O sistema deve informar ao usuário a existência e, quando aplicável, a quantidade de dados pendentes. | Should | O indicador corresponde ao estado da fila local. |

## 3.5 Geofencing e notificações

| ID | Requisito | Prioridade | Critério de aceitação resumido |
|---|---|---|---|
| RF-GEO-01 | O sistema deve comparar posições com o catálogo implementado de 13 portos monitorados. | Must | Para cada porto e coordenadas controladas, a zona calculada corresponde aos raios configurados. |
| RF-GEO-02 | O sistema deve distinguir, no mínimo, os estados fora da zona, aproximação e atracação. | Must | Transições ocorrem nos limites configurados e sem alternância indevida. |
| RF-GEO-03 | O sistema deve emitir notificações locais para eventos relevantes de aproximação, atracação e saída, quando autorizadas. | Should | Uma transição válida gera o alerta correspondente. |
| RF-GEO-04 | O sistema deve aplicar intervalo de contenção para evitar notificações repetidas do mesmo porto. | Should | Eventos dentro do período de *debounce* não geram spam. |
| RF-GEO-05 | O sistema deve calcular ETA pela distância e velocidade quando a velocidade for suficiente para uma estimativa. | Should | A unidade e o arredondamento são coerentes; baixa velocidade resulta em ETA indisponível. |

## 3.6 Funcionalidades do passageiro

| ID | Requisito | Prioridade | Critério de aceitação resumido |
|---|---|---|---|
| RF-PAS-01 | O sistema deve permitir ao passageiro consultar embarcações ativas. | Must | Lista apresenta apenas registros autorizados e estado compatível. |
| RF-PAS-02 | O sistema deve permitir selecionar uma embarcação para acompanhamento. | Must | A seleção abre o mapa e associa o fluxo à embarcação escolhida. |
| RF-PAS-03 | O sistema deve exibir a última posição válida da embarcação e atualizar o marcador quando chegarem novos dados. | Must | Atualizações remotas são refletidas e dados antigos são identificados. |
| RF-PAS-04 | O sistema deve apresentar, quando disponíveis, ETA, velocidade, progresso e distância restante. | Should | Indicadores usam a viagem ativa e apresentam unidade compreensível. |
| RF-PAS-05 | O sistema deve permitir ativar/desativar alertas de acompanhamento. | Could | Preferência é aplicada sem alterar dados de outros usuários. |

## 3.7 Histórico e comunicação

| ID | Requisito | Prioridade | Critério de aceitação resumido |
|---|---|---|---|
| RF-HIS-01 | O sistema deve permitir consultar histórico de viagens autorizado, em ordem cronológica. | Should | Viagens e resumos exibidos pertencem ao escopo do usuário. |
| RF-HIS-02 | O sistema deve permitir visualizar os principais dados de uma viagem selecionada. | Should | Datas, duração, distância, velocidade e rota são consistentes. |
| RF-CHAT-01 | O sistema deve permitir troca de mensagens entre passageiro e barqueiro em conversa autorizada. | Should | Mensagem enviada é persistida uma vez e aparece aos participantes. |
| RF-CHAT-02 | O sistema deve apresentar lista de conversas com última mensagem e instante. | Should | Ordenação e dados correspondem às mensagens persistidas. |
| RF-CHAT-03 | O sistema deve registrar remetente, conversa, texto, instante e estado de leitura. | Should | Campos obrigatórios são persistidos e somente participantes têm acesso. |

## 3.8 Calendário de viagens

| ID | Requisito | Prioridade | Critério de aceitação resumido |
|---|---|---|---|
| RF-AGE-01 | O sistema deve permitir ao barqueiro agendar viagem com embarcação, origem, destino, paradas, data/hora de saída, chegada estimada, assentos e observações. | Should | Uma agenda válida é vinculada ao proprietário e fica disponível no calendário. |
| RF-AGE-02 | O sistema deve permitir aos usuários consultar viagens agendadas em calendário. | Should | Viagens futuras são exibidas na data correta, com estado e dados essenciais. |
| RF-AGE-03 | O sistema deve permitir ao proprietário cancelar sua viagem agendada. | Should | O estado de cancelamento é persistido e claramente apresentado, sem excluir o histórico. |
| RF-AGE-04 | O sistema deve distinguir viagens futuras, passadas e canceladas. | Should | A classificação corresponde à data atual e ao indicador de cancelamento. |

## 3.9 Distribuição

| ID | Requisito | Prioridade | Critério de aceitação resumido |
|---|---|---|---|
| RF-DIS-01 | A página web de apoio deve explicar os recursos e perfis do produto. | Could | Conteúdo é legível em desktop e dispositivo móvel. |
| RF-DIS-02 | A página web deve disponibilizar o APK aprovado para Android com versão identificável. | Should | O link retorna o arquivo correto e não produz erro HTTP. |

---

# 4. Regras de negócio

| ID | Regra |
|---|---|
| RN-01 | Cada conta deve possuir um UID único fornecido pelo serviço de autenticação. |
| RN-02 | Um CPF deve passar pela validação dos dígitos verificadores e não pode ser composto por todos os dígitos iguais. |
| RN-03 | A senha deve possuir no mínimo seis caracteres na baseline atual; políticas mais fortes podem ser exigidas antes da produção. |
| RN-04 | O nome informado deve conter pelo menos dois termos. |
| RN-05 | Somente o proprietário pode alterar os dados de sua embarcação. |
| RN-06 | Uma viagem de barqueiro deve estar associada a um usuário, uma embarcação e, quando exigido pelo fluxo, uma rota. |
| RN-07 | Pontos GPS devem ser ordenáveis por `timestamp` e vinculados a um `tripId`. |
| RN-08 | Ponto pendente somente pode ser excluído da fila local após confirmação do envio remoto. |
| RN-09 | O identificador local deve permitir deduplicar reenvios. |
| RN-10 | A velocidade armazenada usa metros por segundo; a interface pode convertê-la para quilômetros por hora. |
| RN-11 | Distâncias persistidas usam metros; a interface pode apresentá-las em quilômetros. |
| RN-12 | O ETA não deve ser calculado como confiável abaixo do limiar de velocidade definido, inicialmente 0,5 m/s. |
| RN-13 | O acesso a localização, CPF, conversas e histórico deve respeitar finalidade, autenticação e menor privilégio. |
| RN-14 | Usuários inativos não devem iniciar novas operações protegidas. |
| RN-15 | Dados de rastreamento antigos não devem ser apresentados como posição em tempo real sem indicação de desatualização. |

---

# 5. Requisitos de dados

## 5.1 Entidades principais

| Entidade | Dados mínimos |
|---|---|
| Usuário | UID, e-mail, nome completo, CPF, tipo, data de criação, estado ativo. |
| Embarcação | ID, proprietário, nome, tipo, capacidade opcional, foto opcional, rotas e estado ativo. |
| Rota | ID, nome, origem, destino, paradas, duração estimada, frequência e estado ativo. |
| Parada/porto | ID, nome, cidade, estado, latitude, longitude, raio e tipo. |
| Localização | Usuário, viagem, embarcação, latitude, longitude, velocidade, precisão, instante, altitude/direção opcionais. |
| Resumo de viagem | Viagem, usuário, embarcação, início, fim, quantidade de pontos, velocidade média e distância. |
| Viagem agendada | ID, embarcação, proprietário, origem, destino, paradas, saída, chegada estimada, assentos, observações, cancelamento e criação. |
| Conversa | ID, participantes, nomes, última mensagem, último remetente e instante. |
| Mensagem | ID, conversa, remetente, texto, instante e estado de leitura. |
| Ponto local | ID único, usuário, viagem, embarcação, posição, velocidade, instante e estado de sincronização. |

## 5.2 Requisitos de integridade e retenção

| ID | Requisito |
|---|---|
| RD-01 | IDs de usuário, embarcação, viagem, rota e mensagem devem ser não vazios quando obrigatórios. |
| RD-02 | Latitude deve estar entre -90 e 90; longitude, entre -180 e 180. |
| RD-03 | `timestamp` deve representar um instante válido e permitir ordenação cronológica. |
| RD-04 | Leituras com precisão inválida ou coordenadas fora dos limites devem ser rejeitadas ou marcadas. |
| RD-05 | A exclusão/anonimização e a retenção de localização devem ser definidas antes de uso em produção conforme a LGPD. |
| RD-06 | Backups e exportações não devem incluir senhas nem tokens de autenticação. |
| RD-07 | O mecanismo de sincronização deve ser idempotente para impedir duplicidade lógica. |

---

# 6. Requisitos de interfaces externas

| ID | Interface | Requisito |
|---|---|---|
| RI-01 | Firebase Auth | O aplicativo deve autenticar por TLS usando SDK oficial e tratar códigos de erro sem expor informações sensíveis. |
| RI-02 | Cloud Firestore | O aplicativo deve ler/escrever somente coleções e documentos autorizados pelas regras implantadas. |
| RI-03 | Firebase Storage | Fotos devem ser limitadas a usuários autenticados e ao escopo autorizado. |
| RI-04 | GPS/Geolocator | O aplicativo deve tratar serviço desativado, permissão negada, precisão insuficiente e indisponibilidade temporária. |
| RI-05 | OpenStreetMap | O mapa deve respeitar atribuição, política de uso e falhas de carregamento dos blocos. |
| RI-06 | Sistema de notificações | O aplicativo deve solicitar permissão quando exigido e funcionar sem falha caso ela seja negada. |
| RI-07 | Conectividade | Mudanças entre Wi-Fi, rede móvel e ausência de rede devem atualizar o estado de sincronização. |
| RI-08 | Interface humana | Textos, mensagens e unidades devem ser apresentados em português brasileiro de forma consistente. |

---

# 7. Requisitos não funcionais

## 7.1 Segurança e privacidade

| ID | Requisito mensurável | Prioridade |
|---|---|---|
| RNF-SEG-01 | Todas as operações protegidas devem exigir sessão autenticada válida. | Must |
| RNF-SEG-02 | Regras Firestore e Storage de produção devem aplicar menor privilégio, restringindo alterações ao proprietário/participante autorizado. | Must |
| RNF-SEG-03 | Senhas, tokens, CPF completo e coordenadas não devem ser registrados em logs de produção. | Must |
| RNF-SEG-04 | Dados em trânsito devem usar TLS fornecido pelos SDKs/serviços oficiais. | Must |
| RNF-SEG-05 | Tentativas de acesso horizontal entre UIDs devem ser negadas em 100% dos casos críticos de teste. | Must |
| RNF-SEG-06 | O produto deve informar finalidade do uso de localização e obter consentimento/permissão do sistema operacional. | Must |
| RNF-SEG-07 | Credenciais Firebase de cliente devem ser restringidas por aplicativo e as chaves administrativas não podem integrar o APK. | Must |

## 7.2 Desempenho e eficiência

| ID | Requisito mensurável | Prioridade |
|---|---|---|
| RNF-DES-01 | A tela inicial autenticável deve tornar-se utilizável em até 5 segundos em dispositivo de referência, desconsiderado o primeiro download de dependências externas. | Should |
| RNF-DES-02 | O processamento local de um ponto GPS deve ocorrer em até 2 segundos no percentil 95. | Must |
| RNF-DES-03 | Com conexão estável, uma atualização remota deve aparecer ao passageiro em até 10 segundos no percentil 95. | Should |
| RNF-DES-04 | Após a reconexão detectada, o primeiro ciclo de sincronização deve iniciar em até 30 segundos. | Must |
| RNF-DES-05 | A interface deve manter interação fluida, sem ANR, durante sessão contínua de rastreamento de duas horas. | Must |
| RNF-DES-06 | A fila deve ser processada em lotes de até 50 pontos por ciclo, salvo alteração formal de configuração. | Should |

## 7.3 Confiabilidade e recuperação

| ID | Requisito mensurável | Prioridade |
|---|---|---|
| RNF-CON-01 | Em teste offline controlado de 60 minutos, 100% dos pontos aceitos devem permanecer recuperáveis até confirmação de sincronização. | Must |
| RNF-CON-02 | A sincronização deve enviar 100% dos pontos válidos sem duplicação lógica após restauração da rede. | Must |
| RNF-CON-03 | Falhas de um envio não devem impedir o processamento futuro dos dados pendentes. | Must |
| RNF-CON-04 | Encerramento inesperado e reabertura do aplicativo não devem apagar a fila persistida. | Must |
| RNF-CON-05 | Indisponibilidade de mapa, Firebase ou GPS deve produzir estado degradado e mensagem compreensível, sem encerramento abrupto. | Must |

## 7.4 Usabilidade e acessibilidade

| ID | Requisito mensurável | Prioridade |
|---|---|---|
| RNF-USA-01 | Pelo menos 90% dos participantes do teste de aceitação devem concluir login, seleção/acompanhamento e início/encerramento de viagem sem ajuda crítica. | Should |
| RNF-USA-02 | O escore médio da System Usability Scale (SUS) deve ser igual ou superior a 68. | Should |
| RNF-USA-03 | Erros de entrada devem identificar o campo e orientar a correção. | Must |
| RNF-USA-04 | Controles essenciais devem possuir rótulos semânticos e contraste verificável segundo WCAG 2.1 nível AA, quando aplicável. | Should |
| RNF-USA-05 | Estado online/offline, rastreamento ativo e sincronização pendente devem ser visualmente distinguíveis. | Must |

## 7.5 Compatibilidade e portabilidade

| ID | Requisito mensurável | Prioridade |
|---|---|---|
| RNF-COM-01 | A versão Android deve ser validada no `minSdk` efetivamente gerado pelo Flutter e nas APIs 30, 33, 34 e 35, reais ou emuladas. | Must |
| RNF-COM-02 | O layout deve funcionar nas resoluções e densidades do conjunto de dispositivos definido no Plano de Testes. | Must |
| RNF-COM-03 | Mudança entre Wi-Fi e rede móvel não deve encerrar a viagem nem perder pontos aceitos. | Must |
| RNF-COM-04 | Outras plataformas Flutter somente serão declaradas suportadas após execução de suíte específica. | Must |

## 7.6 Manutenibilidade

| ID | Requisito mensurável | Prioridade |
|---|---|---|
| RNF-MAN-01 | O código deve passar pela análise estática configurada sem erros bloqueadores. | Must |
| RNF-MAN-02 | A lógica crítica de validadores, modelos, fila offline, geofencing e regras de cálculo deve possuir testes automatizados. | Must |
| RNF-MAN-03 | Requisitos, casos de teste e defeitos devem possuir identificadores rastreáveis. | Must |
| RNF-MAN-04 | Configurações de ambiente e segredos não devem ser codificados em módulos de domínio. | Must |

---

# 8. Casos de uso essenciais

## UC-01 — Criar conta

**Atores:** Visitante e Firebase.  
**Pré-condições:** Aplicativo instalado; serviço de autenticação configurado.  
**Fluxo principal:**

1. visitante abre a tela de cadastro;
2. informa nome, CPF, e-mail, senha, confirmação e perfil;
3. sistema valida os campos;
4. sistema cria a credencial no Firebase Auth;
5. sistema persiste o perfil;
6. sistema confirma o cadastro e abre a área adequada.

**Alternativas:** dados inválidos; CPF/e-mail já utilizado; falha de rede; credencial criada sem perfil persistido.  
**Pós-condição:** conta e perfil consistentes, ou operação revertida/recuperável.

## UC-02 — Iniciar e encerrar viagem

**Ator:** Barqueiro.  
**Pré-condições:** usuário autenticado; embarcação válida; localização habilitada; permissões concedidas.  
**Fluxo principal:**

1. barqueiro seleciona embarcação e rota;
2. solicita início do rastreamento;
3. sistema cria a viagem e inicia captura periódica;
4. pontos são persistidos localmente e enviados quando possível;
5. mapa e indicadores são atualizados;
6. barqueiro solicita encerramento;
7. sistema interrompe a captura, preserva pendências e gera o resumo.

**Alternativas:** permissão negada; GPS desligado; ausência de internet; falha do Firebase; tentativa de segunda viagem simultânea.  
**Pós-condição:** viagem encerrada com dados íntegros e pendências recuperáveis.

## UC-03 — Acompanhar embarcação

**Ator:** Passageiro.  
**Pré-condições:** usuário autenticado; embarcação/viagem visível e autorizada.  
**Fluxo principal:**

1. passageiro consulta embarcações ativas;
2. seleciona uma embarcação;
3. sistema apresenta mapa, última posição, rota e indicadores disponíveis;
4. novas posições atualizam a tela;
5. sistema sinaliza dados desatualizados e mudanças de zona.

**Alternativas:** nenhuma viagem ativa; ponto antigo; mapa indisponível; perda de conexão.  
**Pós-condição:** acompanhamento pode ser encerrado sem alterar a viagem.

## UC-04 — Sincronizar pontos offline

**Atores:** Aplicativo, sistema operacional e Firebase.  
**Pré-condições:** existência de ponto pendente.  
**Fluxo principal:**

1. aplicativo detecta conectividade;
2. carrega fila FIFO;
3. seleciona lote;
4. envia cada ponto;
5. confirma persistência remota;
6. remove somente os confirmados;
7. atualiza contador e continua em ciclo posterior.

**Alternativas:** falha parcial; conexão oscila; resposta lenta; ponto duplicado; reinício do aplicativo.  
**Pós-condição:** pontos confirmados estão no backend uma única vez; falhas permanecem pendentes.

---

# 9. Critérios globais de aceitação

A versão candidata somente poderá ser recomendada para aceite quando:

1. todos os requisitos **Must** possuírem caso de teste e resultado;
2. 100% dos testes críticos de autenticação, autorização, captura, persistência offline e sincronização forem aprovados;
3. ao menos 95% do total de casos planejados forem aprovados;
4. não houver defeito aberto de severidade crítica ou alta;
5. defeitos médios remanescentes possuírem aceite formal e plano de correção;
6. a suíte automatizada de regressão estiver integralmente aprovada;
7. as regras Firebase de produção forem validadas por testes positivos e negativos;
8. o teste offline demonstrar ausência de perda e duplicidade;
9. documentação de instalação, configuração e operação estiver atualizada;
10. o responsável pelo produto/projeto registrar decisão de aceite.

---

# 10. Matriz de rastreabilidade resumida

| Grupo de requisitos | Componentes/artefatos associados | Tipos de teste previstos |
|---|---|---|
| RF-AUT, RF-PER | autenticação, validadores, usuários, telas de login/cadastro/perfil | unitário, widget, integração, segurança, aceitação |
| RF-EMB, RF-ROT | modelos e persistência de embarcações, rotas e paradas | unitário, integração Firebase, funcional, autorização |
| RF-RAS | localização, viagem, mapa e resumo | unitário, integração, sistema, campo, desempenho |
| RF-OFF | fila local, conectividade e sincronização | unitário, integração, falha/recuperação, estresse |
| RF-GEO | geofencing, ETA e notificações | unitário parametrizado, integração com GPS simulado, sistema |
| RF-PAS | mapa e acompanhamento em tempo real | integração, sistema, usabilidade, desempenho |
| RF-HIS, RF-CHAT | histórico, conversas e mensagens | integração, autorização, sistema |
| RF-AGE | calendário, modelo e provedor de viagens agendadas | unitário, widget, integração, autorização, sistema |
| RF-DIS | página web e distribuição do APK | interface, compatibilidade, download |
| RNF-SEG | Auth, regras Firestore/Storage, logs e LGPD | segurança e revisão de configuração |
| RNF-DES, RNF-CON | app, Firebase, fila offline e rede | desempenho, carga, estabilidade, recuperação |

A matriz detalhada requisito–caso de teste é mantida no **Plano de Testes do AmazonTrackData**.

---

# 11. Pendências para aprovação da baseline

| ID | Pendência | Responsável | Impacto |
|---|---|---|---|
| P-01 | Confirmar o responsável acadêmico e aprovador do documento. | Projeto | Assinatura/controle documental. |
| P-02 | Confirmar o `minSdk` Android resolvido pelo ambiente Flutter. | Desenvolvimento | Define matriz de compatibilidade. |
| P-03 | Definir política de retenção, exclusão e anonimização de localização/CPF. | Produto/privacidade | Obrigatório antes de produção com dados reais. |
| P-04 | Substituir regras permissivas do Firestore por regras de menor privilégio. | Desenvolvimento | Risco crítico de acesso indevido. |
| P-05 | Validar em dispositivo real o rastreamento em segundo plano, com tela bloqueada e restauração de sessão. | QA/Desenvolvimento | Funcionalidade operacional crítica. |
| P-06 | Unificar o projeto Firebase documentado/configurado e substituir identificadores provisórios das plataformas. | Desenvolvimento | Integração e portabilidade. |
| P-07 | Configurar assinatura própria e protegida para builds de produção. | Desenvolvimento | Autenticidade, atualização e distribuição. |
| P-08 | Ampliar testes automatizados para serviços, providers, regras Firebase, chat e calendário. | QA/Desenvolvimento | Risco de regressão nos fluxos críticos. |

---

# 12. Declaração de aprovação

A aprovação deste documento estabelece a baseline dos requisitos do AmazonTrackData. Mudanças posteriores devem registrar solicitação, justificativa, impacto em custo, prazo, risco, arquitetura e testes, além da atualização da rastreabilidade.

| Nome | Papel | Decisão | Data | Assinatura |
|---|---|---|---|---|
|  | Responsável pelo produto/projeto | ( ) Aprovado ( ) Aprovado com ressalvas ( ) Reprovado |  |  |
| João Gabriel da Silva Maciel | Responsável técnico/QA | ( ) Aprovado ( ) Aprovado com ressalvas ( ) Reprovado |  |  |

---

*Itacoatiara — Amazonas, 07 de setembro de 2026.*
