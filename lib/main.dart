import 'package:flutter/material.dart';
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
          textTheme: Theme.of(context).textTheme.apply(
                fontSizeFactor: 1.25,
              )),
      home: ChangeNotifierProvider(
        create: (context) => BattleFieldModel(),
        child: const Scaffold(body: BattleFieldContainer()),
      ),
    );
  }
}

// TODO: does this need to be stateful in and of itself or does the BattleFieldModel take care of that
class BattleFieldContainer extends StatefulWidget {
  const BattleFieldContainer({Key? key}) : super(key: key);

  @override
  State<BattleFieldContainer> createState() => _BattleFieldContainerState();
}

class _BattleFieldContainerState extends State<BattleFieldContainer> {
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
                  child: const HistoryWidget(),
                ),
                const Expanded(
                  child: BattleFieldWidget(),
                )
              ],
            ),
          ),
          const ControlsRow(),
        ],
      );
    });
  }
}

class ControlsRow extends StatelessWidget {
  const ControlsRow({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final field = Provider.of<BattleFieldModel>(context);
    final icButtonsStyle = ElevatedButton.styleFrom(
        backgroundColor: Colors.white, foregroundColor: Colors.black);
    return Container(
      height: 50,
      padding: const EdgeInsets.all(5),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.black),
        ),
      ),
      child: Stack(
        children: [
          Center(
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
          Opacity(
            opacity: field.resultsAvailable ? 1.0 : 0.6,
            child: Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        final s = field.getSuccess();
                        if (s != null) {
                          showModalBottomSheet(
                              context: context,
                              builder: (context) => ExplanationCard(
                                  "IC1", s.ic1, s.ic1Explanation));
                        }
                      },
                      style: icButtonsStyle,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(getICIcon(field.getSuccess()?.ic1)),
                          const Text("IC1")
                        ],
                      ),
                    ),
                    const SizedBox(width: 15), // spacer
                    ElevatedButton(
                      onPressed: () {
                        final s = field.getSuccess();
                        if (s != null) {
                          showModalBottomSheet(
                              context: context,
                              builder: (context) => ExplanationCard(
                                  "IC2", s.ic2, s.ic2Explanation));
                        }
                      },
                      style: icButtonsStyle,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(getICIcon(field.getSuccess()?.ic2)),
                          const Text("IC2")
                        ],
                      ),
                    )
                  ],
                )),
          )
        ],
      ),
    );
  }
}
