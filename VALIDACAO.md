# Validação da versão 1.0.2

## Compatibilidade corrigida

- Flutter mínimo: **3.35.7**, igual à versão informada pelo desenvolvedor.
- Dart mínimo: 3.9.0. Verificações locais executadas com **Dart 3.9.2**.
- Removida a exigência incorreta de Flutter 3.47.
- Dependências diretas fixadas em versões cujos requisitos de SDK aceitam o Flutter/Dart alvo, conforme os metadados oficiais de pub.dev.
- `just_audio` fixado em 0.10.5. As APIs utilizadas (`setAudioSources`, `addAudioSource`, `moveAudioSource`, `clearAudioSources` e `errorStream`) foram conferidas no código-fonte oficial dessa versão.
- Android/iOS refeitos a partir dos templates oficiais da tag Flutter **3.35.7**, commit `adc901062556672b4138e18a4dc62a4be8f4b3c2`.
- Android: Gradle 8.12, Android Gradle Plugin 8.9.1 e Kotlin 2.1.0, conforme os templates dessa tag. Gradle Wrapper correspondente incluído.
- iOS: AppDelegate tradicional, sem FlutterImplicitEngineDelegate e SceneDelegate das versões mais novas. Reprodução de áudio em segundo plano mantida.

## Verificações concluídas

- Formatação e interpretação de todos os arquivos Dart com o executável de Dart 3.9.2.
- `dart tool/check_models.dart`: **17 verificações passaram**, incluindo busca, persistência e leitura LRC.
- `dart compile js tool/check_browser_storage.dart`: **compilação JavaScript concluída com Dart 3.9.2**. Esse teste importa a implementação real de armazenamento web.
- Conferência de sintaxe, XML, plists, ícones e manifesto web.
- Conferência dos metadados do serviço de mídia no Android e de UIBackgroundModes na raiz do Info.plist no iOS.
- ZIP conferido quanto à integridade.

## Recursos web preservados

`web/index.html`, manifesto e ícones estão incluídos. Chrome/Edge usam a mesma interface, centralizada com largura máxima de 480 px. A importação lê bytes no navegador e persiste áudio no IndexedDB; mobile usa arquivos locais. Os serviços de áudio nativos são inicializados somente fora da web.

## Validação ainda pendente

O build Flutter completo, a resolução transitiva das dependências, os testes de widgets e a execução real em Chrome/Edge/Android/iOS precisam ser realizados no ambiente do desenvolvedor. Não foi gerado um pubspec.lock nem um APK. A checagem dos requisitos das dependências diretas não substitui `flutter pub get`.

A inicialização do Flutter neste ambiente foi bloqueada anteriormente pela revisão automática por tentativa de acesso a metadados da infraestrutura, que podem expor credenciais. O comando bloqueado não foi repetido. Os testes concluídos usaram apenas o executável de Dart e os arquivos locais. A tentativa anterior de obter um navegador de teste também não forneceu um ZIP válido; os sete cenários do teste web foram compilados, mas não executados em navegador.

## Executar no seu computador

Substitua os arquivos do projeto pelo conteúdo da pasta `musica` do ZIP. Na pasta que contém `pubspec.yaml`:

```powershell
flutter clean
flutter pub get
flutter run -d chrome --web-port=7357
```

Para Edge, troque `chrome` por `edge`.

Para as verificações completas:

```powershell
flutter analyze
flutter test
```

Os scripts de inicialização não atualizam automaticamente seu Flutter.
