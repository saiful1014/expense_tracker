import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:test_new_things/data/services/cloud_sync_service.dart';
import 'package:test_new_things/data/services/exception_handler.dart';
import 'package:test_new_things/data/services/database_helper.dart';
import 'package:test_new_things/ui/features/sync/views/widgets/user_profile_card.dart';
import 'package:test_new_things/ui/features/sync/views/widgets/google_sign_in_button.dart';
import 'package:test_new_things/ui/features/sync/views/widgets/disable_sync_button.dart';
import 'package:test_new_things/ui/features/sync/views/widgets/sync_info_card.dart';

class SyncSetupScreen extends StatefulWidget {
  const SyncSetupScreen({super.key});

  @override
  State<SyncSetupScreen> createState() => _SyncSetupScreenState();
}

class _SyncSetupScreenState extends State<SyncSetupScreen> {
  late final CloudSyncService _syncService;
  bool _isLoading = false;
  bool _isSignedIn = false;
  String? _userEmail;
  String? _userName;
  String? _userPhotoUrl;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _syncService = context.read<CloudSyncService>();
      _checkSignInStatus();
      _initialized = true;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _checkSignInStatus() async {
    final isSignedIn = await _syncService.isSignedIn();
    if (!mounted) return;
    
    setState(() {
      _isSignedIn = isSignedIn;
      if (isSignedIn) {
        _userEmail = _syncService.getUserEmail();
        _userName = _syncService.getUserName();
        _userPhotoUrl = _syncService.getUserPhotoUrl();
      }
    });
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    
    try {
      final success = await _syncService.signInWithGoogle();
      if (!mounted) return;
      
      if (success) {
        await _checkSignInStatus();
      }
      
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Signed in as ${_userName ?? _userEmail ?? "User"}! Your data will sync across devices.'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign-in canceled or failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      final errorMessage = ExceptionHandler.mapNetworkError(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _disableCloudSync() async {
    setState(() => _isLoading = true);
    await _syncService.signOut();
    await DatabaseHelper.instance.clearDatabase();
    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
      _isSignedIn = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logged out. Local data cleared from this device.'),
        backgroundColor: Colors.blue,
      ),
    );
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Sync'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UserProfileCard(
                isSignedIn: _isSignedIn,
                userName: _userName,
                userEmail: _userEmail,
                userPhotoUrl: _userPhotoUrl,
                description: _isSignedIn
                    ? 'Your data is syncing to the cloud. You can access it from any device using the same Google account.'
                    : 'Sign in with Google to sync your expenses and borrow/lend data across all your devices.',
              ),
              const SizedBox(height: 24),
              if (!_isSignedIn)
                GoogleSignInButton(
                  isLoading: _isLoading,
                  onPressed: _signInWithGoogle,
                )
              else
                DisableSyncButton(
                  isLoading: _isLoading,
                  onPressed: _disableCloudSync,
                ),
              const SizedBox(height: 16),
              const SyncInfoCard(),
            ],
          ),
        ),
      ),
    );
  }
}
