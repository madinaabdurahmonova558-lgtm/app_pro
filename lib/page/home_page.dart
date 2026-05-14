// home_page.dart
import 'package:app_proect/page/chat_page.dart';
import 'package:app_proect/page/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class HomePage extends StatefulWidget {
  final String currentUserEmail;

  const HomePage({super.key, required this.currentUserEmail});

  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;
  String? selectedGroup; // выбранная группа для чата
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late User currentUser;
  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser!;
    _setOnlineStatus(true);
  }

  @override
  void dispose() {
    _setOnlineStatus(false);
    super.dispose();
  }

  void _setOnlineStatus(bool online) {
    _firestore.collection('users').doc(currentUser.uid).set({
      'email': currentUser.email,
      'online': online,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void createGroup() {
    TextEditingController groupController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2C34),
          title: const Text(
            "Create Group",
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: groupController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Group name",
              hintStyle: TextStyle(color: Colors.grey),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (groupController.text.trim().isEmpty) return;

                await _firestore
                    .collection('groups')
                    .doc(groupController.text.trim())
                    .set({
                      "name": groupController.text.trim(),
                      "createdBy": currentUser.email,
                      "members": [currentUser.email],
                      "time": FieldValue.serverTimestamp(),
                    });

                setState(() {
                  selectedGroup = groupController.text.trim();
                });

                Navigator.pop(context);
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  void addMembers(String groupName) async {
    final usersSnapshot = await _firestore.collection('users').get();
    final users = usersSnapshot.docs
        .where((u) => u.id != currentUser.uid)
        .toList();

    List<String> selectedUsers = [];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2C34),
          title: const Text(
            "Add Members",
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: users.length,
              itemBuilder: (context, index) {
                final data = users[index].data() as Map<String, dynamic>? ?? {};
                final email = data['email'] ?? '';
                return CheckboxListTile(
                  title: Text(
                    email,
                    style: const TextStyle(color: Colors.white),
                  ),
                  value: selectedUsers.contains(email),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        selectedUsers.add(email);
                      } else {
                        selectedUsers.remove(email);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (selectedUsers.isNotEmpty) {
                  final groupDoc = _firestore
                      .collection('groups')
                      .doc(groupName);
                  final groupData = await groupDoc.get();
                  List members = List.from(groupData['members'] ?? []);
                  members.addAll(
                    selectedUsers.where((e) => !members.contains(e)),
                  );
                  await groupDoc.update({"members": members});
                }
                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void joinGroup(String groupName, List members) async {
    if (groupName.isEmpty) return;
    setState(() {
      selectedGroup = groupName;
    });
  }

  void sendMessage() {
    if (_controller.text.trim().isEmpty || selectedGroup == null) return;

    _firestore
        .collection('groups')
        .doc(selectedGroup)
        .collection('messages')
        .add({
          'text': _controller.text,
          'sender': widget.currentUserEmail,
          'time': FieldValue.serverTimestamp(),
        });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1418),
      appBar: AppBar(
        backgroundColor: Color(0xFF1F2C34),
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Search...",
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
            suffixIcon: Icon(Icons.search, color: Colors.grey),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
          ),
        ),
      ),
      body: getCurrentScreen(),
      bottomNavigationBar: Container(
        height: 8.h,
        color: const Color(0xFF1F2C34),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            navText("Chats", 0),
            navText("Groups", 1),
            navText("Calls", 2),
            navText("Status", 3),
          ],
        ),
      ),
    );
  }

  Widget getCurrentScreen() {
    switch (_selectedIndex) {
      case 0: // Личные чаты
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());

            final users = snapshot.data!.docs
                .where((u) => u.id != currentUser.uid)
                .toList();

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final data = user.data() as Map<String, dynamic>? ?? {};

                return ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage:
                        (data['photoUrl'] != null && data['photoUrl'] != '')
                        ? NetworkImage(data['photoUrl'])
                        : null,
                    child: (data['photoUrl'] == null || data['photoUrl'] == '')
                        ? Text(
                            (data['email'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          )
                        : null,
                  ),
                  title: Text(
                    data['email'] ?? 'Unknown',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    (data['online'] ?? false) ? "Online" : "Offline",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          peerEmail: data['email'],
                          currentUserEmail: currentUser.email!,
                          username: null,
                        ),
                      ),
                    );
                  },
                );
                // ignore: dead_code
                return null;
              },
            );
          },
        );

      // Остальной код (Groups, Calls, Status) — **не изменён**
      case 1:
        return Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('groups').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  final groups = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final data =
                          groups[index].data() as Map<String, dynamic>? ?? {};
                      // ignore: unused_local_variable
                      final groupName = data['name'] ?? '';
                      // ignore: unused_local_variable
                      final members = List.from(data['members'] ?? []);

                      return Container();
                    },
                  );
                },
              ),
            ),
          ],
        );

      case 2:
        return const Center(
          child: Text("No data", style: TextStyle(color: Colors.grey)),
        );

      case 3:
        return StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection('users')
              .doc(currentUser.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());

            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            final email = data['email'] ?? 'No email';
            final online = data['online'] ?? false;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    height: 10.h,
                    width: 25.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRALYxjoWjGaTOECYmxmoNqY24Q4Z6DFWngIw&s',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    email,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    online ? 'Online' : 'Offline',
                    style: const TextStyle(color: Colors.green, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      children: [
                        ListTile(
                          leading: Icon(Icons.logout, color: Colors.red),
                          title: Text(
                            "Log out",
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: () async {
                            await FirebaseAuth.instance.signOut();

                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginPage(),
                              ),
                              (route) => false,
                            );
                          },
                        ),
                        Divider(),
                        ListTile(
                          leading: Icon(Icons.vpn_key, color: Colors.white),
                          title: Text(
                            "Account",
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            "Security notifications, change number",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ListTile(
                          leading: Icon(Icons.lock, color: Colors.white),
                          title: Text(
                            "Privacy",
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            "Block contacts, disappearing messages",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ListTile(
                          leading: Icon(Icons.person, color: Colors.white),
                          title: Text(
                            "Avatar",
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            "Create, edit, profile photo",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ListTile(
                          leading: Icon(Icons.chat, color: Colors.white),
                          title: Text(
                            "Chats",
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            "Theme, wallpapers, chat history",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.notifications,
                            color: Colors.white,
                          ),
                          title: Text(
                            "Notifications",
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            "Messages, group & call tunes",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ListTile(
                          leading: Icon(Icons.storage, color: Colors.white),
                          title: Text(
                            "Storage",
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            "Network usage, auto-download",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ListTile(
                          leading: Icon(Icons.language, color: Colors.white),
                          title: Text(
                            "App language",
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            "English (phone’s language)",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.help_outline,
                            color: Colors.white,
                          ),
                          title: Text(
                            "Help",
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            "Help centre, contact us, privacy policy",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ListTile(
                          leading: Icon(Icons.group, color: Colors.white),
                          title: Text(
                            "Invite a friend",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );

      default:
        return Container();
    }
  }

  Widget navText(String title, int index) {
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Text(
        title,
        style: TextStyle(
          color: _selectedIndex == index ? Colors.green : Colors.grey,
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}