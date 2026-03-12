import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/popup_notification.dart';

class UserManagementTab extends StatefulWidget {
  const UserManagementTab({Key? key}) : super(key: key);

  @override
  UserManagementTabState createState() => UserManagementTabState();
}

class UserManagementTabState extends State<UserManagementTab> {
  final ApiService _apiService = ApiService();
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void refreshUsers() => _fetchUsers();

  Future<void> _fetchUsers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    _users = await _apiService.getUsers();
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  void _showUserDialog({dynamic existingUser}) {
    final nameCtrl = TextEditingController(text: existingUser?['name'] ?? '');
    final emailCtrl = TextEditingController(text: existingUser?['email'] ?? '');
    final passCtrl = TextEditingController();
    String selectedRole = existingUser?['role'] ?? 'cashier';
    final isEdit = existingUser != null;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(isEdit ? 'Edit User' : 'Tambah User', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nama',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: isEdit ? 'Password (kosongkan jika tidak diubah)' : 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedRole,
                          isExpanded: true,
                          items: [
                            DropdownMenuItem(value: 'cashier', child: Row(children: [
                              Icon(Icons.point_of_sale, color: Colors.blue, size: 20), SizedBox(width: 8),
                              Text('Kasir')
                            ])),
                            DropdownMenuItem(value: 'owner', child: Row(children: [
                              Icon(Icons.admin_panel_settings, color: Colors.orange, size: 20), SizedBox(width: 8),
                              Text('Owner / Admin')
                            ])),
                          ],
                          onChanged: (val) {
                            setDialogState(() => selectedRole = val!);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text('Batal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty) {
                      PopupNotification.show(ctx, title: 'Error', message: 'Nama dan email wajib diisi.', type: PopupType.warning);
                      return;
                    }
                    if (!isEdit && passCtrl.text.isEmpty) {
                      PopupNotification.show(ctx, title: 'Error', message: 'Password wajib diisi untuk user baru.', type: PopupType.warning);
                      return;
                    }

                    Navigator.pop(dialogCtx);

                    Map<String, dynamic> data = {
                      'name': nameCtrl.text,
                      'email': emailCtrl.text,
                      'role': selectedRole,
                    };
                    if (passCtrl.text.isNotEmpty) {
                      data['password'] = passCtrl.text;
                    }

                    bool success;
                    if (isEdit) {
                      success = await _apiService.updateUser(existingUser['id'], data);
                    } else {
                      success = await _apiService.createUser(data);
                    }

                    if (success) {
                      PopupNotification.show(context, title: 'Berhasil! ✅', message: isEdit ? 'User berhasil diperbarui.' : 'User baru berhasil ditambahkan.', type: PopupType.success);
                      _fetchUsers();
                    } else {
                      PopupNotification.show(context, title: 'Gagal', message: 'Terjadi kesalahan. Periksa data yang diisi.', type: PopupType.error);
                    }
                  },
                  child: Text(isEdit ? 'Simpan' : 'Tambah'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(dynamic user) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Hapus User?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Yakin ingin menghapus "${user['name']}"? Aksi ini tidak bisa dibatalkan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final success = await _apiService.deleteUser(user['id']);
                if (success) {
                  PopupNotification.show(context, title: 'Dihapus 🗑️', message: '"${user['name']}" telah dihapus.', type: PopupType.success);
                  _fetchUsers();
                } else {
                  PopupNotification.show(context, title: 'Gagal', message: 'Tidak bisa menghapus user.', type: PopupType.error);
                }
              },
              child: Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Kelola Karyawan', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: Icon(Icons.refresh, color: Colors.black), onPressed: _fetchUsers),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        icon: Icon(Icons.person_add),
        label: Text('Tambah User'),
        onPressed: () => _showUserDialog(),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.black))
          : _users.isEmpty
              ? Center(child: Text('Belum ada user.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final isOwner = user['role'] == 'owner';

                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: isOwner ? Colors.orange[100] : Colors.blue[100],
                          child: Icon(
                            isOwner ? Icons.admin_panel_settings : Icons.point_of_sale,
                            color: isOwner ? Colors.orange[800] : Colors.blue[800],
                          ),
                        ),
                        title: Text(user['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['email'], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isOwner ? Colors.orange[50] : Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isOwner ? 'OWNER' : 'KASIR',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isOwner ? Colors.orange[800] : Colors.blue[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit_outlined, color: Colors.black),
                              onPressed: () => _showUserDialog(existingUser: user),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmDelete(user),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
