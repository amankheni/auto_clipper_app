// File: lib/manager/update_manager.dart

import 'dart:io';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Manages app updates using Firebase Remote Config
/// Handles version checking, dialog display, and Play Store redirection
class UpdateManager {
  // Singleton pattern
  static final UpdateManager _instance = UpdateManager._internal();
  factory UpdateManager() => _instance;
  UpdateManager._internal();

  FirebaseRemoteConfig? _remoteConfig;
  PackageInfo? _packageInfo;

  // Cache values to avoid repeated calls
  bool _isInitialized = false;

  /// Initialize the UpdateManager - Call this in main() after Firebase.initializeApp()
  Future<void> initialize() async {
    try {
      debugPrint('UpdateManager: Initializing...');

      // Initialize Remote Config
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Configure Remote Config settings
      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(
            hours: 1,
          ), // Fetch at most once per hour
        ),
      );

      // Set default values for Remote Config parameters
      await _remoteConfig!.setDefaults({
        'latest_version_code': 1,
        'force_update': false,
        'update_message':
            'A new version is available with bug fixes and improvements. Update now for the best experience!',
        'force_update_message':
            'This version is no longer supported. Please update immediately to continue using the app.',
        'update_enabled': true, // Global flag to enable/disable update checks
        'play_store_url':
            'https://play.google.com/store/apps/details?id=com.honorixinnovation.auto_clipper',
      });

      // Get current app package information
      _packageInfo = await PackageInfo.fromPlatform();

      debugPrint(
        'UpdateManager: Current version - ${_packageInfo!.version} (${_packageInfo!.buildNumber})',
      );

      // Perform initial fetch of remote config
      await _fetchRemoteConfig();

      _isInitialized = true;
      debugPrint('UpdateManager: Initialization complete');
    } catch (e) {
      debugPrint('UpdateManager: Initialization error - $e');
      _isInitialized = false;
    }
  }

  /// Fetch latest values from Firebase Remote Config
  Future<void> _fetchRemoteConfig() async {
    try {
      await _remoteConfig!.fetchAndActivate();
      debugPrint('UpdateManager: Remote config fetched successfully');
    } catch (e) {
      debugPrint('UpdateManager: Error fetching remote config - $e');
    }
  }

  /// Check if update functionality is enabled
  bool get isUpdateEnabled {
    return _remoteConfig?.getBool('update_enabled') ?? true;
  }

  /// Check if a new version is available
  bool get isUpdateAvailable {
    if (_remoteConfig == null || _packageInfo == null || !isUpdateEnabled) {
      return false;
    }

    final latestVersionCode = _remoteConfig!.getInt('latest_version_code');
    final currentVersionCode = int.tryParse(_packageInfo!.buildNumber) ?? 0;

    debugPrint(
      'UpdateManager: Comparing versions - Current: $currentVersionCode, Latest: $latestVersionCode',
    );

    return currentVersionCode < latestVersionCode;
  }

  /// Check if this is a mandatory update
  bool get isForceUpdate {
    if (_remoteConfig == null) return false;
    return _remoteConfig!.getBool('force_update');
  }

  /// Get the appropriate update message
  String get updateMessage {
    if (_remoteConfig == null) {
      return 'A new version is available. Please update to continue.';
    }

    return isForceUpdate
        ? _remoteConfig!.getString('force_update_message')
        : _remoteConfig!.getString('update_message');
  }

  /// Get latest version code from Remote Config
  int get latestVersionCode {
    return _remoteConfig?.getInt('latest_version_code') ?? 1;
  }

  /// Get current app version code
  int get currentVersionCode {
    return int.tryParse(_packageInfo?.buildNumber ?? '1') ?? 1;
  }

  /// Get current app version name
  String get currentVersionName {
    return _packageInfo?.version ?? '1.0.0';
  }

  /// Get Play Store URL
  String get playStoreUrl {
    final configUrl = _remoteConfig?.getString('play_store_url');
    if (configUrl != null && configUrl.isNotEmpty) {
      return configUrl;
    }

    final packageName =
        _packageInfo?.packageName ?? 'com.honorixinnovation.auto_clipper';
    return Platform.isAndroid
        ? 'https://play.google.com/store/apps/details?id=$packageName'
        : 'https://apps.apple.com/app/id$packageName';
  }

  /// Main method to check for updates and show dialog if needed
  Future<void> checkForUpdates(
    BuildContext context, {
    bool silent = false,
  }) async {
    debugPrint('=== UPDATE CHECK STARTED ===');

    if (!_isInitialized) {
      debugPrint('❌ UpdateManager: Not initialized, skipping update check');
      if (!silent) {
        _showErrorSnackBar(context, 'Update service not initialized');
      }
      return;
    }

    if (_remoteConfig == null) {
      debugPrint('❌ UpdateManager: Remote config is null');
      if (!silent) {
        _showErrorSnackBar(context, 'Remote config not available');
      }
      return;
    }

    if (_packageInfo == null) {
      debugPrint('❌ UpdateManager: Package info is null');
      if (!silent) {
        _showErrorSnackBar(context, 'Package info not available');
      }
      return;
    }

    try {
      debugPrint('🔍 UpdateManager: Starting update check...');

      // Refresh remote config to get latest values
      debugPrint('🔄 Fetching remote config...');
      await _fetchRemoteConfig();

      // Debug current state
      debugPrint('📱 Current app info:');
      debugPrint('   - Package: ${_packageInfo!.packageName}');
      debugPrint('   - Version Name: ${_packageInfo!.version}');
      debugPrint('   - Version Code: ${_packageInfo!.buildNumber}');
      debugPrint('   - Current Version Code (parsed): $currentVersionCode');

      debugPrint('☁️ Remote config values:');
      debugPrint('   - Latest Version Code: $latestVersionCode');
      debugPrint('   - Force Update: $isForceUpdate');
      debugPrint('   - Update Enabled: $isUpdateEnabled');
      debugPrint('   - Update Message: $updateMessage');

      debugPrint('🔍 Version comparison:');
      debugPrint('   - Current: $currentVersionCode');
      debugPrint('   - Latest: $latestVersionCode');
      debugPrint('   - Is Update Available: $isUpdateAvailable');
      debugPrint('   - Is Update Enabled: $isUpdateEnabled');

      if (!isUpdateEnabled) {
        debugPrint('⚠️ Update checks are disabled via remote config');
        if (!silent) {
          _showNoUpdateSnackBar(
            context,
            'Update checks are currently disabled',
          );
        }
        return;
      }

      if (isUpdateAvailable) {
        debugPrint('✅ Update available! Showing dialog...');
        debugPrint('   - Context mounted: ${context.mounted}');

        if (context.mounted) {
          _showUpdateDialog(context);
          debugPrint('✅ Dialog displayed successfully');
        } else {
          debugPrint('❌ Context not mounted, cannot show dialog');
        }
      } else {
        debugPrint('ℹ️ No update available');
        if (!silent) {
          _showNoUpdateSnackBar(context, 'You are using the latest version!');
        }
      }

      debugPrint('=== UPDATE CHECK COMPLETED ===');
    } catch (e, stackTrace) {
      debugPrint('❌ UpdateManager: Error checking for updates - $e');
      debugPrint('Stack trace: $stackTrace');
      if (!silent) {
        _showErrorSnackBar(context, 'Error checking for updates: $e');
      }
    }
  }

  /// Show update dialog with appropriate options
  void _showUpdateDialog(BuildContext context) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: !isForceUpdate,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: !isForceUpdate,
          child: UpdateDialog(
            message: updateMessage,
            isForceUpdate: isForceUpdate,
            currentVersion: currentVersionName,
            latestVersionCode: latestVersionCode,
            onUpdate: () async {
              Navigator.of(dialogContext).pop();
              await _openPlayStore();
            },
            onLater:
                isForceUpdate ? null : () => Navigator.of(dialogContext).pop(),
          ),
        );
      },
    );
  }

  /// Show snackbar when no update is available (for manual checks)
  void _showNoUpdateSnackBar(BuildContext context, [String? message]) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'You are using the latest version!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Open Play Store for app update
  Future<void> _openPlayStore() async {
    try {
      final uri = Uri.parse(playStoreUrl);

      debugPrint('UpdateManager: Opening Play Store - $playStoreUrl');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('UpdateManager: Could not launch Play Store URL');
      }
    } catch (e) {
      debugPrint('UpdateManager: Error opening Play Store - $e');
    }
  }

  /// Force refresh remote config (useful for testing)
  Future<void> forceRefresh() async {
    if (_remoteConfig == null) return;

    try {
      debugPrint('UpdateManager: Force refreshing remote config...');
      await _remoteConfig!.fetch();
      await _remoteConfig!.activate();
      debugPrint('UpdateManager: Force refresh complete');
    } catch (e) {
      debugPrint('UpdateManager: Error during force refresh - $e');
    }
  }

  /// Get initialization status
  bool get isInitialized => _isInitialized;
}

/// Custom Update Dialog Widget
class UpdateDialog extends StatelessWidget {
  final String message;
  final bool isForceUpdate;
  final String currentVersion;
  final int latestVersionCode;
  final VoidCallback onUpdate;
  final VoidCallback? onLater;

  const UpdateDialog({
    Key? key,
    required this.message,
    required this.isForceUpdate,
    required this.currentVersion,
    required this.latestVersionCode,
    required this.onUpdate,
    this.onLater,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(0),
      content: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              (isForceUpdate ? Colors.red : Colors.blue).withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isForceUpdate ? Colors.red : Colors.blue)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isForceUpdate
                        ? Icons.warning_rounded
                        : Icons.system_update_rounded,
                    color: isForceUpdate ? Colors.red : Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isForceUpdate ? 'Update Required' : 'Update Available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isForceUpdate ? Colors.red : Colors.blue,
                        ),
                      ),
                      Text(
                        'Version $currentVersion → $latestVersionCode',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Update message
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
                color: Colors.black87,
              ),
            ),

            // Force update warning (if applicable)
            if (isForceUpdate) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.red.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This update is mandatory to continue using the app.',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Later button (only for optional updates)
                if (!isForceUpdate && onLater != null) ...[
                  TextButton(
                    onPressed: onLater,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Later', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 8),
                ],

                // Update button
                ElevatedButton(
                  onPressed: onUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isForceUpdate ? Colors.red : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.download_rounded, size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        'Update',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
