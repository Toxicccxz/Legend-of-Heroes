import 'package:flutter_test/flutter_test.dart';
import 'package:legend_of_heroes/game/core/game_state.dart';
import 'package:legend_of_heroes/game/models/item_definition.dart';
import 'package:legend_of_heroes/game/repositories/game_definition_repository.dart';
import 'package:legend_of_heroes/game/systems/equipment_system.dart';

void main() {
  test('equipItem moves equipment from inventory into its slot', () {
    const equipmentSystem = EquipmentSystem();
    final state = GameState.initial(_definitions()).copyWith(
      inventory: const [InventoryEntry(itemId: 'cloth', count: 1)],
      equippedItems: const {},
    );

    final nextState = equipmentSystem.equipItem(state, 'cloth');

    expect(nextState.equippedItems['body'], 'cloth');
    expect(
      nextState.inventory.where((entry) => entry.itemId == 'cloth'),
      isEmpty,
    );
  });

  test('equipItem returns replaced equipment to inventory', () {
    const equipmentSystem = EquipmentSystem();
    final state = GameState.initial(_definitions()).copyWith(
      inventory: const [InventoryEntry(itemId: 'robe', count: 1)],
      equippedItems: const {'body': 'cloth'},
    );

    final nextState = equipmentSystem.equipItem(state, 'robe');

    expect(nextState.equippedItems['body'], 'robe');
    expect(
      nextState.inventory.singleWhere((entry) => entry.itemId == 'cloth').count,
      1,
    );
  });

  test('unequipItem returns equipment to inventory', () {
    const equipmentSystem = EquipmentSystem();
    final state = GameState.initial(
      _definitions(),
    ).copyWith(inventory: const [], equippedItems: const {'body': 'cloth'});

    final nextState = equipmentSystem.unequipItem(state, 'body');

    expect(nextState.equippedItems, isNot(contains('body')));
    expect(
      nextState.inventory.singleWhere((entry) => entry.itemId == 'cloth').count,
      1,
    );
  });

  test('getEquippedEffects totals equipment effects', () {
    const equipmentSystem = EquipmentSystem();
    final state = GameState.initial(
      _definitions(),
    ).copyWith(equippedItems: const {'body': 'cloth', 'head': 'hat'});

    expect(equipmentSystem.getEquippedEffects(state), {
      'defense': 3,
      'maxHp': 5,
    });
  });
}

GameDefinitions _definitions() {
  return const GameDefinitions(
    rooms: {},
    npcs: {},
    items: {
      'cloth': ItemDefinition(
        id: 'cloth',
        name: 'Cloth',
        description: '',
        type: ItemType.equipment,
        effects: {'defense': 1},
        slot: 'body',
      ),
      'robe': ItemDefinition(
        id: 'robe',
        name: 'Robe',
        description: '',
        type: ItemType.equipment,
        effects: {'defense': 2},
        slot: 'body',
      ),
      'hat': ItemDefinition(
        id: 'hat',
        name: 'Hat',
        description: '',
        type: ItemType.equipment,
        effects: {'defense': 2, 'maxHp': 5},
        slot: 'head',
      ),
    },
    quests: {},
    dialogues: {},
    events: {},
    sects: {},
    skills: {},
  );
}
