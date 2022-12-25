import 'dart:math';

import 'package:flutter/material.dart';
import 'package:align_positioned/align_positioned.dart';
import 'package:flutter/services.dart';
import 'package:generals/models.dart';
import 'package:generals/widgets.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Byzantine Generals Problem',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: ChangeNotifierProvider(
        create: (context) => BattleFieldModel(),
        child: const Scaffold(body: BattleField()),
      ),
    );
  }
}

// TODO: does this need to be stateful in and of itself or does the BattleFieldModel take care of that
class BattleField extends StatefulWidget {
  const BattleField({Key? key}) : super(key: key);

  @override
  State<BattleField> createState() => _BattleFieldState();
}

class _BattleFieldState extends State<BattleField> {
  final _generalCountInput = TextEditingController(
      text: BattleFieldModel.initialGeneralCount.toString());

  @override
  Widget build(BuildContext context) {
    return Consumer<BattleFieldModel>(builder: (context, field, child) {
      return Column(
        children: [
          Container(
            height: 50,
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.black),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Number of generals (n) = "),
                SizedBox(
                  width: 30,
                  child: TextField(
                    decoration: const InputDecoration(isDense: true),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1)
                    ],
                    onChanged: (content) {
                      final result = int.tryParse(content);
                      if (result != null) {
                        field.setGeneralCount(result);
                      }
                    },
                    controller: _generalCountInput,
                  ),
                ),
                const Text(", number of traitors (m) = "),
                Text(
                  field.traitorCount.toString(),
                  style: TextStyle(
                      color: field.consistencyPossible
                          ? Colors.black
                          : Colors.red),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 200,
                  color: Colors.black12,
                  child: HistoryWidget(),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: BattleFieldBackgroundPainter(field.generals
                              .map((g) => g.visualPosition)
                              .toList()),
                        ),
                      ),
                      for (var i = 0; i < field.generals.length; i++)
                        AlignPositioned(
                          touch: Touch.middle,
                          alignment: field.generals[i].visualPosition,
                          child: GeneralWidget(field.generals[i], i),
                        )
                    ],
                  ),
                )
              ],
            ),
          ),
          Container(
            height: 50,
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.black),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: field.state != BattleFieldState.waiting
                      ? null
                      : () => field.start(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [Icon(Icons.play_arrow), Text("Run")],
                  ),
                ),
                const SizedBox(width: 20), // spacer
                ElevatedButton(
                  onPressed: () => field.reset(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [Icon(Icons.refresh), Text("Reset")],
                  ),
                )
              ],
            ),
          ),
        ],
      );
    });
  }
}
