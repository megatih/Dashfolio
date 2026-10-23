import 'package:decimal/decimal.dart';
import 'package:dashfolio/domain/entities/enums.dart';
import 'package:dashfolio/domain/services/csv_import.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders.dart';

void main() {
  const imp = CsvImporter();
  final today = DateTime.utc(2024, 6, 1);

  group('parseCsvText', () {
    test('handles quotes, BOM, semicolons and blank lines', () {
      final rows = parseCsvText('﻿Date;Symbol;Note\n2024-01-02;AAPL;"hello; world"\n\n2024-01-03;MSFT;x\n');
      expect(rows.length, 3);
      expect(rows.first, ['Date', 'Symbol', 'Note']);
      expect(rows[1][2], 'hello; world');
    });

    test('keeps numbers as text so decimals are never lossy', () {
      final rows = parseCsvText('a,b\n1.10,0010\n');
      expect(rows[1], ['1.10', '0010']);
    });
  });

  group('parseType', () {
    test('recognises common broker wording', () {
      expect(imp.parseType('BUY'), TxType.buy);
      expect(imp.parseType('Bought'), TxType.buy);
      expect(imp.parseType('YOU SOLD'), TxType.sell);
      expect(imp.parseType('Cash Dividend'), TxType.dividend);
      expect(imp.parseType('Stock Split'), TxType.split);
      expect(imp.parseType('ACH Deposit'), TxType.deposit);
      expect(imp.parseType('Transfer Out'), TxType.withdrawal);
      expect(imp.parseType('something odd'), isNull);
      expect(imp.parseType(''), isNull);
    });
  });

  group('parseNumber', () {
    test('dot mark: thousands, currency symbols, parentheses, signs', () {
      expect(imp.parseNumber('1,234.56', DecimalMark.dot), D('1234.56'));
      expect(imp.parseNumber(r'$1,000', DecimalMark.dot), D('1000'));
      expect(imp.parseNumber('(250.5)', DecimalMark.dot), D('-250.5'));
      expect(imp.parseNumber('-3', DecimalMark.dot), D('-3'));
      expect(imp.parseNumber('+3', DecimalMark.dot), D('3'));
      expect(imp.parseNumber('abc', DecimalMark.dot), isNull);
      expect(imp.parseNumber('', DecimalMark.dot), isNull);
    });
    test('comma mark', () {
      expect(imp.parseNumber('1.234,56', DecimalMark.comma), D('1234.56'));
      expect(imp.parseNumber('0,5', DecimalMark.comma), D('0.5'));
    });
  });

  group('dates', () {
    test('iso, us and eu formats', () {
      expect(imp.parseDate('2024-03-15', DateOrder.auto), DateTime.utc(2024, 3, 15));
      expect(imp.parseDate('03/15/2024', DateOrder.mdy), DateTime.utc(2024, 3, 15));
      expect(imp.parseDate('15/03/2024', DateOrder.dmy), DateTime.utc(2024, 3, 15));
      expect(imp.parseDate('15.03.2024', DateOrder.dmy), DateTime.utc(2024, 3, 15));
      expect(imp.parseDate('3/5/24', DateOrder.mdy), DateTime.utc(2024, 3, 5));
      expect(imp.parseDate('2024-03-15T10:30:00Z', DateOrder.auto), DateTime.utc(2024, 3, 15));
    });
    test('named months', () {
      expect(imp.parseDate('Mar 15, 2024', DateOrder.auto), DateTime.utc(2024, 3, 15));
      expect(imp.parseDate('15 March 2024', DateOrder.auto), DateTime.utc(2024, 3, 15));
    });
    test('rejects impossible dates', () {
      expect(imp.parseDate('2024-02-31', DateOrder.iso), isNull);
      expect(imp.parseDate('13/13/2024', DateOrder.mdy), isNull);
      expect(imp.parseDate('garbage', DateOrder.auto), isNull);
    });
    test('detects day-first columns from evidence', () {
      expect(imp.detectDateOrder(['03/04/2024', '25/04/2024']), DateOrder.dmy);
      expect(imp.detectDateOrder(['03/04/2024', '04/25/2024']), DateOrder.mdy);
      expect(imp.detectDateOrder(['03/04/2024']), DateOrder.mdy); // ambiguous -> US
      expect(imp.detectDateOrder(['2024-03-04']), DateOrder.iso);
    });
  });

  test('autoDetect maps typical headers', () {
    final m = imp.autoDetect([
      'Trade Date',
      'Ticker',
      'Action',
      'Shares',
      'Fill Price',
      'Commission',
      'Currency',
      'Description',
      'Net Amount',
    ]);
    expect(m.date, 'Trade Date');
    expect(m.symbol, 'Ticker');
    expect(m.type, 'Action');
    expect(m.quantity, 'Shares');
    expect(m.price, 'Fill Price');
    expect(m.fees, 'Commission');
    expect(m.currency, 'Currency');
    expect(m.notes, 'Description');
    expect(m.amount, 'Net Amount');
    expect(m.missingRequired, isEmpty);
  });

  group('parse', () {
    final rows = parseCsvText('''Date,Symbol,Action,Qty,Price,Fees,Currency,Amount
2024-01-02,aapl,Buy,10,150.25,1,USD,
2024-02-01,AAPL,Sell,-4,160,0.5,USD,
2024-03-01,AAPL,Dividend,,,,USD,12.34
2024-03-02,,Buy,1,1,,,
2024-03-03,MSFT,Wire,1,1,,,
not-a-date,MSFT,Buy,1,1,,,
2024-04-01,,Deposit,,,,USD,"1,000.00"
2024-04-02,NVDA,Buy,2,,,,300
2024-05-01,NVDA,Split,10,1,,,
2099-01-01,AAPL,Buy,1,1,,,
''');
    final mapping = imp.autoDetect(rows.first);
    final parsed = imp.parse(rows: rows, mapping: mapping, today: today);

    test('buy row', () {
      final r = parsed[0];
      expect(r.valid, isTrue);
      expect(r.symbol, 'AAPL');
      expect(r.type, TxType.buy);
      expect(r.quantity, D('10'));
      expect(r.price, D('150.25'));
      expect(r.fees, D('1'));
      expect(r.line, 2);
    });
    test('negative sell quantity becomes positive', () => expect(parsed[1].quantity, D('4')));
    test('dividend from total amount', () {
      expect(parsed[2].valid, isTrue);
      expect(parsed[2].quantity, Decimal.zero);
      expect(parsed[2].price, D('12.34'));
    });
    test('reports row-level errors without aborting the file', () {
      expect(parsed[3].errors, contains('Missing symbol'));
      expect(parsed[4].errors.single, contains('Unknown type'));
      expect(parsed[5].errors.single, contains('date'));
      expect(parsed.where((r) => r.valid).length, 6);
    });
    test('cash rows need no symbol and use the amount', () {
      expect(parsed[6].valid, isTrue);
      expect(parsed[6].symbol, isNull);
      expect(parsed[6].price, D('1000.00'));
    });
    test('price derived from total amount / quantity', () => expect(parsed[7].price, D('150')));
    test('split keeps both counts', () {
      expect(parsed[8].quantity, D('10'));
      expect(parsed[8].price, D('1'));
    });
    test('future dates are rejected', () => expect(parsed[9].errors.single, contains('future')));
  });

  test('default type applies when no type column is mapped', () {
    final rows = parseCsvText('Date,Ticker,Shares,Price\n2024-01-02,AAPL,3,10\n');
    final p = imp.parse(
      rows: rows,
      mapping: imp.autoDetect(rows.first).with_('type', null),
      options: const ImportOptions(defaultType: TxType.buy),
      today: today,
    );
    expect(p.single.valid, isTrue);
    expect(p.single.type, TxType.buy);
  });

  test('comma decimals with dd.MM.yyyy', () {
    final rows = parseCsvText('Datum;Symbol;Typ;Stück;Kurs\n15.03.2024;SAP.DE;Kauf;1.000,5;120,25\n');
    final m = imp.autoDetect(rows.first).with_('date', 'Datum').with_('type', 'Typ').with_('quantity', 'Stück').with_('price', 'Kurs');
    final p = imp.parse(
      rows: [
        rows.first,
        [...rows[1]]..[2] = 'Buy',
      ],
      mapping: m,
      options: const ImportOptions(decimalMark: DecimalMark.comma),
      today: today,
    );
    expect(p.single.valid, isTrue);
    expect(p.single.quantity, D('1000.5'));
    expect(p.single.price, D('120.25'));
    expect(p.single.date, DateTime.utc(2024, 3, 15));
  });

  test('markDuplicates flags rows matching existing transactions only', () {
    final rows = parseCsvText('Date,Symbol,Action,Qty,Price\n2024-01-02,AAPL,Buy,10,150\n2024-01-03,AAPL,Buy,10,150\n');
    final parsed = imp.parse(rows: rows, mapping: imp.autoDetect(rows.first), today: today);
    final marked = imp.markDuplicates(parsed, [buy('AAPL', '2024-01-02', 10, 150)]);
    expect(marked[0].duplicate, isTrue);
    expect(marked[1].duplicate, isFalse);
  });

  test('identical rows inside the file are not treated as duplicates', () {
    final rows = parseCsvText('Date,Symbol,Action,Qty,Price\n2024-01-02,AAPL,Buy,5,150\n2024-01-02,AAPL,Buy,5,150\n');
    final marked = imp.markDuplicates(imp.parse(rows: rows, mapping: imp.autoDetect(rows.first), today: today), const []);
    expect(marked.where((r) => r.duplicate), isEmpty);
  });
}
