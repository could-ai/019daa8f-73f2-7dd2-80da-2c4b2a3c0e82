import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart' as vector;
import 'block.dart';

class Camera {
  double pitch; // Up/down rotation (radians)
  double yaw;   // Left/right rotation (radians)
  double distance; // Distance from center
  vector.Vector3 target; // What the camera is looking at

  Camera({
    this.pitch = math.pi / 4,
    this.yaw = math.pi / 4,
    this.distance = 500.0,
    vector.Vector3? target,
  }) : target = target ?? vector.Vector3.zero();

  // Get the camera's position in 3D space
  vector.Vector3 get position {
    // Spherical to Cartesian coordinates
    double x = distance * math.cos(pitch) * math.sin(yaw);
    double y = distance * math.sin(pitch);
    double z = distance * math.cos(pitch) * math.cos(yaw);
    
    return target + vector.Vector3(x, y, z);
  }
}

class World {
  final Map<String, Block> _blocks = {};

  void setBlock(Block block) {
    if (block.type == BlockType.air) {
      _blocks.remove('${block.x},${block.y},${block.z}');
    } else {
      _blocks['${block.x},${block.y},${block.z}'] = block;
    }
  }

  Block? getBlock(int x, int y, int z) {
    return _blocks['$x,$y,$z'];
  }

  List<Block> get blocks => _blocks.values.toList();

  void generateChunk() {
    for (int x = -5; x <= 5; x++) {
      for (int z = -5; z <= 5; z++) {
        // Base layer
        setBlock(Block(x: x, y: 0, z: z, type: BlockType.stone));
        // Dirt layer
        setBlock(Block(x: x, y: 1, z: z, type: BlockType.dirt));
        // Grass layer
        setBlock(Block(x: x, y: 2, z: z, type: BlockType.grass));
      }
    }
    // Add some random blocks above
    setBlock(Block(x: 0, y: 3, z: 0, type: BlockType.stone));
    setBlock(Block(x: 1, y: 3, z: 0, type: BlockType.dirt));
    setBlock(Block(x: 0, y: 4, z: 0, type: BlockType.grass));
  }
}
