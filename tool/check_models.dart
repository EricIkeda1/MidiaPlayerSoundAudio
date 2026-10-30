import '../lib/models/track.dart';

void main() {
  var checks = 0;
  void check(bool condition, String name) {
    if (!condition) throw StateError('Falhou: $name');
    checks++;
  }

  const track = Track(
    id: '1',
    title: 'Canção de Verão',
    artist: 'João',
    album: 'Férias',
    art: 'chill',
    source: '/data/a.mp3',
    imported: true,
    lyrics: '[00:01.20]Olá',
  );
  check(searchTracks([track], 'CANCAO joao').length == 1, 'busca sem acentos');
  check(searchTracks([track], 'ferias').length == 1, 'busca por álbum');
  check(searchTracks([track], 'outono').isEmpty, 'busca sem resultado');
  check(searchTracks([track], '  ').length == 1, 'busca vazia');
  final restored = Track.decode(Track.encode([track])).single;
  check(restored.id == track.id, 'id persistido');
  check(restored.imported, 'origem persistida');
  check(restored.source == track.source, 'arquivo persistido');
  check(restored.lyrics == track.lyrics, 'letra persistida');
  check(
    restored.withLyrics('nova').id == track.id,
    'atualizar letra mantém identidade',
  );
  final lines = parseLrc(
    '[ar:Artista]\n[01:02.50]Depois\n[00:01.2][00:03.005]Refrão\n[00:00]Início',
  );
  check(lines.length == 4, 'múltiplos tempos por verso');
  check(lines.first.text == 'Início', 'ordenação das linhas');
  check(lines[1].time.inMilliseconds == 1200, 'fração de um dígito');
  check(lines[2].time.inMilliseconds == 3005, 'fração de três dígitos');
  check(lines.last.time.inMilliseconds == 62500, 'minutos e centésimos');
  check(parseLrc('Texto simples').isEmpty, 'detecção de texto sem tempo');
  check(parseLrc('[00:01.00]   ').isEmpty, 'ignorar versos vazios');
  check(
    demoTracks.map((t) => t.id).toSet().length == demoTracks.length,
    'ids únicos',
  );
  print('$checks verificações de modelos passaram.');
}
