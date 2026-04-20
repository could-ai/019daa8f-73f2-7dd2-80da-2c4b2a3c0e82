enum BlockType {
  air,
  grass,
  dirt,
  stone,
}

class Block {
  final int x;
  final int y;
  final int z;
  final BlockType type;

  Block({
    required this.x,
    required this.y,
    required this.z,
    required this.type,
  });
}
