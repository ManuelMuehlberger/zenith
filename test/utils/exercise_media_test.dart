import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/utils/exercise_media.dart';

void main() {
  group('exercise_media', () {
    test('decodeExerciseImagePaths returns an empty list for blank input', () {
      expect(decodeExerciseImagePaths('   '), isEmpty);
    });

    test(
      'decodeExerciseImagePaths parses JSON image lists and filters blanks',
      () {
        expect(
          decodeExerciseImagePaths(
            '["asset://one.png", "", "asset://two.png"]',
          ),
          ['asset://one.png', 'asset://two.png'],
        );
      },
    );

    test(
      'decodeExerciseImagePaths falls back to the raw path for legacy values',
      () {
        expect(decodeExerciseImagePaths('assets/images/exercise.png'), [
          'assets/images/exercise.png',
        ]);
      },
    );

    test(
      'exerciseImageProviderFor returns an AssetImage for bundled assets',
      () {
        final provider = exerciseImageProviderFor('assets/images/exercise.png');

        expect(provider, isA<AssetImage>());
      },
    );

    test('exerciseImageProviderFor returns a FileImage for local files', () {
      final provider = exerciseImageProviderFor('file:///tmp/exercise.png');

      expect(provider, isA<FileImage>());
      expect((provider as FileImage).file.path, '/tmp/exercise.png');
    });

    test('exerciseImageProviderFor returns a FileImage for absolute paths', () {
      final provider = exerciseImageProviderFor('/tmp/exercise.png');

      expect(provider, isA<FileImage>());
      expect((provider as FileImage).file.path, '/tmp/exercise.png');
    });
  });
}
