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

    expect(nextState.equippedItems['upperBody'], 'cloth');
    expect(
      nextState.inventory.where((entry) => entry.itemId == 'cloth'),
      isEmpty,
    );
  });

  test('equipItem returns replaced equipment to inventory', () {
    const equipmentSystem = EquipmentSystem();
    final state = GameState.initial(_definitions()).copyWith(
      inventory: const [InventoryEntry(itemId: 'robe', count: 1)],
      equippedItems: const {'upperBody': 'cloth'},
    );

    final nextState = equipmentSystem.equipItem(state, 'robe');

    expect(nextState.equippedItems['upperBody'], 'robe');
    expect(
      nextState.inventory.singleWhere((entry) => entry.itemId == 'cloth').count,
      1,
    );
  });

  test('unequipItem returns equipment to inventory', () {
    const equipmentSystem = EquipmentSystem();
    final state = GameState.initial(_definitions()).copyWith(
      inventory: const [],
      equippedItems: const {'upperBody': 'cloth'},
    );

    final nextState = equipmentSystem.unequipItem(state, 'upperBody');

    expect(nextState.equippedItems, isNot(contains('upperBody')));
    expect(
      nextState.inventory.singleWhere((entry) => entry.itemId == 'cloth').count,
      1,
    );
  });

  test('getEquippedEffects totals equipment effects', () {
    const equipmentSystem = EquipmentSystem();
    final state = GameState.initial(
      _definitions(),
    ).copyWith(equippedItems: const {'upperBody': 'cloth', 'head': 'hat'});

    expect(equipmentSystem.getEquippedEffects(state), {
      'defense': 3,
      'maxHp': 15,
    });
  });

  test('calculatePlayerStats applies equipped player stat effects', () {
    const equipmentSystem = EquipmentSystem();
    final state = GameState.initial(
      _definitions(),
    ).copyWith(equippedItems: const {'upperBody': 'cloth', 'head': 'hat'});

    final player = equipmentSystem.calculatePlayerStats(state);

    expect(player.maxHp, GameState.initial(_definitions()).player.maxHp + 15);
    expect(player.level, GameState.initial(_definitions()).player.level);
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
        effects: {'defense': 1, 'maxHp': 10},
        slot: 'upperBody',
      ),
      'robe': ItemDefinition(
        id: 'robe',
        name: 'Robe',
        description: '',
        type: ItemType.equipment,
        effects: {'defense': 2},
        slot: 'upperBody',
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
