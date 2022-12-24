import 'package:flutter/material.dart';
import "package:generals/models.dart";
import 'package:provider/provider.dart';

class GeneralWidget extends StatelessWidget {
  final GeneralModel g;
  final int i;
  const GeneralWidget(this.g, this.i, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final field = Provider.of<BattleFieldModel>(context, listen: false);
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [g.name, if (g.rank == Rank.commander) "(Commander)"].join(" "),
            style: const TextStyle(fontWeight: FontWeight.bold),
            textScaleFactor: 1.2,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: g.treacherous,
                onChanged: (c) => field.setTreachery(i, c ?? false),
              ),
              const Text("Traitor"),
            ],
          ),
          if (g.rank != Rank.lieutenant)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Radio<Decision>(
                groupValue: g.ownDecision,
                value: Decision.attack,
                onChanged: (value) =>
                    {if (value != null) field.setDecision(i, value)},
              ),
              Text(decisionVisuals[Decision.attack]!),
              Radio<Decision>(
                groupValue: g.ownDecision,
                value: Decision.retreat,
                onChanged: (value) =>
                    {if (value != null) field.setDecision(i, value)},
              ),
              Text(decisionVisuals[Decision.retreat]!)
            ])
        ],
      ),
    );
  }
}

class BattleFieldBackgroundPainter extends CustomPainter {
  // points are probably produced by calls to _BattleFieldState.getAlignment
  List<Alignment> points;
  BattleFieldBackgroundPainter(this.points);
  @override
  bool shouldRepaint(BattleFieldBackgroundPainter oldDelegate) =>
      oldDelegate.points != points;
  @override
  void paint(Canvas canvas, Size size) {
    print("am painting");
    final scaledPoints = points.map(
        (p) => Offset((p.x + 1) / 2 * size.width, (p.y + 1) / 2 * size.height));
    print(size);
    for (final pointA in scaledPoints) {
      for (final pointB in scaledPoints) {
        if (pointA != pointB) {
          canvas.drawLine(pointA, pointB, Paint()..color = Colors.black);
        }
      }
    }
  }
}
