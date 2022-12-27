import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:generals/names.dart';

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
  OrderModel(this.decision, this.receiver, this.mWhenSent, this.call,
      [this.variableName]) {
    if (decision == Decision.confuse && variableName == null) {
      var variable =
          String.fromCharCode("a".codeUnits[0] + (_confusingOrders % 26));
      if (_confusingOrders > 25) {
        final primes = (_confusingOrders / 25).floor();
        for (var i = 0; i < primes; i++) {
          variable += "'";
        }
      }
      variableName = variable;
      _confusingOrders++;
    }
  }
  String visualizeDecision() {
    return decisionVisuals[decision] ?? variableName!;
  }

  static resetVariableNames() {
    _confusingOrders = 0;
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
      if (a.decision == b.decision && a.decision != Decision.confuse) {
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
  static int sendingTimeMS = 1500;
  // if this changes during the async function that initiates state changes
  // after a delay, then that function will know to instead cancel itself and return
  int timesReset = 0;

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
    if (state != BattleFieldState.running) {
      reset();
      generals[generalIndex].treacherous = treachery;
      notifyListeners();
    }
  }

  void setDecision(int generalIndex, Decision d) {
    if (state != BattleFieldState.running) {
      generals[generalIndex].ownDecision = d;
      notifyListeners();
    }
  }

  void setGeneralPositions() {
    generals.forEachIndexed((index, element) =>
        element.visualPosition = getAlignment(index, generals.length));
  }

  void setGeneralCount(int newCount) {
    if (newCount < 1 || newCount > 9 || state == BattleFieldState.running) {
      return;
    } else if (newCount < generals.length) {
      generals = generals.getRange(0, newCount).toList();
      setGeneralPositions();
      reset();
      notifyListeners();
    } else if (newCount > generals.length) {
      generals.addAll(getNames(newCount)
          .getRange(generals.length, newCount)
          .mapIndexed((index, name) => GeneralModel.defaults(
              name,
              // placeholder position to keep type checker happy :/
              const Alignment(0, 0))));
      setGeneralPositions();
      reset();
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
    orderOutbox.clear();
    for (final g in generals) {
      g.orders.clear();
      if (g.rank == Rank.actingCommander) {
        g.rank = Rank.lieutenant;
      }
    }
    OrderModel.resetVariableNames();
    timesReset++;
    notifyListeners();
  }

  void start() {
    if (state == BattleFieldState.running) {
      return;
    } else {
      om(
          traitorCount,
          0,
          generals[0],
          generals.getRange(1, generals.length).toList(),
          null,
          null,
          timesReset);
    }
  }

  Future<void> om(
      int m,
      int depth,
      GeneralModel actingCommander,
      List<GeneralModel> recipients,
      OrderModel? receivedOrder,
      CallModel? parentCall,
      int resetID) async {
    if (timesReset != resetID) {
      return;
    }

    state = BattleFieldState.running;
    if (actingCommander.rank == Rank.lieutenant) {
      actingCommander.rank = Rank.actingCommander;
    }
    final call = CallModel(actingCommander, depth, m, parentCall);
    final sendingDecision =
        receivedOrder?.decision ?? actingCommander.ownDecision;
    history.add(call);
    assert(orderOutbox.isEmpty);
    Map<GeneralModel, OrderModel> ordersByRecipient = {};
    for (final r in recipients) {
      final rWillReceive = OrderModel(
          actingCommander.treacherous ? Decision.confuse : sendingDecision,
          r,
          m,
          call,
          receivedOrder?.variableName);
      ordersByRecipient[r] = rWillReceive;
      orderOutbox.add(rWillReceive);
    }
    notifyListeners();
    await Future.delayed(Duration(milliseconds: sendingTimeMS));
    if (timesReset != resetID) {
      return;
    }
    for (final o in orderOutbox) {
      o.receiver.addOrder(o);
    }
    orderOutbox.clear();
    state = BattleFieldState.waiting;
    if (actingCommander.rank == Rank.actingCommander) {
      actingCommander.rank = Rank.lieutenant;
    }
    // check IC1 and IC2
    notifyListeners();
    if (m > 0) {
      for (final general in recipients) {
        await om(
            m - 1,
            depth + 1,
            general,
            recipients.where((r) => r != general).toList(),
            ordersByRecipient[general]!,
            call,
            resetID);
      }
    }
  }
}
