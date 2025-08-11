// File: lib/screens/update_debug_screen.dart
// Add this screen to test your update functionality

import 'package:flutter/material.dart';
import 'package:auto_clipper_app/manager/update_manager.dart';

class UpdateDebugScreen extends StatefulWidget {
  const UpdateDebugScreen({Key? key}) : super(key: key);

  @override
  State<UpdateDebugScreen> createState() => _UpdateDebugScreenState();
}

class _UpdateDebugScreenState extends State<UpdateDebugScreen> {
  final UpdateManager _updateManager = UpdateManager();
  bool _isLoading = false;
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Wait a moment for initialization
      await Future.delayed(const Duration(milliseconds: 500));

      final info = StringBuffer();
      info.writeln('=== UPDATE MANAGER DEBUG INFO ===\n');

      info.writeln('📋 Initialization Status:');
      info.writeln('  - Is Initialized: ${_updateManager.isInitialized}');
      info.writeln('');

      if (_updateManager.isInitialized) {
        info.writeln('📱 Current App Info:');
        info.writeln('  - Version Name: ${_updateManager.currentVersionName}');
        info.writeln('  - Version Code: ${_updateManager.currentVersionCode}');
        info.writeln('');

        info.writeln('☁️ Remote Config Values:');
        info.writeln(
          '  - Latest Version Code: ${_updateManager.latestVersionCode}',
        );
        info.writeln('  - Update Enabled: ${_updateManager.isUpdateEnabled}');
        info.writeln('  - Force Update: ${_updateManager.isForceUpdate}');
        info.writeln('');

        info.writeln('🔍 Update Check Results:');
        info.writeln(
          '  - Is Update Available: ${_updateManager.isUpdateAvailable}',
        );
        info.writeln(
          '  - Comparison: ${_updateManager.currentVersionCode} < ${_updateManager.latestVersionCode}',
        );
        info.writeln('');

        info.writeln('📝 Messages:');
        info.writeln('  - Update Message: ${_updateManager.updateMessage}');
        info.writeln('');

        info.writeln('🔗 Store URL:');
        info.writeln('  - Play Store: ${_updateManager.playStoreUrl}');
      } else {
        info.writeln('❌ UpdateManager is not initialized!');
        info.writeln(
          'Make sure to call UpdateManager().initialize() in main()',
        );
      }

      setState(() {
        _debugInfo = info.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugInfo = 'Error loading debug info: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testUpdateCheck() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _updateManager.checkForUpdates(context, silent: false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _forceRefreshAndCheck() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _updateManager.forceRefresh();
      await _updateManager.checkForUpdates(context, silent: false);
      await _loadDebugInfo(); // Reload debug info
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Manager Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Action buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _testUpdateCheck,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Test Update Check'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _forceRefreshAndCheck,
                            icon: const Icon(Icons.cloud_download),
                            label: const Text('Force Refresh & Check'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _loadDebugInfo,
                            icon: const Icon(Icons.info),
                            label: const Text('Reload Debug Info'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(),

                  // Debug information
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            _debugInfo.isEmpty
                                ? 'Loading debug information...'
                                : _debugInfo,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
