import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musica/core/theme.dart';
import 'package:musica/models/track.dart';
import 'package:musica/ui/widgets.dart';

void main() {
  testWidgets('Biblioteca comporta títulos longos em celular estreito', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: musicTheme(),
        home: Scaffold(
          body: MusicTile(
            track: const Track(
              id: 'a',
              title: 'Uma música com um título muito longo para este celular',
              artist: 'Nome de artista também bastante extenso',
              art: 'chill',
              source: 'night',
            ),
            onTap: () {},
            onMore: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Opções da música'), findsOneWidget);
  });
  testWidgets('Menu de filtros informa a seleção e recebe toque', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: musicTheme(),
        home: Scaffold(
          body: FilterPills(
            labels: const ['Tudo', 'Músicas', 'Álbuns'],
            selected: 'Tudo',
            onSelected: (v) => selected = v,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Álbuns'));
    expect(selected, 'Álbuns');
  });
}
