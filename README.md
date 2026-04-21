# Recebimento App

Aplicativo Android para controle de recebimento de mercadorias via leitura de código DUN-14, integrado à API REST hospedada na nuvem.

## Tecnologias

- Flutter 3.19 + Dart
- Biblioteca: mobile_scanner (leitura DUN-14 via câmera)
- Integração com API REST via HTTP

## Funcionalidades

- Leitura de código DUN-14 por câmera
- Contagem automática por scan (sem input manual)
- Cache local de produtos para leitura rápida
- Debounce visual de 1s entre leituras
- Relatório de recebimento em tempo real

## Como rodar

```bash
git clone https://github.com/IanBd00/recebimento-app
cd recebimento_app
flutter pub get
flutter run
```

## Configuração

A URL da API está definida em `lib/screens/scan_screen.dart`:

```dart
const String baseUrl = 'https://web-production-7c79c.up.railway.app';
```

## Projeto relacionado

Backend: [recebimento-api](https://github.com/IanBd00/recebimento-api)