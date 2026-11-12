import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutorku/providers/app_state_provider.dart';
import 'package:tutorku/views/dashboard_view.dart';
import 'package:tutorku/views/jasa_crud_view.dart';
import 'package:tutorku/views/order_history_view.dart';
import 'package:tutorku/views/settings_view.dart';
import 'package:tutorku/views/theme.dart';

class MainShellView extends StatefulWidget {
  const MainShellView({super.key});

  @override
  State<MainShellView> createState() => _MainShellViewState();
}

class _MainShellViewState extends State<MainShellView> {
  late final PageController _pageController;
  late final AppStateProvider _provider;

  final List<Widget> _views = const [
    _KeepAliveWrapper(child: DashboardView()),
    _KeepAliveWrapper(child: JasaCrudView()),
    _KeepAliveWrapper(child: OrderHistoryView()),
    _KeepAliveWrapper(child: SettingsView()),
  ];

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<AppStateProvider>(context, listen: false);
    _pageController = PageController(initialPage: _provider.currentTabIndex);
    _provider.addListener(_onProviderTabIndexChanged);
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderTabIndexChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onProviderTabIndexChanged() {
    if (!mounted) return;
    if (_pageController.hasClients) {
      final targetIndex = _provider.currentTabIndex;
      if (_pageController.page?.round() != targetIndex) {
        _pageController.animateToPage(
          targetIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, provider, child) {
        final int activeIndex = provider.currentTabIndex;
        final double width = MediaQuery.of(context).size.width;
        final bool isWide = width > 750;

        if (isWide) {
          // Windows Desktop & Wide screens: Sidebar Navigation Rail
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: activeIndex,
                  onDestinationSelected: (index) {
                    provider.setTabIndex(index);
                  },
                  elevation: 2,
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: Theme.of(context).cardTheme.color,
                  selectedIconTheme: const IconThemeData(color: AppTheme.primaryColor, size: 28),
                  unselectedIconTheme: const IconThemeData(color: Colors.grey, size: 24),
                  selectedLabelTextStyle: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                  indicatorColor: AppTheme.primaryColor.withOpacity(0.12),
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Column(
                      children: [
                        provider.shopLogoPath != null && File(provider.shopLogoPath!).existsSync()
                            ? Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.borderColor),
                                  image: DecorationImage(
                                    image: FileImage(File(provider.shopLogoPath!)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.school,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                        const SizedBox(height: 8),
                        Text(
                          provider.shopName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.archive_outlined),
                      selectedIcon: Icon(Icons.archive),
                      label: Text('Jasa Les'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(Icons.receipt_long),
                      label: Text('Riwayat'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Pengaturan'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      provider.setTabIndex(index);
                    },
                    children: _views,
                  ),
                ),
              ],
            ),
          );
        } else {
          // Mobile: Bottom Navigation Bar with Swipe Support
          return Scaffold(
            body: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                provider.setTabIndex(index);
              },
              children: _views,
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: activeIndex,
              onDestinationSelected: (index) {
                provider.setTabIndex(index);
              },
              backgroundColor: Theme.of(context).cardTheme.color,
              indicatorColor: AppTheme.primaryColor.withOpacity(0.12),
              elevation: 8,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard, color: AppTheme.primaryColor),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.archive_outlined),
                  selectedIcon: Icon(Icons.archive, color: AppTheme.primaryColor),
                  label: 'Produk',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long, color: AppTheme.primaryColor),
                  label: 'Riwayat',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings, color: AppTheme.primaryColor),
                  label: 'Pengaturan',
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
