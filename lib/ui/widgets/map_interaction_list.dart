part of 'map_panel.dart';

class _MapInteractionList extends StatelessWidget {
  const _MapInteractionList({required this.state, required this.ref});

  final GameState state;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final room = state.definitions?.rooms[state.currentRoomId];
    final npcs =
        room?.npcs
            .map((id) => state.definitions?.npcs[id])
            .whereType<NpcDefinition>()
            .toList() ??
        const <NpcDefinition>[];
    final hasInvestigate = room?.investigateEvents.isNotEmpty ?? false;
    final hasRest = room?.restEvents.isNotEmpty ?? false;
    final hasInteractions = npcs.isNotEmpty || hasInvestigate || hasRest;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('可互动', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Expanded(
            child:
                hasInteractions
                    ? ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        for (final npc in npcs)
                          _InteractionRow(
                            icon: Icons.person_outline,
                            label: npc.name,
                            actionLabel: '对话',
                            onPressed: () => _showNpcDialog(context, npc),
                          ),
                        if (hasInvestigate)
                          _InteractionRow(
                            icon: Icons.search,
                            label: '可疑线索',
                            actionLabel: '调查',
                            onPressed:
                                () => ref
                                    .read(gameControllerProvider.notifier)
                                    .dispatch(const InvestigateAction()),
                          ),
                        if (hasRest)
                          _InteractionRow(
                            icon: Icons.bed,
                            label: '休息点',
                            actionLabel: '休息',
                            onPressed:
                                () => ref
                                    .read(gameControllerProvider.notifier)
                                    .dispatch(const RestAction()),
                          ),
                      ],
                    )
                    : const Center(child: Text('无')),
          ),
        ],
      ),
    );
  }

  Future<void> _showNpcDialog(BuildContext context, NpcDefinition npc) {
    final options = [
      const _NpcDialogOption(type: 'talk', label: '交谈', icon: Icons.chat),
      const _NpcDialogOption(
        type: 'spar',
        label: '切磋',
        icon: Icons.sports_martial_arts,
      ),
      for (final option in npc.interactions)
        _NpcDialogOption(
          type: option.type,
          label: option.label,
          icon: _iconForOption(option.type),
        ),
    ];

    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(npc.name),
          content: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(npc.description),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in options)
                      OutlinedButton.icon(
                        icon: Icon(option.icon, size: 16),
                        label: Text(option.label),
                        onPressed: () {
                          Navigator.of(context).pop();
                          ref
                              .read(gameControllerProvider.notifier)
                              .dispatch(
                                InteractWithNpcAction(npc.id, option.type),
                              );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  IconData _iconForOption(String type) {
    return switch (type) {
      'trade' => Icons.storefront,
      'quest' => Icons.assignment_outlined,
      'joinSect' => Icons.account_balance,
      'learn' => Icons.school_outlined,
      'battle' => Icons.local_fire_department_outlined,
      _ => Icons.more_horiz,
    };
  }
}

class _NpcDialogOption {
  const _NpcDialogOption({
    required this.type,
    required this.label,
    required this.icon,
  });

  final String type;
  final String label;
  final IconData icon;
}

class _InteractionRow extends StatelessWidget {
  const _InteractionRow({
    required this.icon,
    required this.label,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(42, 28),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: onPressed,
            child: Text(actionLabel, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
