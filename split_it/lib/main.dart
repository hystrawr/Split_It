import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_routes.dart';
import 'providers/balance_provider.dart';
import 'providers/currency_provider.dart';
import 'providers/group_provider.dart';
import 'providers/home_provider.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const SplitItApp());
}

class SplitItApp extends StatelessWidget {
  const SplitItApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The providers sit above MaterialApp so every screen can reach them
    // with context.watch / context.read, without passing data through
    // constructors.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GroupProvider()..loadGroups()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()..loadRates()),
        // BalanceProvider is calculated from the groups, so it is rebuilt
        // with the latest GroupProvider every time the groups change.
        ChangeNotifierProxyProvider<GroupProvider, BalanceProvider>(
          create: (_) => BalanceProvider(),
          update: (_, groups, balances) =>
              (balances ?? BalanceProvider())..updateGroups(groups),
        ),
        // HomeProvider puts the groups and balances together for Home.
        ChangeNotifierProxyProvider2<
          GroupProvider,
          BalanceProvider,
          HomeProvider
        >(
          create: (_) => HomeProvider()..loadUserName(),
          update: (_, groups, balances, home) =>
              (home ?? HomeProvider())..update(groups, balances),
        ),
      ],
      child: MaterialApp(
        title: 'Split It',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.home,
        routes: AppRoutes.routes,
      ),
    );
  }
}
