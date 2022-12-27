import 'package:flutter/material.dart';
import "package:test/test.dart";
import "package:generals/models.dart";

void main() {
  test("order variable names filled out correctly", () {
    final fakeGeneral =
        GeneralModel("test", Rank.lieutenant, const Alignment(0, 0));
    final fakeCall = CallModel(fakeGeneral, 0, 0);
    final first = OrderModel(Decision.confuse, fakeGeneral, 0, fakeCall);
    final second = OrderModel(Decision.attack, fakeGeneral, 0, fakeCall);
    final third = OrderModel(Decision.confuse, fakeGeneral, 0, fakeCall);
    OrderModel? last;
    for (var i = 3; i <= 27; i++) {
      last = OrderModel(Decision.confuse, fakeGeneral, 0, fakeCall);
    }
    expect(first.variableName, equals("a"));
    expect(second.variableName, isNull);
    expect(third.variableName, equals("b"));
    expect(last?.variableName, equals("a'"));
  });
}
