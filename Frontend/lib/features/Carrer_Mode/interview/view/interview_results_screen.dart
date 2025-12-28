import 'package:flutter/material.dart';

class InterviewResultsScreen extends StatefulWidget {
  const InterviewResultsScreen({super.key});

  @override
  State<InterviewResultsScreen> createState() => _InterviewResultsScreenState();
}

class _InterviewResultsScreenState extends State<InterviewResultsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _appBar(context),
              Container(
                width: double.infinity,
                child: ExpandableCard()
              ),

            ],
          ),
        ),
      ),
    );
  }
}

class ExpandableCard extends StatefulWidget {
  const ExpandableCard({super.key});

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard>
    with TickerProviderStateMixin {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          setState(() {
            expanded = !expanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "AI Interview Analysis",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (expanded)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      "Score: 7.5/10\nVerdict: Good\nImprove system design answers.",
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
            "Interview's Report",
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