import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'results_screen.dart';
import 'scanning_screen.dart';
import 'models/recognition_result.dart';


final GoRouter router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        final autoStart = state.uri.queryParameters['autoStart'] == 'true';
        final timestamp = state.uri.queryParameters['t'] ?? '0';
        // Clé unique pour forcer la reconstruction du widget
        return HomeScreen(
          key: ValueKey('home_$autoStart\_$timestamp'),
          autoStart: autoStart,
        );
      },
      routes: <RouteBase>[
        // AnalysisScreen removed.
        // We navigate directly from Home -> ImagePicker -> ScanningScreen (pushed) -> ResultsScreen (pushed or routed)

        GoRoute(
          path: 'results', // Changed from /analysis/results to /results
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return ResultsScreen(
              imageFile: extra['imageFile'] as File,
              currencyResult: extra['result'] as CurrencyResult,
            );
          },
        ),
      ],
    ),
  ],
);
