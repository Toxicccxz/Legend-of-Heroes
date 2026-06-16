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
      backgroundColor: const Color(0xFFF2F0EA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              const _MudHeader(),
              const SizedBox(height: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 900) {
                      return const _WideMudLayout();
                    }
                    return const _CompactMudLayout();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MudHeader extends StatelessWidget {
  const _MudHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(width: 1.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Text(
              '侠客行 · 江湖终端',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          Text('地图 / 交互 / 战斗 / 师承'),
        ],
      ),
    );
  }
}

class _WideMudLayout extends StatelessWidget {
  const _WideMudLayout();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        SizedBox(width: 340, child: MapPanel()),
        SizedBox(width: 8),
        Expanded(child: ActionMessagePanel()),
        SizedBox(width: 8),
        SizedBox(width: 360, child: CharacterStatusPanel(expanded: true)),
      ],
    );
  }
}

class _CompactMudLayout extends StatelessWidget {
  const _CompactMudLayout();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        CharacterStatusPanel(),
        SizedBox(height: 8),
        Expanded(flex: 5, child: MapPanel()),
        SizedBox(height: 8),
        Expanded(flex: 5, child: ActionMessagePanel()),
      ],
    );
  }
}
