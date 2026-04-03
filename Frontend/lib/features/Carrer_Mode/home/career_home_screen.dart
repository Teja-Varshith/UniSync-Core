import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';
import 'package:url_launcher/url_launcher.dart';

class CareerHomeScreen extends ConsumerStatefulWidget {
  final Function(int)? onTabChanged;
  
  const CareerHomeScreen({super.key, this.onTabChanged});

  @override
  ConsumerState<CareerHomeScreen> createState() => _CareerHomeScreenState();
}

class _CareerHomeScreenState extends ConsumerState<CareerHomeScreen> {
final roadmapData = [
  {
    "title": "Programming Languages",
    "subtitle": "Master the building blocks of software development",
    "subItems": [
      {"name": "C++", "url": "https://roadmap.sh/pdfs/roadmaps/cpp.pdf"},
      {"name": "Java", "url": "https://roadmap.sh/pdfs/roadmaps/java.pdf"},
      {"name": "Python", "url": "https://roadmap.sh/pdfs/roadmaps/python.pdf"},
      {"name": "JavaScript", "url": "https://roadmap.sh/pdfs/roadmaps/javascript.pdf"},
      {"name": "Go", "url": "https://roadmap.sh/pdfs/roadmaps/golang.pdf"},
    ]
  },
  {
    "title": "Frontend Development",
    "subtitle": "Create stunning, responsive interfaces",
    "subItems": [
      {"name": "Frontend Roadmap", "url": "https://roadmap.sh/pdfs/roadmaps/frontend.pdf"},
      {"name": "React", "url": "https://roadmap.sh/pdfs/roadmaps/react.pdf"},
      {"name": "Vue", "url": "https://roadmap.sh/pdfs/roadmaps/vue.pdf"},
      {"name": "Angular", "url": "https://roadmap.sh/pdfs/roadmaps/angular.pdf"},
    ]
  },
  {
    "title": "Backend Development",
    "subtitle": "Build scalable server-side systems",
    "subItems": [
      {"name": "Backend Roadmap", "url": "https://roadmap.sh/pdfs/roadmaps/backend.pdf"},
      {"name": "Node.js", "url": "https://roadmap.sh/pdfs/roadmaps/nodejs.pdf"},
      {"name": "Spring Boot", "url": "https://roadmap.sh/pdfs/roadmaps/spring-boot.pdf"},
      {"name": "ASP.NET Core", "url": "https://roadmap.sh/pdfs/roadmaps/aspnet-core.pdf"},
    ]
  },
  {
    "title": "Data Structures & Algorithms",
    "subtitle": "Crack interviews with solid fundamentals",
    "subItems": [
      {"name": "Computer Science", "url": "https://roadmap.sh/pdfs/roadmaps/computer-science.pdf"},
      {"name": "Data Structures", "url": "https://roadmap.sh/pdfs/roadmaps/data-structures-and-algorithms.pdf"},
    ]
  },
  {
    "title": "DevOps & Cloud",
    "subtitle": "Deploy and manage scalable applications",
    "subItems": [
      {"name": "DevOps Roadmap", "url": "https://roadmap.sh/pdfs/roadmaps/devops.pdf"},
      {"name": "Docker", "url": "https://roadmap.sh/pdfs/roadmaps/docker.pdf"},
      {"name": "Kubernetes", "url": "https://roadmap.sh/pdfs/roadmaps/kubernetes.pdf"},
      {"name": "AWS", "url": "https://roadmap.sh/pdfs/roadmaps/aws.pdf"},
    ]
  },
];


  void _showSubRoadmaps(Map<String, dynamic> category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final List<Map<String, String>> subItems = List<Map<String, String>>.from(category["subItems"]);
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category["title"],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ...subItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () async {
                    final uri = Uri.parse(item["url"]!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[850]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, color: Colors.orangeAccent, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          item["name"]!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                      ],
                    ),
                  ),
                ),
              )),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 5),
              child: Row(
                children: [
                   Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                          '# Hustle',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),


                        Text(
                              'Get Placement Ready',
                              style: const TextStyle(
                                fontSize: 14,
                                // fontStyle: FontStyle.italic,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                        ),

                     ],
                   ),
                                    
                  
                ],
              ),
            ),

             Divider(
                   color: Colors.white,
                       ),

            _interviewCard(context),
            SizedBox(height: 10,),
            softActionCard(
              title: 'Build your Portfolio',
              subtitle: 'Upload resume and auto-generate a beautiful website',
              bgColor: const Color(0xFFE3F2FD),
              titleColor: const Color(0xFF0D47A1),
              subtitleColor: const Color(0xFF1565C0),
              arrowBg: const Color(0xFFBBDEFB),
              arrowColor: const Color(0xFF0D47A1),
              onTap: () {
                widget.onTabChanged?.call(2);
              },
            ),
            softActionCard(
              title: 'Resume review with Arya',
              subtitle: 'Receive in real-time, in-depth resume feedback',
              bgColor: const Color(0xFFF2EEFF),
              titleColor: const Color(0xFF4B3F72),
              subtitleColor: const Color(0xFF6E6A86),
              arrowBg: const Color(0xFFE6DEFF),
              arrowColor: const Color(0xFF4B3F72),
              onTap: () {
                Routemaster.of(context).push('/resume-analyzer');
              },
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
    itemCount: (roadmapData.length / 2).ceil(),
    itemBuilder: (context, columnIndex) {
      final int firstIndex = columnIndex * 2;
      final int secondIndex = firstIndex + 1;

      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            // TOP CARD
            topicCard(
              title: roadmapData[firstIndex]["title"] as String,
              subtitle: roadmapData[firstIndex]["subtitle"] as String,
              index: firstIndex,
              onTap: () => _showSubRoadmaps(roadmapData[firstIndex]),
            ),

            const SizedBox(height: 12),

            // BOTTOM CARD (only if exists)
            if (secondIndex < roadmapData.length)
              topicCard(
                title: roadmapData[secondIndex]["title"] as String,
                subtitle: roadmapData[secondIndex]["subtitle"] as String,
                index: secondIndex,
                onTap: () => _showSubRoadmaps(roadmapData[secondIndex]),
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
  final List<List<Color>> topicGradients = [
    [const Color(0xFFFBBF24), const Color(0xFFF59E0B)], // yellow-orange
    [const Color(0xFF34D399), const Color(0xFF10B981)], // green-emerald
    [const Color(0xFF60A5FA), const Color(0xFF3B82F6)], // blue
    [const Color(0xFFF472B6), const Color(0xFFEC4899)], // pink
    [const Color(0xFFA78BFA), const Color(0xFF8B5CF6)], // purple
    [const Color(0xFFFB7185), const Color(0xFFF43F5E)], // rose
  ];

  final gradient = topicGradients[index % topicGradients.length];

  return Padding(
    padding: const EdgeInsets.only(right: 12),
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: 280,
        height: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: gradient[1].withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Glassmorphism arrow icon
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Icon(
                  Icons.arrow_outward_rounded,
                  size: 20,
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
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.3,
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
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
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
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            // ARROW
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: arrowBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: arrowColor,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _interviewCard(BuildContext context) {
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
                'Hey, I am Uni\nyour AI interviewer',
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
              onPressed: () {
                Routemaster.of(context).push('/carrer-interview-screen');
              },
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
