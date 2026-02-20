import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final ApiService _api = ApiService();
  List<dynamic> _posts = [];
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchPosts();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (mounted) setState(() => _currentUser = user);
  }

  Future<void> _fetchPosts() async {
    setState(() { _isLoading = true; _error = null; });
    final res = await _api.getCommunityPosts();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success'] == true) {
          _posts = res['posts'] ?? [];
        } else {
          _error = 'Could not load posts. Is the backend running?';
        }
      });
    }
  }

  Future<void> _likePost(String postId, int index) async {
    final res = await _api.likePost(postId);
    if (mounted && res['success'] == true) {
      setState(() => _posts[index]['likes'] = res['likes']);
    }
  }

  void _showCreatePostSheet() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    String selectedCategory = 'experience';
    bool submitting = false;

    final categories = ['experience', 'safety_tip', 'warning', 'food', 'attraction'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A0533), Color(0xFF2D1B69)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                const Text('Share Your Experience', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                _buildSheetField(titleCtrl, 'Title', Icons.title_rounded),
                const SizedBox(height: 12),
                _buildSheetField(locationCtrl, 'Place/Location', Icons.place_rounded),
                const SizedBox(height: 12),
                _buildSheetField(contentCtrl, 'Your experience...', Icons.notes_rounded, maxLines: 4),
                const SizedBox(height: 12),

                // Category chips
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: categories.map((cat) {
                      final isSelected = cat == selectedCategory;
                      return GestureDetector(
                        onTap: () => setInner(() => selectedCategory = cat),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFF4D6D) : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(cat.replaceAll('_', ' '), style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                GestureDetector(
                  onTap: submitting ? null : () async {
                    if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) return;
                    setInner(() => submitting = true);
                    final res = await _api.createCommunityPost(
                      userId: _currentUser?['id'] ?? 'guest',
                      userName: _currentUser?['name'] ?? 'Traveler',
                      title: titleCtrl.text.trim(),
                      content: contentCtrl.text.trim(),
                      locationName: locationCtrl.text.trim(),
                      category: selectedCategory,
                    );
                    setInner(() => submitting = false);
                    if (res['success'] == true && ctx.mounted) {
                      Navigator.pop(ctx);
                      _fetchPosts();
                    }
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6C3DE0), Color(0xFFFF4D6D)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: const Color(0xFF6C3DE0).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Center(child: Text(submitting ? 'Posting...' : '📤 Share Post', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetField(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A0533), Color(0xFF6C3DE0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Text('🌸', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 8),
                            const Text('Community', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('${_posts.length} posts', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Share experiences, tips & travel stories', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            backgroundColor: const Color(0xFF1A0533),
          ),
        ],
        body: _isLoading
            ? const Center(child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  CircularProgressIndicator(color: Color(0xFF6C3DE0)),
                  SizedBox(height: 16),
                  Text('Loading community posts...', style: TextStyle(color: Colors.grey)),
                ]),
              ))
            : _error != null
                ? _buildError()
                : RefreshIndicator(
                    onRefresh: _fetchPosts,
                    color: const Color(0xFF6C3DE0),
                    child: _posts.isEmpty
                        ? _buildEmpty()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                            itemCount: _posts.length,
                            itemBuilder: (ctx, i) => _buildPostCard(_posts[i], i),
                          ),
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePostSheet,
        backgroundColor: const Color(0xFF6C3DE0),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Share Experience', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 8,
      ),
    );
  }

  Widget _buildPostCard(dynamic post, int index) {
    final categoryColors = {
      'experience': const Color(0xFF6C3DE0),
      'safety_tip': const Color(0xFF06D6A0),
      'warning': const Color(0xFFFF4D6D),
      'food': const Color(0xFFFFB703),
      'attraction': const Color(0xFF00B4D8),
    };
    final cat = post['category'] as String? ?? 'experience';
    final catColor = categoryColors[cat] ?? const Color(0xFF6C3DE0);
    final catEmojis = {'experience': '✈️', 'safety_tip': '🛡️', 'warning': '⚠️', 'food': '🍛', 'attraction': '🏛️'};

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [catColor.withOpacity(0.1), catColor.withOpacity(0.03)]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: catColor.withOpacity(0.15),
                  child: Text(
                    (post['user_name'] as String? ?? 'T')[0].toUpperCase(),
                    style: TextStyle(color: catColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post['user_name'] ?? 'Traveler', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      if ((post['location_name'] as String?)?.isNotEmpty == true)
                        Row(children: [
                          Icon(Icons.place_rounded, size: 11, color: catColor),
                          const SizedBox(width: 2),
                          Text(post['location_name'], style: TextStyle(color: catColor, fontSize: 11, fontWeight: FontWeight.w600)),
                        ]),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: catColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: Text('${catEmojis[cat] ?? '📝'} ${cat.replaceAll('_', ' ')}',
                      style: TextStyle(color: catColor, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A0533))),
                const SizedBox(height: 6),
                Text(post['content'] ?? '', style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.5), maxLines: 4, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _likePost(post['id'] as String, index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4D6D).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.favorite_rounded, color: Color(0xFFFF4D6D), size: 15),
                            const SizedBox(width: 4),
                            Text('${post['likes'] ?? 0}', style: const TextStyle(color: Color(0xFFFF4D6D), fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(_formatDate(post['created_at']), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌸', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text('No posts yet!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text('Be the first to share your travel\nexperience with the community.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton.icon(onPressed: _fetchPosts, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString());
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return ''; }
  }
}
