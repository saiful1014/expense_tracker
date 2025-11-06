import 'package:flutter/material.dart';
import '../services/cloud_sync_service.dart';

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
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
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
  }

  Future<void> _disableCloudSync() async {
    setState(() => _isLoading = true);
    await _syncService.signOut();
    setState(() {
      _isLoading = false;
      _isSignedIn = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cloud sync disabled.'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pop(context, true);
    }
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_isSignedIn && _userPhotoUrl != null)
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(_userPhotoUrl!),
                          )
                        else
                          Icon(
                            Icons.cloud,
                            size: 32,
                            color: Colors.blue.shade700,
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isSignedIn ? (_userName ?? 'Signed In') : 'Cloud Sync',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_isSignedIn && _userEmail != null)
                                Text(
                                  _userEmail!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_isSignedIn)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isSignedIn
                          ? 'Your data is syncing to the cloud. You can access it from any device using the same Google account.'
                          : 'Sign in with Google to sync your expenses and borrow/lend data across all your devices.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!_isSignedIn)
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login, color: Colors.black87),
                label: Text(_isLoading ? 'Signing in...' : 'Sign in with Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  elevation: 1,
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _disableCloudSync,
                icon: const Icon(Icons.cloud_off),
                label: const Text('Disable Cloud Sync'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'How it works',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Sign in with your Google account\n'
                      '• Your data is stored securely in the cloud\n'
                      '• Access your expenses from any device\n'
                      '• Changes sync automatically\n'
                      '• Works offline - syncs when online',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
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

