import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dhan_mitra/components/models/mutual_funds/sip_engine.dart';
import 'package:dhan_mitra/components/models/mutual_funds/swp_engine.dart';
import 'package:dhan_mitra/components/models/mutual_funds/mutual_fund_nav_simulator.dart';

class FinancialEngineRunner {
  static bool _isRunning = false;

  static Future<void> runOnce() async {
    if (_isRunning) return;
    _isRunning = true;

    try {
      await MutualFundNAVUpdater().updateAllNAV();
      await SIPEngine().processSIPs();
      await SWPEngine().processSWP();
    } catch (_) {}

    _isRunning = false;
  }
}

