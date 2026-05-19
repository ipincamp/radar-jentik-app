import 'package:flutter/material.dart';

class OfficerUserManagementPage extends StatelessWidget {
  const OfficerUserManagementPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Kader')),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text('Kader ${index + 1}'),
            subtitle: const Text('Desa Panusupan'),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Tugas')),
                const PopupMenuItem(
                  value: 'reset',
                  child: Text('Reset Password'),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Dialog tambah kader
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
