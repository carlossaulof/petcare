# PetCare — Sistema de Gerenciamento de Petshop

Aplicativo Flutter/Dart para petshop com banho, tosa e atendimento veterinário,
integrando **cliente**, **funcionário** e **gerente** em uma única plataforma.
Interface 100% em PT-BR (R$, DD/MM/AAAA, 24 h), paleta verde-sálvia, branco,
bege e creme.

> Versão atual: **dados locais** (sem servidor). Tudo funciona de verdade no
> aparelho — cadastro, login, agendamento, atualização em tempo real entre os
> três perfis, pagamentos presenciais, avaliações e relatórios. Integrações
> externas (pagamento online, push, e-mail) **não são simuladas**: aparecem
> como "não configuradas" até você conectá-las (veja *Integrações*).

---

## 1. Como rodar

Requisitos: Flutter **3.22 ou superior** (Dart 3.4+).

```bash
cd petcare
# Gera as pastas de plataforma (android/, ios/, web/, windows/...) sem tocar em lib/
flutter create . --project-name petcare --org br.com.petcare
flutter pub get
flutter test          # testes de regra de negócio
flutter run           # escolha emulador, celular, Chrome ou Windows
```

Na primeira execução o app cria uma base de demonstração.

### Contas de demonstração

| Perfil | E-mail | Senha |
|---|---|---|
| Cliente | cliente@petcare.app | cliente123 |
| Cliente 2 | diego@petcare.app | diego123 |
| Funcionário (banho e tosa) | func@petcare.app | func123 |
| Funcionária (banho e tosa) | bruna@petcare.app | bruna123 |
| Veterinária | vet@petcare.app | vet123 |
| Gerente | gerente@petcare.app | gerente123 |

Na tela de login há atalhos que preenchem essas contas. O gerente pode
restaurar a base em **Perfil › Restaurar dados de demonstração**.

**Teste do tempo real:** entre como cliente, agende um banho, saia e entre
como funcionário — o atendimento já aparece no painel. Inicie as etapas,
volte para o cliente: linha do tempo, previsão e notificações estão
atualizadas. Tudo que um perfil faz reflete imediatamente nos outros.

### Permissões de plataforma (foto do pet)

- **iOS** — em `ios/Runner/Info.plist` adicione:
  ```xml
  <key>NSPhotoLibraryUsageDescription</key>
  <string>Usamos a galeria para a foto do seu pet.</string>
  <key>NSCameraUsageDescription</key>
  <string>Usamos a câmera para fotografar seu pet.</string>
  ```
- **Android** — nada a configurar para galeria/câmera com `image_picker`.
- **Web/Windows** — a câmera pode não estar disponível; a galeria funciona.

---

## 2. Funcionalidades

### Autenticação e permissões
- Login, cadastro (sempre como **cliente**), recuperação de senha por código
  de 6 dígitos (15 min), alteração de senha. Senhas com hash SHA-256 + salt.
- Funcionários e gerentes **só podem ser criados por um gerente**.
- Toda regra é validada na camada de dados (`ensure(...)`), não só na tela:
  uma ação sem permissão gera `PermissionDenied`.

| Ação | Cliente | Funcionário | Veterinário | Gerente |
|---|:-:|:-:|:-:|:-:|
| Cadastrar/editar os próprios pets | ✓ | editar | editar | ✓ |
| Agendar | próprios pets | — | — | para qualquer cliente |
| Cancelar / reagendar | até X h antes | — | — | ✓ |
| Atualizar etapas, observações, adicionais | — | atribuídos | atribuídos | ✓ |
| Autorizar serviço adicional | ✓ (tutor) | — | — | — |
| Confirmar pagamento no balcão | — | ✓ | ✓ | ✓ |
| Ficha clínica completa | vê diagnóstico/prescrição do próprio pet | — | ✓ | ✓ |
| Serviços, preços, horários, equipe, financeiro, relatórios | — | — | — | ✓ |

### Cliente — Início, Pets, Agenda, Avisos, Perfil
- Pets com foto, espécie, raça, sexo, porte, nascimento, peso, castração,
  alergias, condições, medicações, comportamento e vacinas.
- Agendamento: pet → serviço → data → **horários realmente livres**
  (expediente + profissional habilitado sem conflito + pet sem conflito).
- Acompanhamento em tempo real: linha do tempo das etapas com horário e
  responsável, % de progresso e **previsão de conclusão**.
- Aprovar/recusar serviços adicionais sugeridos pela equipe.
- Notificações a cada mudança (início, etapa, ocorrência, conclusão…).
- Pagamento após o atendimento e avaliação de 1 a 5 estrelas.
- Histórico completo de atendimentos.

### Funcionário
- Painel por dia com atendimentos atribuídos, dados do animal, alertas de
  saúde e dados do tutor.
- Iniciar/concluir etapas (horário e responsável registrados
  automaticamente), ajustar previsão, observações e **ocorrências**,
  solicitar adicional (exige autorização do tutor), consultar histórico.
- Recepção (especialidade) vê todos os atendimentos do dia.
- **Área veterinária restrita**: consultas abertas, retornos, fichas
  clínicas com queixa, anamnese, sinais vitais, diagnóstico, prescrição e
  retorno.

### Gerente
- Dashboard com dados reais: em andamento, faturamento (dia/7 dias),
  clientes, nota média, gráfico de faturamento e atendimentos por área.
- Agenda geral com filtros por data, status e profissional; atribuição de
  funcionário, cancelamento e reagendamento.
- Serviços, preços, duração e etapas; horários e dias de funcionamento;
  antecedência mínima para o cliente cancelar.
- Equipe e clientes: cadastro, perfil de acesso, especialidade, ativar/
  desativar.
- Financeiro: faturamento, a receber, ticket médio, por forma de pagamento,
  confirmação e estorno.
- Relatórios: produtividade por profissional, tempo médio, cancelamentos,
  reagendamentos, serviços mais realizados e avaliações.

---

## 3. Arquitetura

```
lib/
├── main.dart                 # injeção de dependências (fonte de dados e integrações)
├── app.dart                  # MaterialApp PT-BR + roteamento por perfil
├── core/                     # tema, formatação PT-BR, validadores, ids/hash
├── data/
│   ├── models/               # usuários, animais, serviços, agendamentos,
│   │                         # procedimentos, pagamentos, avaliações, notificações
│   ├── data_source.dart      # interface de persistência (+ SharedPreferences)
│   ├── store_base.dart       # base em memória, commit/notify, permissões
│   ├── repositories/         # regras de negócio por domínio (mixins)
│   ├── app_data.dart         # fachada única (ChangeNotifier)
│   └── seed.dart             # dados de demonstração
├── services/integrations.dart# interfaces: pagamento, push, e-mail
├── state/auth_controller.dart
└── ui/
    ├── auth/  client/  staff/ (vet/)  manager/
    ├── shared/               # perfil, notificações, ficha do pet, horários
    └── common/               # widgets, gráficos, linha do tempo
```

- **Tempo real**: toda alteração passa por `commit()` → `notifyListeners()`
  (Provider). Todas as telas abertas dos três perfis se reconstroem na hora;
  um *ticker* de 1 min atualiza previsões e barras de progresso.
- **Persistência**: JSON em `SharedPreferences` (Android, iOS, Web, Windows,
  macOS, Linux), com escrita agrupada a cada 250 ms.
- **Escalável**: telas não conhecem a persistência. Para usar um backend,
  implemente `PetCareDataSource` (ou troque os repositórios por chamadas
  remotas) sem mudar a interface.

### Limitação da versão local
O tempo real vale para todos os perfis **no mesmo aparelho/navegador**. Para
sincronizar aparelhos diferentes (cliente no celular, equipe no tablet), é
preciso um backend — veja abaixo.

---

## 4. Integrações (o que configurar)

Nenhuma credencial está no projeto. Cada integração tem uma interface em
`lib/services/integrations.dart` e é injetada em `main.dart`.

### 4.1 Backend multi-dispositivo (Firebase recomendado)
1. Crie um projeto no Firebase Console e rode `flutterfire configure`.
2. Adicione `firebase_core`, `firebase_auth`, `cloud_firestore`.
3. Substitua `AuthController.login/register` por Firebase Auth e guarde o
   perfil (`role`, `especialidade`) em `users/{uid}` — **nunca** confie no
   perfil enviado pelo app.
4. Crie coleções `users`, `pets`, `services`, `appointments` (etapas, notas,
   adicionais e eventos como subcampos ou subcoleções), `payments`,
   `reviews`, `notifications`, `clinicalEntries`.
5. Ouça as coleções com `snapshots()` e chame `notifyListeners()` — a
   interface já está pronta para isso.
6. Replique as regras de `ensure(...)` nas **Security Rules** (ex.: só o
   gerente escreve em `services`; só o funcionário atribuído altera etapas;
   `clinicalEntries` só para veterinários/gerentes).
7. Criação de funcionários por gerente: use uma Cloud Function com Admin SDK.

### 4.2 Pagamento online (Pix/cartão)
Implemente `PaymentGateway` (ex.: Mercado Pago, Stripe, PagSeguro, Asaas):
- A cobrança deve ser criada **no servidor** (Cloud Function/API própria);
  o app só recebe o QR Code Pix ou o token do cartão.
- Confirme o pagamento via **webhook** do provedor, gravando
  `status = pago` e `referenciaExterna`.
- Credenciais necessárias: *access token* / *secret key* (no servidor) e
  *public key* (no app, se usar tokenização de cartão).
- Troque `const UnconfiguredPaymentGateway()` em `main.dart` pela sua classe.

Enquanto isso, o fluxo presencial funciona: o cliente informa a forma de
pagamento e a equipe confirma o recebimento.

### 4.3 Notificações push (FCM)
Implemente `PushGateway.send` chamando uma Cloud Function que envia via
FCM para os tokens do usuário (`firebase_messaging`). Configure APNs
(certificado/chave `.p8`) para iOS. As notificações dentro do app já
funcionam sem isso.

### 4.4 E-mail (recuperação de senha)
Com Firebase Auth use `sendPasswordResetEmail`. Com backend próprio,
implemente `EmailGateway` (SendGrid, Amazon SES, Resend). Sem ele, o código
aparece na tela com o aviso "Modo local".

### 4.5 Login com Google/Apple
Não incluído para não exibir botões que não funcionam. Requer Firebase Auth
+ `google_sign_in` / `sign_in_with_apple` e configuração nos consoles.

---

## 5. Testes

`flutter test` executa testes de formatação, validação e um fluxo completo:
cliente agenda → funcionário inicia → solicita adicional → cliente aprova →
conclusão gera pagamento → equipe confirma → cliente avalia; além de checar
bloqueios de permissão e a persistência dos dados.
