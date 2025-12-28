// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';
import 'package:unisync/features/Carrer_Mode/interview/controllers/carrer_controller.dart';
import 'package:unisync/models/template_model.dart';

 final selectedTemplateProvider =
    StateProvider<TemplateModel?>((ref) => null);

class CarrerInterviewScreen extends ConsumerStatefulWidget {
  const CarrerInterviewScreen({super.key});

  @override
  ConsumerState<CarrerInterviewScreen> createState() => _CarrerInterviewScreenState();
}

class _CarrerInterviewScreenState extends ConsumerState<CarrerInterviewScreen> {


  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(carrerControllerProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _appBar(),
            _searchBar(),

            templates.when(
               loading: () => const Center(
      child: CircularProgressIndicator(),
    ),

    error: (error, _) => Center(
      child: Text(
        error.toString(),
        style: const TextStyle(color: Colors.red),
      ),
    ),
    data: (data) {
      final chips = ["All",...ref.read(carrerControllerProvider.notifier).AvailableDomains];
       return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                children: List.generate(
                  chips.length,
                  (index) => SelectableChip(
                    label: chips[index],
                    isSelected: selectedIndex == index,
                    onTap: () {
                      setState(() {
                        ref.read(carrerControllerProvider.notifier).filterByDomain(chips[index]);
                        selectedIndex = index;
                      });
                    },
                  ),
                ),
              ),
            );
    },
            ),

           Expanded(
  child: templates.when(
    loading: () => const Center(
      child: CircularProgressIndicator(),
    ),

    error: (error, _) => Center(
      child: Text(
        error.toString(),
        style: const TextStyle(color: Colors.red),
      ),
    ),

    data: (data) {
      if (data.isEmpty) {
        return const Center(
          child: Text("No templates found"),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final template = data[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                ref.read(selectedTemplateProvider.notifier).state = template;
                Routemaster.of(context).push('/startInterviewScreen');
              },
              child: TemplateCard(
                logo: template.icon,
                heading: template.title,
                topics: template.topics,
              ),
            ),
          );
        },
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

class TemplateCard extends StatelessWidget {
  final String logo;
  final String heading;
  final List<String> topics;
  const TemplateCard({
    Key? key,
    required this.logo,
    required this.heading,
    required this.topics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          width: 2,
          color: Colors.grey
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 50,
                  width: 50,
                  child: CachedNetworkImage(imageUrl: logo),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                     heading,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              
                   RichText(
  text: TextSpan(
    text: topics.join(','),
    style: const TextStyle(
      fontWeight: FontWeight.w900,
      fontSize: 14,
      color: Colors.black54,
      height: 1.4,
    ),
  ),
)

                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}



class SelectableChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectableChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.lightBlueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.black : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}


Widget _searchBar() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Container(
      child: TextField(
        decoration: InputDecoration(
          hint: Text("Search for templates"),
          filled: false,
         
          focusedBorder: OutlineInputBorder(
             borderSide: BorderSide(
              color: Colors.black,
            ),
            borderRadius: BorderRadius.circular(20)
          ),
          disabledBorder: OutlineInputBorder(
             borderSide: BorderSide(
              color: Colors.black,
            ),
            borderRadius: BorderRadius.circular(20)
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.black,
            ),
            borderRadius: BorderRadius.circular(20)
          ),
          border: OutlineInputBorder(
             borderSide: BorderSide(
              color: Colors.black,
            ),
            borderRadius: BorderRadius.circular(20)
          ),
          suffixIcon: Icon(Icons.search)
        ),
      )
    ),
  );
}

Widget _appBar() {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      child: Row(
        children: [
          IconButton(onPressed: () {}, icon: Icon(Icons.arrow_back_ios_new_outlined)),
          Text(
            "Select Interview Template",
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