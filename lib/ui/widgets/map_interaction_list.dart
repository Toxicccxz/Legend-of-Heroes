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
    final items =
        room?.items
            .map((id) => state.definitions?.items[id])
            .whereType<ItemDefinition>()
            .toList() ??
        const <ItemDefinition>[];
    final commands = room?.commands ?? const <RoomCommandDefinition>[];
    final hasInteractions =
        npcs.isNotEmpty ||
        items.isNotEmpty ||
        commands.isNotEmpty ||
        hasInvestigate ||
        hasRest;

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
          const Text('动作面板', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Expanded(
            child:
                hasInteractions
                    ? ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _SectionLabel(label: '房间'),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _CommandChip(
                              icon: Icons.visibility_outlined,
                              label: '查看',
                              onPressed: () => _dispatchCommand('look room'),
                            ),
                            if (hasInvestigate)
                              _CommandChip(
                                icon: Icons.search,
                                label: '调查',
                                onPressed:
                                    () => _dispatchCommand('investigate'),
                              ),
                            if (hasRest)
                              _CommandChip(
                                icon: Icons.bed,
                                label: '休息',
                                onPressed: () => _dispatchCommand('rest'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        for (final npc in npcs)
                          _NpcActionCard(
                            npc: npc,
                            onOpenDialog: () => _showNpcDialog(context, npc),
                            onCommand: _dispatchCommand,
                            onApprentice:
                                (sectId) => _handleApprenticeCommand(
                                  context,
                                  npc,
                                  sectId,
                                ),
                          ),
                        if (items.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _SectionLabel(label: '物品'),
                          for (final item in items)
                            _InteractionRow(
                              icon: Icons.inventory_2_outlined,
                              label: item.name,
                              actionLabel: '查看',
                              onPressed:
                                  () => _dispatchCommand('look ${item.id}'),
                            ),
                        ],
                        if (commands.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _SectionLabel(label: '场景'),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final command in commands)
                                _CommandChip(
                                  icon: Icons.touch_app_outlined,
                                  label:
                                      command.label.isEmpty
                                          ? command.verb
                                          : command.label,
                                  onPressed:
                                      () => _dispatchCommand(command.verb),
                                ),
                            ],
                          ),
                        ],
                      ],
                    )
                    : const Center(child: Text('无')),
          ),
        ],
      ),
    );
  }

  void _dispatchCommand(String command) {
    ref
        .read(gameControllerProvider.notifier)
        .dispatch(ExecuteCommandAction(command));
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
          sectId: option.sectId,
        ),
    ];

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
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
                        onPressed:
                            () => _handleNpcOption(
                              context,
                              dialogContext,
                              npc,
                              option,
                            ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleNpcOption(
    BuildContext parentContext,
    BuildContext dialogContext,
    NpcDefinition npc,
    _NpcDialogOption option,
  ) async {
    Navigator.of(dialogContext).pop();
    if (option.type == 'joinSect' &&
        state.player.sectId == null &&
        option.sectId != null) {
      final confirmed = await _confirmFirstApprenticeship(
        parentContext,
        option.sectId!,
      );
      if (!confirmed) {
        return;
      }
    }
    _dispatchCommand(_commandForNpcOption(npc, option.type));
  }

  Future<void> _handleApprenticeCommand(
    BuildContext context,
    NpcDefinition npc,
    String? sectId,
  ) async {
    if (state.player.sectId == null && sectId != null) {
      final confirmed = await _confirmFirstApprenticeship(context, sectId);
      if (!confirmed) {
        return;
      }
    }
    _dispatchCommand('apprentice ${npc.id}');
  }

  Future<bool> _confirmFirstApprenticeship(
    BuildContext context,
    String sectId,
  ) async {
    final sect = state.definitions?.sects[sectId];
    if (sect == null) {
      return true;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('拜入${sect.name}？'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sect.description),
                if (sect.features.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('门派特点：${sect.features}'),
                ],
                const SizedBox(height: 8),
                const Text('拜师规则：'),
                for (final rule in sect.rules) Text('· $rule'),
                const SizedBox(height: 8),
                const Text('这是第一次拜师，请三思而后行。'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('再想想'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确认拜师'),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
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

  String _commandForNpcOption(NpcDefinition npc, String type) {
    return switch (type) {
      'talk' => 'ask ${npc.id}',
      'spar' => 'spar ${npc.id}',
      'trade' => 'trade ${npc.id}',
      'quest' => 'quest ${npc.id}',
      'joinSect' => 'apprentice ${npc.id}',
      'learn' => 'learn ${npc.id}',
      'battle' => 'kill ${npc.id}',
      _ => 'look ${npc.id}',
    };
  }
}

class _NpcActionCard extends StatelessWidget {
  const _NpcActionCard({
    required this.npc,
    required this.onOpenDialog,
    required this.onCommand,
    required this.onApprentice,
  });

  final NpcDefinition npc;
  final VoidCallback onOpenDialog;
  final void Function(String command) onCommand;
  final Future<void> Function(String? sectId) onApprentice;

  @override
  Widget build(BuildContext context) {
    final joinSectOption = _optionFor('joinSect');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF7),
        border: Border.all(),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, size: 18),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  npc.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: '更多',
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 28,
                  height: 28,
                ),
                onPressed: onOpenDialog,
                icon: const Icon(Icons.more_horiz),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              _CommandChip(
                icon: Icons.visibility_outlined,
                label: '看',
                onPressed: () => onCommand('look ${npc.id}'),
              ),
              _CommandChip(
                icon: Icons.chat_bubble_outline,
                label: '问',
                onPressed: () => onCommand('ask ${npc.id}'),
              ),
              _CommandChip(
                icon: Icons.sports_martial_arts,
                label: '切磋',
                onPressed: () => onCommand('spar ${npc.id}'),
              ),
              for (final option in npc.interactions)
                if (option.type == 'joinSect')
                  _CommandChip(
                    icon: Icons.account_balance,
                    label: option.label,
                    onPressed: () => onApprentice(joinSectOption?.sectId),
                  )
                else
                  _CommandChip(
                    icon: _iconForOptionType(option.type),
                    label: option.label,
                    onPressed: () => onCommand(_commandForOption(option.type)),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  NpcInteractionOption? _optionFor(String type) {
    for (final option in npc.interactions) {
      if (option.type == type) {
        return option;
      }
    }
    return null;
  }

  String _commandForOption(String type) {
    return switch (type) {
      'trade' => 'trade ${npc.id}',
      'quest' => 'quest ${npc.id}',
      'learn' => 'learn ${npc.id}',
      'battle' => 'kill ${npc.id}',
      _ => 'look ${npc.id}',
    };
  }

  IconData _iconForOptionType(String type) {
    return switch (type) {
      'trade' => Icons.storefront,
      'quest' => Icons.assignment_outlined,
      'learn' => Icons.school_outlined,
      'battle' => Icons.local_fire_department_outlined,
      _ => Icons.more_horiz,
    };
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _CommandChip extends StatelessWidget {
  const _CommandChip({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 28),
        padding: const EdgeInsets.symmetric(horizontal: 7),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        side: const BorderSide(color: Colors.black),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onPressed,
    );
  }
}

class _NpcDialogOption {
  const _NpcDialogOption({
    required this.type,
    required this.label,
    required this.icon,
    this.sectId,
  });

  final String type;
  final String label;
  final IconData icon;
  final String? sectId;
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
