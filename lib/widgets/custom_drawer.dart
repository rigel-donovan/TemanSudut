import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class CustomDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final userName = auth.user?['name'] ?? 'Guest';
        return Drawer(
          backgroundColor: Colors.white,
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  color: Colors.black,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hi, $userName', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      if (auth.isOwner) ...[
                        SizedBox(height: 24),
                        Text('Revenue', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        SizedBox(height: 8),
                        Text('\$35.85', style: TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold)), // Placeholder for actual revenue
                      ]
                    ],
                  ),
                ),
                if (auth.can('manage_stock') || auth.can('manage_employees'))
                  ListTile(
                    leading: Icon(Icons.grid_view),
                    title: Text('Management'),
                    trailing: Icon(Icons.keyboard_arrow_down, size: 20),
                    onTap: () {},
                  ),
                if (auth.can('view_history'))
                  ListTile(
                    leading: Icon(Icons.receipt_long),
                    title: Text('History'),
                    onTap: () {},
                  ),
                if (auth.isOwner)
                  ListTile(
                    leading: Icon(Icons.bar_chart),
                    title: Text('Report Sale'),
                    onTap: () {},
                  ),
                ListTile(
                  leading: Icon(Icons.language),
                  title: Text('Language'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('English', style: TextStyle(color: Colors.grey)),
                      SizedBox(width: 8),
                      Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.grey),
                    ]
                  ),
                  onTap: () {},
                ),
                ListTile(
                  leading: Icon(Icons.light_mode_outlined),
                  title: Text('Light Mode'),
                  trailing: Switch(
                    value: false, 
                    onChanged: (val) {},
                    activeColor: Colors.black,
                  ),
                ),
                Spacer(),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.redAccent),
                  title: Text('Logout', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    auth.logout();
                  },
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        );
      }
    );
  }
}
