import 'package:flutter/foundation.dart';
import 'package:generals/names.dart';
import 'package:provider/provider.dart';

enum Decision { attack, retreat, confuse }

Map<Decision, String> decisionVisuals = {
  Decision.attack: "⚔",
  Decision.retreat: "🏃‍♂️"
};

enum Rank { commander, actingCommander, lieutenant }

class OrderModel {
  Decision decision;
  int senderIndex;
  int receiverIndex;
  int mWhenSent;
  static int _confusingOrders = 0;
  // if order == Confuse, this order will be represented by an arbitrary
  // variable name
  String? variableName;
  OrderModel(
      this.decision, this.senderIndex, this.receiverIndex, this.mWhenSent) {
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
  GeneralModel(this.name, this.rank,
      [this.treacherous = false, this.ownDecision = Decision.retreat]);
  GeneralModel.fromName(String name) : this(name, Rank.lieutenant);
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

  OrderModel finalDecision() {
    // finds the decision endorsed by a majority of orders by finding the median
    // decision received.
    return orders[(orders.length / 2).floor()];
  }
}

class BattleFieldModel extends ChangeNotifier {
  List<GeneralModel> generals = [];
  BattleFieldModel(int generalCount) {
    generals.addAll(getNames(generalCount).map(GeneralModel.fromName));
    generals[0].rank = Rank.commander;
  }
  int get traitorCount =>
      generals.where((element) => element.treacherous).length;
  void setTreachery(int generalIndex, bool treachery) {
    generals[generalIndex].treacherous = treachery;
    notifyListeners();
  }

  void setDecision(int generalIndex, Decision d) {
    generals[generalIndex].ownDecision = d;
    notifyListeners();
  }

  void setGeneralCount(int newCount) {
    if (newCount < 1) {
      return;
    } else if (newCount < generals.length) {
      generals = generals.getRange(0, newCount).toList();
      notifyListeners();
    } else if (newCount > generals.length) {
      generals.addAll(getNames(newCount)
          .getRange(generals.length, newCount)
          .map(GeneralModel.fromName));
    }
  }
}
