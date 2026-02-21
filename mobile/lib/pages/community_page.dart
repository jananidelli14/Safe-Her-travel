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
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                const Text('Share Your Story', style: TextStyle(color: Color(0xFF1F1F1F), fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 24),

                _buildSheetField(titleCtrl, 'Headline', Icons.title_rounded),
                const SizedBox(height: 16),
                _buildSheetField(locationCtrl, 'Place / City', Icons.place_rounded),
                const SizedBox(height: 16),
                _buildSheetField(contentCtrl, 'What happened? Share your experience...', Icons.notes_rounded, maxLines: 4),
                const SizedBox(height: 20),

                _sectionLabelSmall('Select Category'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: categories.map((cat) {
                      final isSelected = cat == selectedCategory;
                      return GestureDetector(
                        onTap: () => setInner(() => selectedCategory = cat),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF5D3891) : const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(cat.replaceAll('_', ' ').toUpperCase(), 
                                style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 32),

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
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D3891),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF5D3891).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Center(child: Text(submitting ? 'Sharing...' : 'Post to Community', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))),
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
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Color(0xFF1F1F1F), fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: const Color(0xFF5D3891), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _sectionLabelSmall(String label) {
    return Text(label, style: const TextStyle(color: Color(0xFF1F1F1F), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(color: Colors.white),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('SafeHer Circle', style: TextStyle(color: Color(0xFF1F1F1F), fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('Travel community • ${_posts.length} stories', style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13, fontWeight: FontWeight.w500)),
                            const Spacer(),
                            IconButton(
                              onPressed: _fetchPosts,
                              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF5D3891), size: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF5D3891)))
            : _error != null
                ? _buildError()
                : RefreshIndicator(
                    onRefresh: _fetchPosts,
                    color: const Color(0xFF5D3891),
                    child: _posts.isEmpty
                        ? _buildEmpty()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _posts.length,
                            itemBuilder: (ctx, i) => _buildPostCard(_posts[i], i),
                          ),
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePostSheet,
        backgroundColor: const Color(0xFF5D3891),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildPostCard(dynamic post, int index) {
    final categoryColors = {
      'experience': const Color(0xFF5D3891),
      'safety_tip': const Color(0xFF00ADB5),
      'warning': const Color(0xFFE71C23),
      'food': const Color(0xFFF9A826),
      'attraction': const Color(0xFF2D31FA),
    };
    final cat = post['category'] as String? ?? 'experience';
    final catColor = categoryColors[cat] ?? const Color(0xFF5D3891);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF2F2F7)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: catColor.withOpacity(0.08),
                  child: Text(
                    (post['user_name'] as String? ?? 'T')[0].toUpperCase(),
                    style: TextStyle(color: catColor, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post['user_name'] ?? 'Traveler', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1F1F1F))),
                      const SizedBox(height: 2),
                      Row(children: [
                        Icon(Icons.access_time_rounded, size: 12, color: const Color(0xFF8E8E93)),
                        const SizedBox(width: 4),
                        Text(_formatDate(post['created_at']), style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.w500)),
                      ]),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: catColor.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                  child: Text(cat.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(color: catColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF1F1F1F), letterSpacing: -0.3)),
                const SizedBox(height: 8),
                Text(post['content'] ?? '', style: const TextStyle(color: Color(0xFF666666), fontSize: 14, height: 1.5)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if ((post['location_name'] as String?)?.isNotEmpty == true) ...[
                      const Icon(Icons.place_rounded, size: 14, color: Color(0xFF8E8E93)),
                      const SizedBox(width: 4),
                      Text(post['location_name'], style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12, fontWeight: FontWeight.w600)),
                      const Spacer(),
                    ],
                    GestureDetector(
                      onTap: () => _likePost(post['id'] as String, index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.favorite_rounded, color: Color(0xFFE71C23), size: 16),
                            const SizedBox(width: 6),
                            Text('${post['likes'] ?? 0}', style: const TextStyle(color: Color(0xFF1F1F1F), fontWeight: FontWeight.w900, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
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
            Icon(Icons.forum_outlined, size: 60, color: const Color(0xFFF2F2F7)),
            const SizedBox(height: 24),
            const Text('No Stories Yet', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF1F1F1F))),
            const SizedBox(height: 8),
            const Text('Start a conversation or share a tip with fellow travelers in Tamil Nadu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14)),
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
            const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFFE71C23)),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14)),
            const SizedBox(height: 24),
            TextButton.icon(onPressed: _fetchPosts, icon: const Icon(Icons.refresh_rounded), label: const Text('Try Again')),
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
