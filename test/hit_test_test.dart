import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _size = Size(300, 200);
const _option = DanmakuOption();
const _enlargedFontSize = 48.0;

/// 与 DanmakuScreen 内部轨道高同式，避免写死测试字体的度量
double get _trackHeight => (TextPainter(
      text: TextSpan(
        text: '弹幕',
        style: TextStyle(
          fontSize: _option.fontSize,
          fontFamily: _option.fontFamily,
          height: _option.lineHeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout())
        .height;

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
            option: _option,
            size: _size,
          ),
        ),
      ),
    ),
  );
  return controller!;
}

/// 静态弹幕的水平位置在 paint 时才写入，添加后需 pump 一帧
Future<DanmakuItem<int>> _addStatic(
  WidgetTester tester,
  DanmakuController<int> ctr, {
  DanmakuItemType type = DanmakuItemType.top,
  double? fontSize,
}) async {
  final content =
      DanmakuContentItem<int>('弹幕', type: type, fontSize: fontSize);
  expect(ctr.addDanmaku(content), isTrue);
  await tester.pump();
  return ctr.staticDanmaku.nonNulls.firstWhere((e) => e.content == content);
}

void main() {
  const x = 150.0;

  testWidgets('普通弹幕保持整格可点', (tester) async {
    final ctr = await _pumpScreen(tester);
    final item = await _addStatic(tester, ctr);
    final h = _trackHeight;
    expect(item.height, lessThan(h));

    expect(ctr.findSingleDanmaku(const Offset(x, 1)), (0.0, item));
    // 字形下方、本轨之内的空隙
    expect(ctr.findSingleDanmaku(Offset(x, h - 1)), (0.0, item));
    expect(ctr.findSingleDanmaku(Offset(x, h + 1)), isNull);
  });

  testWidgets('放大弹幕越过本轨的部分可点，超出字形不可点', (tester) async {
    final ctr = await _pumpScreen(tester);
    final item = await _addStatic(tester, ctr, fontSize: _enlargedFontSize);
    final h = _trackHeight;
    expect(item.height, greaterThan(h + 2));

    expect(ctr.findSingleDanmaku(Offset(x, h + 1)), (0.0, item));
    expect(ctr.findSingleDanmaku(Offset(x, item.height - 1)), (0.0, item));
    expect(ctr.findSingleDanmaku(Offset(x, item.height + 1)), isNull);
  });

  testWidgets('重叠区命中后绘制（轨道号大）的弹幕', (tester) async {
    final ctr = await _pumpScreen(tester);
    final enlarged =
        await _addStatic(tester, ctr, fontSize: _enlargedFontSize);
    final normal = await _addStatic(tester, ctr);
    final h = _trackHeight;
    expect(ctr.staticDanmaku[1], same(normal));

    final pos = Offset(x, h + 1);
    expect(ctr.findSingleDanmaku(pos), (h, normal));
    expect(ctr.findDanmaku(pos).toList(), [(h, normal), (0.0, enlarged)]);
  });

  testWidgets('最后一条轨道的放大弹幕伸出轨道区的部分可点', (tester) async {
    final ctr = await _pumpScreen(tester);
    final item = await _addStatic(
      tester,
      ctr,
      type: DanmakuItemType.bottom,
      fontSize: _enlargedFontSize,
    );
    final h = _trackHeight;
    final last = ctr.getTrackCount() - 1;
    expect(ctr.staticDanmaku[last], same(item));

    final top = last * h;
    final pos = Offset(x, top + h + 1);
    expect(pos.dy, lessThan(_size.height));
    expect(pos.dy, lessThan(top + item.height));
    expect(ctr.findSingleDanmaku(pos), (top, item));
  });
}
