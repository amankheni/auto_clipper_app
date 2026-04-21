import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

// ── App dark palette ──────────────────────────────────────────────────
const _kBg = Color(0xFF0A0E1A);
const _kCard = Color(0xFF111827);
const _kCardAlt = Color(0xFF1F2937);
const _kOrange = Color(0xFFFF6B35);
const _kPink = Color(0xFFE91E63);
const _kPurple = Color(0xFF9C27B0);
const _kGreen = Color(0xFF25D366);
const _kBlue = Color(0xFF6C63FF);
const _kCoral = Color(0xFFFF6584);
const _kCyan = Color(0xFF00BCD4);

class _SettingItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final List<String> tags;
  final Future<void> Function(BuildContext) onTap;

  const _SettingItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.tags,
    required this.onTap,
  });
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardFadeAnims;
  late List<Animation<Offset>> _cardSlideAnims;

  String _appVersion = '';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Support email
  static const String _supportEmail = 'honorixinnovation@gmail.com';

  late final List<_SettingItem> _items = [
    _SettingItem(
      title: 'Share App',
      subtitle: 'Invite friends to use Video Clipper',
      icon: Icons.share_rounded,
      gradientColors: [_kBlue, _kCoral],
      tags: ['WhatsApp', 'Social', 'Invite'],
      onTap: _shareApp,
    ),
    _SettingItem(
      title: 'Send Feedback',
      subtitle: 'Report bugs or issues — email us directly',
      icon: Icons.bug_report_outlined,
      gradientColors: [_kOrange, _kPink],
      tags: ['Bug report', 'Issues', 'Email'],
      onTap: _sendFeedback,
    ),
    _SettingItem(
      title: 'Suggestion',
      subtitle: 'Share your ideas to improve the app',
      icon: Icons.lightbulb_outline_rounded,
      gradientColors: [_kGreen, _kCyan],
      tags: ['Ideas', 'Feature request', 'Improve'],
      onTap: _openSuggestionDialog,
    ),
    _SettingItem(
      title: 'Rate Us ⭐',
      subtitle: 'Love the app? Give us 5 stars!',
      icon: Icons.star_rounded,
      gradientColors: [_kPurple, _kBlue],
      tags: ['Play Store', '5 Stars', 'Review'],
      onTap: _rateUs,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _setupAnimations();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = info.version);
    } catch (_) {}
  }

  void _setupAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _cardControllers = List.generate(
      _items.length,
      (_) => AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      ),
    );

    _cardFadeAnims =
        _cardControllers
            .map(
              (c) => Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutBack)),
            )
            .toList();

    _cardSlideAnims =
        _cardControllers
            .map(
              (c) => Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)),
            )
            .toList();

    for (int i = 0; i < _cardControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 200 + i * 150), () {
        if (mounted) _cardControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    for (final c in _cardControllers) c.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════
  // ACTIONS
  // ══════════════════════════════════════════════════════════════════

  // 1. Share App
  Future<void> _shareApp(BuildContext ctx) async {
    HapticFeedback.mediumImpact();
    try {
      await Share.share(
        '🎬 Check out Video Clipper — Split long videos instantly!\n\n'
        'Download free: https://play.google.com/store/apps/details?id=com.honorixinnovation.auto_clipper\n\n'
        '✂️ Split videos for WhatsApp, Reels, YouTube Shorts & more!',
        subject: 'Video Clipper App',
      );
    } catch (e) {
      _showSnack(ctx, 'Could not open share sheet', isError: true);
    }
  }

  // 2. ✅ Send Feedback — Direct Gmail open
  Future<void> _sendFeedback(BuildContext ctx) async {
    HapticFeedback.mediumImpact();
    final version = _appVersion.isNotEmpty ? _appVersion : 'Unknown';

    final subject = Uri.encodeComponent('Video Clipper — Feedback (v$version)');
    final body = Uri.encodeComponent(
      'Hi Honorix Team,\n\n'
      'I want to share the following feedback:\n\n'
      '[Write your feedback here]\n\n'
      '---\n'
      'App Version: $version\n',
    );

    // Gmail app direct open
    final gmailUri = Uri.parse(
      'googlegmail://co?to=$_supportEmail&subject=$subject&body=$body',
    );
    // Fallback — any mail app
    final mailtoUri = Uri.parse(
      'mailto:$_supportEmail?subject=$subject&body=$body',
    );

    try {
      // 🔹 Try Gmail app first
      if (await canLaunchUrl(gmailUri)) {
        await launchUrl(
          gmailUri,
          mode: LaunchMode.externalApplication,
        );
        return;
      }

      // 🔹 Fallback: any email app
      if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(
          mailtoUri,
          mode: LaunchMode.externalApplication,
        );
        return;
      }

      // 🔹 Last fallback: copy email
      await Clipboard.setData(ClipboardData(text: _supportEmail));
      _showSnack(ctx, 'Email copied: $_supportEmail');
    } catch (e) {
      // 🔹 Safe fallback
      await Clipboard.setData(ClipboardData(text: _supportEmail));
      _showSnack(ctx, 'Email copied: $_supportEmail');
    }
  }

  // 3. ✅ Suggestion Dialog — Firestore save
  Future<void> _openSuggestionDialog(BuildContext ctx) async {
    HapticFeedback.mediumImpact();

    // ✅ FIX: Separate StatefulWidget — controllers lifecycle safe
    await showDialog(
      context: ctx,
      barrierColor: Colors.black.withOpacity(0.75),
      barrierDismissible: true,
      builder:
          (_) => _SuggestionDialog(
            appVersion: _appVersion,
            onSuccess: () {
              // ✅ Called after dialog closed — safe context
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 16.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '✅ Suggestion submitted! Thank you 🙏',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: _kGreen,
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.all(16.r),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
    );
  }

  // ✅ Save to Firestore — suggestions collection
  Future<bool> _saveSuggestion({
    required String improve,
    required String newFeature,
    required String other,
  }) async {
    try {
      await _firestore.collection('suggestions').add({
        'improve': improve,
        'new_feature': newFeature,
        'other': other,
        'app_version': _appVersion,
        'platform': 'android',
        'created_at': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Suggestion saved to Firestore');
      return true;
    } catch (e) {
      debugPrint('❌ Firestore save error: $e');
      return false;
    }
  }

  // 4. Rate Us
  Future<void> _rateUs(BuildContext ctx) async {
    HapticFeedback.mediumImpact();
    const pkg = 'com.honorixinnovation.auto_clipper';
    final storeUri = Uri.parse('market://details?id=$pkg&reviewId=0');
    final webUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$pkg&reviewId=0',
    );
    try {
      if (await canLaunchUrl(storeUri)) {
        await launchUrl(storeUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        _showSnack(ctx, 'Could not open Play Store', isError: true);
      }
    }
  }

  // ── Snackbar ──────────────────────────────────────────────────────
  void _showSnack(BuildContext ctx, String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 16.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                msg,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFEF4444) : _kGreen,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.r),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Field builders ────────────────────────────────────────────────
  Widget _buildLabel(String text) => Text(
    text,
    style: TextStyle(
      color: Colors.white70,
      fontSize: 12.sp,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardAlt,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.white, fontSize: 13.sp),
        cursorColor: _kGreen,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white30, fontSize: 12.sp),
          prefixIcon:
              maxLines == 1
                  ? Icon(icon, color: Colors.white30, size: 18.sp)
                  : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 14.w,
            vertical: 12.h,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _headerController,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_kBlue, _kCoral],
                              ),
                              borderRadius: BorderRadius.circular(14.r),
                              boxShadow: [
                                BoxShadow(
                                  color: _kBlue.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.settings_rounded,
                              color: Colors.white,
                              size: 22.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Settings',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'App preferences & support',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),

                      // Version banner
                      Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _kBlue.withOpacity(0.15),
                              _kCoral.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: _kBlue.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Text('✂️', style: TextStyle(fontSize: 22.sp)),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Video Clipper',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    _appVersion.isNotEmpty
                                        ? 'Version $_appVersion'
                                        : 'Loading...',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 5.h,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_kBlue, _kCoral],
                                ),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                'v${_appVersion.isNotEmpty ? _appVersion : "..."}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 4.h),
                child: Text(
                  'SUPPORT & FEEDBACK',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 30.h),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => AnimatedBuilder(
                    animation: _cardFadeAnims[i],
                    builder:
                        (ctx, _) => SlideTransition(
                          position: _cardSlideAnims[i],
                          child: FadeTransition(
                            opacity: _cardFadeAnims[i],
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 16.h),
                              child: _SettingCard(
                                item: _items[i],
                                onTap: () => _items[i].onTap(context),
                              ),
                            ),
                          ),
                        ),
                  ),
                  childCount: _items.length,
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 32.h),
                child: Column(
                  children: [
                    Text(
                      'Made with ❤️ by Honorix Innovation',
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _appVersion.isNotEmpty
                          ? 'Video Clipper v$_appVersion'
                          : 'Video Clipper',
                      style: TextStyle(color: Colors.white12, fontSize: 11.sp),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Setting Card — FeaturesHub exact style
// ══════════════════════════════════════════════════════════════════════
class _SettingCard extends StatefulWidget {
  final _SettingItem item;
  final VoidCallback onTap;

  const _SettingCard({required this.item, required this.onTap});

  @override
  State<_SettingCard> createState() => _SettingCardState();
}

class _SettingCardState extends State<_SettingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pc;
  late Animation<double> _sc;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pc = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _sc = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _pc, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final g = item.gradientColors;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        _pc.forward();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        _pc.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        _pc.reverse();
      },
      child: ScaleTransition(
        scale: _sc,
        child: Container(
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color:
                  _pressed
                      ? g[0].withOpacity(0.5)
                      : Colors.white.withOpacity(0.07),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: g[0].withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top strip
              Container(
                height: 110.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      g[0].withOpacity(0.25),
                      g[1].withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.r),
                    topRight: Radius.circular(20.r),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 90.w,
                        height: 90.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: g[0].withOpacity(0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 20,
                      bottom: -10,
                      child: Container(
                        width: 55.w,
                        height: 55.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: g[1].withOpacity(0.06),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(14.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: g),
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: [
                                BoxShadow(
                                  color: g[0].withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              item.icon,
                              color: Colors.white,
                              size: 24.sp,
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  item.subtitle,
                                  style: TextStyle(
                                    color: g[0],
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white54,
                              size: 13.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tags
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 14.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12.sp,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 6.h,
                      children:
                          item.tags
                              .map(
                                (tag) => Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: g[0].withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(
                                      color: g[0].withOpacity(0.25),
                                    ),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      color: g[0],
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionDialog extends StatefulWidget {
  final String appVersion;
  final VoidCallback onSuccess;

  const _SuggestionDialog({required this.appVersion, required this.onSuccess});

  @override
  State<_SuggestionDialog> createState() => _SuggestionDialogState();
}

class _SuggestionDialogState extends State<_SuggestionDialog> {
  // ✅ Controllers lifecycle — managed by this widget's State
  final _improveCtrl = TextEditingController();
  final _newFeatureCtrl = TextEditingController();
  final _otherCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    // ✅ Safe dispose — only when widget actually removed
    _improveCtrl.dispose();
    _newFeatureCtrl.dispose();
    _otherCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_improveCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill "What to improve" field',
            style: TextStyle(color: Colors.white, fontSize: 13.sp),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16.r),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('suggestions').add({
        'improve': _improveCtrl.text.trim(),
        'new_feature': _newFeatureCtrl.text.trim(),
        'other': _otherCtrl.text.trim(),
        'app_version': widget.appVersion,
        'platform': 'android',
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      // ✅ Close dialog first
      Navigator.of(context).pop();
      // ✅ Then notify parent via callback
      widget.onSuccess();
    } catch (e) {
      debugPrint('❌ Firestore error: $e');
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to submit. Try again.',
            style: TextStyle(color: Colors.white, fontSize: 13.sp),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16.r),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: _kGreen.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_kGreen, _kCyan]),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share Suggestion',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Help us improve Video Clipper',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white54,
                        size: 16.sp,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),
              _label('What should we improve? *'),
              SizedBox(height: 6.h),
              _field(
                controller: _improveCtrl,
                hint: 'e.g. Faster processing, better UI...',
                icon: Icons.build_outlined,
                maxLines: 3,
              ),

              SizedBox(height: 14.h),
              _label('New feature you want?'),
              SizedBox(height: 6.h),
              _field(
                controller: _newFeatureCtrl,
                hint: 'e.g. Batch processing, watermark...',
                icon: Icons.add_circle_outline,
                maxLines: 3,
              ),

              SizedBox(height: 14.h),
              _label('Anything else?'),
              SizedBox(height: 6.h),
              _field(
                controller: _otherCtrl,
                hint: 'Any other thoughts...',
                icon: Icons.chat_bubble_outline,
                maxLines: 2,
              ),

              SizedBox(height: 20.h),

              // ── Submit button ────────────────────────────────
              GestureDetector(
                onTap: _isSaving ? null : _submit,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 50.h,
                  decoration: BoxDecoration(
                    gradient:
                        _isSaving
                            ? null
                            : const LinearGradient(colors: [_kGreen, _kCyan]),
                    color: _isSaving ? Colors.white.withOpacity(0.06) : null,
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow:
                        _isSaving
                            ? []
                            : [
                              BoxShadow(
                                color: _kGreen.withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                  ),
                  child: Center(
                    child:
                        _isSaving
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: _kGreen,
                                strokeWidth: 2.5,
                              ),
                            )
                            : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 18.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Submit Suggestion',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────
  Widget _label(String text) => Text(
    text,
    style: TextStyle(
      color: Colors.white70,
      fontSize: 12.sp,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardAlt,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.white, fontSize: 13.sp),
        cursorColor: _kGreen,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.transparent,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white30, fontSize: 12.sp),
          prefixIcon:
              maxLines == 1
                  ? Icon(icon, color: Colors.white30, size: 18.sp)
                  : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 14.w,
            vertical: 12.h,
          ),
        ),
      ),
    );
  }
}
