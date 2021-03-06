import 'dart:ui';
import 'package:rive/src/rive_core/component_dirt.dart';
import 'package:rive/src/rive_core/container_component.dart';
import 'package:rive/src/rive_core/shapes/clipping_shape.dart';
import 'package:rive/src/generated/drawable_base.dart';
import 'package:rive/src/rive_core/transform_component.dart';
export 'package:rive/src/generated/drawable_base.dart';

abstract class Drawable extends DrawableBase {
  void draw(Canvas canvas);
  BlendMode get blendMode => BlendMode.values[blendModeValue];
  set blendMode(BlendMode value) => blendModeValue = value.index;
  @override
  void blendModeValueChanged(int from, int to) {}
  @override
  void drawOrderChanged(int from, int to) {
    artboard?.markDrawOrderDirty();
  }

  List<ClippingShape> _clippingShapes;
  bool clip(Canvas canvas) {
    if (_clippingShapes == null) {
      return false;
    }
    canvas.save();
    for (final clip in _clippingShapes) {
      if (!clip.isVisible) {
        continue;
      }
      var shape = clip.shape;
      var fillInWorld = shape.fillInWorld;
      if (!fillInWorld) {
        canvas.transform(shape.worldTransform.mat4);
      }
      if (clip.clipOp == ClipOp.difference) {
        var path = Path();
        path.fillType = PathFillType.evenOdd;
        path.addPath(artboard.path, Offset.zero);
        path.addPath(clip.shape.fillPath, Offset.zero);
        canvas.clipPath(path);
      } else {
        canvas.clipPath(clip.shape.fillPath);
      }
      if (!fillInWorld) {
        assert(
            clip.shapeInverseWorld != null,
            'Expect shapeInverseWorld to have been '
            'created by the time we draw');
        canvas.transform(clip.shapeInverseWorld.mat4);
      }
    }
    return true;
  }

  @override
  void update(int dirt) {
    super.update(dirt);
    if (dirt & ComponentDirt.clip != 0) {
      List<ClippingShape> clippingShapes = [];
      for (ContainerComponent p = this; p != null; p = p.parent) {
        if (p is TransformComponent) {
          if (p.clippingShapes != null) {
            clippingShapes.addAll(p.clippingShapes);
          }
        }
      }
      _clippingShapes = clippingShapes.isEmpty ? null : clippingShapes;
    }
  }
}
