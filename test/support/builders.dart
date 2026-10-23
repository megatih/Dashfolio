import 'package:decimal/decimal.dart';
import 'package:dashfolio/core/decimal_ext.dart';
import 'package:dashfolio/domain/entities/enums.dart';
import 'package:dashfolio/domain/entities/portfolio.dart';

int _id = 0;

PortfolioTransaction tx(
  TxType type,
  String? symbol,
  String date, {
  Object quantity = 0,
  Object price = 0,
  Object fees = 0,
  String currency = 'USD',
  Object fx = 1,
  int portfolio = 1,
  DateTime? executedAt,
  TxSource source = TxSource.manual,
}) {
  _id++;
  return PortfolioTransaction(
    id: _id,
    portfolioId: portfolio,
    symbol: symbol,
    type: type,
    tradeDate: DateTime.parse('${date}T00:00:00Z'),
    quantity: dec(quantity),
    price: dec(price),
    fees: dec(fees),
    currency: currency,
    fxRateToBase: dec(fx),
    createdAt: DateTime.utc(2020, 1, 1).add(Duration(seconds: _id)),
    executedAt: executedAt,
    source: source,
  );
}

PortfolioTransaction buy(
  String s,
  String d,
  Object q,
  Object p, {
  Object fees = 0,
  String currency = 'USD',
  Object fx = 1,
  int portfolio = 1,
}) => tx(TxType.buy, s, d, quantity: q, price: p, fees: fees, currency: currency, fx: fx, portfolio: portfolio);

PortfolioTransaction sell(
  String s,
  String d,
  Object q,
  Object p, {
  Object fees = 0,
  String currency = 'USD',
  Object fx = 1,
  int portfolio = 1,
}) => tx(TxType.sell, s, d, quantity: q, price: p, fees: fees, currency: currency, fx: fx, portfolio: portfolio);

PortfolioTransaction dividendTx(String s, String d, Object q, Object p, {String currency = 'USD', Object fx = 1, int portfolio = 1}) =>
    tx(TxType.dividend, s, d, quantity: q, price: p, currency: currency, fx: fx, portfolio: portfolio);

PortfolioTransaction splitTx(String s, String d, int num, int den, {int portfolio = 1}) =>
    tx(TxType.split, s, d, quantity: num, price: den, portfolio: portfolio);

Decimal D(String v) => Decimal.parse(v);
