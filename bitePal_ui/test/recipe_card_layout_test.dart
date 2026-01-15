import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_eator/widgets/recipe_card.dart';
import 'package:my_eator/models/recipe.dart';

void main() {
  testWidgets('RecipeCard fits within 171x228 constraints without overflow', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    // Setup exception handling to fail test on overflow
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception is FlutterError &&
          (details.exception as FlutterError).message.contains('overflowed')) {
         originalOnError?.call(details); // Report the error
         throw details.exception;
      }
      originalOnError?.call(details);
    };

    addTearDown(() {
      FlutterError.onError = originalOnError;
    });

    // Define the recipe
    final recipe = Recipe(
      id: '1',
      name: 'Test Recipe with a slightly longer name',
      time: '30 min',
      difficulty: '家常便饭',
      tags: ['Tag1', 'Tag2', 'Tag3', 'Tag4', 'Tag5'],
      tagColors: ['red', 'blue', 'green', 'yellow', 'purple'],
      categories: [],
      ingredients: [],
    );

    // Build the widget with strict constraints found in RecipesScreen
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 171,
              height: 228,
              child: RecipeCard(recipe: recipe),
            ),
          ),
        ),
      ),
    );

    // If we reach here without exception, check if widgets are found
    expect(find.text('Test Recipe with a slightly longer name'), findsOneWidget);
    expect(find.text('30 min'), findsOneWidget);
  });
}
