import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisync/app/providers.dart';
import 'package:unisync/features/Exam_Mode/controller/exam_doubts_controller.dart';
import 'package:unisync/features/Exam_Mode/create_doubt_screen.dart';
import 'package:unisync/features/Exam_Mode/models/exam_doubt_comment_model.dart';
import 'package:unisync/features/Exam_Mode/models/exam_doubt_post_model.dart';
import 'package:unisync/features/Exam_Mode/repository/exam_doubts_repository.dart';

class ExamDoubtsScreen extends ConsumerStatefulWidget {
  const ExamDoubtsScreen({super.key});

  @override
  ConsumerState<ExamDoubtsScreen> createState() => _ExamDoubtsScreenState();
}

class _ExamDoubtsScreenState extends ConsumerState<ExamDoubtsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8FAFC), Color(0xFFFFFFFF)],
            ),
          ),
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _postsTab(ref.watch(examAllDoubtsProvider)),
                    _postsTab(ref.watch(examMyDoubtsProvider), emptyTitle: 'No doubts posted yet'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            backgroundColor: const Color(0xFF1F2937),
            foregroundColor: Colors.white,
            onPressed: _openCreateDoubtScreen,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Student Doubts',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Discuss exam doubts with peers',
                          style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'All Doubts'),
                Tab(text: 'My Doubts'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _postsTab(AsyncValue<List<ExamDoubtPost>> postsAsync,
      {String emptyTitle = 'No doubts in feed'}) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return postsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load doubts: $e')),
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Text(
              emptyTitle,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(examAllDoubtsProvider);
            ref.invalidate(examMyDoubtsProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final post = posts[index];
              final liked = post.likedBy.contains(currentUid);
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _ExamDoubtDetailScreen(post: post),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            child: Text(
                              (post.authorName.isEmpty
                                      ? 'S'
                                      : post.authorName[0])
                                  .toUpperCase(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.authorName,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  _formatTime(post.createdAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (post.isResolved)
                            const _TinyBadge(label: 'Resolved', color: Color(0xFF16A34A)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        post.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(height: 1.35, color: Color(0xFF475569)),
                      ),
                      if ((post.imageUrl ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _DoubtImage(url: post.imageUrl!),
                      ],
                      if (post.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: post.tags
                              .take(4)
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    tag,
                                    style: const TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          IconButton(
                            onPressed: currentUid.isEmpty
                                ? null
                                : () => ref
                                    .read(examDoubtsRepositoryProvider)
                                    .togglePostLike(post.postId, currentUid),
                            icon: Icon(
                              liked ? Icons.favorite : Icons.favorite_border,
                              color: liked ? Colors.red : const Color(0xFF64748B),
                            ),
                          ),
                          Text('${post.likedBy.length}'),
                          const SizedBox(width: 12),
                          const Icon(Icons.chat_bubble_outline, size: 18),
                          const SizedBox(width: 4),
                          Text('${post.commentCount}'),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openCreateDoubtScreen() async {
    final posted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const CreateDoubtScreen(),
      ),
    );

    if (posted == true) {
      ref.invalidate(examAllDoubtsProvider);
      ref.invalidate(examMyDoubtsProvider);
    }
  }
}

class _ExamDoubtDetailScreen extends ConsumerStatefulWidget {
  final ExamDoubtPost post;

  const _ExamDoubtDetailScreen({required this.post});

  @override
  ConsumerState<_ExamDoubtDetailScreen> createState() =>
      _ExamDoubtDetailScreenState();
}

class _ExamDoubtDetailScreenState extends ConsumerState<_ExamDoubtDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(examDoubtCommentsProvider(widget.post.postId));
    final user = ref.watch(userProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Doubt Discussion')),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE7E5E4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(widget.post.description),
                if ((widget.post.imageUrl ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _DoubtImage(url: widget.post.imageUrl!),
                ],
              ],
            ),
          ),
          Expanded(
            child: commentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load comments: $e')),
              data: (comments) {
                if (comments.isEmpty) {
                  return const Center(child: Text('No replies yet. Be the first to answer.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.authorName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(comment.message),
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
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE7E5E4))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Write your answer...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: (uid == null || user == null)
                        ? null
                        : () async {
                            final message = _commentController.text.trim();
                            if (message.isEmpty) return;
                            final comment = ExamDoubtComment(
                              commentId: DateTime.now().microsecondsSinceEpoch.toString(),
                              postId: widget.post.postId,
                              uid: uid,
                              authorName: user.name,
                              message: message,
                              likedBy: const [],
                              createdAt: DateTime.now(),
                            );
                            await ref.read(examDoubtsRepositoryProvider).addComment(comment);
                            _commentController.clear();
                          },
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TinyBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DoubtImage extends StatelessWidget {
  final String url;

  const _DoubtImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 220),
        width: double.infinity,
        color: const Color(0xFFE2E8F0),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (_, __, ___) => const SizedBox(
            height: 120,
            child: Center(
              child: Text(
                'Image unavailable',
                style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _formatTime(DateTime value) {
  final diff = DateTime.now().difference(value);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  final weeks = (diff.inDays / 7).floor();
  return '${weeks}w ago';
}
