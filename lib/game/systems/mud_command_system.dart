class MudCommandSystem {
  const MudCommandSystem();

  MudCommand parse(String input) {
    final normalized = input.trim();
    if (normalized.isEmpty) {
      return const MudCommand(verb: '');
    }
    final parts = normalized.split(RegExp(r'\s+'));
    final verb = _normalizeVerb(parts.first);
    final args = parts.skip(1).toList();
    return MudCommand(
      verb: verb,
      target: args.isEmpty ? null : args.first,
      extra: args.length < 2 ? null : args.skip(1).join(' '),
      raw: normalized,
    );
  }

  String _normalizeVerb(String value) {
    return switch (value.toLowerCase()) {
      'l' || 'look' || '查看' => 'look',
      'go' || 'move' || 'walk' || '走' || '去' => 'go',
      'n' || 'north' || '北' => 'north',
      's' || 'south' || '南' => 'south',
      'e' || 'east' || '东' => 'east',
      'w' || 'west' || '西' => 'west',
      'ne' || 'northeast' || '东北' => 'northeast',
      'nw' || 'northwest' || '西北' => 'northwest',
      'se' || 'southeast' || '东南' => 'southeast',
      'sw' || 'southwest' || '西南' => 'southwest',
      'u' || 'up' || '上' => 'up',
      'd' || 'down' || '下' => 'down',
      'out' || '出去' => 'out',
      'enter' || '进' || '进入' => 'enter',
      'ask' || 'talk' || '交谈' || '问' => 'ask',
      'trade' || '交易' => 'trade',
      'give' || '交给' || '给予' => 'give',
      'quest' || '任务' => 'quest',
      'apprentice' || '拜师' || '拜' => 'apprentice',
      'learn' || 'study' || '请教' || '学习' => 'learn',
      'enable' || 'map' || '映射' => 'enable',
      'spar' || '切磋' => 'spar',
      'kill' || 'fight' || 'hit' || '战斗' || '攻击' => 'kill',
      'perform' || 'pfm' || '绝招' => 'perform',
      'investigate' || 'search' || '调查' => 'investigate',
      'rest' || '休息' => 'rest',
      'inventory' || 'inv' || 'i' || '背包' => 'inventory',
      'score' || '状态' || '属性' => 'score',
      _ => value,
    };
  }
}

class MudCommand {
  const MudCommand({
    required this.verb,
    this.target,
    this.extra,
    this.raw = '',
  });

  final String verb;
  final String? target;
  final String? extra;
  final String raw;
}
