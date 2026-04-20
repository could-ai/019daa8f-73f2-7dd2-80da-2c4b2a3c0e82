import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:math' as math;
import 'world.dart';
import 'block.dart';
import 'voxel_renderer.dart';

class VoxelEngine extends StatefulWidget {
  const VoxelEngine({Key? key}) : super(key: key);

  void _handleFaceTap(Block block, vector.Vector3 normal) {
    setState(() {
      if (_isPlacing) {
        // Place block adjacent to the tapped face
        int newX = block.x + normal.x.round();
        int newY = block.y + normal.y.round();
        int newZ = block.z + normal.z.round();
        
        // Ensure we don't place block on existing block (though world.setBlock handles replacement)
        if (world.getBlock(newX, newY, newZ) == null) {
          world.setBlock(Block(x: newX, y: newY, z: newZ, type: _selectedBlockType));
        }
      } else {
        // Break block
        world.setBlock(Block(x: block.x, y: block.y, z: block.z, type: BlockType.air));
      }
    });
  }

  @override
  _VoxelEngineState createState() => _VoxelEngineState();
}

class _VoxelEngineState extends State<VoxelEngine> {
  late World world;
  late Camera camera;
  
  double blockSize = 50.0;
  Offset _lastPan = Offset.zero;
  BlockType _selectedBlockType = BlockType.grass;
  bool _isPlacing = true;

  @override
  void initState() {
    super.initState();
    world = World();
    world.generateChunk();
    camera = Camera(
      pitch: math.pi / 6,
      yaw: math.pi / 4,
      distance: 800.0,
    );
  }

  void _handlePanStart(DragStartDetails details) {
    _lastPan = details.localPosition;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      final delta = details.localPosition - _lastPan;
      camera.yaw += delta.dx * 0.01;
      camera.pitch -= delta.dy * 0.01;
      
      // Clamp pitch to avoid flipping over
      camera.pitch = camera.pitch.clamp(-math.pi / 2.1, math.pi / 2.1);
      
      _lastPan = details.localPosition;
    });
  }

  void _handleZoom(ScaleUpdateDetails details) {
    if (details.scale != 1.0) {
      setState(() {
        camera.distance /= details.scale;
        camera.distance = camera.distance.clamp(200.0, 2000.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort blocks by distance to camera
    List<Block> sortedBlocks = world.blocks.toList();
    sortedBlocks.sort((a, b) {
      vector.Vector3 posA = vector.Vector3(a.x * blockSize, -a.y * blockSize, a.z * blockSize);
      vector.Vector3 posB = vector.Vector3(b.x * blockSize, -b.y * blockSize, b.z * blockSize);
      
      double distA = posA.distanceToSquared(camera.position);
      double distB = posB.distanceToSquared(camera.position);
      
      return distB.compareTo(distA); // Draw furthest first
    });

    // Create the view transformation matrix
    Matrix4 viewMatrix = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // perspective
      ..translate(0.0, 0.0, camera.distance)
      ..rotateX(camera.pitch)
      ..rotateY(camera.yaw);

    return Scaffold(
      body: GestureDetector(
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onScaleUpdate: _handleZoom,
        child: Container(
          color: const Color(0xFF87CEEB), // Sky color
          child: Center(
            child: Transform(
              transform: viewMatrix,
              alignment: Alignment.center,
              child: SizedBox(
                width: 3000,
                height: 3000,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: sortedBlocks.map((block) {
                    // Determine screen position or just apply a local translation
                    Matrix4 blockTransform = Matrix4.identity()
                      ..translate(
                        block.x * blockSize,
                        -block.y * blockSize, // -Y because Flutter +Y is down
                        block.z * blockSize,
                      );

                    return Positioned(
                      child: Transform(
                        transform: blockTransform,
                        alignment: Alignment.center,
                        child: VoxelRenderer(
                          block: block,
                          camera: camera,
                          size: blockSize,
                          onFaceTap: _handleFaceTap,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildToolbar(),
    );
  }

  Widget _buildToolbar() {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildModeButton(true, 'Place'),
                const SizedBox(width: 10),
                _buildModeButton(false, 'Break'),
              ],
            ),
            if (_isPlacing)
              Row(
                children: [
                  _buildBlockSelector(BlockType.grass, Colors.green),
                  const SizedBox(width: 10),
                  _buildBlockSelector(BlockType.dirt, Colors.brown),
                  const SizedBox(width: 10),
                  _buildBlockSelector(BlockType.stone, Colors.grey),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(bool isPlacing, String text) {
    bool isSelected = _isPlacing == isPlacing;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[800],
        foregroundColor: Colors.white,
      ),
      onPressed: () {
        setState(() {
          _isPlacing = isPlacing;
        });
      },
      child: Text(text),
    );
  }

  Widget _buildBlockSelector(BlockType type, Color color) {
    bool isSelected = _selectedBlockType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBlockType = type;
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
