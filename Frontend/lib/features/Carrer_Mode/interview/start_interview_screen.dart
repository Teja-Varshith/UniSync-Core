import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';
import 'package:unisync/app/providers.dart';
import 'package:unisync/features/Carrer_Mode/interview/carrer_interview_screen.dart';
import 'package:unisync/features/Carrer_Mode/interview/interview_controller.dart';
import 'package:unisync/models/template_model.dart';
import 'package:unisync/sockets/socket_methods.dart';

class StartInterviewScreen extends ConsumerStatefulWidget {
  const StartInterviewScreen({super.key});

  @override
  ConsumerState<StartInterviewScreen> createState() =>
      _StartInterviewScreenState();
}

class _StartInterviewScreenState extends ConsumerState<StartInterviewScreen> {
  @override
  void initState() {
    ref.read(socketMethodProvider).interviewQuestionListener(context);
    ref.read(socketMethodProvider).errorListener(context);
    super.initState();
  }

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(interviewControllerProvider, (prev, next) {
      if (next.questionreceived != null) {
        Routemaster.of(context).push('/coreInterviewScreen');
      }
    });

    final user = ref.read(userProvider);
    final tmplte = ref.read(selectedTemplateProvider);
    final chips = tmplte!.topics;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _appBar(context),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  SizedBox(
                      height: 70,
                      width: 70,
                      child: CachedNetworkImage(imageUrl: tmplte.icon)),
                  SizedBox(
                    width: 10,
                  ),
                  Flexible(
                    child: Text(
                      tmplte.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
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
            SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Evaluation Metrics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: tmplte.evaluationMetrics.length,
              itemBuilder: (context, index) {
                final t = tmplte.evaluationMetrics[index];
                return _evaluationMetrics(t.description, t.topic);
              },
            ),
            Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black,
                    shape: StadiumBorder(),
                    minimumSize: Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    setState(() {
                      loading = true;
                    });
                    ref
                        .read(socketMethodProvider)
                        .startInterview(tmplte.id, user!.id!);
                    loading = false;
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
                      : const Text("Start Interview"),
                )),
          ],
        ),
      )),
    );
  }
}

Widget _evaluationMetrics(String subheading, String heading) {
  return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: _evalWidget(subheading, heading));
}

Widget _evalWidget(String subheading, String heading) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
    child: Container(
      decoration: BoxDecoration(
        border: Border.all(width: 1, color: Colors.black),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              heading,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              subheading,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _appBar(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      child: Row(
        children: [
          IconButton(
              onPressed: () {
                Navigator.pop(context);
              }, icon: Icon(Icons.arrow_back_ios_new_outlined)),
          Text(
            "Detailed Info",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}
