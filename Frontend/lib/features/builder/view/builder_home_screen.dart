import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';
import 'package:unisync/app/providers.dart';
import 'package:unisync/features/services/appMode.dart';

class BuilderHomeScreen extends ConsumerStatefulWidget {
  const BuilderHomeScreen({super.key});

  @override
  ConsumerState<BuilderHomeScreen> createState() => _BuilderHomeScreenState();
}

class _BuilderHomeScreenState extends ConsumerState<BuilderHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: Column(
        children: [
          _appBar(ref, context),
        ],
      )),
    );
  }
}

Widget _appBar(WidgetRef ref, BuildContext context) {
  return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 20),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.tag),
                      Text(
                        'Grind',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Get your projects Alive!',
                    style: const TextStyle(
                      fontSize: 14,
                      // fontStyle: FontStyle.italic,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Spacer(),
              AvatarSlideToggle(
                currentMode: ref.read(AppModeProvider),
                user: ref.read(userProvider)!,
                menu: [AppMode.career, AppMode.campus, AppMode.builder],
                onModeChanged: (mode) {
                  if (mode == AppMode.campus) {
                    Routemaster.of(context).replace("/");
                    // mode = ref.watch(AppModeProvider);
                    ref.read(AppModeProvider.notifier).state = AppMode.campus;
                  }

                  if (mode == AppMode.career) {
                    Routemaster.of(context).replace("/carrer");
                    // mode = ref.watch(AppModeProvider);
                    ref.read(AppModeProvider.notifier).state = AppMode.builder;
                  }

                  // YOU control this
                  // trigger AnimatedSwitcher / PageTransition
                  debugPrint("Switched to $mode");
                },
              )
            ],
          ),
        ),

        


      ]));
}
