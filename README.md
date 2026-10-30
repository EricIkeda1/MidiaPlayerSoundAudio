# Música • Flutter 3.35.7

Player mobile e web em português. Tema claro, menus arredondados e player em degradê seguindo a referência visual. Sem marca pessoal e sem músicas, capas comerciais, letras ou playlists pré-carregadas.

## Atualizar o aplicativo Android

Substitua **todo o conteúdo do projeto**, incluindo `android/`, pelo conteúdo da pasta `musica` do ZIP. A correção da notificação inclui recursos nativos e precisa de um APK novo; hot reload/restart não atualiza os recursos já instalados.

Na pasta que contém `pubspec.yaml`:

```powershell
flutter clean
flutter pub get
flutter build apk --release
```

Instale o arquivo `build/app/outputs/flutter-apk/app-release.apk` por cima da versão atual. Ou conecte o Android por USB e execute `flutter run` selecionando o aparelho.

A migração remove os identificadores dos antigos exemplos, favoritos e letras vinculados a esses exemplos e as playlists fornecidas que não têm arquivos reais. Preserva importações, letras e playlists com músicas do usuário. Não é necessário desinstalar ou apagar os dados do app.

## Abrir no navegador

```powershell
flutter pub get
flutter run -d chrome --web-port=7357
```

Para Edge, troque `chrome` por `edge`. Alternativa no Windows: `powershell -ExecutionPolicy Bypass -File .\abrir-navegador.ps1`.

O navegador mantém a interface mobile centralizada. Arquivos selecionados ficam no IndexedDB; use a mesma porta para manter a mesma origem entre execuções. Fechar a aba encerra a reprodução. O build web padrão é JavaScript, sem `--wasm`.

## Sua biblioteca

O aplicativo abre diretamente em Música, com estado vazio até que você permita o acesso ou importe arquivos. As telas não dependem de faixas de exemplo.

No Android, toque **Biblioteca → Acessar músicas do dispositivo** e aceite a autorização. O app consulta o MediaStore e reproduz as faixas pela URI do sistema, com seus títulos, artistas e álbuns. Use Menu ⋯ → Configurações → Músicas do dispositivo para atualizar a leitura.

- Android 13+: `READ_MEDIA_AUDIO`.
- Android 12 e anteriores: `READ_EXTERNAL_STORAGE`, limitado à API 32.
- Recusa da permissão não bloqueia o restante do app. Bloqueio permanente abre as configurações do Android.
- A permissão lê músicas indexadas no armazenamento compartilhado; não os arquivos privados de outros aplicativos. Para outros arquivos, use Importar músicas.

No iPhone e no navegador, use **Importar músicas** e selecione seus arquivos. Formatos disponíveis no seletor: MP3, WAV, M4A, AAC, OGG e FLAC. A decodificação depende do sistema/navegador.

## Notificação de reprodução

A versão 1.1.1 corrige a configuração ligada ao erro `Invalid notification (no valid small icon)`:

- Ícone monocromático incluído em cinco densidades, além do recurso vetorial.
- Referências nativas estáticas e `res/raw/keep.xml` preservam o ícone buscado pelo nome pelo serviço de áudio.
- Minificação e remoção de recursos desativadas no build de release desta versão.
- Verificação do recurso no APK e fallback para o ícone do launcher antes de inicializar a sessão.
- Pedido de autorização de notificações no Android 13+ ao iniciar a primeira reprodução.

Toque em uma música para reproduzir e abra a central de notificações. Se as notificações estiverem bloqueadas, use **Menu ⋯ → Configurações → Player nas notificações** para abrir as configurações reais do Android.

A sessão de mídia mantém título, artista, capa genérica e controles de reprodução. A aparência real é definida pelo Android/fabricante. As opções de prévia em Configurações são apenas telas ilustrativas dentro do app.

## Wi-Fi/internet

As permissões normais `INTERNET`, `ACCESS_NETWORK_STATE` e `ACCESS_WIFI_STATE` permitem usar a conexão existente e acompanhar mudanças. Menu ⋯ → Configurações → Wi-Fi e internet mostra o estado e abre o painel de conexão do Android. Não é necessário um diálogo de autorização para essas permissões normais.

## Menus e recursos

- Barra flutuante: Início, Explorar, Biblioteca e acesso à reprodução.
- Filtros: Músicas, Álbuns, Artistas, Playlists e Downloads.
- Player: Adicionar, Download, Letras e Mais. Mais inclui fila de reprodução, timer e opções da faixa.
- Download salva uma cópia de um arquivo seu usando o destino escolhido no sistema, ou o download do navegador.
- Busca local, favoritos, playlists criadas por você e fila reordenável.
- Letras `.lrc` sincronizadas ou `.txt`, ajuste de tamanho, compartilhamento e timer.
- Spotify e YouTube Music abrem pesquisas externas. Não há login, catálogo fictício nem download/streaming desses serviços dentro do app.
- Os gêneros em Explorar são atalhos para buscas externas, sem listas inventadas de músicas.

## Verificação

Consulte `VALIDACAO.md` para distinguir o que foi executado das verificações ainda pendentes em aparelho.

```powershell
flutter analyze
flutter test
```

Requisitos: Flutter 3.35.7/Dart 3.9.x ou superior. Para Android, Android SDK e JDK compatível com a instalação do Flutter. Para iPhone, macOS com Xcode e assinatura configurada.

O projeto de release usa a assinatura de desenvolvimento do template. Para publicação pública, configure sua assinatura própria.
