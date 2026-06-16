class ShopDefinition {
  const ShopDefinition({
    required this.id,
    required this.name,
    this.description = '',
    this.goods = const [],
  });

  final String id;
  final String name;
  final String description;
  final List<ShopGoodDefinition> goods;

  factory ShopDefinition.fromJson(Map<String, dynamic> json) {
    return ShopDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      goods:
          (json['goods'] as List<dynamic>? ?? const [])
              .map(
                (item) => ShopGoodDefinition.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(),
    );
  }
}

class ShopGoodDefinition {
  const ShopGoodDefinition({
    required this.itemId,
    required this.price,
    this.stock,
  });

  final String itemId;
  final int price;
  final int? stock;

  factory ShopGoodDefinition.fromJson(Map<String, dynamic> json) {
    return ShopGoodDefinition(
      itemId: json['itemId'] as String,
      price: json['price'] as int? ?? 0,
      stock: json['stock'] as int?,
    );
  }
}
