# Amazon Track Data - Documentação Completa

Aplicativo Flutter multiplataforma para rastreamento em tempo real de embarcações e mototáxis na região amazônica.

## 📋 Requisitos

- Flutter 3.13+ 
- Dart 3.1+
- Android SDK 21+ (mínimo API 21)
- iOS 12.0+
- Conta Firebase ativa

## 🚀 Início Rápido

### 1. Setup do Projeto

```bash
# Clone ou abra o projeto
cd amazon_track_data

# Obtenha as dependências
flutter pub get

# Gere os arquivos necessários (se usar Drift)
flutter pub run build_runner build
```

### 2. Configuração Firebase

#### Criar Projeto Firebase

1. Acesse [Firebase Console](https://console.firebase.google.com)
2. Crie novo projeto: `amazon-track-data`
3. Ative Google Analytics (opcional)

#### Download de Credenciais

**Android:**
1. Em Firebase Console → Configurações do Projeto → Apps Android
2. Baixe `google-services.json`
3. Coloque em `android/app/`

**iOS:**
1. Em Firebase Console → Configurações do Projeto → Apps iOS
2. Baixe `GoogleService-Info.plist`
3. Coloque em `ios/Runner/`
4. Adicione ao Xcode: Right-click `Runner` → Add Files

### 3. Configurar firebase_options.dart

Edite `lib/firebase_options.dart` com suas credenciais:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'SUA_API_KEY',
  appId: 'SUA_APP_ID',
  messagingSenderId: 'SEU_MESSAGING_SENDER_ID',
  projectId: 'amazon-track-data',
  databaseURL: 'https://amazon-track-data.firebaseio.com',
  storageBucket: 'amazon-track-data.appspot.com',
);

// Faça o mesmo para ios, web e macos
```

### 4. Regras Firestore (Firebase Console)

Vá para **Firestore Database → Regras**:

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
      allow write: if request.auth != null;
    }
    match /locations/{userId}/tracks/{trackId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 5. Regras Firebase Storage

Vá para **Storage → Regras**:

```firebasestore
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## 📱 Configuração por Plataforma

### Android

#### AndroidManifest.xml

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.amazon_track_data">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <application>
        <!-- Seu código aqui -->
        <service
            android:name="com.example.amazon_track_data.LocationTrackingService"
            android:enabled="true"
            android:exported="false"
            android:foregroundServiceType="location" />
    </application>
</manifest>
```

#### build.gradle.kts (app)

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")  // Google Services plugin
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.0.0"))
    implementation("com.google.firebase:firebase-analytics-ktx")
    // Outros Firebase dependencies...
}
```

### iOS

#### Info.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Permissões de Localização -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Este app precisa de acesso à sua localização para rastreamento enquanto estiver usando.</string>
    
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>Este app precisa de acesso à sua localização em tempo real.</string>
    
    <key>NSLocationAlwaysUsageDescription</key>
    <string>Este app precisa de acesso contínuo à sua localização em background.</string>
    
    <!-- Background Modes -->
    <key>UIBackgroundModes</key>
    <array>
        <string>location</string>
        <string>processing</string>
        <string>fetch</string>
    </array>
    
    <!-- Restantes das configurações... -->
</dict>
</plist>
```

## 🔌 Compilação e Execução

### Android

```bash
# Debug
flutter run -d emulator  # ou seu device ID

# Release
flutter build apk --release
```

### iOS

```bash
# Debug
flutter run -d ios

# Release
flutter build ios --release
```

## 📚 Estrutura de Pastas

```
lib/
├── config/           # Configurações (Firebase, Router, Theme)
├── core/             # Utilitários (Validators, Errors, Extensions)
├── data/             # Camada de dados (Datasources, Repositories, Models)
├── domain/           # Entidades e interfaces (opcional)
├── presentation/     # UI (Screens, Widgets, Providers, Dialogs)
└── main.dart         # Entrada principal

test/                 # Testes unitários
android/              # Configurações Android
ios/                  # Configurações iOS
```

## 🧪 Testes

```bash
# Rodar todos os testes
flutter test

# Testes específicos
flutter test test/test_cpf_validator.dart
flutter test test/test_trip_id_generator.dart
flutter test test/test_serialization.dart
```

## 🎯 Funcionalidades Principais

### ✅ Autenticação Firebase
- Login com email/senha
- Cadastro com validação
- Persistência de sessão

### ✅ 3 tipos de usuário
- **Passageiro**: Visualiza mapa em tempo real
- **Mototáxi**: Inicia rastreamento direto
- **Barqueiro**: Seleciona embarcação e rota antes de rastrear

### ✅ Mapa em Tempo Real
- OpenStreetMap com flutter_map
- Marcadores de usuários rastreados
- Localização atual do usuário
- Zoom e navegação

### ✅ Rastreamento GPS
- Coleta contínua a cada 5s
- Suporte a background (Android)
- Sincronização offline

### ✅ Gerenciamento de Embarcações
- CRUD completo de barcos
- Upload de fotos para Firebase Storage
- Vínculo com rotas

### ✅ Rotas
- Criação de rotas entre paradas
- Rotas pré-cadastradas
- Rotas customizadas no momento

## ⚙️ Variáveis de Ambiente

Crie um arquivo `.env` (opcional):

```env
FIREBASE_PROJECT_ID=amazon-track-data
FIREBASE_WEB_API_KEY=your_web_api_key
LOCATION_UPDATE_INTERVAL_SECONDS=5
```

## 🐛 Troubleshooting

### Erro: "Firebase not initialized"
→ Verifique se `google-services.json` e `GoogleService-Info.plist` estão nos locais corretos

### Erro: "Permission denied" para localização
→ Conceda permissões manualmente nas configurações do aparelho

### Erro: "Firestore rules deny" 
→ Verifique a autenticação e as regras do Firestore

## 📞 Suporte

Para problemas:
1. Verifique o console do Firebase
2. Ative logs de debug: `flutter run -v`
3. Verifique permissões do AndroidManifest e Info.plist

## 📄 Licença

Projeto de código aberto para uso educacional.
