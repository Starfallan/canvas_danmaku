import 'package:canvas_danmaku/models/danmaku_content_item.dart';
import 'package:canvas_danmaku/models/danmaku_item.dart';
import 'package:canvas_danmaku/models/danmaku_option.dart';
import 'package:material_ui/material_ui.dart';

class DanmakuController<T> {
  final bool Function(DanmakuContentItem<T>) addDanmaku;

  /// 遮挡区（画布坐标系）：区内不绘制弹幕，也不参与 [findDanmaku] / [findSingleDanmaku] 命中。
  /// null 表示不遮挡。每次传入新的 Path 对象都会触发重裁剪，调用方负责去重与坐标换算。
  final ValueChanged<Path?> setMask;
  final ValueChanged<DanmakuOption> updateOption;
  final VoidCallback pause;
  final VoidCallback resume;
  final VoidCallback clear;
  final ValueGetter<DanmakuOption> getOption;
  final ValueGetter<bool> isRunning;
  final Iterable<(double, DanmakuItem<T>)> Function(Offset) findDanmaku;
  final (double, DanmakuItem<T>)? Function(Offset) findSingleDanmaku;
  final ValueGetter<int> getTrackCount;

  final List<List<DanmakuItem<T>>> scrollDanmaku;
  final List<DanmakuItem<T>?> staticDanmaku;
  final List<DanmakuItem<T>> specialDanmaku;

  DanmakuOption get option => getOption();

  bool get running => isRunning();

  int get trackCount => getTrackCount();

  DanmakuController({
    required this.addDanmaku,
    required this.setMask,
    required this.updateOption,
    required this.pause,
    required this.resume,
    required this.clear,
    required this.getOption,
    required this.isRunning,
    required this.findDanmaku,
    required this.findSingleDanmaku,
    required this.getTrackCount,
    required this.scrollDanmaku,
    required this.staticDanmaku,
    required this.specialDanmaku,
  });
}
