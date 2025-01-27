import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'cal_point.dart';
import 'dart:math' as Math;

enum PositionStyle {
  STYLE_TOP_RIGHT,
  STYLE_LOWER_RIGHT,
  STYLE_LEFT,
  STYLE_RIGHT,
  STYLE_MIDDLE,
}

///页面画笔
class BookPainter extends CustomPainter {
  CalPoint a, f, g, e, h, c, j, b, k, d, i;

  double viewWidth;
  double viewHeight;

  final Path pathA;
  Path pathB;

  final Path pathC;

  Paint bgPaint; //背景画笔
  Paint pathAPaint, pathCPaint, pathBPaint; //绘制区域画笔

  PositionStyle style;
  ValueChanged changedPoint;
  String text;
  Color bgColor;
  Color frontColor;

  BookPainter({
    @required this.text,
    @required this.pathA,
    @required this.pathC,
    @required this.viewWidth,
    @required this.viewHeight,
    @required this.frontColor,
    @required this.bgColor,
    @required CalPoint cur,
    @required CalPoint pre,
    @required this.changedPoint,
    @required this.style,
    bool limitAngle,
  }) {
    init(cur, pre, limitAngle);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  @override
  void paint(Canvas canvas, Size size) {
    onDraw(canvas, size);
  }

  init(CalPoint cur, CalPoint pre, bool limitAngle) {
    _initPoint();

    _selectCalPoint(cur, pre, limitAngle: limitAngle);

    _calcPointsXY(a, f);

    _initPaintAndPath();
  }

  _initPoint() {
    ///计算起始触摸点
    a = CalPoint();

    ///计算的位置起点
    f = CalPoint();

    ///其他坐标
    g = new CalPoint();
    e = new CalPoint();
    h = new CalPoint();
    c = new CalPoint();
    j = new CalPoint();
    b = new CalPoint();
    k = new CalPoint();
    d = new CalPoint();
    i = new CalPoint();

    pathB = new Path();
  }

  _selectCalPoint(CalPoint cur, CalPoint pre, {bool limitAngle = true}) {
    a.x = cur.x;
    a.y = cur.y;
    doCalAngle() {
      CalPoint touchPoint = CalPoint.data(cur.x, cur.y);
      if (f.x != null &&
          touchPoint.x != null &&
          (limitAngle != null && limitAngle)) {
        ///如果大于0则设置a点坐标重新计算各标识点位置，否则a点坐标不变
        if (_calcPointCX(touchPoint, f) > 0) {
          changedPoint?.call(cur);
          _calcPointsXY(a, f);
        } else {
          a.x = pre.x;
          a.y = pre.y;
          _calcPointsXY(a, f);
        }
      } else if (_calcPointCX(touchPoint, f) < 0) {
        ///如果c点x坐标小于0则重新测量a点坐标
        _calcPointAByTouchPoint();
        _calcPointsXY(a, f);
      } else {
        a.x = pre.x;
        a.y = pre.y;
      }
    }

    switch (style) {
      case PositionStyle.STYLE_TOP_RIGHT:
        f.x = viewWidth;
        f.y = 0;
        doCalAngle();
        break;
      case PositionStyle.STYLE_LOWER_RIGHT:
        f.x = viewWidth;
        f.y = viewHeight;
        doCalAngle();
        break;
      case PositionStyle.STYLE_LEFT:
      case PositionStyle.STYLE_RIGHT:
        a.y = viewHeight - 1;
        f.x = viewWidth;
        f.y = viewHeight;
        _calcPointsXY(a, f);
        break;
      default:
        break;
    }
  }

  _initPaintAndPath() {
    bgPaint = new Paint();
    bgPaint.color = Colors.white;

    pathAPaint = new Paint();
    pathAPaint.color = bgColor;
    pathAPaint.isAntiAlias = true;

    pathCPaint = new Paint();
    pathCPaint.color = frontColor;
    pathCPaint.blendMode = BlendMode.dstATop;
    pathCPaint.isAntiAlias = true;

    pathBPaint = new Paint();
    pathBPaint.color = Colors.lightBlue;
    pathBPaint.blendMode = BlendMode.dstATop;
    pathBPaint.isAntiAlias = true;

    pathB = new Path();
  }

  void onDraw(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTRB(0, 0, size.width, size.height), bgPaint);

    if (a.x == -1 && a.y == -1) {
      canvas.drawPath(_getPathDefault(), pathAPaint);
    } else {
      if (f.x == viewWidth && f.y == 0) {
        canvas.drawPath(_getPathAFromTopRight(), pathAPaint);
      } else if (f.x == viewWidth && f.y == viewHeight) {
        canvas.drawPath(_getPathAFromLowerRight(), pathAPaint);
      }
      canvas.drawPath(_getPathC(), pathCPaint);
      canvas.drawPath(_getPathB(), pathBPaint);
    }
    canvas.restore();
  }

  /// 计算各点坐标
  void _calcPointsXY(CalPoint a, CalPoint f) {
    g.x = (a.x + f.x) / 2;
    g.y = (a.y + f.y) / 2;

    e.x = g.x - (f.y - g.y) * (f.y - g.y) / (f.x - g.x);
    e.y = f.y;

    h.x = f.x;
    h.y = g.y - (f.x - g.x) * (f.x - g.x) / (f.y - g.y);

    c.x = e.x - (f.x - e.x) / 2;
    c.y = f.y;

    j.x = f.x;
    j.y = h.y - (f.y - h.y) / 2;

    b = _getInterPoint(a, e, c, j);
    k = _getInterPoint(a, h, c, j);

    d.x = (c.x + 2 * e.x + b.x) / 4;
    d.y = (2 * e.y + c.y + b.y) / 4;

    i.x = (j.x + 2 * h.x + k.x) / 4;
    i.y = (2 * h.y + j.y + k.y) / 4;
  }

  /// 计算两线段相交点坐标
  CalPoint _getInterPoint(
      CalPoint lineOneToPointOne,
      CalPoint lineOneToPointTwo,
      CalPoint lineTwoToPointOne,
      CalPoint lineTwoToPointTwo) {
    double x1, y1, x2, y2, x3, y3, x4, y4;
    x1 = lineOneToPointOne.x;
    y1 = lineOneToPointOne.y;
    x2 = lineOneToPointTwo.x;
    y2 = lineOneToPointTwo.y;
    x3 = lineTwoToPointOne.x;
    y3 = lineTwoToPointOne.y;
    x4 = lineTwoToPointTwo.x;
    y4 = lineTwoToPointTwo.y;

    double pointX =
        ((x1 - x2) * (x3 * y4 - x4 * y3) - (x3 - x4) * (x1 * y2 - x2 * y1)) /
            ((x3 - x4) * (y1 - y2) - (x1 - x2) * (y3 - y4));
    double pointY =
        ((y1 - y2) * (x3 * y4 - x4 * y3) - (x1 * y2 - x2 * y1) * (y3 - y4)) /
            ((y1 - y2) * (x3 - x4) - (x1 - x2) * (y3 - y4));

    return CalPoint.data(pointX, pointY);
  }

  ///获取f点在右下角的pathA
  Path _getPathAFromLowerRight() {
    pathA.reset();
    pathA.lineTo(0, viewHeight); //移动到左下角
    pathA.lineTo(c.x, c.y); //移动到c点
    pathA.quadraticBezierTo(e.x, e.y, b.x, b.y); //从c到b画贝塞尔曲线，控制点为e
    pathA.lineTo(a.x, a.y); //移动到a点
    pathA.lineTo(k.x, k.y); //移动到k点
    pathA.quadraticBezierTo(h.x, h.y, j.x, j.y); //从k到j画贝塞尔曲线，控制点为h
    pathA.lineTo(viewWidth, 0); //移动到右上角
    pathA.close(); //闭合区域
    return pathA;
  }

  ///获取f点在右上角的pathA
  Path _getPathAFromTopRight() {
    pathA.reset();
    pathA.lineTo(c.x, c.y); //移动到c点
    pathA.quadraticBezierTo(e.x, e.y, b.x, b.y); //从c到b画贝塞尔曲线，控制点为e
    pathA.lineTo(a.x, a.y); //移动到a点
    pathA.lineTo(k.x, k.y); //移动到k点
    pathA.quadraticBezierTo(h.x, h.y, j.x, j.y); //从k到j画贝塞尔曲线，控制点为h
    pathA.lineTo(viewWidth, viewHeight); //移动到右下角
    pathA.lineTo(0, viewHeight); //移动到左下角
    pathA.close();
    return pathA;
  }

  ///翻页折角区域
  Path _getPathC() {
    pathC.reset();
    pathC.moveTo(i.x, i.y); //移动到i点
    pathC.lineTo(d.x, d.y); //移动到d点
    pathC.lineTo(b.x, b.y); //移动到b点
    pathC.lineTo(a.x, a.y); //移动到a点
    pathC.lineTo(k.x, k.y); //移动到k点
    pathC.close(); //闭合区域
    return pathC;
  }

  ///翻页后剩余区域
  Path _getPathB() {
    pathB.reset();
    pathB.lineTo(0, viewHeight); //移动到左下角
    pathB.lineTo(viewWidth, viewHeight); //移动到右下角
    pathB.lineTo(viewWidth, 0); //移动到右上角
    pathB.close(); //闭合区域
    return pathB;
  }

  ///绘制默认的界面
  Path _getPathDefault() {
    pathA.reset();
    pathA.lineTo(0, viewHeight);
    pathA.lineTo(viewWidth, viewHeight);
    pathA.lineTo(viewWidth, 0);
    pathA.close();
    return pathA;
  }

  ///计算C点的X值
  _calcPointCX(CalPoint a, CalPoint f) {
    CalPoint g, e;
    g = new CalPoint();
    e = new CalPoint();
    g.x = (a.x + f.x) / 2;
    g.y = (a.y + f.y) / 2;

    e.x = g.x - (f.y - g.y) * (f.y - g.y) / (f.x - g.x);
    e.y = f.y;

    return e.x - (f.x - e.x) / 2;
  }

  ///如果c点x坐标小于0,根据触摸点重新测量a点坐标
  _calcPointAByTouchPoint() {
    double w0 = viewWidth - c.x;

    double w1 = (f.x - a.x).abs();
    double w2 = viewWidth * w1 / w0;
    a.x = (f.x - w2).abs();

    double h1 = (f.y - a.y).abs();
    double h2 = w2 * h1 / w1;
    a.y = (f.y - h2).abs();
  }

  ///利用 Paragraph 实现 _drawText
  _drawText(
      Canvas canvas, String text, Color color, double width, Offset offset,
      {TextAlign textAlign = TextAlign.start, double fontSize}) {
    ui.ParagraphBuilder pb = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: textAlign,
      fontSize: fontSize,
    ));
    pb.pushStyle(ui.TextStyle(color: color));
    pb.addText(text);
    ui.ParagraphConstraints pc = ui.ParagraphConstraints(width: width);

    ///这里需要先layout, 后面才能获取到文字高度
    ui.Paragraph paragraph = pb.build()..layout(pc);
    canvas.drawParagraph(paragraph, offset);
  }

  _drawTestPoint() {
//    _drawText(canvas, "a",  Colors.red, size.width, Offset(a.x, a.y),
//        textAlign: TextAlign.left, fontSize: 25);
//    _drawText(canvas, "f",  Colors.red, size.width, Offset(f.x, f.y),
//        textAlign: TextAlign.left, fontSize: 25);
//    _drawText(canvas, "g",  Colors.red, size.width, Offset(g.x, g.y),
//        textAlign: TextAlign.left, fontSize: 25);
//
//    _drawText(canvas, "e",  Colors.red, size.width, Offset(e.x, e.y),
//        textAlign: TextAlign.left, fontSize: 25);
//    _drawText(canvas, "h",  Colors.red, size.width, Offset(h.x, h.y),
//        textAlign: TextAlign.left, fontSize: 25);
//
//    _drawText(canvas, "c",  Colors.red, size.width, Offset(c.x, c.y),
//        textAlign: TextAlign.left, fontSize: 25);
//    _drawText(canvas, "j",  Colors.red, size.width, Offset(j.x, j.y),
//        textAlign: TextAlign.left, fontSize: 25);
//
//    _drawText(canvas, "b",  Colors.red, size.width, Offset(b.x, b.y),
//        textAlign: TextAlign.left, fontSize: 25);
//    _drawText(canvas, "k",  Colors.red, size.width, Offset(k.x, k.y),
//        textAlign: TextAlign.left, fontSize: 25);
//
//    _drawText(canvas, "d",  Colors.red, size.width, Offset(d.x, d.y),
//        textAlign: TextAlign.left, fontSize: 25);
//    _drawText(canvas, "i",  Colors.red, size.width, Offset(i.x, i.y),
//        textAlign: TextAlign.left, fontSize: 25);
  }
}
