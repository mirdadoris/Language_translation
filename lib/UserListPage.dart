import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserListPage extends StatefulWidget {
  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  Future<List<Map<String, String>>> _getUserLogins() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? userLogins = prefs.getStringList('userLogins');
    if (userLogins == null) {
      return [];
    }
    return userLogins.map((e) => Map<String, String>.from(json.decode(e))).toList();
  }

  Future<List<Map<String, String>>> _getTranslationHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? history = prefs.getStringList('translationHistory');
    if (history == null) {
      return [];
    }
    return history.map((e) => Map<String, String>.from(json.decode(e))).toList();
  }

  Future<List<List<Map<String, String>>>> _getUserLoginsAndHistory() async {
    List<Map<String, String>> userLogins = await _getUserLogins();
    List<Map<String, String>> translationHistory = await _getTranslationHistory();
    return [userLogins, translationHistory];
  }

  void _deleteUser(String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? userLogins = prefs.getStringList('userLogins');
    if (userLogins != null) {
      userLogins.removeWhere((login) {
        Map<String, String> loginMap = Map<String, String>.from(json.decode(login));
        return loginMap['email'] == email;
      });
      await prefs.setStringList('userLogins', userLogins);
    }

    // Xóa lịch sử dịch thuật của người dùng
    List<String>? history = prefs.getStringList('translationHistory');
    if (history != null) {
      history.removeWhere((entry) {
        Map<String, String> entryMap = Map<String, String>.from(json.decode(entry));
        return entryMap['email'] == email;
      });
      await prefs.setStringList('translationHistory', history);
    }

    setState(() {});
  }

  void _editUser(String oldEmail, String newEmail, String newPassword) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? userLogins = prefs.getStringList('userLogins');
    if (userLogins != null) {
      int index = userLogins.indexWhere((login) {
        Map<String, String> loginMap = Map<String, String>.from(json.decode(login));
        return loginMap['email'] == oldEmail;
      });
      if (index != -1) {
        Map<String, String> loginMap = Map<String, String>.from(json.decode(userLogins[index]));
        loginMap['email'] = newEmail;
        loginMap['password'] = newPassword;
        userLogins[index] = json.encode(loginMap);
        await prefs.setStringList('userLogins', userLogins);
      }
    }

    // Cập nhật lịch sử dịch thuật của người dùng
    List<String>? history = prefs.getStringList('translationHistory');
    if (history != null) {
      for (int i = 0; i < history.length; i++) {
        Map<String, String> entryMap = Map<String, String>.from(json.decode(history[i]));
        if (entryMap['email'] == oldEmail) {
          entryMap['email'] = newEmail;
          history[i] = json.encode(entryMap);
        }
      }
      await prefs.setStringList('translationHistory', history);
    }

    setState(() {});
  }

  void _showEditDialog(Map<String, String> user) {
    TextEditingController emailController = TextEditingController(text: user['email']);
    TextEditingController passwordController = TextEditingController(text: user['password']);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Chỉnh sửa tài khoản'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Mật khẩu'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                _editUser(user['email']!, emailController.text, passwordController.text);
                Navigator.of(context).pop();
              },
              child: Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thông Tin Đăng Nhập Người Dùng'),
      ),
      body: FutureBuilder(
        future: _getUserLoginsAndHistory(),
        builder: (context, AsyncSnapshot<List<List<Map<String, String>>>> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          List<Map<String, String>> userLogins = snapshot.data![0];
          List<Map<String, String>> translationHistory = snapshot.data![1];

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Mật Khẩu')),
                DataColumn(label: Text('Thời Gian')),
                DataColumn(label: Text('Lịch Sử Dịch Thuật')),
                DataColumn(label: Text('Hành Động')),
              ],
              rows: userLogins.map((login) {
                List<Map<String, String>> userTranslations = translationHistory.where((entry) => entry['email'] == login['email']).toList();
                String history = userTranslations.map((entry) => "${entry['Before']} -> ${entry['After']} (${entry['Time']})").join('\n');

                return DataRow(cells: [
                  DataCell(Text(login['email'] ?? '')),
                  DataCell(Text(login['password'] ?? '')),
                  DataCell(Text(login['timestamp'] ?? '')),
                  DataCell(Text(history)),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          _showEditDialog(login);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _deleteUser(login['email'] ?? '');
                        },
                      ),
                    ],
                  )),
                ]);
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
