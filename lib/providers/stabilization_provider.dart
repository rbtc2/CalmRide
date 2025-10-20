import 'package:flutter/material.dart';
import '../models/app_enums.dart';

/// 멀미 방지 시스템 상태를 관리하는 Provider
class StabilizationProvider extends ChangeNotifier {
  bool _isActive = false;
  StabilizationMode _currentMode = StabilizationMode.dot;
  AppState _appState = AppState.inactive;

  // Getters
  bool get isActive => _isActive;
  StabilizationMode get currentMode => _currentMode;
  AppState get appState => _appState;

  /// 멀미 방지 시스템 활성화/비활성화
  void toggleStabilization() {
    _isActive = !_isActive;
    _appState = _isActive ? AppState.active : AppState.inactive;
    notifyListeners();
  }

  /// 멀미 방지 시스템 활성화
  void activateStabilization() {
    if (!_isActive) {
      _isActive = true;
      _appState = AppState.active;
      notifyListeners();
    }
  }

  /// 멀미 방지 시스템 비활성화
  void deactivateStabilization() {
    if (_isActive) {
      _isActive = false;
      _appState = AppState.inactive;
      notifyListeners();
    }
  }

  /// 안정화 모드 변경
  void changeMode(StabilizationMode mode) {
    _currentMode = mode;
    notifyListeners();
  }

  /// 앱 상태 변경
  void updateAppState(AppState state) {
    _appState = state;
    notifyListeners();
  }

  /// 시스템 일시정지
  void pauseStabilization() {
    if (_isActive) {
      _appState = AppState.paused;
      notifyListeners();
    }
  }

  /// 시스템 재개
  void resumeStabilization() {
    if (_isActive && _appState == AppState.paused) {
      _appState = AppState.active;
      notifyListeners();
    }
  }
}
