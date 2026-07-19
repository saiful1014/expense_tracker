import 'package:flutter/material.dart';
import '../services/cloud_sync_service.dart';
import '../presentation/widgets/user_profile_card.dart';
import '../presentation/widgets/google_sign_in_button.dart';
import '../presentation/widgets/disable_sync_button.dart';
import '../presentation/widgets/sync_info_card.dart';

class SyncSetupScreen extends StatefulWidget {
  const SyncSetupScreen({super.key});

  @override
  State<SyncSetupScreen> createState() => _SyncSetupScreenState();
}

class _SyncSetupScreenState extends State<SyncSetupScreen> {
  final CloudSyncService _syncService = CloudSyncService();
  bool _isLoading = false;
  bool _isSignedIn = false;
  String? _userEmail;
  String? _userName;
  String? _userPhotoUrl;

  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
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
          Navigator.pop(context, true);
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
      
      final errorMessage = e.toString().contains('No internet connection')
          ? 'No internet connection'
          : 'Failed to sign in. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _disableCloudSync() async {
    setState(() => _isLoading = true);
    await _syncService.signOut();
    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
      _isSignedIn = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cloud sync disabled.'),
        backgroundColor: Colors.orange,
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Sync'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
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
    );
  }
}
