# Configuração de Permissões e Background Tracking

## Android

### 1. AndroidManifest.xml

Localização: `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.amazon_track_data">

    <!-- Permissões de Localização -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
    
    <!-- Serviço em Foreground -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
    
    <!-- Notificações (Android 13+) -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    
    <!-- Internet e conectividade -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application
        android:label="Amazon Track Data"
        android:icon="@mipmap/ic_launcher">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <!-- Serviço de Tracking em Background -->
        <service
            android:name=".LocationTrackingService"
            android:enabled="true"
            android:exported="false"
            android:foregroundServiceType="location" />

        <!-- Meta-data do Flutter -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

### 2. build.gradle.kts (nivel app)

Localização: `android/app/build.gradle.kts`

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.amazon_track_data"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.amazon_track_data"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            // ... configurações release
        }
    }
}

dependencies {
    // Firebase BOM
    implementation(platform("com.google.firebase:firebase-bom:32.0.0"))
    implementation("com.google.firebase:firebase-analytics-ktx")
    
    // Google Play Services
    implementation("com.google.android.gms:play-services-location:21.0.1")
    
    // WorkManager para sync offline
    implementation("androidx.work:work-runtime-ktx:2.8.1")
}
```

## iOS

### 1. Info.plist

Localização: `ios/Runner/Info.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Chave padrão -->
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Amazon Track Data</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>

    <!-- Localização - Tipo de Uso -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Amazon Track Data precisa de acesso à sua localização para rastreamento enquanto usa o app.</string>
    
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>Amazon Track Data precisa de acesso à sua localização em tempo real para rastreamento preciso.</string>
    
    <key>NSLocationAlwaysUsageDescription</key>
    <string>Amazon Track Data precisa de acesso contínuo à sua localização mesmo quando o app está em background.</string>

    <!-- Background Modes (OBRIGATÓRIO para rastreamento em background) -->
    <key>UIBackgroundModes</key>
    <array>
        <string>location</string>
        <string>processing</string>
        <string>fetch</string>
    </array>

    <!-- Tema -->
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UIMainStoryboardFile</key>
    <string>Main</string>
    <key>UIStatusBarDefault</key>
    <true/>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UISupportedInterfaceOrientationsIPad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UIViewControllerBasedStatusBarAppearance</key>
    <false/>
    
    <!-- Bluetooth (se usar em futuro) -->
    <key>NSBluetoothPeripheralUsageDescription</key>
    <string>Bluetooth é necessário para conectar dispositivos de rastreamento.</string>
</dict>
</plist>
```

### 2. Xcode Build Settings

1. Abra `ios/Runner.xcworkspace` no Xcode
2. Selecione **Runner** → **Build Settings**
3. Busque: `IPHONEOS_DEPLOYMENT_TARGET`
4. Altere para `12.0` (mínimo)

### 3. Entitlements

Crie/edite `ios/Runner/Runner.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.location.push</key>
    <true/>
    <key>com.apple.developer.healthkit</key>
    <true/>
</dict>
</plist>
```

## Testes de Permissões

### Teste no Emulador Android

```bash
# Verificar permissiones concedidas
adb shell pm list permissions -d

# Conceder permissão de localização
adb shell pm grant com.example.amazon_track_data android.permission.ACCESS_FINE_LOCATION

# Localização simulada
emulator -avd <device_name> -location-control
```

### Teste em Dispositivo Real

1. **Android**: Configurações → Apps → Amazon Track Data → Permissões  
2. **iOS**: Configurações → Privacidade → Localização  

Selecione: **"Sempre"** (para rastreamento em background)

## Verificação

Para confirmar setup correto:

```bash
# Android
flutter doctor -v
adb logcat | grep "amazon_track_data"

# iOS
flutter run -v --no-fast-start
```

Procure por:
- ✅ Nenhum erro de permissão
- ✅ Conexão Firebase bem-sucedida
- ✅ Notificações de localização aparecendo
