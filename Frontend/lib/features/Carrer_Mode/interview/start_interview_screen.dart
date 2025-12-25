import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisync/features/Carrer_Mode/interview/carrer_interview_screen.dart';

class StartInterviewScreen extends ConsumerStatefulWidget {
  const StartInterviewScreen({super.key});

  @override
  ConsumerState<StartInterviewScreen> createState() => _StartInterviewScreenState();
}

class _StartInterviewScreenState extends ConsumerState<StartInterviewScreen> {
  @override
  Widget build(BuildContext context) {
    final tmplte = ref.read(selectedTemplateProvider);
    final chips = tmplte!.topics;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _appBar(),
            Row(
              children: [
                SizedBox(
                  height: 50,
                  width: 50,
                  child: CachedNetworkImage(imageUrl: tmplte.icon)),
                Text(tmplte.title + 'dfghjkfghjklfghjkbjkfghjkfghjk'),
              ],
            ),
            Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                children: List.generate(
                  chips.length,
                  (index) => SelectableChip(
                    label: chips[index],
                    isSelected: false,
                    onTap: () {
                    },
                  ),
                ),
              ),
              Text('Evaluation Metrics'),
              Text(tmplte.evalutionMetrics.toString()),
              ElevatedButton(onPressed: () {

              }, child: Text("Start Interview")),

          ],
        )
      ),
    );
  }
}


Widget _appBar() {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      child: Row(
        children: [
          IconButton(onPressed: () {}, icon: Icon(Icons.arrow_back_ios_new_outlined)),
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