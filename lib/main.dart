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

class BattleField extends StatefulWidget {
  const BattleField({Key? key}) : super(key: key);

  @override
  State<BattleField> createState() => _BattleFieldState();
}

class _BattleFieldState extends State<BattleField> {
  final _generalCountInput = TextEditingController(
      text: BattleFieldModel.initialGeneralCount.toString());

  static Alignment getAlignment(int i, int l, [double radius = 0.75]) {
    final rotateBy = (pi * 2) / l * i - pi / 2;
    return Alignment(cos(rotateBy) * radius, sin(rotateBy) * radius);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BattleFieldModel>(
      builder: (context, field, child) => Column(
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
                Text(", number of traitors (m) = ${field.traitorCount}"),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                for (var i = 0; i < field.generals.length; i++)
                  AlignPositioned(
                    touch: Touch.middle,
                    alignment: getAlignment(i, field.generals.length),
                    child: GeneralWidget(field.generals[i], i),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
