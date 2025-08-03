import 'package:flutter/material.dart';

class CustomNavigationBar extends StatelessWidget {
  final int index;

  const CustomNavigationBar({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      color: Colors.white,
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 2,
        backgroundColor: Colors.white,
        onTap: (index) {
          // Replace with real navigation
          switch (index) {
            case 0:
              print('Navigate to Forum');
              break;
            case 1:
              print('Navigate to Ask');
              break;
            case 2:
              // Already on Chat
              break;
            case 3:
              print('Navigate to Profile');
              break;
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.forum),
            label: 'Forum',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.question_mark),
            label: 'Ask',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, size: 16, color: Colors.black),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
