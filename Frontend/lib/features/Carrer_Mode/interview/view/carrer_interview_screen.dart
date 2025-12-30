// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';
import 'package:unisync/features/Carrer_Mode/interview/controllers/carrer_controller.dart';
import 'package:unisync/models/template_model.dart';

final selectedTemplateProvider = StateProvider<TemplateModel?>((ref) => null);

class CarrerInterviewScreen extends ConsumerStatefulWidget {
  const CarrerInterviewScreen({super.key});

  @override
  ConsumerState<CarrerInterviewScreen> createState() =>
      _CarrerInterviewScreenState();
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
            _appBar(context),
            Divider(),
            _searchBar(context),
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
                final chips = [
                  "All",
                  ...ref
                      .read(carrerControllerProvider.notifier)
                      .AvailableDomains
                ];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.start,
                    children: List.generate(
                      chips.length,
                      (index) => GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIndex = index;
                          });
                          ref
                              .read(carrerControllerProvider.notifier)
                              .filterByDomain(chips[index]);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selectedIndex == index
                                ? Theme.of(context).primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selectedIndex == index
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            chips[index],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: selectedIndex == index
                                  ? Colors.white
                                  : Colors.grey.shade800,
                            ),
                          ),
                        ),
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
                            ref.read(selectedTemplateProvider.notifier).state =
                                template;
                            Routemaster.of(context)
                                .push('/startInterviewScreen');
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
    super.key,
    required this.logo,
    required this.heading,
    required this.topics,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), // subtle tint
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 52,
            width: 52,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: CachedNetworkImage(
              imageUrl: logo,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 14),
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
                  topics.join(" • "),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
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

Widget _searchBar(BuildContext context) {
  final accent = Theme.of(context).colorScheme.primary;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16),
    child: TextField(
      decoration: InputDecoration(
        hintText: "Search for templates",
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: accent,
            width: 1.4,
          ),
        ),
        suffixIcon: Icon(
          Icons.search,
          color: Colors.grey.shade600,
        ),
      ),
    ),
  );
}




Widget _appBar(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
    child: Row(
      children: [
        IconButton(
          onPressed: () => Routemaster.of(context).replace('/carrer'),
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
      ],
    ),
  );
}
