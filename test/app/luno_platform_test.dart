import 'package:dashfolio/app/providers.dart';
import 'package:dashfolio/data/db/app_database.dart';
import 'package:dashfolio/data/repositories/market_data_repository_impl.dart';
import 'package:dashfolio/data/repositories/routing_market_data_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  ProviderContainer make({required bool luno}) {
    final c = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db), lunoSupportedProvider.overrideWithValue(luno)]);
    addTearDown(c.dispose);
    return c;
  }

  test('where Luno is supported, market data routes Luno pairs to Luno and the rest to Yahoo', () {
    expect(make(luno: true).read(marketDataRepositoryProvider), isA<RoutingMarketDataRepository>());
  });

  test('where it is not (web), market data is Yahoo only: no Luno client is even built', () {
    final c = make(luno: false);
    expect(c.read(marketDataRepositoryProvider), isA<MarketDataRepositoryImpl>());
  });

  test('Luno is supported everywhere but the web by default', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(lunoSupportedProvider), isTrue, reason: 'the test VM is not a browser');
  });
}
