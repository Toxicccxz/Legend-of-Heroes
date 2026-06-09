import '../core/game_state.dart';
import '../models/dialogue_definition.dart';

class DialogueSystem {
  const DialogueSystem();

  DialogueDefinition? getDialogueForNpc(GameState state, String npcId) {
    final definitions = state.definitions;
    final npc = definitions?.npcs[npcId];
    if (definitions == null || npc == null) {
      return null;
    }
    return definitions.dialogues[npc.dialogueId];
  }

  List<String> talkToNpc(GameState state, String npcId) {
    final dialogue = getDialogueForNpc(state, npcId);
    if (dialogue == null) {
      return const ['对方没有回应。'];
    }
    return dialogue.lines;
  }
}
