import 'package:csv/csv.dart';
import 'package:decimal/decimal.dart';

import '../../core/decimal_ext.dart';
import '../entities/enums.dart';
import '../entities/portfolio.dart';

/// Parses CSV text into rows of trimmed strings. The delimiter is auto-detected.
List<List<String>> parseCsvText(String text) {
  final cleaned = text.startsWith('﻿') ? text.substring(1) : text;
  final rows = csv.decode(cleaned);
  return [
    for (final r in rows)
      if (r.any((c) => '$c'.trim().isNotEmpty)) [for (final c in r) '$c'.trim()],
  ];
}

enum DateOrder {
  auto('Detect automatically'),
  iso('Year-Month-Day (2024-03-15)'),
  mdy('Month/Day/Year (03/15/2024)'),
  dmy('Day/Month/Year (15/03/2024)');

  const DateOrder(this.label);
  final String label;
}

enum DecimalMark {
  dot('1,234.56'),
  comma('1.234,56');

  const DecimalMark(this.label);
  final String label;
}

/// Which CSV column feeds which transaction field (null = not mapped).
class ColumnMapping {
  const ColumnMapping({this.date, this.symbol, this.type, this.quantity, this.price, this.fees, this.currency, this.notes, this.amount});

  final String? date;
  final String? symbol;
  final String? type;
  final String? quantity;
  final String? price;
  final String? fees;
  final String? currency;
  final String? notes;

  /// Total amount, used for dividends/cash rows when no price column exists.
  final String? amount;

  static const fields = ['date', 'symbol', 'type', 'quantity', 'price', 'fees', 'currency', 'notes', 'amount'];

  String? operator [](String field) => switch (field) {
    'date' => date,
    'symbol' => symbol,
    'type' => type,
    'quantity' => quantity,
    'price' => price,
    'fees' => fees,
    'currency' => currency,
    'notes' => notes,
    'amount' => amount,
    _ => null,
  };

  ColumnMapping with_(String field, String? header) => ColumnMapping(
    date: field == 'date' ? header : date,
    symbol: field == 'symbol' ? header : symbol,
    type: field == 'type' ? header : type,
    quantity: field == 'quantity' ? header : quantity,
    price: field == 'price' ? header : price,
    fees: field == 'fees' ? header : fees,
    currency: field == 'currency' ? header : currency,
    notes: field == 'notes' ? header : notes,
    amount: field == 'amount' ? header : amount,
  );

  Map<String, Object?> toJson() => {for (final f in fields) f: this[f]};

  factory ColumnMapping.fromJson(Map<String, Object?> j) => ColumnMapping(
    date: j['date'] as String?,
    symbol: j['symbol'] as String?,
    type: j['type'] as String?,
    quantity: j['quantity'] as String?,
    price: j['price'] as String?,
    fees: j['fees'] as String?,
    currency: j['currency'] as String?,
    notes: j['notes'] as String?,
    amount: j['amount'] as String?,
  );

  /// Required fields that are not mapped.
  List<String> get missingRequired => [if (date == null) 'date', if (type == null) 'type'];
}

class ImportOptions {
  const ImportOptions({this.dateOrder = DateOrder.auto, this.decimalMark = DecimalMark.dot, this.defaultType, this.defaultCurrency});

  final DateOrder dateOrder;
  final DecimalMark decimalMark;

  /// Used when the type column is empty/unmapped (e.g. a file of purchases only).
  final TxType? defaultType;

  /// Used when the row has no currency; null lets the app resolve it from the instrument.
  final String? defaultCurrency;
}

/// A parsed CSV row.
class ImportRow {
  const ImportRow({
    required this.line,
    this.type,
    this.symbol,
    this.date,
    this.quantity,
    this.price,
    this.fees,
    this.currency,
    this.notes,
    this.errors = const [],
    this.duplicate = false,
  });

  /// 1-based line number in the file (header = 1).
  final int line;
  final TxType? type;
  final String? symbol;
  final DateTime? date;
  final Decimal? quantity;
  final Decimal? price;
  final Decimal? fees;
  final String? currency;
  final String? notes;
  final List<String> errors;
  final bool duplicate;

  bool get valid => errors.isEmpty;

  ImportRow markDuplicate() => ImportRow(
    line: line,
    type: type,
    symbol: symbol,
    date: date,
    quantity: quantity,
    price: price,
    fees: fees,
    currency: currency,
    notes: notes,
    errors: errors,
    duplicate: true,
  );
}

class CsvImporter {
  const CsvImporter();

  static const _aliases = <TxType, List<String>>{
    TxType.buy: [
      'buy',
      'bought',
      'purchase',
      'purchased',
      'b',
      'market buy',
      'limit buy',
      'buy to open',
      'acquire',
      'reinvest shares',
      'reinvestment',
    ],
    TxType.sell: ['sell', 'sold', 'sale', 's', 'market sell', 'limit sell', 'sell to close', 'dispose'],
    TxType.dividend: [
      'dividend',
      'div',
      'dividends',
      'cash dividend',
      'dividend received',
      'distribution',
      'qualified dividend',
      'ordinary dividend',
    ],
    TxType.split: ['split', 'stock split'],
    TxType.deposit: ['deposit', 'contribution', 'transfer in', 'cash in', 'funding', 'ach deposit', 'wire in'],
    TxType.withdrawal: ['withdrawal', 'withdraw', 'transfer out', 'cash out', 'ach withdrawal', 'wire out'],
    TxType.fee: ['fee', 'fees', 'commission', 'account fee', 'management fee'],
    TxType.openingPosition: ['opening position', 'opening balance', 'position', 'holding', 'opening'],
  };

  /// Maps free-form broker action text to a [TxType]; null when unrecognized.
  TxType? parseType(String raw) {
    final v = raw.trim().toLowerCase();
    if (v.isEmpty) return null;
    for (final e in _aliases.entries) {
      if (e.value.contains(v)) return e.key;
    }
    // Looser matching on words ("YOU BOUGHT", "Dividend - AAPL").
    for (final e in _aliases.entries) {
      for (final a in e.value) {
        if (a.length >= 4 && v.contains(a)) return e.key;
      }
    }
    return null;
  }

  /// Guesses a column mapping from common header names.
  ColumnMapping autoDetect(List<String> headers) {
    String? find(List<String> names) {
      for (final n in names) {
        for (final h in headers) {
          if (h.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') == n) return h;
        }
      }
      for (final n in names) {
        for (final h in headers) {
          if (h.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').contains(n)) return h;
        }
      }
      return null;
    }

    return ColumnMapping(
      date: find(['tradedate', 'date', 'transactiondate', 'settlementdate', 'time', 'datetime']),
      symbol: find(['symbol', 'ticker', 'instrument', 'security', 'code']),
      type: find(['type', 'action', 'transactiontype', 'side', 'activity', 'buysell']),
      quantity: find(['quantity', 'shares', 'qty', 'units', 'amountofshares']),
      price: find(['price', 'pricepershare', 'fillprice', 'tradeprice', 'unitprice', 'executionprice']),
      fees: find(['fees', 'fee', 'commission', 'commissions', 'charges']),
      currency: find(['currency', 'ccy', 'curr']),
      notes: find(['notes', 'note', 'description', 'memo', 'comment']),
      amount: find(['amount', 'total', 'netamount', 'value', 'proceeds']),
    );
  }

  Decimal? parseNumber(String raw, DecimalMark mark) {
    var s = raw.trim();
    if (s.isEmpty) return null;
    var negative = false;
    if (s.startsWith('(') && s.endsWith(')')) {
      negative = true;
      s = s.substring(1, s.length - 1);
    }
    s = s.replaceAll(RegExp(r'[\s $€£¥₹%]'), '').replaceAll(RegExp(r'^[A-Za-z]{3}(?=[\d\-.,])'), '');
    if (s.startsWith('-')) {
      negative = !negative;
      s = s.substring(1);
    } else if (s.startsWith('+')) {
      s = s.substring(1);
    }
    s = mark == DecimalMark.dot ? s.replaceAll(',', '') : s.replaceAll('.', '').replaceAll(',', '.');
    final d = Decimal.tryParse(s);
    if (d == null) return null;
    return negative ? -d : d;
  }

  /// Resolves the date order for a column by inspecting its values.
  DateOrder detectDateOrder(Iterable<String> samples) {
    var dayFirstEvidence = false, monthFirstEvidence = false;
    for (final s in samples) {
      final m = RegExp(r'^(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{2,4})').firstMatch(s.trim());
      if (m == null) {
        if (RegExp(r'^\d{4}[/.\-]\d{1,2}[/.\-]\d{1,2}').hasMatch(s.trim())) return DateOrder.iso;
        continue;
      }
      final a = int.parse(m.group(1)!), b = int.parse(m.group(2)!);
      if (a > 12) dayFirstEvidence = true;
      if (b > 12) monthFirstEvidence = true;
    }
    if (dayFirstEvidence && !monthFirstEvidence) return DateOrder.dmy;
    return DateOrder.mdy; // US default when ambiguous
  }

  DateTime? parseDate(String raw, DateOrder order) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    RegExpMatch? m = RegExp(r'^(\d{4})[/.\-](\d{1,2})[/.\-](\d{1,2})').firstMatch(s);
    int y, mo, d;
    if (m != null) {
      // Year-first dates are unambiguous regardless of the chosen order.
      y = int.parse(m.group(1)!);
      mo = int.parse(m.group(2)!);
      d = int.parse(m.group(3)!);
    } else {
      m = RegExp(r'^(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{2,4})').firstMatch(s);
      if (m == null) {
        // "Mar 15, 2024" / "15 Mar 2024"
        return _parseNamedMonth(s);
      }
      final a = int.parse(m.group(1)!), b = int.parse(m.group(2)!);
      var yr = int.parse(m.group(3)!);
      if (yr < 100) yr += yr >= 70 ? 1900 : 2000;
      y = yr;
      if (order == DateOrder.dmy) {
        d = a;
        mo = b;
      } else {
        mo = a;
        d = b;
      }
    }
    if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
    final date = DateTime.utc(y, mo, d);
    return date.month == mo ? date : null; // rejects Feb 31 etc.
  }

  DateTime? _parseNamedMonth(String s) {
    const months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
    final m1 = RegExp(r'^([A-Za-z]{3,9})\.?\s+(\d{1,2}),?\s+(\d{4})').firstMatch(s);
    final m2 = RegExp(r'^(\d{1,2})\s+([A-Za-z]{3,9})\.?,?\s+(\d{4})').firstMatch(s);
    String? mon;
    int? d, y;
    if (m1 != null) {
      mon = m1.group(1);
      d = int.parse(m1.group(2)!);
      y = int.parse(m1.group(3)!);
    } else if (m2 != null) {
      d = int.parse(m2.group(1)!);
      mon = m2.group(2);
      y = int.parse(m2.group(3)!);
    } else {
      return null;
    }
    final idx = months.indexOf(mon!.toLowerCase().substring(0, 3));
    if (idx < 0) return null;
    final date = DateTime.utc(y, idx + 1, d);
    return date.month == idx + 1 ? date : null;
  }

  /// Converts [rows] (including the header row) into [ImportRow]s.
  List<ImportRow> parse({
    required List<List<String>> rows,
    required ColumnMapping mapping,
    ImportOptions options = const ImportOptions(),
    required DateTime today,
  }) {
    if (rows.length < 2) return const [];
    final headers = rows.first;
    int? idx(String? h) => h != null && headers.contains(h) ? headers.indexOf(h) : null;
    final iDate = idx(mapping.date), iSym = idx(mapping.symbol), iType = idx(mapping.type), iQty = idx(mapping.quantity);
    final iPrice = idx(mapping.price),
        iFees = idx(mapping.fees),
        iCcy = idx(mapping.currency),
        iNotes = idx(mapping.notes),
        iAmt = idx(mapping.amount);

    String cell(List<String> r, int? i) => (i == null || i >= r.length) ? '' : r[i];

    final order = options.dateOrder == DateOrder.auto ? detectDateOrder([for (final r in rows.skip(1)) cell(r, iDate)]) : options.dateOrder;

    final out = <ImportRow>[];
    for (var n = 1; n < rows.length; n++) {
      final r = rows[n];
      final errors = <String>[];

      final date = parseDate(cell(r, iDate), order);
      if (date == null) {
        errors.add('Unrecognized date "${cell(r, iDate)}"');
      } else if (date.isAfter(DateTime.utc(today.year, today.month, today.day))) {
        errors.add('Date is in the future');
      }

      var type = iType == null ? options.defaultType : parseType(cell(r, iType));
      if (type == null && cell(r, iType).isEmpty) type = options.defaultType;
      if (type == null) errors.add(iType == null ? 'No transaction type column or default' : 'Unknown type "${cell(r, iType)}"');

      var symbol = cell(r, iSym).toUpperCase().replaceAll(RegExp(r'\s+'), '');
      if (symbol.isEmpty) symbol = '';
      final needsSymbol = type?.hasSymbol ?? true;
      if (needsSymbol && symbol.isEmpty) errors.add('Missing symbol');

      Decimal? qty = parseNumber(cell(r, iQty), options.decimalMark);
      Decimal? price = parseNumber(cell(r, iPrice), options.decimalMark);
      final amount = parseNumber(cell(r, iAmt), options.decimalMark);
      var fees = parseNumber(cell(r, iFees), options.decimalMark);
      fees = fees?.abs();

      if (type != null) {
        switch (type) {
          case TxType.deposit || TxType.withdrawal || TxType.fee:
            final v = (amount ?? price ?? qty)?.abs();
            if (v == null || v <= Decimal.zero) errors.add('Missing amount');
            qty = Decimal.one;
            price = v;
          case TxType.dividend:
            // Either shares × per-share, or a total amount.
            if (qty != null && qty != Decimal.zero && price != null) {
              qty = qty.abs();
              price = price.abs();
            } else if (amount != null) {
              qty = Decimal.zero;
              price = amount.abs();
            } else {
              errors.add('Missing dividend amount');
            }
          case TxType.split:
            if (qty == null || price == null || qty <= Decimal.zero || price <= Decimal.zero) {
              errors.add('Split needs new and old share counts');
            }
          case TxType.buy || TxType.sell || TxType.openingPosition || TxType.transferIn || TxType.transferOut || TxType.reward:
            qty = qty?.abs();
            if (qty == null || qty <= Decimal.zero) errors.add('Missing quantity');
            if (price == null && amount != null && qty != null && qty > Decimal.zero) {
              price = amount.abs().div(qty);
            }
            price = price?.abs();
            if (price == null) errors.add('Missing price');
        }
      }

      final ccy = cell(r, iCcy).trim().toUpperCase();
      out.add(
        ImportRow(
          line: n + 1,
          type: type,
          symbol: symbol.isEmpty ? null : symbol,
          date: date,
          quantity: qty,
          price: price,
          fees: fees ?? Decimal.zero,
          currency: ccy.isEmpty ? options.defaultCurrency : _normaliseCurrency(ccy),
          notes: cell(r, iNotes).isEmpty ? null : cell(r, iNotes),
          errors: errors,
        ),
      );
    }
    return out;
  }

  String _normaliseCurrency(String c) => switch (c) {
    'GBX' || 'GBP' => 'GBP',
    _ => c,
  };

  /// Flags rows that already exist in [existing] (same symbol, type, date, quantity and price).
  List<ImportRow> markDuplicates(List<ImportRow> rows, Iterable<PortfolioTransaction> existing) {
    String key(String? s, TxType? t, DateTime? d, Decimal? q, Decimal? p) =>
        '${s ?? ''}|${t?.dbName}|${d?.toIso8601String().substring(0, 10)}|${q?.toString()}|${p?.toString()}';
    final seen = {for (final t in existing) key(t.symbol, t.type, t.tradeDate, t.quantity, t.price)};
    return [for (final r in rows) r.valid && seen.contains(key(r.symbol, r.type, r.date, r.quantity, r.price)) ? r.markDuplicate() : r];
  }
}
