import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisync/features/Carrer_Mode/cards/controller/domain_controller.dart';

class CardQuiz extends ConsumerStatefulWidget {
  const CardQuiz({super.key});

  @override
  ConsumerState<CardQuiz> createState() => _CardQuizState();
}

class _CardQuizState extends ConsumerState<CardQuiz> {
  @override
  Widget build(BuildContext context) {
      final _selctedDomain = ref.read(SelectedDomainProvider);
    return Scaffold(
      body: Column(
        children: [
          Center(child: Text(_selctedDomain.toString()))
        ],
      ),
    );
  }
}