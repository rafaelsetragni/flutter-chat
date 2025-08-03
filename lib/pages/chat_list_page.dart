import 'package:chatpoc/widgets/custom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';
import 'chat_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  static Route<void> route(String chatId) {
    return MaterialPageRoute(
      builder: (context) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => ChatProvider(),
            ),
          ],
          child: ChatListPage(),
        );
      },
    );
  }

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  late final chatProvider;

  @override
  void initState() {
    chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.fetchChats();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat Demo',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        centerTitle: true,
      ),
      body: Builder(
        builder: (context) {
          final chats = context.watch<ChatProvider>().chats;

          if (chats.isEmpty) {
            return const Center(child: Text('You haven\'t any chat'));
          }

          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chat = chats[index];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: chat.avatarUrl != null
                        ? NetworkImage(chat.avatarUrl!)
                        : const AssetImage('assets/images/default_avatar.png')
                            as ImageProvider,
                  ),
                  title: Text(
                    chat.title ?? 'Chat sem título',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: chat.subtitle != null
                      ? Text(
                          chat.subtitle!,
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          chatId: chat.id,
                          userId: chat.lastProfileId?.toString() ?? '',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: CustomNavigationBar(index: 2),
    );
  }
}
