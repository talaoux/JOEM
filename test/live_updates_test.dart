import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:joem/core/network/api_client.dart';
import 'package:joem/core/network/live_updates.dart';
import 'package:joem/core/network/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> domains;
  late int syncCalls;
  late int notifications;

  void countNotification() => notifications++;

  setUp(() async {
    domains = {'jobs': '1|2026-09-29 10:00:00', 'applications': '0|'};
    syncCalls = 0;
    notifications = 0;
    final storage = MemoryTokenStorage();
    await storage.write('jeton');
    ApiClient.shared = ApiClient(
      baseUrl: 'http://pc.local:8000/api',
      tokenStorage: storage,
      httpClient: MockClient((request) async {
        syncCalls++;
        return http.Response.bytes(
          utf8.encode(jsonEncode({'success': true, 'message': 'ok', 'data': {'domains': domains}})),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    LiveUpdates.instance.reset();
  });

  tearDown(() {
    LiveUpdates.instance.removeListener(countNotification);
    ApiClient.shared = null;
  });

  test('the first check is a baseline, an unchanged fingerprint notifies nobody', () async {
    LiveUpdates.instance.addListener(countNotification);
    await LiveUpdates.instance.checkNow();
    await LiveUpdates.instance.checkNow();

    expect(syncCalls, greaterThanOrEqualTo(2));
    expect(notifications, 0);
  });

  test('a change made on the other phone notifies the screens once', () async {
    LiveUpdates.instance.addListener(countNotification);
    await LiveUpdates.instance.checkNow();

    domains = {...domains, 'applications': '1|2026-09-29 10:05:00'};
    await LiveUpdates.instance.checkNow();
    await LiveUpdates.instance.checkNow();

    expect(notifications, 1);
  });

  test('after logout the next account starts from a new baseline', () async {
    LiveUpdates.instance.addListener(countNotification);
    await LiveUpdates.instance.checkNow();

    LiveUpdates.instance.reset();
    domains = {'jobs': '9|2026-09-30 08:00:00'};
    await LiveUpdates.instance.checkNow();

    expect(notifications, 0);
  });

  test('nothing is polled without a session', () async {
    ApiClient.shared = ApiClient(
      baseUrl: 'http://pc.local:8000/api',
      tokenStorage: MemoryTokenStorage(),
      httpClient: MockClient((_) async {
        syncCalls++;
        return http.Response('{}', 200);
      }),
    );

    await LiveUpdates.instance.checkNow();

    expect(syncCalls, 0);
  });
}
