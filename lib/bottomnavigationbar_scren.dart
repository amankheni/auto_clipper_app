import 'package:auto_clipper_app/Logic/ad_service.dart';
import 'package:auto_clipper_app/Screens/Split_screen.dart';
import 'package:auto_clipper_app/Screens/features_hub_screen.dart';
import 'package:auto_clipper_app/Screens/settings_screen.dart';
import 'package:auto_clipper_app/Screens/video_download_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ─── Dark palette — FeaturesHubScreen exact ──────────────────────────────────
const _kDarkBg = Color(0xFF0A0E1A);
const _kDarkCard = Color(0xFF111827);
const _kGradOrange = Color(0xFFFF6B35);
const _kGradPink = Color(0xFFE91E63);
const _kGradPurple = Color(0xFF9C27B0);

const _primaryGradient = LinearGradient(
  colors: [_kGradOrange, _kGradPink, _kGradPurple],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class BottomNavigationScreen extends StatefulWidget {
  const BottomNavigationScreen({super.key});

  @override
  _BottomNavigationScreenState createState() => _BottomNavigationScreenState();
}

class _BottomNavigationScreenState extends State<BottomNavigationScreen>
    with AutomaticKeepAliveClientMixin {
  int _currentIndex = 0;

  // ✅ Track which tabs have been visited — lazy init
  // Only index 0 (SplitScreen) is built on app start
  final Set<int> _visitedTabs = {0};

  static const int _tabCount = 4;

  /// Returns the screen widget for a given tab index.
  /// Called only when that tab is visited for the first time.
  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const VideoSplitterScreen();
      case 1:
        return const FeaturesHubScreen();
      case 2:
        return const VideoDownloadScreen();
      case 3:
        return const SettingsScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdService.checkForUpdate();
    });
    // Dark status bar — matches FeaturesHubScreen dark bg
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.lightImpact();
    setState(() {
      // ✅ First visit: add to set → screen gets built and init() called
      // Subsequent visits: already in set → screen stays alive (no re-init)
      _visitedTabs.add(index);
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: _kDarkBg,

      // ✅ IndexedStack replaces PageView:
      //   - Only shows the current tab (others are hidden, not destroyed)
      //   - Un-visited tabs return SizedBox.shrink() → zero cost, no init
      //   - Once visited, screen stays in tree (ads/data stay loaded)
      //   - No swipe-between-tabs (prevents accidental loads)
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(_tabCount, (i) {
          if (!_visitedTabs.contains(i)) {
            // Tab not yet selected → placeholder, no widget built, no initState
            return const SizedBox.shrink();
          }
          return _buildScreen(i);
        }),
      ),

      bottomNavigationBar: _DarkBottomNav(
        currentIndex: _currentIndex,
        onTabTapped: _onTabTapped,
      ),
    );
  }
}

// ─── Dark bottom nav bar ──────────────────────────────────────────────────────

class _DarkBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabTapped;

  const _DarkBottomNav({required this.currentIndex, required this.onTabTapped});

  static const _items = [
    (Icons.content_cut_rounded, Icons.content_cut_outlined, 'Split'),
    (Icons.auto_awesome_rounded, Icons.auto_awesome_outlined, 'Tools'),
    (Icons.download_done_rounded, Icons.download_outlined, 'Downloads'),
    (Icons.settings, Icons.settings, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kDarkCard,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.07), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: _kGradPink.withValues(alpha: 0.05),
            blurRadius: 40,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64.h,
          child: Row(
            children:
            _items.asMap().entries.map((e) {
              final i = e.key;
              final (active, inactive, label) = e.value;
              return Expanded(
                child: _NavItem(
                  activeIcon: active,
                  inactiveIcon: inactive,
                  label: label,
                  isActive: currentIndex == i,
                  onTap: () => onTabTapped(i),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Nav item — press scale + gradient active state ───────────────────────────

class _NavItem extends StatefulWidget {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _pc;
  late Animation<double> _sc;

  @override
  void initState() {
    super.initState();
    _pc = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _sc = Tween<double>(
      begin: 1.0,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _pc, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _pc.forward(),
      onTapUp: (_) {
        _pc.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pc.reverse(),
      child: ScaleTransition(
        scale: _sc,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          decoration: BoxDecoration(
            color:
            widget.isActive
                ? _kGradPink.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14.r),
            border:
            widget.isActive
                ? Border.all(color: _kGradPink.withValues(alpha: 0.2))
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder:
                    (child, anim) => ScaleTransition(scale: anim, child: child),
                child:
                widget.isActive
                    ? ShaderMask(
                  key: ValueKey('a_${widget.label}'),
                  shaderCallback:
                      (b) => _primaryGradient.createShader(b),
                  child: Icon(
                    widget.activeIcon,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                )
                    : Icon(
                  widget.inactiveIcon,
                  key: ValueKey('n_${widget.label}'),
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 22.sp,
                ),
              ),
              SizedBox(height: 3.h),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight:
                  widget.isActive ? FontWeight.w700 : FontWeight.w400,
                  color:
                  widget.isActive
                      ? _kGradPink
                      : Colors.white.withValues(alpha: 0.3),
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}