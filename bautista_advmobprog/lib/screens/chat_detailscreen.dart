import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/custom_text.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';

final ChatService chatService = ChatService();

class ChatDetailScreen extends StatefulWidget {
  final String currentUserEmail;
  final Map<String, dynamic> tappedUser;

  const ChatDetailScreen({
    Key? key,
    required this.currentUserEmail,
    required this.tappedUser,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();

  late Future<String> _currentUserIdFuture;
  bool _isSending = false;
  Timestamp? _sendingStartedAt;

  bool _markingSeen = false;

  static const _postSendDelay = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _currentUserIdFuture = _getCurrentUserId();
  }

  Future<String> _getCurrentUserId() async {
    final uid = userService.value.currentUser?.uid;
    if (uid == null) {
      throw StateError('No Firebase user is signed in');
    }
    return uid;
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String currentUserId, String receiverId) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _sendingStartedAt = Timestamp.now();
    });

    try {
      await chatService.sendMessage(receiverId, text);
      _msgCtrl.clear();
      _msgFocus.requestFocus();

      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }

      await Future.delayed(_postSendDelay);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _sendingStartedAt = null;
        });
      }
    }
  }

  Future<void> _markMessagesAsSeen(
    List<QueryDocumentSnapshot> docs,
    String currentUserId,
  ) async {
    if (_markingSeen) return;
    _markingSeen = true;
    try {
      await chatService.markMessagesAsSeen(docs, currentUserId);
    } finally {
      _markingSeen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tappedUserId = (widget.tappedUser['uid'] ?? '').toString();
    final tappedUserName =
        '${widget.tappedUser['firstName'] ?? ''} '
                '${widget.tappedUser['lastName'] ?? ''}'
            .trim();

    return FutureBuilder<String>(
      future: _currentUserIdFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Error loading user data')),
          );
        }

        final currentUserId = snap.data!;

        return Scaffold(
          appBar: AppBar(
            centerTitle: false,
            title: Row(
              children: [
                _messageAvatar(
                  (widget.tappedUser['image'] ?? '').toString(),
                  tappedUserName,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tappedUserName.isEmpty ? 'Unknown' : tappedUserName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 20.sp),
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: chatService.getMessage(currentUserId, tappedUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading messages: ${snapshot.error}',
                        ),
                      );
                    }

                    List<QueryDocumentSnapshot> docs =
                        snapshot.data?.docs ?? [];

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _markMessagesAsSeen(docs, currentUserId);
                    });

                    if (docs.isEmpty) {
                      return const Center(child: Text('No messages yet'));
                    }

                    return ListView.builder(
                      controller: _scrollCtrl,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final msgText = (data['message'] ?? '').toString();
                        final senderId = (data['senderId'] ?? '').toString();
                        final isMe = senderId == currentUserId;

                        final messageDoc = docs[index];
                        final pending = messageDoc.metadata.hasPendingWrites;
                        final seenBy = data['seenBy'] is List
                            ? data['seenBy'] as List
                            : const [];
                        final isSeen = seenBy.contains(tappedUserId);

                        final otherName = tappedUserName;
                        final myName =
                            userService.value.currentUser?.displayName ?? '';
                        final otherImageUrl = (widget.tappedUser['image'] ?? '')
                            .toString();
                        final myImageUrl =
                            userService.value.currentUser?.photoURL ?? '';

                        final rawTimestamp = data['timestamp'];
                        final messageDateTime = rawTimestamp is Timestamp
                            ? rawTimestamp.toDate()
                            : null;
                        final timeLabel = messageDateTime == null
                            ? ''
                            : MaterialLocalizations.of(context).formatTimeOfDay(
                                TimeOfDay.fromDateTime(messageDateTime),
                              );

                        return TweenAnimationBuilder<double>(
                          key: ValueKey(messageDoc.id),
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(
                                  (isMe ? 16 : -16) * (1 - value),
                                  8 * (1 - value),
                                ),
                                child: child,
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: isMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!isMe)
                                _messageAvatar(otherImageUrl, otherName),
                              Flexible(
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                        0.72,
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 5,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(18),
                                      topRight: const Radius.circular(18),
                                      bottomLeft: Radius.circular(
                                        isMe ? 18 : 4,
                                      ),
                                      bottomRight: Radius.circular(
                                        isMe ? 4 : 18,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msgText.isNotEmpty
                                            ? msgText
                                            : '[empty]',
                                        textAlign: TextAlign.start,
                                        softWrap: true,
                                        style: TextStyle(
                                          color: isMe
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.onPrimary
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                          fontSize: 15.sp,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (timeLabel.isNotEmpty)
                                            Text(
                                              timeLabel,
                                              style: TextStyle(
                                                fontSize: 10.sp,
                                                color: isMe
                                                    ? Theme.of(context)
                                                          .colorScheme
                                                          .onPrimary
                                                          .withOpacity(0.75)
                                                    : Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                              ),
                                            ),
                                          if (isMe) ...[
                                            const SizedBox(width: 6),
                                            Text(
                                              pending
                                                  ? 'Sending…'
                                                  : isSeen
                                                  ? 'Seen'
                                                  : 'Delivered',
                                              style: TextStyle(
                                                fontSize: 10.sp,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary
                                                    .withOpacity(0.75),
                                              ),
                                            ),
                                            if (!pending) ...[
                                              const SizedBox(width: 3),
                                              Icon(
                                                Icons.done_all,
                                                size: 13,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onPrimary,
                                              ),
                                            ],
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (isMe) _messageAvatar(myImageUrl, myName),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          focusNode: _msgFocus,
                          enabled: !_isSending,
                          textInputAction: TextInputAction.send,
                          minLines: 1,
                          maxLines: 4,
                          onSubmitted: (_) => !_isSending
                              ? _send(currentUserId, tappedUserId)
                              : null,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(fontFamily: 'Poppins'),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _isSending
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: () =>
                                  _send(currentUserId, tappedUserId),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _messageAvatar(String imageUrl, String name) {
    final trimmedName = name.trim();
    final initial = trimmedName.isEmpty ? '?' : trimmedName[0].toUpperCase();

    Widget fallback() => Center(
      child: Text(initial, style: const TextStyle(fontWeight: FontWeight.bold)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: CircleAvatar(
        radius: 16,
        child: ClipOval(
          child: imageUrl.trim().isEmpty
              ? SizedBox.expand(child: fallback())
              : Image.network(
                  imageUrl,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => fallback(),
                ),
        ),
      ),
    );
  }
}
