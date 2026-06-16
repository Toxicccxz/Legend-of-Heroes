import 'package:flutter_test/flutter_test.dart';
import 'package:legend_of_heroes/game/core/game_action.dart';
import 'package:legend_of_heroes/game/core/game_controller.dart';
import 'package:legend_of_heroes/game/models/dialogue_definition.dart';
import 'package:legend_of_heroes/game/models/item_definition.dart';
import 'package:legend_of_heroes/game/models/npc_definition.dart';
import 'package:legend_of_heroes/game/models/shop_definition.dart';
import 'package:legend_of_heroes/game/repositories/game_definition_repository.dart';
import 'package:legend_of_heroes/game/repositories/save_repository.dart';

void main() {
  test('buying a shop item spends gold and adds inventory', () {
    final controller = GameController(
      definitions: _definitions(price: 8),
      saveRepository: InMemorySaveRepository(),
    );

    controller.dispatch(const BuyShopItemAction('merchant', 'bread'));

    expect(controller.state.player.gold, 248);
    expect(
      controller.state.inventory
          .where((entry) => entry.itemId == 'bread')
          .single
          .count,
      3,
    );
    expect(controller.state.logs.last.message, '你花费 8 金币买下了面包。');
  });

  test('buying with insufficient gold leaves inventory unchanged', () {
    final controller = GameController(
      definitions: _definitions(price: 999),
      saveRepository: InMemorySaveRepository(),
    );

    controller.dispatch(const BuyShopItemAction('merchant', 'bread'));

    expect(controller.state.player.gold, 256);
    expect(
      controller.state.inventory
          .where((entry) => entry.itemId == 'bread')
          .single
          .count,
      2,
    );
    expect(controller.state.logs.last.message, '你的金币不够购买面包。');
  });
}

GameDefinitions _definitions({required int price}) {
  return GameDefinitions(
    rooms: const {},
    zones: const {},
    npcs: const {
      'merchant': NpcDefinition(
        id: 'merchant',
        name: '商人',
        description: '',
        dialogueId: 'dialogue_merchant',
        shopId: 'merchant_shop',
      ),
    },
    items: const {
      'bread': ItemDefinition(
        id: 'bread',
        name: '面包',
        description: '',
        type: ItemType.consumable,
        effects: {},
      ),
    },
    quests: const {},
    dialogues: const {
      'dialogue_merchant': DialogueDefinition(
        id: 'dialogue_merchant',
        lines: [],
        events: [],
      ),
    },
    events: const {},
    sects: const {},
    skills: const {},
    shops: {
      'merchant_shop': ShopDefinition(
        id: 'merchant_shop',
        name: '商店',
        goods: [ShopGoodDefinition(itemId: 'bread', price: price)],
      ),
    },
  );
}
