import 'package:test/test.dart';
import 'package:generals/names.dart';

void main() {
  test("Random names list filled out correctly", () {
    final fewNames = getNames(5);
    expect(fewNames, hasLength(5));
    final manyNames = getNames(105);
    expect(manyNames, hasLength(105));
    final manyNamesSet = Set<String>.from(manyNames);
    expect(manyNamesSet, hasLength(manyNames.length));
    final doubles = manyNames.where((element) => element.endsWith("2"));
    expect(doubles, hasLength(5));
    print("Doubled names have 2 after them:");
    print(doubles);
  });
}
