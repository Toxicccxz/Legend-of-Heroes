import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/core/game_controller.dart';
import '../widgets/action_message_panel.dart';
import '../widgets/character_status_panel.dart';
import '../widgets/map_panel.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);

    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final errorMessage = state.errorMessage;
    if (errorMessage != null) {
      return Scaffold(body: Center(child: Text(errorMessage)));
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: const [
              CharacterStatusPanel(),
              SizedBox(height: 8),
              Expanded(flex: 5, child: MapPanel()),
              SizedBox(height: 8),
              Expanded(flex: 5, child: ActionMessagePanel()),
            ],
          ),
        ),
      ),
    );
  }
}
