import 'dart:convert';
import 'dart:io';

import 'package:dashfolio/data/luno/luno_mappers.dart';

String lunoFixtureText(String name) => File('test/fixtures/luno/$name').readAsStringSync();

/// Decoded the way the client decodes live responses (ledger numbers preserved exactly).
Json lunoFixture(String name) => decodeLunoJson(lunoFixtureText(name));

Object? rawJson(String name) => jsonDecode(lunoFixtureText(name));
