import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:generals/names.dart';
import 'package:async/async.dart';

enum Decision { attack, retreat, confuse }

Map<Decision, String> decisionVisuals = {
  Decision.attack: "⚔",
  Decision.retreat: "🏃‍♂️"
};

enum Rank { commander, actingCommander, lieutenant }

class CallModel {
  GeneralModel actingCommander;
  int depth;
  int assumedM;
  CallModel? parent;
  bool highlighted = false;
  CallModel(this.actingCommander, this.depth, this.assumedM, [this.parent]);
}

class OrderModel {
  Decision decision;
  CallModel call;
  GeneralModel receiver;
  int mWhenSent;
  static int _confusingOrders = 0;
  // if order == Confuse, this order will be represented by an arbitrary
  // variable name
  String? variableName;
  OrderModel(this.decision, this.call, this.receiver, this.mWhenSent) {
    if (decision == Decision.confuse) {
      var variable =
          String.fromCharCode("a".codeUnits[0] + (_confusingOrders % 26));
      if (_confusingOrders > 25) {
        variable += (_confusingOrders / 25).floor().toString();
      }
      variableName = variable;
      _confusingOrders++;
    }
  }
  String visualizeDecision() {
    return decisionVisuals[decision] ?? variableName!;
  }
}

class GeneralModel {
  String name;
  bool treacherous;
  Rank rank;
  Decision ownDecision;
  List<OrderModel> orders = [];
  Alignment visualPosition;
  GeneralModel(this.name, this.rank, this.visualPosition,
      [this.treacherous = false, this.ownDecision = Decision.retreat]);
  GeneralModel.defaults(String name, Alignment pos)
      : this(name, Rank.lieutenant, pos);
  void addOrder(OrderModel o) {
    // with decisions A (attack), R (retreat), and the arbitrary decisions
    // produced by traitors here represented as lowercase variables starting
    // from "a", you would want to order them something like this:
    // A, A, A, A, a, b, c, R, R, R, R, R
    // with the order of the arbitrary variables being, well, arbitrary. the
    // point is, putting them in the middle lets them each be either attack or
    // retreat without breaking the ordering completely. If there is no
    // legitimate majority for either attacking or retreating, the generals just
    // need to all choose the same variable for their decision. Using the median
    // in finalDecision lets us do that.
    orders.add(o);
    orders.sort((a, b) {
      if (a.decision == b.decision) {
        return 0;
      } else if (a.decision == Decision.attack) {
        return -1;
      } else if (a.decision == Decision.retreat) {
        return 1;
      } else {
        // A is a symbolic variable
        if (b.decision == Decision.attack) {
          return 1;
        } else if (b.decision == Decision.retreat) {
          return -1;
        } else {
          return a.variableName!.compareTo(b.variableName!);
        }
      }
    });
  }

  OrderModel? finalDecision() {
    // finds the decision endorsed by a majority of orders by finding the median
    // decision received.
    return orders.isNotEmpty ? orders[(orders.length / 2).floor()] : null;
  }
}

enum BattleFieldState { waiting, running }

class BattleFieldModel extends ChangeNotifier {
  List<GeneralModel> generals = [];
  static const int initialGeneralCount = 4;
  BattleFieldState state = BattleFieldState.waiting;
  List<CallModel> history = [];
  List<OrderModel> orderOutbox = [];
  static int sendingTimeMS = 2500;
  CancelableOperation? runningProcess;

  static Alignment getAlignment(int i, int l, [double radius = 0.75]) {
    final rotateBy = (pi * 2) / l * i - pi / 2;
    return Alignment(cos(rotateBy) * radius, sin(rotateBy) * radius);
  }

  BattleFieldModel() : this.createGenerals(initialGeneralCount);
  BattleFieldModel.createGenerals(int generalCount) {
    setGeneralCount(generalCount);
    generals[0].rank = Rank.commander;
  }

  int get traitorCount =>
      generals.where((element) => element.treacherous).length;

  bool get consistencyPossible => generals.length > traitorCount * 3;

  void setTreachery(int generalIndex, bool treachery) {
    generals[generalIndex].treacherous = treachery;
    notifyListeners();
  }

  void setDecision(int generalIndex, Decision d) {
    generals[generalIndex].ownDecision = d;
    notifyListeners();
  }

  void setGeneralCount(int newCount) {
    if (newCount < 1 || newCount > 9) {
      return;
    } else if (newCount < generals.length) {
      generals = generals.getRange(0, newCount).toList();
      notifyListeners();
    } else if (newCount > generals.length) {
      generals.addAll(getNames(newCount)
          .getRange(generals.length, newCount)
          .mapIndexed(
              (i, n) => GeneralModel.defaults(n, getAlignment(i, newCount))));
      notifyListeners();
    }
  }

  void highlightCall(CallModel? c) {
    for (final call in history) {
      call.highlighted = false;
    }
    while (c != null) {
      c.highlighted = true;
      c = c.parent;
    }
    notifyListeners();
  }

  void reset() {
    state = BattleFieldState.waiting;
    history.clear();
    for (final g in generals) {
      g.orders.clear();
    }
    if (runningProcess != null) {
      runningProcess?.cancel();
      runningProcess = null;
    }
    notifyListeners();
  }

  void start() {
    if (state == BattleFieldState.running) {
      return;
    } else {
      runningProcess = CancelableOperation.fromFuture(om(
          traitorCount,
          0,
          generals[0],
          generals.getRange(1, generals.length).toList(),
          generals[0].ownDecision));
    }
  }

  Future<void> om(int m, int depth, GeneralModel actingCommander,
      List<GeneralModel> recipients, Decision toTransmit) async {
    if (m != 0) {
      print("not implemented yet");
      return;
    }
    state = BattleFieldState.running;
    if (actingCommander.rank == Rank.lieutenant) {
      actingCommander.rank = Rank.actingCommander;
    }
    final call = CallModel(actingCommander, depth, m);
    history.add(call);
    for (final r in recipients) {
      orderOutbox.add(OrderModel(toTransmit, call, r, m));
    }
    notifyListeners();
    await Future.delayed(Duration(milliseconds: sendingTimeMS));
    for (final o in orderOutbox) {
      o.receiver.orders.add(o);
    }
    orderOutbox.clear();
    state = BattleFieldState.waiting;
    if (actingCommander.rank == Rank.actingCommander) {
      actingCommander.rank = Rank.lieutenant;
    }
    // check IC1 and IC2
    notifyListeners();
  }
}
