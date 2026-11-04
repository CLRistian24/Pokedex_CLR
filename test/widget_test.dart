
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_app/main.dart';

void main() {
  testWidgets('La aplicación Pokédex inicia correctamente',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PokedexApp());

    expect(find.text('PokéDex Nacional'), findsOneWidget);
  });
}
