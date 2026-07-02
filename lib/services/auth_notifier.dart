import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase/supabase.dart';

// Lauscht auf Supabase Auth-State-Änderungen und benachrichtigt den GoRouter.
class AuthNotifier extends ChangeNotifier {
  StreamSubscription<AuthState>? _subscription;

  void attach(SupabaseClient client) {
    _subscription?.cancel();
    _subscription = client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final authNotifier = AuthNotifier();
