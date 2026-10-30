import 'package:flutter_test/flutter_test.dart';
import 'package:musica/models/track.dart';

void main() {
  test('Busca aceita acentos e combina título, artista e álbum', () {
    const t = Track(
      id: '1',
      title: 'Canção de Verão',
      artist: 'João',
      album: 'Férias',
      art: 'chill',
      source: 'night',
    );
    expect(searchTracks([t], 'CANCAO joao').single.id, '1');
    expect(searchTracks([t], 'ferias').single.id, '1');
    expect(searchTracks([t], 'outono'), isEmpty);
    expect(searchTracks([t], '  '), hasLength(1));
  });
  test('Arquivos importados e letras sobrevivem à persistência', () {
    const t = Track(
      id: 'local-1',
      title: 'Minha faixa',
      artist: 'Eu',
      art: 'chill',
      source: '/data/music/a.mp3',
      imported: true,
      lyrics: '[00:02.00]Olá',
    );
    final restored = Track.decode(Track.encode([t])).single;
    expect(restored.source, t.source);
    expect(restored.imported, true);
    expect(restored.lyrics, t.lyrics);
    expect(restored.withLyrics('nova').id, t.id);
  });
  test(
    'LRC aceita centésimos, milésimos, múltiplos tempos e ordena as linhas',
    () {
      final lines = parseLrc(
        '[ar:Artista]\n[01:02.50]Depois\n[00:01.2][00:03.005]Refrão\n[00:00]Início',
      );
      expect(lines.map((l) => l.text), [
        'Início',
        'Refrão',
        'Refrão',
        'Depois',
      ]);
      expect(lines[1].time.inMilliseconds, 1200);
      expect(lines[2].time.inMilliseconds, 3005);
      expect(lines.last.time.inMilliseconds, 62500);
    },
  );
  test('Texto sem marcas de tempo não é confundido com LRC', () {
    expect(parseLrc('Uma letra sem tempo\nOutro verso'), isEmpty);
    expect(parseLrc('[00:01.00]   '), isEmpty);
  });
  test('Cada faixa de demonstração tem um identificador único', () {
    expect(demoTracks.map((t) => t.id).toSet().length, demoTracks.length);
  });
}
