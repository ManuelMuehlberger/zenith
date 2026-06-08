import 'dart:convert';

// policy: no-test-needed image processing utility covered by integration tests

import 'dart:io';

import 'package:flutter/material.dart';

// policy: allow-public-api shared exercise image decoding helper used by creator and info flows.
List<String> decodeExerciseImagePaths(String value) {
  if (value.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(value);
    if (decoded is List) {
      return decoded
          .map((entry) => entry.toString())
          .where((entry) => entry.trim().isNotEmpty)
          .toList();
    }
  } catch (_) {
    // Legacy bundled exercises store a plain asset path.
  }
  return [value];
}

// policy: allow-public-api shared image provider helper used by creator and info flows.
ImageProvider exerciseImageProviderFor(String path) {
  if (path.startsWith('/') || path.startsWith('file://')) {
    return FileImage(File(path.replaceFirst('file://', '')));
  }
  return AssetImage(path);
}
