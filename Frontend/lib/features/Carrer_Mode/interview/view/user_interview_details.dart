import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';
import 'package:unisync/features/Carrer_Mode/interview/controllers/carrer_controller.dart';
import 'package:unisync/features/Carrer_Mode/interview/controllers/reports_controller.dart';
import 'package:unisync/features/Carrer_Mode/interview/view/carrer_interview_screen.dart';

class UserInterviewDetails extends ConsumerStatefulWidget {
  const UserInterviewDetails({super.key});

  @override
  ConsumerState<UserInterviewDetails> createState() =>
      _UserInterviewDetailsState();
}

class _UserInterviewDetailsState extends ConsumerState<UserInterviewDetails> {
  @override
  Widget build(BuildContext context) {
    final tmplt = ref.watch(getAllUserTemplate);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16.0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mock Interviews',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    tmplt.when(
                        loading: () => const Text(
                              'Loading interviews...',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                        error: (_, __) => const Text(
                              'Total Interviews (0)',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                        data: (data) => Text(
                              'Total Interviews (${data.length})',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ))
                  ],
                ),
                Spacer(),
                IconButton(
                    onPressed: () {
                      ref.invalidate(getAllUserTemplate);
                    },
                    icon: Icon(Icons.refresh_rounded))
              ],
            ),
          ),
          Divider(),
          tmplt.when(
            skipLoadingOnRefresh: false,
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text("Something broke  $e"),
            data: (data) {
              return ListView.builder(
                shrinkWrap: true,
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final t = data[index];
                  return GestureDetector(
                      onTap: () {
                        ref.read(selectedTemplateProvider.notifier).state = t;
                        ref.invalidate(ReportsControllerProvider);
                        Routemaster.of(context).push('/reportsScreen');
                      },
                      child: _templateCard(
                          heading: t.title,
                          subheading: t.topics.toString(),
                          logourl: t.icon));
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

Widget _templateCard({
  required String heading,
  required String subheading,
  required String logourl,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), // subtle light tint
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subheading,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.done_all,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 48,
            width: 48,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: CachedNetworkImage(
              imageUrl: logourl,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    ),
  );
}
