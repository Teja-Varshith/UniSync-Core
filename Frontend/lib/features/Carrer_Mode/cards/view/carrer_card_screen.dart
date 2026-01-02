import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';
import 'package:unisync/features/Carrer_Mode/cards/controller/domain_controller.dart';
import 'package:unisync/models/domain_model.dart';

class CarrerCardScreen extends ConsumerStatefulWidget {
  const CarrerCardScreen({super.key});

  @override
  ConsumerState<CarrerCardScreen> createState() => _CarrerCardScreenState();
}

class _CarrerCardScreenState extends ConsumerState<CarrerCardScreen> {
  @override
  Widget build(BuildContext context) {
    final domains = ref.watch(getAllDomains);
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 239, 210),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                "Practice Cards",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            domains.when(
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
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    return domainArea(ref,context,data[index]);
                  },
                );
              },
            )


           
          ],
        ),
      ),
    );
  }
}

Widget domainArea(WidgetRef ref, BuildContext context, DomainModel domain) {
  return  Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      domain.domain.toUpperCase(),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: List.generate(
                        domain.subDomain.length,
                        (indx) => GestureDetector(
                          onTap: () {
                            ref.read(SelectedDomainProvider.notifier).state = domain.subDomain[indx].id;
                            Routemaster.of(context).push("/cardsQuiz");
                          },
                          child: SelectableChip2(label: domain.subDomain[indx].label, logo: domain.subDomain[indx].logo),
                        )
                        
                      )
                    ),
                  ],
                ),
              ),
  );
}

class SelectableChip2 extends StatelessWidget {
  final String label;
  final String logo;

  const SelectableChip2({
    super.key,
    required this.label,
    required this.logo,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            // color: isSelected ? Colors.black : Colors.grey,
            ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
