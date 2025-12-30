import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';
import 'package:unisync/app/providers.dart';
import 'package:unisync/features/Carrer_Mode/interview/controllers/reports_controller.dart';
import 'package:unisync/features/Carrer_Mode/interview/controllers/interview_controller.dart';
import 'package:unisync/features/Carrer_Mode/interview/view/carrer_interview_screen.dart';
import 'package:unisync/models/template_model.dart';
import 'package:unisync/sockets/socket_methods.dart';

class StartInterviewScreen extends ConsumerStatefulWidget {
  const StartInterviewScreen({super.key});

  @override
  ConsumerState<StartInterviewScreen> createState() =>
      _StartInterviewScreenState();
}

class _StartInterviewScreenState
    extends ConsumerState<StartInterviewScreen> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(interviewControllerProvider, (prev, next) {
      if (next.questionreceived != null) {
        Routemaster.of(context).replace('/coreInterviewScreen');
      }
    });

    final user = ref.read(userProvider);
    final tmplte = ref.read(selectedTemplateProvider)!;
    final chips = tmplte.topics;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _appBar(context, ref),
              Divider(),

              // TEMPLATE HEADER
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 64,
                      width: 64,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.grey.shade200),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: tmplte.icon,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tmplte.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // TOPICS
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    chips.length,
                    (index) => SelectableChip(
                      label: chips[index],
                      isSelected: false,
                      onTap: () {},
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // EVALUATION METRICS TITLE
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Evaluation Metrics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // METRICS LIST
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tmplte.evaluationMetrics.length,
                itemBuilder: (context, index) {
                  final t = tmplte.evaluationMetrics[index];
                  return _evaluationMetricCard(
                    t.topic,
                    t.description,
                  );
                },
              ),

              const SizedBox(height: 24),

              // START BUTTON
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize:
                        const Size(double.infinity, 52),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: loading
                      ? null
                      : () {
                          setState(() => loading = true);
                          ref
                              .read(socketMethodProvider)
                              .startInterview(
                                  tmplte.id, user!.id!);
                        },
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Start Interview",
                          style: TextStyle(
                              fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// EVALUATION METRIC CARD (CLEAN)
Widget _evaluationMetricCard(String title, String desc) {
  return Padding(
    padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    ),
  );
}

// APP BAR (FLAT, CLEAN)
Widget _appBar(BuildContext context, WidgetRef ref) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
    child: Row(
      children: [
        IconButton(
          onPressed: () => Routemaster.of(context).replace('/carrer-interview-screen'),
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20),
          splashRadius: 20,
        ),
        const SizedBox(width: 4),
        const Text(
          "Detailed Info",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () {
            ref.invalidate(ReportsControllerProvider);
            Routemaster.of(context).push('/reportsScreen');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black, foregroundColor: Colors.white
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal:  8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Text(
                  'Reports   ',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                 Icon(Icons.launch)
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

