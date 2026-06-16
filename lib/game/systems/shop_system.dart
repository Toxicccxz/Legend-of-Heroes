import '../core/game_state.dart';
import '../models/shop_definition.dart';
import 'inventory_system.dart';

class ShopSystem {
  const ShopSystem();

  static const _inventorySystem = InventorySystem();

  ShopBuyResult buyItem(
    GameState state, {
    required ShopDefinition shop,
    required String itemId,
  }) {
    final good = _goodFor(shop, itemId);
    if (good == null) {
      return ShopBuyResult(state: state, success: false, message: '这里没有这件货品。');
    }
    final item = state.definitions?.items[itemId];
    if (item == null) {
      return ShopBuyResult(
        state: state,
        success: false,
        message: '这件货品暂时无法购买。',
      );
    }
    if (state.player.gold < good.price) {
      return ShopBuyResult(
        state: state,
        success: false,
        message: '你的金币不够购买${item.name}。',
      );
    }

    var nextState = state.copyWith(
      player: state.player.copyWith(gold: state.player.gold - good.price),
    );
    nextState = _inventorySystem.addItem(nextState, itemId, 1);
    return ShopBuyResult(
      state: nextState,
      success: true,
      message: '你花费 ${good.price} 金币买下了${item.name}。',
    );
  }

  ShopGoodDefinition? _goodFor(ShopDefinition shop, String itemId) {
    for (final good in shop.goods) {
      if (good.itemId == itemId) {
        return good;
      }
    }
    return null;
  }
}

class ShopBuyResult {
  const ShopBuyResult({
    required this.state,
    required this.success,
    required this.message,
  });

  final GameState state;
  final bool success;
  final String message;
}
