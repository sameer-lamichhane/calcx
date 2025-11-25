import 'package:flutter/material.dart';

class ContactTile extends StatelessWidget {
  final String displayName;
  final String email;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final bool isPinned;

  const ContactTile({
    super.key,
    required this.displayName,
    required this.email,
    required this.onTap,
    this.onLongPress,
    this.lastMessage,
    this.lastMessageTime,
    this.isPinned = false,
  });

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue[700],
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isPinned)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: const Icon(
                    Icons.push_pin,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                displayName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isPinned)
              Icon(
                Icons.push_pin,
                size: 16,
                color: Colors.blue.shade700,
              ),
          ],
        ),
        subtitle: lastMessage != null
            ? Text(
                lastMessage!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : Text(
                email,
                style: TextStyle(color: Colors.grey[600]),
              ),
        trailing: lastMessageTime != null
            ? Text(
                _formatTime(lastMessageTime),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}

