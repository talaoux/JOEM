import 'package:flutter/material.dart';

/// Observateur de navigation partagé, enregistré sur le `MaterialApp`
/// (`main.dart`) — permet à un écran (les deux dashboards, en particulier)
/// de savoir qu'il redevient visible après qu'un sous-écran a été fermé,
/// même quand ce retour se fait en plusieurs sauts (`pushReplacement` entre
/// écrans de la nav basse puis `popUntil` vers le dashboard) plutôt que par
/// un simple `pop` que le dashboard aurait lui-même attendu.
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
