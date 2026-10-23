import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/record_luno_fixtures.dart';

void main() {
  test('replaces identifying values deterministically and scales amounts but not prices', () {
    final s = Scrubber(Decimal.parse('0.5'));
    final input = {
      'id': '123456789',
      'transactions': [
        {
          'account_id': '123456789',
          'reference': 'secret-ref-1',
          'description': 'Sent to bc1qrealaddressxxxxxxxxxxxxxxxxxxxxxx',
          'balance_delta': '-0.2',
          'detail_fields': {
            'crypto_details': {'address': 'bc1qrealaddress', 'txid': 'deadbeef'},
            'trade_details': {'price': '200000.00', 'volume': '0.5'},
          },
        },
        {'account_id': '123456789', 'reference': 'secret-ref-1', 'balance_delta': '4'},
        {'account_id': '987654321', 'reference': 'other', 'balance_delta': '1'},
      ],
    };
    final out = s.scrub(input)! as Map<String, Object?>;
    final rows = (out['transactions']! as List).cast<Map<String, Object?>>();
    expect(out['id'], '1001');
    expect(rows[0]['account_id'], '1001');
    expect(rows[2]['account_id'], '1002');
    expect(rows[0]['reference'], rows[1]['reference']);
    expect(rows[0]['reference'], isNot(rows[2]['reference']));
    expect(rows[0]['description'], isNot(contains('bc1q')));
    expect(rows[0]['balance_delta'], '-0.1');
    expect(rows[1]['balance_delta'], '2');
    final fields = rows[0]['detail_fields']! as Map<String, Object?>;
    expect((fields['crypto_details']! as Map)['address'], 'scrubbed-address-1');
    expect((fields['crypto_details']! as Map)['txid'], 'txid-1-scrubbed');
    expect((fields['trade_details']! as Map)['price'], '200000.00');
    expect((fields['trade_details']! as Map)['volume'], '0.25');
    expect(s.scrub(input), out, reason: 'same input scrubs to the same output');
  });

  test('a bare id is a transfer id in transfer documents', () {
    final out = Scrubber(Decimal.one).scrub({'id': '555555555'}, null, 'transfer')! as Map<String, Object?>;
    expect(out['id'], 'TR1');
  });

  group('human-readable text', () {
    final s = Scrubber(Decimal.one);

    Map<String, Object?> row(Object? description, Map<String, Object?> details, [Object? foreignId]) => {
      'description': description,
      'details': details,
      'foreign_id': ?foreignId,
    };

    test('the details block loses addresses, hashes and every digit', () {
      final out =
          s.scrub(
                row('Received Bitcoin into Jane Doe', {
                  'Address': '3L26YS7hKfxBjCsxo2U6zWMMgS2ZGW2kbz',
                  'Transaction': '94267ee02c12c8cab87dd82b368dcd0419cb6a7d0d6d327d3807b7c44acc6f6c',
                  'Approximate value': '~RM 1,156.10 (101,759 MYR/BTC)',
                  'Fee': 'BTC 0.00033342',
                }),
              )!
              as Map<String, Object?>;
      final d = out['details']! as Map<String, Object?>;
      expect(d['Address'], '[scrubbed]');
      expect(d['Transaction'], '[scrubbed]');
      expect(d['Approximate value'], '~RM #,###.## (###,### MYR/BTC)');
      expect(d['Fee'], 'BTC #.########');
    });

    test('descriptions keep generic wording only: no names, no amounts', () {
      String d(String text) => (s.scrub(row(text, const {}))! as Map<String, Object?>)['description']! as String;
      expect(d('Received Bitcoin into Jane Doe'), 'Received Bitcoin into wallet');
      expect(d('Sent Ether to Jane\'s hardware wallet'), 'Sent Ether to wallet');
      expect(d('Bought BTC\u00a00.01633764 for RM\u00a05,000.00'), 'Bought BTC\u00a0#.######## for RM\u00a0#,###.##');
      expect(d('Sold 0.2498 ETH/MYR @ 15,325'), 'Sold #.#### ETH/MYR @ ##,###');
      expect(d('Trading fee'), 'Trading fee');
      expect(d('Released funds for order [id]'), 'Released funds for order [id]');
      expect(d('Payment to Jane Doe, ref 12345'), '[scrubbed]');
    });

    test('Luno\'s internal numeric ids are replaced by small sequential ones', () {
      final a = (s.scrub(row('Deposit received', const {}, 1028132253353779015))! as Map<String, Object?>)['foreign_id'];
      final b = (s.scrub(row('Deposit received', const {}, 124435299))! as Map<String, Object?>)['foreign_id'];
      final again = (s.scrub(row('Deposit received', const {}, 1028132253353779015))! as Map<String, Object?>)['foreign_id'];
      expect((a, b, again), (1, 2, 1));
    });
  });
}
