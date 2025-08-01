import 'dart:async';

import 'package:chatpoc/models/message.dart';
import 'package:chatpoc/models/profile.dart';
import 'package:chatpoc/utils/constants.dart';
import 'package:chatpoc/widgets/custom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessageGroup {
  final String profileId;
  final List<Message> messages;

  MessageGroup({required this.profileId, required this.messages});
}

/// Page to chat with someone.
///
/// Displays chat bubbles as a ListView and TextField to enter new chat.
class ChatPage extends StatefulWidget {
  final String userId;

  const ChatPage({required this.userId, Key? key}) : super(key: key);

  static Route<void> route(String userId) {
    return MaterialPageRoute(
      builder: (context) => ChatPage(userId: userId),
    );
  }

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final Stream<List<Message>> _messagesStream;
  final Map<String, Profile> _profileCache = {};
  final ScrollController _scrollController = ScrollController();
  DateTime? _currentTopDate;

  @override
  void initState() {
    _messagesStream = supabase
        .from('tb_messages')
        .stream(primaryKey: ['id']).map((maps) => maps
            .map((map) => Message.fromMap(map: map, myUserId: widget.userId))
            .toList());
    _updateTopDate();
    _scrollController.addListener(_updateTopDate);
    super.initState();
  }

  void _updateTopDate() {
    // Placeholder logic: In a production app, you should determine the date of the first visible message.
    // For now, we simulate using today's date if the list is scrolled.
    setState(() {
      // This is a placeholder; in a real implementation, you would determine the correct date.
      _currentTopDate = DateTime.now();
    });
  }

  Future<void> _loadProfileCache(String profileId) async {
    if (_profileCache[profileId] != null) {
      return;
    }
    final data = await supabase
        .from('tb_profiles')
        .select()
        .eq('id', profileId)
        .single();
    final profile = Profile.fromMap(data);
    setState(() {
      _profileCache[profileId] = profile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(),
              SizedBox(width: 8),
              const Text('Chat'),
            ],
          ),
          centerTitle: true,
          elevation: 4,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          shadowColor: Colors.black12,
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'logout') {
                  await Supabase.instance.client.auth.signOut();
                  Navigator.of(context).pop();
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Text('Logout'),
                  ),
                ];
              },
            ),
          ],
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: _buildChatContent(),
        ),
      ),
      bottomNavigationBar: CustomNavigationBar(index: 2),
    );
  }

  Widget _buildChatContent() {
    return StreamBuilder<List<Message>>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final rawMessages = snapshot.data!;
          final groupedMessages = <MessageGroup>[];
          for (final message in rawMessages.reversed) {
            if (groupedMessages.isEmpty ||
                groupedMessages.last.profileId != message.profileId) {
              groupedMessages.add(MessageGroup(
                profileId: message.profileId,
                messages: [message],
              ));
            } else {
              groupedMessages.last.messages.add(message);
            }
          }
          return Column(
            children: [
              Expanded(
                child: groupedMessages.isEmpty
                    ? const Center(
                        child: Text('Start your conversation now :)'),
                      )
                    : Stack(
                        children: [
                          Positioned.fill(
                            child: ListView.builder(
                              controller: _scrollController,
                              reverse: true,
                              itemCount: groupedMessages.length,
                              padding: EdgeInsets.all(12),
                              itemBuilder: (context, index) {
                                final group = groupedMessages[index];
                                for (final message in group.messages) {
                                  _loadProfileCache(message.profileId);
                                }
                                return _ChatBubbleGroup(
                                  messages: group.messages,
                                  profile: _profileCache[group.profileId],
                                );
                              },
                            ),
                          ),
                          if (_currentTopDate != null)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  margin:
                                      const EdgeInsets.only(top: 8, bottom: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    _formatBadgeDate(_currentTopDate!),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              const _MessageBar(),
            ],
          );
        } else {
          return preloader;
        }
      },
    );
  }
}

/// Set of widget that contains TextField and Button to submit message
class _MessageBar extends StatefulWidget {
  const _MessageBar({
    Key? key,
  }) : super(key: key);

  @override
  State<_MessageBar> createState() => _MessageBarState();
}

class _MessageBarState extends State<_MessageBar> {
  late final TextEditingController _textController;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: _submitMessage,
              icon: const Icon(Icons.attach_file),
              color: Theme.of(context).colorScheme.primary,
              tooltip: 'Send message',
            ),
            SizedBox(width: 8),
            Expanded(
              child: Center(
                child: TextFormField(
                  keyboardType: TextInputType.multiline,
                  minLines: 1,
                  maxLines: 5,
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message',
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              onPressed: _submitMessage,
              icon: const Icon(Icons.send),
              color: Theme.of(context).colorScheme.primary,
              tooltip: 'Send message',
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    _textController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submitMessage() async {
    final text = _textController.text;
    final myUserId = supabase.auth.currentUser!.id;
    if (text.isEmpty) {
      return;
    }
    _textController.clear();
    try {
      await supabase.from('messages').insert({
        'profile_id': myUserId,
        'content': text,
      });
    } on PostgrestException catch (error) {
      context.showErrorSnackBar(message: error.message);
    } catch (_) {
      context.showErrorSnackBar(message: unexpectedErrorMessage);
    }
  }
}

class _ChatBubble extends StatelessWidget {
  final Message message;

  const _ChatBubble({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = message.isMine;
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: isCurrentUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                message.content,
                style: TextStyle(
                  color: isCurrentUser ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('HH:mm').format(message.createdAt),
                style: TextStyle(
                  fontSize: 10,
                  color: isCurrentUser ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessageTime extends StatelessWidget {
  const MessageTime({
    super.key,
    required this.message,
  });

  final Message message;

  @override
  Widget build(BuildContext context) {
    return Text(
      DateFormat('HH:mm').format(message.createdAt),
      style: Theme.of(context).textTheme.labelSmall,
    );
  }
}

class _ChatBubbleGroup extends StatelessWidget {
  const _ChatBubbleGroup({
    Key? key,
    required this.messages,
    required this.profile,
  }) : super(key: key);

  final List<Message> messages;
  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final isMine = messages.first.isMine;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMine)
            CircleAvatar(
              child: profile == null
                  ? preloader
                  : Text(profile!.username.substring(0, 2)),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: List.generate(
                messages.length,
                (index) => _ChatBubble(
                  message: messages[index],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatBadgeDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date).inDays;

  if (difference == 0 && now.day == date.day) {
    return 'Today';
  } else if (difference == 1 || (difference == 0 && now.day != date.day)) {
    return 'Yesterday';
  } else if (difference < 7) {
    return _weekdayName(date.weekday);
  } else {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

String _weekdayName(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'Monday';
    case DateTime.tuesday:
      return 'Tuesday';
    case DateTime.wednesday:
      return 'Wednesday';
    case DateTime.thursday:
      return 'Thursday';
    case DateTime.friday:
      return 'Friday';
    case DateTime.saturday:
      return 'Saturday';
    case DateTime.sunday:
      return 'Sunday';
    default:
      return '';
  }
}
