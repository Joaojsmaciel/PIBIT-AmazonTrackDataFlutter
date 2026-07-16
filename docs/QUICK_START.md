# 🚀 Quick Start - Comandos Essenciais

## 1️⃣ Preparação Inicial

```bash
# Entre no diretório
cd amazon_track_data

# Obtenha todas as dependências
flutter pub get

# Limpe (se tiver problemas anteriores)
flutter clean
flutter pub get
```

## 2️⃣ Firebase Setup (OBRIGATÓRIO)

### A. Criar Projeto Firebase
1. Acesse: https://console.firebase.google.com
2. Clique: **"+ Criar Projeto"**
3. Nome: `amazon-track-data`
4. Clique: **"Criar"**
5. Aguarde 2-3 minutos

### B. Baixar Credenciais

**Android:**
```
Projeto → Configurações → Apps → Android
↓
Baixar google-services.json
↓
Copiar para: android/app/google-services.json
```

**iOS:**
```
Projeto → Configurações → Apps → iOS
↓
Baixar GoogleService-Info.plist
↓
Adicionar ao Xcode: Runner → Add Files
```

### C. Atualizar firebase_options.dart

Edit `lib/firebase_options.dart` e substitua:
- `apiKey`
- `appId`
- `messagingSenderId`
- `projectId`

Com os valores reais do Firebase Console.

### D. Ativar Serviços Firebase

```
Firestore Database → Criar (Modo Teste)
         ↓
Cloud Storage → Começar (Modo Teste)
         ↓
Authentication → Email/Senha (Ativar)
```

## 3️⃣ Rodar no Emulador/Dispositivo

### Android
```bash
# Listar emuladores
flutter emulators

# Iniciar emulador
flutter emulators launch <nome>

# Ou rodar no primeiro device conectado
flutter run -d emulator-5554
```

### iOS
```bash
# Listar simuladores
flutter devices

# Rodar em iOS
flutter run -d ios

# Ou abrir Xcode
open ios/Runner.xcworkspace
# Clique Play no Xcode
```

## 4️⃣ Testes

```bash
# Rodar todos os testes
flutter test

# Teste específico
flutter test test/test_cpf_validator.dart

# Com output detalhado
flutter test -v
```

## 5️⃣ Build para Release

### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/apk/release/app-release.apk
```

### Android App Bundle
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS IPA
```bash
flutter build ios --release
# Output: build/ios/iphoneos/
```

## ⚡ Troubleshooting Rápido

### Problema: "Firebase not initialized"
```bash
flutter clean
flutter pub get
# Verifique firebase_options.dart
```

### Problema: "google-services.json not found"
```bash
# Confirme arquivo em: android/app/google-services.json
ls -la android/app/google-services.json
```

### Problema: "Podspec error" (iOS)
```bash
cd ios
rm -rf Pods
rm -rf Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
flutter run -d ios
```

### Problema: "Build fails"
```bash
flutter clean
flutter pub cache clean
flutter pub get
# Se persistir, reconstruir:
flutter clean
flutter pub get
flutter run
```

## 📋 Estrutura Criada

```
amazon_track_data/
├── lib/
│   ├── main.dart (✅ Pronto)
│   ├── firebase_options.dart (⚠️ Precisa credenciais)
│   ├── config/ (✅ Pronto)
│   ├── core/ (✅ Pronto)
│   ├── data/ (✅ Pronto)
│   └── presentation/ (✅ Pronto)
├── test/ (✅ Pronto)
├── android/
│   └── app/
│       └── google-services.json (⚠️ Fazer download)
├── ios/
│   └── Runner/ (⚠️ Adicionar plist via Xcode)
├── pubspec.yaml (✅ Pronto)
└── README_SETUP.md (✅ Leia!)
```

## ✨ Próximos Passos

1. **Firebase**: Siga o Quick Start acima
2. **Compilar**: `flutter run`
3. **Testar**: Crie conta, faça login
4. **Rastrear**: Selecione embarcação e rota
5. **Deploy**: Build release para produção

## 🔗 Documentação Completa

- **README_SETUP.md** - Setup completo detalhado
- **FIREBASE_SETUP.md** - Firebase passo a passo
- **PLATFORM_SETUP.md** - Android/iOS específico
- **IMPLEMENTATION_SUMMARY.md** - Resumo completo da implementação

## ✅ Checklist Final

- [ ] `flutter pub get` executado
- [ ] Projeto Firebase criado
- [ ] google-services.json baixado (Android)
- [ ] GoogleService-Info.plist adicionado (iOS)
- [ ] firebase_options.dart atualizado
- [ ] Firestore, Storage e Auth ativados
- [ ] Regras Firestore aplicadas
- [ ] `flutter run` executado com sucesso
- [ ] App abriu na tela de login
- [ ] Testes passando: `flutter test`

---

**Tudo configurado? Bora codar! 🚀**
