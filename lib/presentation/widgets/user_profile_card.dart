import 'package:flutter/material.dart';

class UserProfileCard extends StatelessWidget {
  final bool isSignedIn;
  final String? userName;
  final String? userEmail;
  final String? userPhotoUrl;
  final String description;

  const UserProfileCard({
    super.key,
    required this.isSignedIn,
    this.userName,
    this.userEmail,
    this.userPhotoUrl,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isSignedIn && userPhotoUrl != null)
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(userPhotoUrl!),
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
                        isSignedIn ? (userName ?? 'Signed In') : 'Cloud Sync',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isSignedIn && userEmail != null)
                        Text(
                          userEmail!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSignedIn)
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
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

