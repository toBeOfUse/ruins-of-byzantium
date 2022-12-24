import 'dart:math';

List<String> _names = [
  "Aemilius",
  "Agrippa",
  "Albinus",
  "Albius",
  "Amatus",
  "Amulius",
  "Ancus",
  "Annius",
  "Antonius",
  "Appius",
  "Aquilius",
  "Ascanius",
  "Asinius",
  "Atticus",
  "Attilius",
  "Augustus",
  "Aulus",
  "Aurelius",
  "Aurelianus",
  "Benedictus",
  "Brutus",
  "Cato",
  "Caecilius",
  "Caelestinus",
  "Caelius",
  "Calvus",
  "Camillus",
  "Candidus",
  "Cassius",
  "Claudius",
  "Clemens",
  "Cocceius",
  "Cornelius",
  "Costantinus",
  "Costantius",
  "Crassus",
  "Crispinus",
  "Decius",
  "Decimus",
  "Donatus",
  "Drusus",
  "Duilius",
  "Emilius",
  "Fabius",
  "Fabricius",
  "Faustus",
  "Felix",
  "Flavius",
  "Florius",
  "Fulvius",
  "Gabinius",
  "Galerius",
  "Gaius",
  "Gellius",
  "Hadrianus",
  "Helius",
  "Hennius",
  "Hercules",
  "Horatius",
  "Hortensius",
  "Iginus",
  "Isidorus",
  "Iulius",
  "Iulianus",
  "Iustus",
  "Lepidus",
  "Linus",
  "Livius",
  "Lucius",
  "Magnus",
  "Manlius",
  "Marcellus",
  "Marcus",
  "Marius",
  "Maximus",
  "Mauritius",
  "Octavius",
  "Ovidius",
  "Paulus",
  "Patricius",
  "Petrus",
  "Pius",
  "Pompeius",
  "Publius",
  "Quartus",
  "Quintus",
  "Remus",
  "Romanus",
  "Romulus",
  "Rufus",
  "Salvus",
  "Sergius",
  "Sirius",
  "Terentius",
  "Titus",
  "Tullius",
  "Ursus",
  "Valerius",
  "Varus",
  "Virgilius"
];

// iffy
var _firstRun = true;

List<String> getNames(int howMany) {
  if (_firstRun) {
    _names.shuffle();
    _firstRun = false;
  }
  var rounds = 1;
  List<String> result = [];
  while (result.length < howMany) {
    var needed = howMany - result.length;
    result.addAll([
      for (final name in _names.getRange(0, min(needed, _names.length)))
        name + (rounds > 1 ? " $rounds" : "")
    ]);
    rounds += 1;
  }
  return result;
}
