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
    final hasRoomActions = hasInvestigate || hasRest;
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
                        if (hasRoomActions) ...[
                          _SectionLabel(label: '房间'),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
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
                        ],
                        for (final npc in npcs)
                          _NpcActionCard(
                            state: state,
                            npc: npc,
                            onOpenDialog: () => _showNpcDialog(context, npc),
                            onCommand: _dispatchCommand,
                            onInquiry:
                                (inquiryId) => _dispatchAction(
                                  AskNpcInquiryAction(npc.id, inquiryId),
                                ),
                            onGiveItem:
                                (itemId) => _dispatchAction(
                                  GiveItemToNpcAction(npc.id, itemId),
                                ),
                            onTrade: () => _showShopDialog(context, npc),
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
                                      () => _dispatchAction(
                                        ExecuteRoomCommandAction(
                                          command.verb,
                                          targetId: command.targetId,
                                        ),
                                      ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    )
                    : const SizedBox.shrink(),
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

  void _dispatchAction(GameAction action) {
    ref.read(gameControllerProvider.notifier).dispatch(action);
  }

  Future<void> _showNpcDialog(BuildContext context, NpcDefinition npc) {
    final options = [
      const _NpcDialogOption(type: 'talk', label: '交谈', icon: Icons.chat),
      for (final option in npc.interactions)
        if (option.type != 'spar')
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
                if (npc.inquiries.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    '可询问',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final inquiry in npc.inquiries)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.help_outline, size: 16),
                          label: Text(inquiry.label),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _dispatchAction(
                              AskNpcInquiryAction(npc.id, inquiry.id),
                            );
                          },
                        ),
                    ],
                  ),
                ],
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
    if (option.type == 'trade') {
      await _showShopDialog(parentContext, npc);
      return;
    }
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

  Future<void> _showShopDialog(BuildContext context, NpcDefinition npc) {
    final shopId = npc.shopId;
    final shop = shopId == null ? null : state.definitions?.shops[shopId];
    if (shop == null) {
      _dispatchCommand('trade ${npc.id}');
      return Future.value();
    }

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(shop.name),
          content: SizedBox(
            width: 340,
            child: _ShopGoodsList(
              state: state,
              npc: npc,
              shop: shop,
              onBuy: (itemId) {
                Navigator.of(dialogContext).pop();
                _dispatchAction(BuyShopItemAction(npc.id, itemId));
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('离开'),
            ),
          ],
        );
      },
    );
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
    required this.state,
    required this.npc,
    required this.onOpenDialog,
    required this.onCommand,
    required this.onInquiry,
    required this.onGiveItem,
    required this.onTrade,
    required this.onApprentice,
  });

  final GameState state;
  final NpcDefinition npc;
  final VoidCallback onOpenDialog;
  final void Function(String command) onCommand;
  final void Function(String inquiryId) onInquiry;
  final void Function(String itemId) onGiveItem;
  final VoidCallback onTrade;
  final Future<void> Function(String? sectId) onApprentice;

  @override
  Widget build(BuildContext context) {
    final joinSectOption = _optionFor('joinSect');
    final visibleOptions = _visibleOptions();
    final availableAcceptedItems = _availableAcceptedItems();
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
                label: '查看',
                onPressed: () => onCommand('look ${npc.id}'),
              ),
              _CommandChip(
                icon: Icons.chat_bubble_outline,
                label: '交谈',
                onPressed: () => onCommand('ask ${npc.id}'),
              ),
              for (final inquiry in npc.inquiries)
                _CommandChip(
                  icon: Icons.help_outline,
                  label: '问：${inquiry.label}',
                  onPressed: () => onInquiry(inquiry.id),
                ),
              for (final acceptedItem in availableAcceptedItems)
                _CommandChip(
                  icon: Icons.volunteer_activism_outlined,
                  label: _acceptedItemLabel(acceptedItem),
                  onPressed: () => onGiveItem(acceptedItem.itemId),
                ),
              for (final option in visibleOptions)
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
                    onPressed:
                        option.type == 'trade'
                            ? onTrade
                            : () => onCommand(_commandForOption(option.type)),
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

  List<NpcInteractionOption> _visibleOptions() {
    return npc.interactions.where((option) => option.type != 'spar').toList();
  }

  List<NpcAcceptedItemDefinition> _availableAcceptedItems() {
    return npc.acceptedItems.where((acceptedItem) {
      return _itemCount(acceptedItem.itemId) >= acceptedItem.count;
    }).toList();
  }

  int _itemCount(String itemId) {
    for (final entry in state.inventory) {
      if (entry.itemId == itemId) {
        return entry.count;
      }
    }
    return 0;
  }

  String _acceptedItemLabel(NpcAcceptedItemDefinition acceptedItem) {
    if (acceptedItem.label.isNotEmpty) {
      return acceptedItem.label;
    }
    final itemName = state.definitions?.items[acceptedItem.itemId]?.name;
    return itemName == null ? '交付' : '交出$itemName';
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

class _ShopGoodsList extends StatelessWidget {
  const _ShopGoodsList({
    required this.state,
    required this.npc,
    required this.shop,
    required this.onBuy,
  });

  final GameState state;
  final NpcDefinition npc;
  final ShopDefinition shop;
  final void Function(String itemId) onBuy;

  @override
  Widget build(BuildContext context) {
    if (shop.goods.isEmpty) {
      return const Text('货箱里空空如也。');
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (shop.description.isNotEmpty) ...[
          Text(shop.description),
          const SizedBox(height: 10),
        ],
        Text(
          '${npc.name}看了看你的钱袋：${state.player.gold} 金币',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        for (final good in shop.goods)
          _ShopGoodRow(
            state: state,
            good: good,
            onBuy: () => onBuy(good.itemId),
          ),
      ],
    );
  }
}

class _ShopGoodRow extends StatelessWidget {
  const _ShopGoodRow({
    required this.state,
    required this.good,
    required this.onBuy,
  });

  final GameState state;
  final ShopGoodDefinition good;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final item = state.definitions?.items[good.itemId];
    final canAfford = state.player.gold >= good.price;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF7),
        border: Border.all(),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_bag_outlined, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item?.name ?? good.itemId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text('${good.price} 金币', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(42, 28),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: canAfford ? onBuy : null,
            child: const Text('购买', style: TextStyle(fontSize: 12)),
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
