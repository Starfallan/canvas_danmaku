import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _size = Size(300, 200);
const _maskRect = Rect.fromLTWH(0, 0, 300, 100);

/// 轨道数与行高受字号影响，避免写死：扫描出真正能命中的点
Offset? _findHit(DanmakuController<int> ctr) {
  for (var dy = 1.0; dy < _size.height; dy += 2) {
    final candidate = Offset(150, dy);
    if (ctr.findSingleDanmaku(candidate) != null) return candidate;
  }
  return null;
}

Future<DanmakuController<int>> _pumpScreen(WidgetTester tester) async {
  DanmakuController<int>? controller;
  await tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: SizedBox(
          width: _size.width,
          height: _size.height,
          child: DanmakuScreen<int>(
            createdController: (e) => controller = e,
            option: const DanmakuOption(),
            size: _size,
          ),
        ),
      ),
    ),
  );
  return controller!;
}

ClipPath _clipPath(WidgetTester tester) {
  return tester.widget<ClipPath>(
    find.descendant(
      of: find.byType(DanmakuScreen<int>),
      matching: find.byType(ClipPath),
    ),
  );
}

void main() {
  testWidgets('遮挡区内不参与命中，置 null 后恢复', (tester) async {
    final ctr = await _pumpScreen(tester);
    expect(
      ctr.addDanmaku(DanmakuContentItem<int>('弹幕', type: DanmakuItemType.top)),
      isTrue,
    );
    // 静态弹幕的水平位置在 paint 时才写入，命中测试依赖它
    await tester.pump();

    final hit = _findHit(ctr);
    expect(hit, isNotNull);
    expect(_maskRect.contains(hit!), isTrue);

    ctr.setMask(Path()..addRect(_maskRect));
    await tester.pump();
    expect(ctr.findSingleDanmaku(hit), isNull);
    expect(_findHit(ctr), isNull);

    ctr.setMask(null);
    await tester.pump();
    expect(ctr.findSingleDanmaku(hit), isNotNull);
  });

  testWidgets('遮挡区外的点仍可命中', (tester) async {
    final ctr = await _pumpScreen(tester);
    ctr.addDanmaku(
      DanmakuContentItem<int>('弹幕', type: DanmakuItemType.bottom),
    );
    await tester.pump();

    final hit = _findHit(ctr);
    expect(hit, isNotNull);
    expect(_maskRect.contains(hit!), isFalse);

    ctr.setMask(Path()..addRect(_maskRect));
    await tester.pump();
    expect(ctr.findSingleDanmaku(hit), isNotNull);
  });

  testWidgets('遮挡区体现为 ClipPath，置 null 后不再裁剪', (tester) async {
    final ctr = await _pumpScreen(tester);

    // 未遮挡：ClipPath 常驻但不裁剪
    var clip = _clipPath(tester);
    expect(clip.clipBehavior, Clip.none);
    expect(clip.clipper, isNull);

    ctr.setMask(Path()..addRect(_maskRect));
    await tester.pump();
    clip = _clipPath(tester);
    expect(clip.clipBehavior, Clip.antiAlias);

    final clipPath = clip.clipper!.getClip(_size);
    expect(clipPath.contains(const Offset(150, 50)), isFalse); // 遮挡区内
    expect(clipPath.contains(const Offset(150, 150)), isTrue); // 遮挡区外

    ctr.setMask(null);
    await tester.pump();
    clip = _clipPath(tester);
    expect(clip.clipBehavior, Clip.none);
    expect(clip.clipper, isNull);
  });
}
