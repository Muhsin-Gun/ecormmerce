import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

final _crcTable = _makeCrcTable();

List<int> _makeCrcTable() {
  const poly = 0xEDB88320;
  final table = List<int>.filled(256, 0);
  for (var i = 0; i < 256; i++) {
    var c = i;
    for (var j = 0; j < 8; j++) {
      if ((c & 1) != 0) {
        c = (c >> 1) ^ poly;
      } else {
        c = c >> 1;
      }
    }
    table[i] = c & 0xFFFFFFFF;
  }
  return table;
}

int _crc32(List<int> data) {
  var crc = 0xFFFFFFFF;
  for (final b in data) {
    crc = (crc >> 8) ^ _crcTable[(crc ^ b) & 0xFF];
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

List<int> _u32be(int value) {
  return [
    (value >> 24) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 8) & 0xFF,
    value & 0xFF,
  ];
}

void savePng(File path, int width, int height,
    List<int> Function(int, int, int, int) pixelFn) {
  path.parent.createSync(recursive: true);
  final raw = <int>[];
  for (var y = 0; y < height; y++) {
    raw.add(0); // filter type 0
    for (var x = 0; x < width; x++) {
      final px = pixelFn(x, y, width, height);
      raw.addAll(px);
    }
  }

  List<int> chunk(List<int> tag, List<int> data) {
    final len = _u32be(data.length);
    final chunkData = <int>[]
      ..addAll(tag)
      ..addAll(data);
    final crc = _crc32(chunkData);
    return <int>[]
      ..addAll(len)
      ..addAll(tag)
      ..addAll(data)
      ..addAll(_u32be(crc));
  }

  final ihdr = <int>[];
  ihdr.addAll(_u32be(width));
  ihdr.addAll(_u32be(height));
  ihdr.addAll([8, 6, 0, 0, 0]);

  final encoder = ZLibCodec();
  final idat = encoder.encode(Uint8List.fromList(raw));

  final png = <int>[]
    ..addAll([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
    ..addAll(chunk([0x49, 0x48, 0x44, 0x52], ihdr))
    ..addAll(chunk([0x49, 0x44, 0x41, 0x54], idat))
    ..addAll(chunk([0x49, 0x45, 0x4E, 0x44], []));

  path.writeAsBytesSync(png);
}

List<int> bgGradient(int x, int y, int w, int h) {
  final t = y / (h - 1);
  final r = (8 + 18 * t).toInt();
  final g = (32 + 56 * t).toInt();
  final b = (46 + 50 * t).toInt();
  return [r, g, b, 255];
}

List<int> fgIcon(int x, int y, int w, int h) {
  final cx = w ~/ 2;
  final cy = h ~/ 2;
  final dx = x - cx;
  final dy = y - cy;

  final r = math.sqrt((dx * dx + dy * dy).toDouble());
  final inOuterBadge = r <= 320;
  final inInnerBadge = r <= 265;

  final stem = dx >= -120 && dx <= -45 && dy >= -190 && dy <= 190;
  final bowlOuter =
      math.sqrt(math.pow(dx + 10, 2) + math.pow(dy + 70, 2)) <= 130 &&
          dx >= -45 &&
          dy <= 55;
  final bowlInner =
      math.sqrt(math.pow(dx + 10, 2) + math.pow(dy + 70, 2)) <= 78 &&
          dx >= 18 &&
          dy <= 55;
  final letterP = stem || (bowlOuter && !bowlInner);

  final accent =
      math.sqrt(math.pow(dx - 160, 2) + math.pow(dy + 155, 2)) <= 34;

  if (letterP) {
    return [15, 118, 110, 255];
  }
  if (accent) {
    return [245, 158, 11, 255];
  }
  if (inInnerBadge) {
    return [255, 255, 255, 255];
  }
  if (inOuterBadge) {
    return [15, 118, 110, 255];
  }

  return [0, 0, 0, 0];
}

void main() {
  final root = Directory.current.path;
  final splash = File('$root/assets/images/splash_static.png');
  final bg = File('$root/assets/icons/background.png');
  final fg = File('$root/assets/icons/foreground.png');
  final androidSplash =
      File('$root/android/app/src/main/res/drawable-nodpi/splash_static.png');

  savePng(splash, 1024, 1024, bgGradient);
  savePng(bg, 1024, 1024, bgGradient);
  savePng(fg, 1024, 1024, fgIcon);
  androidSplash.parent.createSync(recursive: true);
  androidSplash.writeAsBytesSync(splash.readAsBytesSync());

  print('Generated assets:');
  print('- ${splash.path.replaceFirst('$root/', '')}');
  print('- ${bg.path.replaceFirst('$root/', '')}');
  print('- ${fg.path.replaceFirst('$root/', '')}');
  print('- ${androidSplash.path.replaceFirst('$root/', '')}');
}
