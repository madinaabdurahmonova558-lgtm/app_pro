import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class ChatPage extends StatefulWidget {
  final String peerEmail;
  final String currentUserEmail;

  const ChatPage({
    super.key,
    required this.peerEmail,
    required this.currentUserEmail,
    required username,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // ignore: unused_field
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get chatId {
    final emails = [widget.currentUserEmail, widget.peerEmail];
    emails.sort();
    return emails.join('_');
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _firestore.collection('chats').doc(chatId).collection('messages').add({
      'sender': widget.currentUserEmail,
      'receiver': widget.peerEmail,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false, // добавляем поле read
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1F2C34),
        title: Text(widget.peerEmail),
        actions: [
          TextButton(onPressed: () {}, child: Icon(Icons.call)),
          SizedBox(width: 1.w),
          TextButton(onPressed: () {}, child: Icon(Icons.video_call_rounded)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['sender'] == widget.currentUserEmail;

                    // Приводим данные к Map<String, dynamic>
                    final data = msg.data() as Map<String, dynamic>;

                    final timestamp =
                        data.containsKey('timestamp') &&
                            data['timestamp'] != null
                        ? (data['timestamp'] as Timestamp).toDate()
                        : DateTime.now();

                    final read = data.containsKey('read')
                        ? data['read'] as bool
                        : false;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 30,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.green : Colors.grey[700],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              data['text'] ?? '',
                              style: const TextStyle(color: Colors.white),
                            ),
                            SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DateFormat('hh:mm a').format(timestamp),
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 12.sp,
                                  ),
                                ),
                                if (isMe) ...[
                                  SizedBox(width: 5),
                                  Icon(
                                    read ? Icons.done_all : Icons.done,
                                    size: 16,
                                    color: read ? Colors.blue : Colors.grey,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2C34),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 6.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(left: 15.sp, right: 15.sp),
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                        onSubmitted: sendMessage,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.green),
                  onPressed: () => sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
