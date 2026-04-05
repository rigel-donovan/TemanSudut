import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfileTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final Map<String, dynamic>? user = auth.user;
        final String name = user?['name'] ?? 'Admin User';
        final String email = user?['email'] ?? 'admin@example.com';
        
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text('Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 24),
                // Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, size: 50, color: Colors.grey[400]),
                ),
                SizedBox(height: 24),
                
                // User Info
                Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(email, style: TextStyle(color: Colors.grey, fontSize: 16)),
                SizedBox(height: 32),
                
                // Settings List
                _buildProfileItem(Icons.edit_outlined, 'Edit Profile'),
                _buildProfileItem(Icons.lock_outline, 'Change Password'),
                _buildProfileItem(Icons.notifications_outlined, 'Notifications'),
                _buildProfileItem(Icons.language_outlined, 'Language', trailingText: 'English'),
                _buildProfileItem(Icons.help_outline, 'Help & Support'),
                
                SizedBox(height: 32),
                
                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.redAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      auth.logout();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 100), 
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildProfileItem(IconData icon, String title, {String? trailingText}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.black87),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText != null) 
              Text(trailingText, style: TextStyle(color: Colors.grey)),
            SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
        onTap: () {},
      ),
    );
  }
}
