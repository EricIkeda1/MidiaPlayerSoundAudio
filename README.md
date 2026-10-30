# Música

Player mobile e web em Flutter, sem marca pessoal, construído a partir da imagem de referência enviada. Abre diretamente na página de música. Interface em português, tema claro, roxo e lavanda, menus flutuantes arredondados e reprodução em degradê rosa/vinho.

## Compatibilidade

Esta versão foi ajustada para **Flutter 3.35.7**. Não é necessário atualizar o Flutter para abrir no Chrome/Edge. As dependências diretas estão fixadas em versões cujos requisitos de Dart/Flutter aceitam esse SDK. Os projetos Android e iOS usam os templates oficiais da tag 3.35.7.

Se estiver substituindo uma versão anterior deste projeto, copie o conteúdo da pasta `musica` do ZIP para a pasta do seu projeto (a mesma que contém `pubspec.yaml`) e execute:

```powershell
flutter clean
flutter pub get
flutter run -d chrome --web-port=7357
```

O pacote não contém `pubspec.lock` gerado: a resolução completa das dependências ainda precisa ser executada no Flutter do desenvolvedor.

## Abrir no navegador (Chrome ou Edge)

A pasta `web/` já está incluída; não é necessário conectar um celular nem instalar um emulador para esta opção.

Extraia o ZIP atualizado e substitua os arquivos da pasta do projeto. No PowerShell, dentro da pasta que contém `pubspec.yaml`:

```powershell
flutter pub get
flutter run -d chrome --web-port=7357
```

Para Edge, troque `chrome` por `edge`. Também é possível executar:

```powershell
powershell -ExecutionPolicy Bypass -File .\abrir-navegador.ps1
```

O layout mantém a largura mobile centralizada na janela. O áudio começa após um toque em Reproduzir. Áudios importados ficam no IndexedDB do navegador; favoritos, playlists e preferências usam o armazenamento local. Use sempre a mesma porta para manter a mesma origem e acessar esses dados nas próximas execuções. Limpar os dados do site remove a biblioteca salva naquele navegador. A decodificação dos formatos depende do navegador.

As prévias de notificação/tela bloqueada ficam disponíveis dentro do app; a inicialização do serviço nativo de áudio é exclusiva das plataformas mobile. No navegador, fechar a aba encerra a reprodução. Esta versão usa o build web padrão em JavaScript, sem a opção `--wasm`.

Para gerar uma versão web de produção:

```powershell
flutter build web
```

Publique o conteúdo de `build/web/` em um servidor HTTP/HTTPS; não abra `index.html` diretamente pelo gerenciador de arquivos.

## Executar no Windows com celular ou emulador Android

Requisitos: Flutter 3.35.7 (Dart 3.9.x incluído no SDK) ou superior, Android Studio/Android SDK e um emulador Android ou celular com depuração USB ativada. Android mínimo: 7.0/API 24.

1. Extraia o ZIP e abra a pasta `musica` no VS Code.
2. Confira o ambiente com `flutter doctor` e os dispositivos com `flutter devices`.
3. No PowerShell, dentro dessa pasta:

```powershell
powershell -ExecutionPolicy Bypass -File .\iniciar.ps1
```

Ou execute os comandos individualmente:

```sh
flutter pub get
flutter run
```

Se precisar recriar as pastas nativas:

```sh
flutter create --platforms=android,ios,web --org app.musica --project-name musica --no-pub .
dart tool/configure.dart
flutter pub get
flutter run
```

No macOS/Linux: `bash iniciar.sh`. Para iPhone, use macOS com Xcode, configure a assinatura no projeto `ios/Runner.xcworkspace` e execute `flutter run` com um iPhone ou simulador selecionado. A compilação e reprodução no iPhone precisam de validação em dispositivo Apple.

## Telas e navegação

| Tela | Como acessar |
| --- | --- |
| Música | Página inicial, sem apresentação |
| Reprodução | Toque numa faixa ou na capa à direita da barra flutuante |
| Letra | Botão Letra/Letras no player |
| Explorar | Lupa da barra inferior |
| Biblioteca | Terceiro botão da barra inferior |
| Busca | Campo de busca no início ou em Explorar |
| Playlist | Chill Vibes ou outras playlists no início/biblioteca |
| Serviços de música | Ícone no topo de Explorar ou avatar → Serviços |
| Fila de reprodução | Botão Fila no player |
| Notificação | Avatar → Notificação, para a prévia; a notificação real aparece ao reproduzir |
| Tela bloqueada | Avatar → Tela bloqueada, para a prévia; os controles reais são integrados ao sistema |

## Recursos implementados

- Reprodução real de arquivos de áudio, pausar, buscar posição, anterior/próxima, aleatório e repetição.
- Três instrumentais originais offline para testar o app assim que abrir.
- Importação múltipla pelo seletor nativo; os arquivos são copiados para a área do app no celular e persistidos no IndexedDB no navegador, evitando dependência de caminhos temporários.
- Biblioteca por músicas, álbuns, artistas, playlists e arquivos importados.
- Pesquisa local sem distinção de acentos, combinando título, artista e álbum.
- Favoritos e mix de favoritas; playlists criadas pelo usuário, inclusão e remoção de faixas.
- Fila reordenável com alças de arrastar e opção de limpar.
- Letras importadas em `.lrc` ou `.txt`. Arquivos LRC acompanham o tempo da música; toque num verso para avançar até ele.
- Tamanho da letra, cópia do texto e timer de sono de 15/30/45/60 minutos.
- Favoritos, playlists, letras, biblioteca importada e preferências persistidos no aparelho.
- Reprodução em segundo plano e sessão de mídia com metadados e capa, configuradas para Android e iOS.
- Ícone do aplicativo derivado da referência, sem texto ou marca pessoal.

## O que a demonstração inclui

Os títulos e capas representam o catálogo mostrado na imagem. **As gravações comerciais não estão incluídas**: o áudio de cada cartão é uma das três prévias instrumentais originais. O player identifica essas faixas como demonstração. Para ouvir suas músicas, use Avatar → Importar músicas ou o botão + em Biblioteca. Os formatos de importação são MP3, WAV, M4A, AAC, OGG e FLAC; o suporte de decodificação depende do aparelho.

O texto exibido na letra de Blinding Lights foi transcrito somente da imagem fornecida e serve de prévia visual. O instrumental de demonstração não tem voz. Importe um LRC da sua faixa para ter a letra correspondente.

As capas foram recortadas da imagem fornecida, cuja resolução é baixa. Isso preserva os elementos visuais da referência, mas limita a nitidez no player. Para substituir: mantenha os nomes dos arquivos em `assets/art/` ou altere os campos `art` do catálogo.

## Spotify e YouTube Music

Os botões abrem a busca correspondente no aplicativo/site do serviço. Não há login falso, estado “Conectado” fictício, download desses catálogos nem reprodução de Spotify/YouTube dentro do app. Uma integração de conta/streaming exigirá registro do aplicativo, autenticação e a solução de reprodução permitida por cada provedor. Não são necessárias chaves para as buscas externas implementadas.

## Notificação e tela bloqueada

As prévias dentro do app seguem a composição da imagem e seus controles acionam o mesmo player. Elas **não substituem** a central de notificações ou a tela bloqueada do aparelho. Na reprodução real, `just_audio_background` publica uma sessão de mídia; o sistema decide layout, botões e aparência conforme versão do Android/iOS e fabricante. O Flutter não pode impor uma tela bloqueada de outro sistema nem criar um notch físico.

Documentação dos componentes usados:
- https://pub.dev/packages/just_audio
- https://pub.dev/packages/just_audio_background
- https://pub.dev/packages/file_picker/versions/10.3.10
- https://pub.dev/packages/url_launcher

## Verificação e APK

```sh
flutter analyze
flutter test
flutter build apk --debug
```

Saída do APK de desenvolvimento: `build/app/outputs/flutter-apk/app-debug.apk`.

Para uma distribuição pública, configure sua assinatura em Android e execute `flutter build appbundle`. A configuração padrão de release gerada pelo Flutter usa assinatura de desenvolvimento; ela não deve ser usada como assinatura de publicação.

O arquivo `VALIDACAO.md` registra os comandos efetivamente executados durante a entrega. Não confundir testes de widgets com validação do áudio/notificação em um aparelho real.

## Estrutura

- `lib/main.dart`: inicialização de tema e sessão de mídia.
- `lib/core/theme.dart`: cores e componentes Material 3.
- `lib/models/track.dart`: catálogo, persistência, busca e leitor LRC.
- `lib/services/music_controller.dart`: reprodução, arquivos, estado e preferências.
- `lib/ui/`: telas e componentes reutilizáveis.
- `assets/art/`: capas e ícone derivados da referência.
- `assets/audio/`: instrumentais originais de demonstração.
- `web/`: inicialização e ícones do navegador.
- `lib/services/platform/`: armazenamento separado para mobile e navegador.
- `abrir-navegador.ps1`: inicialização no Chrome ou Edge.
- `tool/configure.dart`: configuração nativa idempotente.
- `test/`: busca, persistência, interpretação LRC e componentes da interface.
