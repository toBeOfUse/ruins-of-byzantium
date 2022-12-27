import 'package:flutter/material.dart';
import "package:generals/models.dart";
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:align_positioned/align_positioned.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
      child: SizedBox(
        width: 225,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              [
                g.name,
                if (g.rank == Rank.commander)
                  "(Cmdr.)"
                else if (g.rank == Rank.actingCommander)
                  "(Acting Cmdr.)"
              ].join(" "),
              style: const TextStyle(fontWeight: FontWeight.bold),
              textScaleFactor: 1.2,
            ),
            const Divider(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Loyal and Reliable:"),
                Checkbox(
                  value: !g.treacherous,
                  onChanged: (c) => field.setTreachery(i, !(c ?? false)),
                ),
              ],
            ),
            if (g.rank == Rank.commander)
              Opacity(
                opacity: g.treacherous ? 0.7 : 1,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Tooltip(
                    message: "Decide to retreat",
                    verticalOffset: 15,
                    child: Row(children: [
                      Radio<Decision>(
                        groupValue: g.ownDecision,
                        value: Decision.retreat,
                        onChanged: (value) =>
                            {if (value != null) field.setDecision(i, value)},
                      ),
                      Text(decisionVisuals[Decision.retreat]!)
                    ]),
                  ),
                  Tooltip(
                    message: "Decide to attack",
                    verticalOffset: 15,
                    child: Row(children: [
                      Radio<Decision>(
                        groupValue: g.ownDecision,
                        value: Decision.attack,
                        onChanged: (value) =>
                            {if (value != null) field.setDecision(i, value)},
                      ),
                      Text(decisionVisuals[Decision.attack]!)
                    ]),
                  ),
                ]),
              ),
            if (g.rank != Rank.commander)
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  const Text("Orders received: "),
                  ...g.orders.map((o) => OrderWidget(o))
                ],
              ),
            if (g.rank != Rank.commander)
              Text("majority(ordersReceived) = " +
                  (g.finalDecision()?.visualizeDecision() ?? ''))
          ],
        ),
      ),
    );
  }
}

class BattleFieldBackgroundPainter extends CustomPainter {
  // points are probably produced by calls to _BattleFieldState.getAlignment
  final List<Alignment> points;
  BattleFieldBackgroundPainter(this.points);
  @override
  bool shouldRepaint(BattleFieldBackgroundPainter oldDelegate) =>
      !oldDelegate.points.equals(points);
  @override
  void paint(Canvas canvas, Size size) {
    final scaledPoints = points.map(
        (p) => Offset((p.x + 1) / 2 * size.width, (p.y + 1) / 2 * size.height));
    for (final pointA in scaledPoints) {
      for (final pointB in scaledPoints) {
        if (pointA != pointB) {
          canvas.drawLine(pointA, pointB, Paint()..color = Colors.black);
        }
      }
    }
  }
}

class BattleFieldWidget extends StatelessWidget {
  const BattleFieldWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final field = Provider.of<BattleFieldModel>(context);
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: BattleFieldBackgroundPainter(
                field.generals.map((g) => g.visualPosition).toList()),
          ),
        ),
        for (final order in field.orderOutbox)
          Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Text(
                order.visualizeDecision(),
                textScaleFactor: 2.0,
              )).animate(key: Key(order.hashCode.toString())).custom(
              duration: Duration(milliseconds: BattleFieldModel.sendingTimeMS),
              builder: (context, value, child) {
                return Align(
                    alignment: Alignment.lerp(
                        order.call.actingCommander.visualPosition,
                        order.receiver.visualPosition,
                        value)!,
                    child: child);
              }),
        for (var i = 0; i < field.generals.length; i++)
          AlignPositioned(
            touch: Touch.middle,
            alignment: field.generals[i].visualPosition,
            child: GeneralWidget(field.generals[i], i),
          )
      ],
    );
  }
}

class HistoryWidget extends StatelessWidget {
  const HistoryWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<BattleFieldModel>(builder: (context, field, child) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(5.0),
              child: const Text("Call sequence",
                  textScaleFactor: 1.2,
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (final call in field.history)
              Container(
                  color: call.highlighted ? Colors.white : Colors.transparent,
                  padding: const EdgeInsets.all(5.0),
                  child: Text("OM(${call.assumedM}) - " +
                      (call.actingCommander.rank == Rank.commander
                          ? "Cmdr. "
                          : "") +
                      call.actingCommander.name))
          ],
        ),
      );
    });
  }
}

class OrderWidget extends StatelessWidget {
  final OrderModel order;
  const OrderWidget(this.order, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<BattleFieldModel>(builder: (context, field, child) {
      return Material(
        child: InkWell(
          hoverColor: Colors.black12,
          onTap: () => field.highlightCall(order.call),
          child: Text(order.visualizeDecision()),
        ),
      );
    });
  }
}
