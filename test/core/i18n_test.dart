import 'dart:convert';
import 'dart:io';

import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every sentence the app shows in tr('...'), and the label lists collected by tool/i18n_keys.py.
Set<String> sentences() {
  final keys = (jsonDecode(
    File('assets/i18n/keys.json').readAsStringSync(),
  ) as List).cast<String>().toSet();
  final literal = RegExp(r"\btr\(\s*'((?:[^'\\]|\\.)*)'\s*[,)]");
  for (final file in Directory(
    'lib',
  ).listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart') || file.path.contains('i18n')) continue;
    for (final m in literal.allMatches(file.readAsStringSync())) {
      // Built at run time ('1 $word'): listed in keys.json instead.
      if (m.group(1)!.contains(r'$')) continue;
      keys.add(
        m
            .group(1)!
            .replaceAllMapped(
              RegExp(r'\\(.)'),
              (e) => e.group(1) == 'n' ? '\n' : e.group(1)!,
            ),
      );
    }
  }
  return keys;
}

void main() {
  tearDown(I18n.reset);

  test('every sentence is translated in every language, placeholders kept', () {
    final all = sentences();
    final problems = <String>[];
    for (final language in appLanguages.where((l) => l.code != 'en')) {
      final messages = (jsonDecode(
        File('assets/i18n/${language.code}.json').readAsStringSync(),
      ) as Map).cast<String, String>();
      for (final key in all) {
        final text = messages[key];
        if (text == null || text.isEmpty) {
          problems.add('${language.code}: missing "$key"');
          continue;
        }
        for (final placeholder in RegExp(
          r'\{\d\}',
        ).allMatches(key).map((m) => m.group(0)!)) {
          if (!text.contains(placeholder)) {
            problems.add('${language.code}: "$key" lost $placeholder');
          }
        }
      }
    }
    expect(
      problems,
      isEmpty,
      reason: 'Run python tool/i18n_keys.py, then add the sentences to every assets/i18n/<code>.json.',
    );
  });

  test('tr fills placeholders, and an untranslated sentence stays English', () {
    I18n.useCatalog('es', {
      'Your trip to {0} starts in {1} days.':
          'Tu viaje a {0} empieza dentro de {1} días.',
    });

    expect(
      tr('Your trip to {0} starts in {1} days.', ['Goa', 3]),
      'Tu viaje a Goa empieza dentro de 3 días.',
    );
    expect(tr('Nobody translated this.'), 'Nobody translated this.');
    expect(I18n.code, 'es');
  });

  test('prices follow the account, then the traveller\'s choice', () async {
    I18n.accountCurrency = 'JPY';
    expect(I18n.currency, 'JPY');
    I18n.accountCurrency = null;
    I18n.reset();
    expect(I18n.currency, isNot('JPY'));
  });
}
