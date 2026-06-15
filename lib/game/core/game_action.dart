enum StatusTab { inventory, quest, skill, equipment, sect }

enum MessageFilter { all, dialogue, combat, system, quest }

sealed class GameAction {
  const GameAction();
}

class MoveAction extends GameAction {
  const MoveAction(this.direction);

  final String direction;
}

class TalkToNpcAction extends GameAction {
  const TalkToNpcAction(this.npcId);

  final String npcId;
}

class UseItemAction extends GameAction {
  const UseItemAction(this.itemId);

  final String itemId;
}

class EquipItemAction extends GameAction {
  const EquipItemAction(this.itemId);

  final String itemId;
}

class UnequipItemAction extends GameAction {
  const UnequipItemAction(this.slot);

  final String slot;
}

class AcceptQuestAction extends GameAction {
  const AcceptQuestAction(this.questId);

  final String questId;
}

class TrackQuestAction extends GameAction {
  const TrackQuestAction(this.questId);

  final String questId;
}

class InvestigateAction extends GameAction {
  const InvestigateAction();
}

class RestAction extends GameAction {
  const RestAction();
}

class SelectStatusTabAction extends GameAction {
  const SelectStatusTabAction(this.tab);

  final StatusTab tab;
}

class SelectMessageFilterAction extends GameAction {
  const SelectMessageFilterAction(this.filter);

  final MessageFilter filter;
}
