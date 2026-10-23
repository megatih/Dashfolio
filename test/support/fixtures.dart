import 'dart:convert';
import 'dart:io';

import 'package:dashfolio/data/yahoo/yahoo_mappers.dart';

String fixtureText(String name) => File('test/fixtures/yahoo/$name').readAsStringSync();

Json fixture(String name) => jsonDecode(fixtureText(name)) as Json;
