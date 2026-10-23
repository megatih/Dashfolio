import 'package:decimal/decimal.dart';
import 'package:dashfolio/domain/entities/enums.dart';
import 'package:dashfolio/domain/services/transaction_validation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders.dart';

void main() {
  const v = TransactionValidator();
  final now = DateTime.utc(2024, 6, 1);
  DateTime d(String s) => DateTime.parse('${s}T00:00:00Z');

  TxValidation check(TxDraft draft, {List<dynamic> existing = const [], int? exclude}) =>
      v.validate(draft, existing: List.of(existing.cast()), excludeId: exclude, now: now, method: CostMethod.average);

  TxDraft draft(
    TxType type, {
    String? symbol = 'X',
    String date = '2024-05-01',
    Object? q = 1,
    Object? p = 1,
    Object? fees = 0,
    Object fx = 1,
  }) => TxDraft(
    type: type,
    symbol: symbol,
    date: d(date),
    quantity: q == null ? null : D('$q'),
    price: p == null ? null : D('$p'),
    fees: D('$fees'),
    fxRate: D('$fx'),
  );

  test('a valid buy passes', () => expect(check(draft(TxType.buy)).isValid, isTrue));

  test('requires a symbol for security transactions but not for cash', () {
    expect(check(draft(TxType.buy, symbol: null)).errors['symbol'], isNotNull);
    expect(check(draft(TxType.deposit, symbol: null, q: 1, p: 500)).isValid, isTrue);
  });

  test('rejects future dates, bad numbers and negative fees', () {
    final r = check(draft(TxType.buy, date: '2024-06-02', q: 0, p: null, fees: -1, fx: 0));
    expect(r.errors.keys, containsAll(['date', 'quantity', 'price', 'fees', 'fx']));
  });

  test('allows a zero price for buys (gifts, spin-offs) but not for dividends', () {
    expect(check(draft(TxType.buy, p: 0)).isValid, isTrue);
    expect(check(draft(TxType.dividend, p: 0)).errors['price'], isNotNull);
  });

  test('split needs both share counts', () {
    expect(check(draft(TxType.split, q: 4, p: 1)).isValid, isTrue);
    expect(check(draft(TxType.split, q: 4, p: 0)).errors['price'], isNotNull);
  });

  test('sell cannot exceed shares held on the date', () {
    final existing = [buy('X', '2024-04-01', 10, 5)];
    expect(check(draft(TxType.sell, q: 10), existing: existing).isValid, isTrue);
    expect(check(draft(TxType.sell, q: 11), existing: existing).errors['quantity'], contains('10'));
    expect(check(draft(TxType.sell, q: 1, date: '2024-03-01'), existing: existing).errors['quantity'], contains('No shares'));
  });

  test('editing a sell excludes its own previous quantity', () {
    final b = buy('X', '2024-04-01', 10, 5);
    final s = sell('X', '2024-05-01', 10, 6);
    expect(check(draft(TxType.sell, q: 10), existing: [b, s], exclude: s.id).isValid, isTrue);
  });

  test('a sell dated earlier cannot starve a later sell', () {
    final b = buy('X', '2024-04-01', 10, 5);
    final later = sell('X', '2024-05-20', 10, 6);
    final r = check(draft(TxType.sell, q: 5, date: '2024-05-01'), existing: [b, later]);
    expect(r.errors['quantity'], contains('later sell'));
  });

  test('deleteBreaksHistory flags removing a buy that a sell depends on', () {
    final b = buy('X', '2024-04-01', 10, 5);
    final s = sell('X', '2024-05-01', 10, 6);
    expect(v.deleteBreaksHistory(b, [b, s], CostMethod.average), isTrue);
    expect(v.deleteBreaksHistory(s, [b, s], CostMethod.average), isFalse);
    expect(Decimal.zero, Decimal.zero);
  });
}
