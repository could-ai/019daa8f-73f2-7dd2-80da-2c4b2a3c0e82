import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:math' as math;
import 'block.dart';
import 'world.dart';

class Face {
  final vector.Vector3 normal;
  final Widget child;
  final Matrix4 transform;
  final vector.Vector3 center;

  Face({
    required this.normal,
    required this.child,
    required this.transform,
    required this.center,
  });
}

class VoxelRenderer extends StatelessWidget {
  final Block block;
  final double size;
  final Camera camera;
  final Function(Block, vector.Vector3)? onFaceTap;

  const VoxelRenderer({
    Key? key,
    required this.block,
    required this.camera,
    this.onFaceTap,
    this.size = 50.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (block.type == BlockType.air) return const SizedBox();

    Color topColor;
    Color bottomColor;
    Color sideColor1;
    Color sideColor2;
    Color sideColor3;
    Color sideColor4;

    switch (block.type) {
      case BlockType.grass:
        topColor = const Color(0xFF559020);
        bottomColor = const Color(0xFF5D4037);
        sideColor1 = const Color(0xFF6D4C41);
        sideColor2 = const Color(0xFF795548);
        sideColor3 = const Color(0xFF5D4037);
        sideColor4 = const Color(0xFF4E342E);
        break;
      case BlockType.dirt:
        topColor = const Color(0xFF795548);
        bottomColor = const Color(0xFF4E342E);
        sideColor1 = const Color(0xFF6D4C41);
        sideColor2 = const Color(0xFF795548);
        sideColor3 = const Color(0xFF5D4037);
        sideColor4 = const Color(0xFF4E342E);
        break;
      case BlockType.stone:
        topColor = const Color(0xFF9E9E9E);
        bottomColor = const Color(0xFF616161);
        sideColor1 = const Color(0xFF757575);
        sideColor2 = const Color(0xFF808080);
        sideColor3 = const Color(0xFF616161);
        sideColor4 = const Color(0xFF424242);
        break;
      default:
        topColor = Colors.white;
        bottomColor = Colors.white;
        sideColor1 = Colors.white;
        sideColor2 = Colors.white;
        sideColor3 = Colors.white;
        sideColor4 = Colors.white;
    }

    final double half = size / 2;

    Widget makeFace(Color color, vector.Vector3 normal) {
      return GestureDetector(
        onTap: () {
          if (onFaceTap != null) {
            onFaceTap!(block, normal);
          }
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.black.withOpacity(0.2), width: 0.5),
          ),
        ),
      );
    }

    List<Face> faces = [
      // Top face (+Y)
      Face(
        normal: vector.Vector3(0, 1, 0),
        center: vector.Vector3(0, half, 0),
        child: makeFace(topColor, vector.Vector3(0, 1, 0)),
        transform: Matrix4.identity()
          ..translate(0.0, -half, 0.0)
          ..rotateX(math.pi / 2),
      ),
      // Bottom face (-Y)
      Face(
        normal: vector.Vector3(0, -1, 0),
        center: vector.Vector3(0, -half, 0),
        child: makeFace(bottomColor, vector.Vector3(0, -1, 0)),
        transform: Matrix4.identity()
          ..translate(0.0, half, 0.0)
          ..rotateX(-math.pi / 2),
      ),
      // Front face (+Z)
      Face(
        normal: vector.Vector3(0, 0, 1),
        center: vector.Vector3(0, 0, half),
        child: makeFace(sideColor1, vector.Vector3(0, 0, 1)),
        transform: Matrix4.identity()..translate(0.0, 0.0, half),
      ),
      // Back face (-Z)
      Face(
        normal: vector.Vector3(0, 0, -1),
        center: vector.Vector3(0, 0, -half),
        child: makeFace(sideColor2, vector.Vector3(0, 0, -1)),
        transform: Matrix4.identity()
          ..translate(0.0, 0.0, -half)
          ..rotateY(math.pi),
      ),
      // Right face (+X)
      Face(
        normal: vector.Vector3(1, 0, 0),
        center: vector.Vector3(half, 0, 0),
        child: makeFace(sideColor3, vector.Vector3(1, 0, 0)),
        transform: Matrix4.identity()
          ..translate(half, 0.0, 0.0)
          ..rotateY(math.pi / 2),
      ),
      // Left face (-X)
      Face(
        normal: vector.Vector3(-1, 0, 0),
        center: vector.Vector3(-half, 0, 0),
        child: makeFace(sideColor4, vector.Vector3(-1, 0, 0)),
        transform: Matrix4.identity()
          ..translate(-half, 0.0, 0.0)
          ..rotateY(-math.pi / 2),
      ),
    ];

    // Compute block center in world coordinates
    vector.Vector3 blockCenter = vector.Vector3(
      block.x * size,
      -block.y * size,
      block.z * size,
    );

    // Vector from camera to block center
    vector.Vector3 viewDir = camera.position - blockCenter;
    
    // Sort faces by distance to camera (furthest first = draw first)
    faces.sort((a, b) {
      double distA = (a.center + blockCenter).distanceToSquared(camera.position);
      double distB = (b.center + blockCenter).distanceToSquared(camera.position);
      return distB.compareTo(distA);
    });

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: faces.map((f) {
          // Backface culling: only draw if normal points towards camera
          // Dot product > 0 means pointing somewhat towards each other
          // Actually, we can just sort them and draw. But culling is faster.
          // Since camera is looking at center, normal dot viewDir > 0
          if (f.normal.dot(viewDir) <= 0) {
            return const SizedBox();
          }

          return Positioned(
            child: Transform(
              transform: f.transform,
              alignment: Alignment.center,
              child: f.child,
            ),
          );
        }).toList(),
      ),
    );
  }
}
