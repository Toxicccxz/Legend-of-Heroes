import 'package:flutter/material.dart';

import '../../../game/core/game_state.dart';

class SkillTab extends StatelessWidget {
  const SkillTab({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final skills = state.definitions?.skills.values.toList() ?? const [];
    return ListView(
      children: skills
          .map((skill) => Text('${skill.name}｜${skill.category}'))
          .toList(),
    );
  }
}
