// ignore_for_file: file_names
// lib/Controller/ThemeController.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static ThemeController get to => Get.find();

  static const _key = 'app_theme_dark';

  final _isDark = false.obs;

  bool get isDark => _isDark.value;
  ThemeMode get themeMode => _isDark.value ? ThemeMode.dark : ThemeMode.light;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDark.value = prefs.getBool(_key) ?? false;
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, _isDark.value);
    } catch (_) {}
  }

  void toggle() {
    _isDark.value = !_isDark.value;
    Get.changeThemeMode(themeMode);
    _save();
  }

  void setDark()  { _isDark.value = true;  Get.changeThemeMode(ThemeMode.dark);  _save(); }
  void setLight() { _isDark.value = false; Get.changeThemeMode(ThemeMode.light); _save(); }
}