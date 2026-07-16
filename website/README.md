# Site do Amazon Track

Landing page criada com Vite, React e JSX para apresentar o aplicativo e oferecer o APK para download.

## Desenvolvimento

```bash
npm install
npm run dev
```

## Build de produção

```bash
npm run build
```

O resultado é gerado em `dist/`.

## Atualizar o APK

No PowerShell, execute o processo completo:

```powershell
.\prepare-deploy.ps1
```

O script gera o APK release universal, verifica o limite de 100 MB da Vercel
Hobby, substitui o arquivo disponível para download e gera o build Vite.

Para fazer o processo manualmente, gere uma nova versão do aplicativo Flutter:

```bash
flutter build apk --release
```

Depois copie `build/app/outputs/flutter-apk/app-release.apk` para:

```text
website/public/downloads/amazon-track.apk
```

O botão de download da página já aponta para esse arquivo.

## Publicar na Vercel

Ao importar o repositório na Vercel, defina **Root Directory** como `website`.
As demais opções de build estão configuradas em `vercel.json`.
