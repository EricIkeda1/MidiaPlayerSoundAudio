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
    art: 'icon',
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
  const device = Track(
    id: 'device:7',
    title: 'Minha música',
    artist: 'Meu artista',
    art: 'icon',
    source: 'content://media/external/audio/media/7',
    imported: true,
  );
  const imported = Track(
    id: 'local',
    title: 'Arquivo',
    artist: 'Eu',
    art: 'icon',
    source: '/data/local.mp3',
    imported: true,
  );
  check(device.isDeviceTrack, 'reconhece URI do MediaStore');
  check(!imported.isDeviceTrack, 'importação copiada não é MediaStore');
  final merged = mergeDeviceTracks(
    [track, imported, device.withLyrics('minha letra')],
    [device, device],
  );
  check(merged.length == 3, 'atualização não duplica músicas');
  check(merged.last.lyrics == 'minha letra', 'atualização preserva letras');
  final revoked = mergeDeviceTracks(merged, []);
  check(
    revoked.length == 2 && !revoked.any((t) => t.isDeviceTrack),
    'revogação remove apenas as faixas do MediaStore',
  );
  check(
    revoked.any((t) => t.id == 'local'),
    'importações continuam disponíveis',
  );
  check(
    emptyTrack.id.isEmpty && emptyTrack.source.isEmpty,
    'estado vazio não tem áudio',
  );
  final migrated = cleanLegacyPlaylists({
    'Chill Vibes': ['blinding', 'flowers'],
    'Meu mix': ['blinding', 'local', 'device:7'],
    'Minha vazia': [],
    'Relax': ['device:7'],
  });
  check(
    !migrated.containsKey('Chill Vibes'),
    'remove playlist fornecida sem arquivos reais',
  );
  check(
    migrated['Meu mix']!.join(',') == 'local,device:7',
    'preserva faixas reais e remove exemplos',
  );
  check(
    migrated.containsKey('Minha vazia'),
    'preserva playlists vazias do usuário',
  );
  check(
    migrated['Relax']!.single == 'device:7',
    'preserva playlist com conteúdo real',
  );
  check(
    cleanLegacyPlaylists(migrated).toString() == migrated.toString(),
    'migração idempotente',
  );
  print('$checks verificações de modelos passaram.');
}
