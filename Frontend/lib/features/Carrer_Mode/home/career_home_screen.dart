import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CareerHomeScreen extends ConsumerStatefulWidget {
  const CareerHomeScreen({super.key});

  @override
  ConsumerState<CareerHomeScreen> createState() => _CareerHomeScreenState();
}

class _CareerHomeScreenState extends ConsumerState<CareerHomeScreen> {


final topics = [
  {
    "title": "Programming Languages",
    "subtitle": "Master the building blocks of software development",
  },
  {
    "title": "Frontend Development",
    "subtitle": "Create stunning, responsive interfaces",
  },
  {
    "title": "Backend Development",
    "subtitle": "Build scalable server-side systems",
  },
  
  {
    "title": "Data Structures & Algorithms",
    "subtitle": "Crack interviews with solid fundamentals",
  },
  {
    "title": "Data Structures & Algorithms",
    "subtitle": "Crack interviews with solid fundamentals",
  },
  {
    "title": "Data Structures & Algorithms",
    "subtitle": "Crack interviews with solid fundamentals",
  },
  {
    "title": "Data Structures & Algorithms",
    "subtitle": "Crack interviews with solid fundamentals",
  },
];


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _interviewCard(),
            SizedBox(height: 10,),
            softActionCard(
  title: 'Resume review with Arya',
  subtitle: 'Receive in real-time, in-depth resume feedback',
  bgColor: const Color(0xFFF2EEFF),
  titleColor: const Color(0xFF4B3F72),
  subtitleColor: const Color(0xFF6E6A86),
  arrowBg: const Color(0xFFE6DEFF),
  arrowColor: const Color(0xFF4B3F72),
  onTap: () {},
),
softActionCard(
  title: 'Rapid practice flash cards',
  subtitle: 'Brush through every aspect of any skill or tool',
  bgColor: const Color(0xFFFFE8E5),
  titleColor: const Color(0xFF7A3E3E),
  subtitleColor: const Color(0xFF9A5A5A),
  arrowBg: const Color(0xFFFFD6CF),
  arrowColor: const Color(0xFF7A3E3E),
  onTap: () {},
),

            SizedBox(height: 10,),
            Text(
              'Roadmaps',
              style:TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w700,
              ) ,
          ),

          SizedBox(height: 11,),

SizedBox(
  height: 400,
  child: ListView.builder(
    scrollDirection: Axis.horizontal,
    itemCount: (topics.length / 2).ceil(),
    itemBuilder: (context, columnIndex) {
      final int firstIndex = columnIndex * 2;
      final int secondIndex = firstIndex + 1;

      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            // TOP CARD
            topicCard(
              title: topics[firstIndex]["title"]!,
              subtitle: topics[firstIndex]["subtitle"]!,
              index: firstIndex,
              onTap: () {},
            ),

            const SizedBox(height: 12),

            // BOTTOM CARD (only if exists)
            if (secondIndex < topics.length)
              topicCard(
                title: topics[secondIndex]["title"]!,
                subtitle: topics[secondIndex]["subtitle"]!,
                index: secondIndex,
                onTap: () {},
              ),
          ],
        ),
      );
    },
  ),
),


          ],
        ),
      ),
    );
  }
}

Widget topicCard({
  required String title,
  required String subtitle,
  required int index,
  required VoidCallback onTap,
}) {
  final List<Color> topicCardColors = [
  Color(0xFFFACC15), // yellow
  Color(0xFF22C55E), // green
  Color(0xFF60A5FA), // blue
  Color(0xFFF472B6), // pink
  Color(0xFFA78BFA), // purple
  Color(0xFFFB7185), // rose
];

  final bgColor = topicCardColors[index % topicCardColors.length];

  return Padding(
    padding: const EdgeInsets.only(right: 12),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
         width: 300,
  height: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            // Arrow icon
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_outward_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),

            // Text at bottom
            Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


Widget softActionCard({
  required String title,
  required String subtitle,
  required Color bgColor,
  required Color titleColor,
  required Color subtitleColor,
  required Color arrowBg,
  required Color arrowColor,
  VoidCallback? onTap,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // ARROW
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: arrowBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: arrowColor,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _interviewCard() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Color(0xFFFFF1D6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          width: 0,
          color: Colors.black,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFEAEAEA),
                child: Icon(
                  Icons.smart_toy_outlined,
                  size: 18,
                  color: Color(0xFF111111),
                ),
              ),
              SizedBox(width: 10),
              Text(
                'Hey, I am Aavi\nyour ai interview taker',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111111),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Divider(),
          const SizedBox(height: 4),
          const Text(
            'Practice real interview questions and get instant feedback.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF555555),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(
                Icons.rocket_launch,
                size: 18,
                color: Colors.orangeAccent,
              ),
              label: const Text(
                'Start Interview',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111111),
                foregroundColor: const Color(0xFFEDEDED),
                shape: StadiumBorder(),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
