# Amazon Track Data - Guia de Configuração Firebase

Este documento descreve como configurar completamente o Firebase para este projeto.

## Pré-requisitos

- Conta Google ativa
- Acesso a [Firebase Console](https://console.firebase.google.com)
- Firebase CLI instalado (opcional, mas recomendado)

## Passo 1: Criar um Projeto Firebase

1. Acesse https://console.firebase.google.com
2. Clique em **"+ Criar projeto"**
3. Nome do projeto: `amazon-track-data`
4. Desative Google Analytics (opcional)
5. Clique em **"Criar"**
6. Aguarde a criação (2-3 minutos)

## Passo 2: Registrar Apps

### Android

1. Em **Configurações do Projeto** (engrenagem) → **Apps**
2. Clique em **"+ Adicionar app"** → **Android**
3. Pacote: `com.example.amazon_track_data`
4. Nome do app: `Amazon Track Data Android`
5. SHA-1 (opcional): `flutter certificate-sha1`
6. Registered → **Próximo**
7. Baixe `google-services.json`
8. Coloque em `android/app/google-services.json`
9. **Próximo** até finalizar

### iOS

1. Em **Configurações do Projeto** → **Apps**
2. Clique em **"+ Adicionar app"** → **iOS**
3. Bundle ID: `com.example.amazontrackdata`
4. Nome: `Amazon Track Data iOS`
5. **Registrar app**
6. Baixe `GoogleService-Info.plist`
7. Adicione ao Xcode:
   - Abra `ios/Runner.xcworkspace` no Xcode
   - Right-click em **Runner** → **Add Files to Runner**
   - Selecione `GoogleService-Info.plist`
   - Marque **"Copy items if needed"** e **"Add to targets"**

## Passo 3: Ativar Autenticação

1. No Firebase Console → **Autenticação** → **Começar**
2. Abra aba **"Método de login"**
3. Ative **Email/Senha**
4. Salve

## Passo 4: Criar Banco Firestore

1. **Firestore Database** → **Criar banco de dados**
2. Selecione região: `southamerica-east1` (São Paulo) ou próxima
3. Modo de start: **Iniciar no modo de teste** (para desenvolvimento)
4. **Criar**

### Depois, adicione as regras:

1. Aba **Regras**
2. Substitua todo conteúdo por:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /boats/{boatId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.resource.data.ownerId == request.auth.uid;
      allow update, delete: if request.auth != null && resource.data.ownerId == request.auth.uid;
    }
    
    match /routes/{routeId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    match /stops/{stopId} {
      allow read: if request.auth != null;
    }
    
    match /locations/{userId}/tracks/{trackId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

3. **Publicar**

## Passo 5: Configurar Storage

1. **Storage** → **Começar**
2. Selecione local: próximo ao Firestore
3. Modo de segurança: **Iniciar no modo de teste**
4. **Próximo** → **Concluir**

### Adicione regras de Storage:

1. Aba **Regras**
2. Substitua por:

```firebasestore
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        (request.resource.name.matches('boat_images/.*') ||
         request.resource.name.matches('profile_images/.*'));
    }
  }
}
```

3. **Publicar**

## Passo 6: Copiar Credenciais

1. Vá para **Configurações do Projeto** (engrenagem)
2. Aba **Apps**
3. Para cada app (Android/iOS), anote:
   - `API Key`
   - `App ID`
   - `Messaging Sender ID`
   - `Project ID`

## Passo 7: Atualizar firebase_options.dart

Edite `lib/firebase_options.dart`:

```dart
// Substitua os valores dummy pelas credenciais reais

static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyDxxxxxxxxxxxxxxxxxxxxxxxx',  // Android API Key
  appId: '1:123456789:android:xxxxx',
  messagingSenderId: '123456789',
  projectId: 'amazon-track-data',
  databaseURL: 'https://amazon-track-data.firebaseio.com',
  storageBucket: 'amazon-track-data.appspot.com',
);

// Faça o mesmo para ios, web, macos
```

## Passo 8: Teste a Conexão

```bash
# Obtenha dependências
flutter pub get

# Execute em Android
flutter run -d emulator

# Ou em iOS
flutter run -d ios
```

Você deve ver:
- ✅ App iniciando
- ✅ Tela de LoginScreen carregando
- ✅ Sem erros de Firebase no console

## Dicas Importantes

### ⚠️ Segurança em Produção

Antes de fazer deploy:
1. Altere as regras de Firestore (remova modo de teste)
2. Configure autenticação com limites de taxa
3. Ative HTTPS apenas
4. Ajuste permissões de usuário por role

### 📦 Dados de Teste

Para testar, crie dados de exemplo no Firestore:

```
stops/
  - stop1: {name: "Porto Central", city: "Manaus", latitude: -3.119, longitude: -60.02, type: "porto"}
  - stop2: {name: "Terminal A", city: "Manaus", latitude: -3.0500, longitude: -60.01, type: "terminal"}

routes/
  - route1: {name: "Manaus-Interior", origin: stop1, destination: stop2, estimatedDurationMinutes: 120}
```

## Troubleshooting

| Erro | Solução |
|------|---------|
| "Project not found" | Verifique project ID em `firebase_options.dart` |
| "Permission denied" | Atualize regras Firestore e Storage |
| "google-services.json not found" | Coloque em `android/app/` |
| "GoogleService-Info.plist not found" | Adicione ao Xcode (Build Phases) |
| "Can't connect to Firestore" | Verifique internet e configuração de rede |

## Próximos Passos

Após setup:
1. Execute `flutter pub get`
2. Rode `flutter run`
3. Crie uma conta de teste
4. Teste compartilhar localização
5. Verifique dados no Firestore Console
