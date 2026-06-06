import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrangAdminPage extends StatefulWidget {
  const TrangAdminPage({super.key});

  @override
  State<TrangAdminPage> createState() => _TrangAdminPageState();
}

class _TrangAdminPageState extends State<TrangAdminPage>
    with SingleTickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;

  late TabController tabController;

  bool isLoading = true;
  bool isAdmin = false;

  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> posts = [];

  int totalUsers = 0;
  int lockedUsers = 0;
  int totalPosts = 0;
  int hiddenPosts = 0;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    checkAdminAndLoadData();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Future<void> checkAdminAndLoadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final currentUser = supabase.auth.currentUser;

      if (currentUser == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final profile = await supabase
          .from('profiles')
          .select('id, role, status')
          .eq('id', currentUser.id)
          .maybeSingle();

      if (profile == null || profile['role'] != 'admin') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bạn không có quyền quản trị')),
          );
          Navigator.pop(context);
        }
        return;
      }

      isAdmin = true;
      await loadAllData();
    } catch (e) {
      debugPrint('Lỗi kiểm tra admin: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loadAllData() async {
    await loadUsers();
    await loadPosts();

    totalUsers = users.length;
    lockedUsers = users.where((user) => user['status'] == 'locked').length;

    totalPosts = posts.length;
    hiddenPosts = posts.where((post) => post['is_hidden'] == true).length;
  }

  Future<void> loadUsers() async {
    final data = await supabase
        .from('profiles')
        .select(
          'id, nickname, email, phone, full_name, avatar_url, role, status, lock_reason, city, bio, created_at, updated_at, last_login_at',
        )
        .order('created_at', ascending: false);

    users = List<Map<String, dynamic>>.from(data);
  }

  Future<void> loadPosts() async {
    final data = await supabase
        .from('posts')
        .select()
        .order('created_at', ascending: false);

    posts = List<Map<String, dynamic>>.from(data);
  }

  Future<void> refreshData() async {
    setState(() {
      isLoading = true;
    });

    await loadAllData();

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> toggleLockUser(Map<String, dynamic> user) async {
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) return;

    if (user['id'] == currentUser.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin không thể tự khóa chính mình')),
      );
      return;
    }

    final bool isLocked = user['status'] == 'locked';

    try {
      await supabase
          .from('profiles')
          .update({
            'status': isLocked ? 'active' : 'locked',
            'lock_reason': isLocked ? null : 'Bị khóa bởi quản trị viên',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user['id']);

      await loadAllData();

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isLocked ? 'Đã mở khóa tài khoản' : 'Đã khóa tài khoản',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> toggleHidePost(Map<String, dynamic> post) async {
    final bool isHidden = post['is_hidden'] == true;

    try {
      await supabase
          .from('posts')
          .update({
            'is_hidden': !isHidden,
            'hidden_reason': isHidden ? null : 'Bị ẩn bởi quản trị viên',
            'hidden_at': isHidden ? null : DateTime.now().toIso8601String(),
          })
          .eq('id', post['id']);

      await loadAllData();

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isHidden ? 'Đã hiện lại bài viết' : 'Đã ẩn bài viết'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String getUserName(Map<String, dynamic> user) {
    final fullName = user['full_name']?.toString().trim();
    final nickname = user['nickname']?.toString().trim();
    final email = user['email']?.toString().trim();

    if (fullName != null && fullName.isNotEmpty && fullName != 'EMPTY') {
      return fullName;
    }

    if (nickname != null && nickname.isNotEmpty && nickname != 'EMPTY') {
      return nickname;
    }

    if (email != null && email.isNotEmpty && email != 'EMPTY') {
      return email;
    }

    return 'Người dùng';
  }

  String getPostContent(Map<String, dynamic> post) {
    final keys = ['content', 'caption', 'title', 'description', 'body'];

    for (final key in keys) {
      final value = post[key]?.toString().trim();

      if (value != null && value.isNotEmpty && value != 'null') {
        return value;
      }
    }

    return 'Không có nội dung';
  }

  String getPostAuthorName(Map<String, dynamic> post) {
    final possibleUserIds = [
      post['profile_id'],
      post['user_id'],
      post['author_id'],
      post['created_by'],
      post['owner_id'],
    ];

    for (final id in possibleUserIds) {
      if (id == null) continue;

      final found = users.where((user) => user['id'] == id).toList();

      if (found.isNotEmpty) {
        return getUserName(found.first);
      }
    }

    return 'Người dùng';
  }

  Widget buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B2B2B)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: refreshData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Thống kê hệ thống',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          buildStatCard(
            title: 'Tổng tài khoản',
            value: totalUsers.toString(),
            icon: Icons.people_alt_outlined,
            color: const Color(0xFF4AA8FF),
          ),
          const SizedBox(height: 12),
          buildStatCard(
            title: 'Tài khoản bị khóa',
            value: lockedUsers.toString(),
            icon: Icons.lock_outline_rounded,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 12),
          buildStatCard(
            title: 'Tổng bài viết',
            value: totalPosts.toString(),
            icon: Icons.article_outlined,
            color: Colors.greenAccent,
          ),
          const SizedBox(height: 12),
          buildStatCard(
            title: 'Bài viết bị ẩn',
            value: hiddenPosts.toString(),
            icon: Icons.visibility_off_outlined,
            color: Colors.orangeAccent,
          ),
        ],
      ),
    );
  }

  Widget buildUsersTab() {
    if (users.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có tài khoản nào',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];

          final bool isLocked = user['status'] == 'locked';
          final bool userIsAdmin = user['role'] == 'admin';

          return Card(
            color: const Color(0xFF1C1C1E),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF2B2B2B)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF2B2B2B),
                  backgroundImage:
                      user['avatar_url'] != null &&
                          user['avatar_url'].toString().trim().isNotEmpty
                      ? NetworkImage(user['avatar_url'])
                      : null,
                  child:
                      user['avatar_url'] == null ||
                          user['avatar_url'].toString().trim().isEmpty
                      ? const Icon(Icons.person, color: Colors.white70)
                      : null,
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        getUserName(user),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (userIsAdmin)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    isLocked
                        ? 'Trạng thái: Đang bị khóa'
                        : 'Trạng thái: Hoạt động',
                    style: TextStyle(
                      color: isLocked ? Colors.redAccent : Colors.greenAccent,
                      fontSize: 13,
                    ),
                  ),
                ),
                trailing: userIsAdmin
                    ? const Text(
                        'Admin',
                        style: TextStyle(color: Colors.white54),
                      )
                    : ElevatedButton(
                        onPressed: () => toggleLockUser(user),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLocked
                              ? Colors.green
                              : Colors.redAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(isLocked ? 'Mở khóa' : 'Khóa'),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildPostsTab() {
    if (posts.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có bài viết nào',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];

          final bool isHidden = post['is_hidden'] == true;
          final authorName = getPostAuthorName(post);

          return Card(
            color: const Color(0xFF1C1C1E),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF2B2B2B)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFF2B2B2B),
                        child: Icon(Icons.person, color: Colors.white70),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          authorName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isHidden
                              ? Colors.redAccent.withValues(alpha: 0.16)
                              : Colors.greenAccent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isHidden ? 'Đã ẩn' : 'Đang hiện',
                          style: TextStyle(
                            color: isHidden
                                ? Colors.redAccent
                                : Colors.greenAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    getPostContent(post),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => toggleHidePost(post),
                      icon: Icon(
                        isHidden
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                      ),
                      label: Text(isHidden ? 'Hiện lại' : 'Ẩn bài'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isHidden
                            ? Colors.green
                            : Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4AA8FF)),
        ),
      );
    }

    if (!isAdmin) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Bạn không có quyền quản trị',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Quản trị viên',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        bottom: TabBar(
          controller: tabController,
          indicatorColor: const Color(0xFF4AA8FF),
          labelColor: const Color(0xFF4AA8FF),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Thống kê'),
            Tab(icon: Icon(Icons.people_alt_outlined), text: 'Tài khoản'),
            Tab(icon: Icon(Icons.article_outlined), text: 'Bài viết'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [buildDashboardTab(), buildUsersTab(), buildPostsTab()],
      ),
    );
  }
}
