import 'dart:async';

import 'package:chatpoc/models/message.dart';
import 'package:chatpoc/models/profile.dart';
import 'package:chatpoc/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/chat_title_provider.dart';
import '../widgets/grouped_list_view.dart';

final List<Color> userColors = [
  Colors.red,
  Colors.green,
  Colors.blue,
  Colors.orange,
  Colors.purple,
  Colors.cyan,
  Colors.amber,
  Colors.teal,
  Colors.indigo,
  Colors.pink,
  Colors.lime,
  Colors.brown,
  Colors.deepOrange,
  Colors.deepPurple,
  Colors.lightBlue,
  Colors.lightGreen,
  Colors.yellow,
  Colors.grey,
  Colors.blueGrey,
  Colors.lightGreenAccent,
  Colors.orangeAccent,
  Colors.pinkAccent,
  Colors.purpleAccent,
  Colors.tealAccent,
];

/// Page to chat with someone.
///
/// Displays chat bubbles as a ListView and TextField to enter new chat.
class ChatPage extends StatefulWidget {
  final String userId;
  final String chatId;

  const ChatPage({required this.userId, required this.chatId, super.key});

  static Route<void> route(String userId, String chatId) {
    return MaterialPageRoute(
      builder: (context) => ChangeNotifierProvider(
        create: (_) => ChatProvider(chatId: chatId),
        child: ChatPage(userId: userId, chatId: chatId),
      ),
    );
  }

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final Stream<List<Message>> _messagesStream;
  final Map<String, Profile> _profileCache = {};
  final ScrollController _scrollController = ScrollController();

  final Map<String, Color> _userColorMap = {};

  Color _getUserColor(String profileId) {
    if (_userColorMap.containsKey(profileId)) {
      return _userColorMap[profileId]!;
    }

    final usedColors = _userColorMap.values.toSet();
    final availableColors =
        userColors.where((c) => !usedColors.contains(c)).toList();
    final color = availableColors.isNotEmpty
        ? availableColors.first
        : userColors[_userColorMap.length % userColors.length];

    _userColorMap[profileId] = color;
    return color;
  }

  @override
  void initState() {
    _messagesStream = supabase
        .from('tb_messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((maps) => maps
            .map((map) => Message.fromMap(map: map, myUserId: widget.userId))
            .toList());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.addListener(_onScroll);
    });
    super.initState();
  }

  void _onScroll() {
    if (!mounted) return;
    // lógica futura de scroll, se necessário
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<ChatProvider>(
            builder: (_, provider, __) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                provider.buildChatAvatar(),
                SizedBox(width: 16),
                Column(
                  children: [
                    Text(provider.title ?? 'Chat'),
                    Text(
                      '35 online',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          centerTitle: true,
          elevation: 4,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          shadowColor: Colors.black12,
          actions: [
            PopupMenuButton<String>(
              icon: Icon(Icons.settings),
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
        body: Column(
          children: [
            _buildChatContent(),
            const _MessageBar(),
          ],
        ),
        //bottomNavigationBar: CustomNavigationBar(index: 2),
      ),
    );
  }

  Widget _buildChatContent() {
    return StreamBuilder<List<Message>>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return preloader;

        final rawMessages = snapshot.data!;
        return Expanded(
          child: GroupedListView<List<Message>, String>(
            elements: _groupMessagesByUserAndDay(rawMessages),
            groupBy: (group) => DateTime(
              group.first.createdAt.year,
              group.first.createdAt.month,
              group.first.createdAt.day,
            ).toIso8601String(),
            groupHeaderBuilder: (group) {
              final date = group.first.createdAt;
              return _buildDateBadge(date);
            },
            itemBuilder: (context, List<Message> group) {
              final profileId = group.first.profileId;
              _loadProfileCache(profileId);
              return _ChatBubbleGroup(
                messages: group,
                profile: _profileCache[profileId],
                userColor: _getUserColor(profileId),
              );
            },
            floatingHeader: true,
            useStickyGroupSeparators: true,
            order: GroupedListOrder.DESC,
            reverse: true,
            controller: _scrollController,
            padding: EdgeInsets.all(12),
          ),
        );
      },
    );
  }

  List<List<Message>> _groupMessagesByUserAndDay(List<Message> messages) {
    if (messages.isEmpty) return [];

    final List<List<Message>> groups = [];
    List<Message> currentGroup = [messages.first];

    for (int i = 1; i < messages.length; i++) {
      final previous = currentGroup.last;
      final current = messages[i];

      final sameUser = current.profileId == previous.profileId;
      final sameDay = current.createdAt.year == previous.createdAt.year &&
          current.createdAt.month == previous.createdAt.month &&
          current.createdAt.day == previous.createdAt.day;

      if (sameUser && sameDay) {
        currentGroup.add(current);
      } else {
        groups.add(currentGroup);
        currentGroup = [current];
      }
    }

    groups.add(currentGroup);
    return groups;
  }

  Widget _buildDateBadge(DateTime date) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
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
          _formatBadgeDate(date),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
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
      await supabase.from('tb_messages').insert({
        'profile_id': myUserId,
        'chat_id':
            (context.findAncestorWidgetOfExactType<ChatPage>() as ChatPage)
                .chatId,
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
  final String? leadingText;
  final Color? usernameColor;
  final bool hasTail;

  const _ChatBubble({
    required this.message,
    this.leadingText,
    this.usernameColor,
    this.hasTail = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = message.isMine;
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.fromLTRB(
              12,
              4,
              12,
              8,
            ),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isCurrentUser && leadingText != null)
                        Text(
                          leadingText!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: usernameColor ?? Colors.black87,
                          ),
                        ),
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isCurrentUser ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
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
          if (hasTail && !isCurrentUser)
            CustomPaint(
              size: Size(16, 10),
              painter: TrianglePainter(color: Colors.grey[300]!),
            ),
        ],
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
    required this.userColor,
  }) : super(key: key);

  final List<Message> messages;
  final Profile? profile;
  final Color userColor;

  @override
  Widget build(BuildContext context) {
    final isMine = messages.first.isMine;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine)
            CircleAvatar(
              radius: 16,
              child: profile == null
                  ? preloader
                  : Text(profile!.username.substring(0, 2)),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                ...List.generate(
                  messages.length,
                  (index) => _ChatBubble(
                    message: messages[index],
                    leadingText: !isMine && profile != null
                        ? '${profile!.username}:'
                        : null,
                    usernameColor: userColor,
                    hasTail: index == messages.length - 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
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
