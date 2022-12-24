import "package:test/test.dart";
import "package:generals/models.dart";

void main() {
  test("order variable names filled out correctly", () {
    final first = OrderModel(Decision.confuse, 0, 0, 0);
    final second = OrderModel(Decision.attack, 0, 0, 0);
    final third = OrderModel(Decision.confuse, 0, 0, 0);
    expect(first.variableName, equals("a"));
    expect(second.variableName, isNull);
    expect(third.variableName, equals("b"));
  });
}
