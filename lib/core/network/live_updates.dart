import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'api_client.dart';

/// Rafraîchissement automatique en mode API : ce qu'un téléphone fait
/// (publier, postuler, décider, planifier...) apparaît sur l'autre sans
/// redémarrer l'application.
///
/// Tant qu'au moins un écran écoute et que l'application est au premier
/// plan, `GET /sync` est interrogé toutes les [interval]. Cette route ne
/// renvoie qu'une empreinte (nombres de lignes et dernières dates de
/// modification) : les écrans ne rechargent leurs données que lorsqu'elle
/// change. Au retour au premier plan, la vérification est immédiate.
///
/// Sans `API_BASE_URL` (mode 100% local), rien n'est interrogé.
class LiveUpdates extends ChangeNotifier with WidgetsBindingObserver {
  LiveUpdates._();

  static final LiveUpdates instance = LiveUpdates._();

  static const Duration interval = Duration(seconds: 5);

  Timer? _timer;
  Map<String, dynamic>? _lastDomains;
  bool _checking = false;
  bool _observingLifecycle = false;
  bool _inForeground = true;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _updateTimer();
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    _updateTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inForeground = state == AppLifecycleState.resumed;
    _updateTimer();
    if (_inForeground) checkNow();
  }

  /// Interroge le serveur tout de suite ; prévient les écrans si quelque
  /// chose a changé depuis la dernière vérification.
  Future<void> checkNow() async {
    final api = ApiClient.shared;
    if (_checking || api == null || await api.token == null) return;

    _checking = true;
    try {
      final data = await api.get('/sync', fresh: true) as Map<String, dynamic>;
      final domains = data['domains'] as Map<String, dynamic>;
      final changed = _lastDomains != null && !mapEquals(_lastDomains, domains);
      _lastDomains = domains;
      if (changed) {
        // Les réponses gardées en mémoire par `ApiClient` datent d'avant ce
        // changement : les écrans doivent relire le serveur.
        api.invalidateCache();
        notifyListeners();
      }
    } on ApiException catch (error) {
      // Serveur injoignable ou session terminée : on réessaiera au prochain tour.
      debugPrint('LiveUpdates : vérification impossible — $error');
    } finally {
      _checking = false;
    }
  }

  /// À la déconnexion : l'empreinte connue appartenait à l'ancien compte.
  void reset() => _lastDomains = null;

  void _updateTimer() {
    if (!_observingLifecycle) {
      WidgetsBinding.instance.addObserver(this);
      _observingLifecycle = true;
    }

    final shouldRun = hasListeners && _inForeground && ApiClient.shared != null;
    if (shouldRun && _timer == null) {
      _timer = Timer.periodic(interval, (_) => checkNow());
      checkNow();
    } else if (!shouldRun) {
      _timer?.cancel();
      _timer = null;
    }
  }
}

/// À mixer dans le `State` d'un écran qui affiche des données partagées :
/// [onLiveUpdate] est appelé chaque fois que le serveur signale un
/// changement, tant que l'écran est affiché.
mixin LiveRefresh<T extends StatefulWidget> on State<T> {
  /// Recharge les données de l'écran (mêmes méthodes qu'à son ouverture).
  void onLiveUpdate();

  @override
  void initState() {
    super.initState();
    LiveUpdates.instance.addListener(_handleLiveUpdate);
  }

  @override
  void dispose() {
    LiveUpdates.instance.removeListener(_handleLiveUpdate);
    super.dispose();
  }

  void _handleLiveUpdate() {
    if (mounted) onLiveUpdate();
  }
}
