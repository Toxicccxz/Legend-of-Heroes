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
                            actionLabel: '交谈',
                            onPressed:
                                () => ref
                                    .read(gameControllerProvider.notifier)
                                    .dispatch(TalkToNpcAction(npc.id)),
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
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: 8),
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
