import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/message_service.dart';

class SharePostSheet extends StatefulWidget {
  final int postId;

  const SharePostSheet({super.key, required this.postId});

  @override
  State<SharePostSheet> createState() => _SharePostSheetState();
}

class _SharePostSheetState extends State<SharePostSheet> {
  static const Color blue = Color(0xFF4AA8FF);

  final MessageService _messageService = MessageService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<_Friend> _allFriends = [];
  List<_Friend> _filtered = [];
  final Set<String> _selected = {};
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      // Lấy danh sách mutual follow (bạn bè)
      final followingRows = await client
          .from('follows')
          .select('following_id')
          .eq('follower_id', user.id)
          .eq('status', 'active');

      final followingIds = (followingRows as List)
          .map((r) => (r as Map)['following_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      if (followingIds.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final mutualRows = await client
          .from('follows')
          .select('follower_id')
          .inFilter('follower_id', followingIds)
          .eq('following_id', user.id)
          .eq('status', 'active');

      final mutualIds = (mutualRows as List)
          .map((r) => (r as Map)['follower_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      if (mutualIds.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final profileRows = await client
          .from('profiles')
          .select('id, nickname, avatar_url')
          .inFilter('id', mutualIds);

      final friends = (profileRows as List).map((p) {
        final m = p as Map<String, dynamic>;
        return _Friend(
          id: m['id']?.toString() ?? '',
          nickname: m['nickname']?.toString() ?? 'Người dùng',
          avatarUrl: m['avatar_url']?.toString(),
        );
      }).where((f) => f.id.isNotEmpty).toList();

      friends.sort((a, b) => a.nickname.compareTo(b.nickname));
      setState(() {
        _allFriends = friends;
        _filtered = friends;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _allFriends
          : _allFriends
              .where((f) => f.nickname.toLowerCase().contains(q))
              .toList();
    });
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  Future<void> _send() async {
    if (_selected.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final count = await _messageService.sharePostToFriends(
        postId: widget.postId,
        friendProfileIds: _selected.toList(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Đã chia sẻ đến $count người'),
        backgroundColor: blue,
      ));
    } catch (_) {
      setState(() => _sending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Chia sẻ thất bại, thử lại sau.'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title + Send button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Chia sẻ bài viết',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _selected.isEmpty || _sending ? null : _send,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    disabledBackgroundColor: blue.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(0, 38),
                    elevation: 0,
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Gửi${_selected.isNotEmpty ? ' (${_selected.length})' : ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tìm bạn bè...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white38, size: 20),
                filled: true,
                fillColor: const Color(0xFF2C2C2E),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // List
          Flexible(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: blue))
                : _filtered.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Không có bạn bè nào',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final f = _filtered[index];
                          final selected = _selected.contains(f.id);
                          final hasAvatar = f.avatarUrl?.trim().isNotEmpty == true;
                          return InkWell(
                            onTap: () => _toggle(f.id),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: blue,
                                    backgroundImage: hasAvatar
                                        ? NetworkImage(f.avatarUrl!)
                                        : null,
                                    child: hasAvatar
                                        ? null
                                        : Text(
                                            f.nickname.isEmpty
                                                ? '?'
                                                : f.nickname[0].toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      f.nickname,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: selected ? blue : Colors.transparent,
                                      border: Border.all(
                                        color: selected ? blue : Colors.white38,
                                        width: 2,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: selected
                                        ? const Icon(Icons.check,
                                            color: Colors.white, size: 14)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _Friend {
  final String id;
  final String nickname;
  final String? avatarUrl;
  const _Friend({required this.id, required this.nickname, this.avatarUrl});
}
