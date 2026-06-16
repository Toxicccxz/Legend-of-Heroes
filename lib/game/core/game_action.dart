enum StatusTab { inventory, quest, skill, equipment, sect }

enum MessageFilter { all, dialogue, combat, system, quest }

sealed class GameAction {
  const GameAction();
}

class MoveAction extends GameAction {
  const MoveAction(this.direction);

  final String direction;
}

class ExecuteCommandAction extends GameAction {
  const ExecuteCommandAction(this.input);

  final String input;
}

class ExecuteRoomCommandAction extends GameAction {
  const ExecuteRoomCommandAction(this.verb, {this.targetId});

  final String verb;
  final String? targetId;
}

class TalkToNpcAction extends GameAction {
  const TalkToNpcAction(this.npcId);

  final String npcId;
}

class InteractWithNpcAction extends GameAction {
  const InteractWithNpcAction(this.npcId, this.interactionType);

  final String npcId;
  final String interactionType;
}

class AskNpcInquiryAction extends GameAction {
  const AskNpcInquiryAction(this.npcId, this.inquiryId);

  final String npcId;
  final String inquiryId;
}

class GiveItemToNpcAction extends GameAction {
  const GiveItemToNpcAction(this.npcId, this.itemId);

  final String npcId;
  final String itemId;
}

class BuyShopItemAction extends GameAction {
  const BuyShopItemAction(this.npcId, this.itemId);

  final String npcId;
  final String itemId;
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

class MapSkillAction extends GameAction {
  const MapSkillAction(this.slot, this.skillId);

  final String slot;
  final String skillId;
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
