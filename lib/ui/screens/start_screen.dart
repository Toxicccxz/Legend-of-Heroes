import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/core/game_controller.dart';
import '../../game/repositories/game_definition_repository.dart';
import 'game_screen.dart';

class StartScreen extends ConsumerWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definitions = ref.watch(gameDefinitionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F0EA),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: definitions.when(
                loading: () => const CircularProgressIndicator(),
                error:
                    (error, stackTrace) =>
                        _StartCard(child: Text('游戏数据加载失败：$error')),
                data:
                    (gameDefinitions) =>
                        _StartMenu(definitions: gameDefinitions),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StartMenu extends ConsumerWidget {
  const _StartMenu({required this.definitions});

  final GameDefinitions definitions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedGame = ref.watch(savedGameProvider);

    return savedGame.when(
      loading:
          () => const _StartCard(
            child: Center(child: CircularProgressIndicator()),
          ),
      error: (error, stackTrace) => _StartCard(child: Text('存档读取失败：$error')),
      data: (savedState) {
        final hasSave = savedState != null;
        final savedRoomName =
            savedState == null
                ? null
                : definitions.rooms[savedState.currentRoomId]?.name ??
                    savedState.currentRoomId;
        return _StartCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '侠客行',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                '文字江湖',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 28),
              _MenuButton(
                label: '继续游戏',
                enabled: hasSave,
                onPressed: () => _continueGame(context, ref),
              ),
              const SizedBox(height: 12),
              _MenuButton(
                label: '新的冒险',
                onPressed: () => _startNewGame(context, ref),
              ),
              if (savedRoomName != null) ...[
                const SizedBox(height: 16),
                Text(
                  '存档位置：$savedRoomName',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _continueGame(BuildContext context, WidgetRef ref) async {
    final loaded =
        await ref.read(gameControllerProvider.notifier).loadSavedGame();
    if (!context.mounted || !loaded) {
      return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const GameScreen()));
    if (context.mounted) {
      ref.invalidate(savedGameProvider);
    }
  }

  Future<void> _startNewGame(BuildContext context, WidgetRef ref) async {
    await ref.read(gameControllerProvider.notifier).startNewGame();
    ref.invalidate(savedGameProvider);
    if (!context.mounted) {
      return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const GameScreen()));
    if (context.mounted) {
      ref.invalidate(savedGameProvider);
    }
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          disabledForegroundColor: Colors.black38,
          side: BorderSide(color: enabled ? Colors.black : Colors.black26),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: enabled ? onPressed : null,
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
