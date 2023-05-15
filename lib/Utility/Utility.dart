import 'package:flutter/material.dart';

class Utility {
  static final Utility _instance = Utility._internal();

  factory Utility() {
    return _instance;
  }

  Utility._internal();

  final String appName = 'honoo';
  final String text1 = 'Io lo scrivo sempre così:\nsenza virgolette\ne iniziale minuscola.\nE lo pronuncio "onù",\nsenza aspirazione iniziale.\n\nhonoo è un progetto multimediale,\narticolato in\nperformance,\nesplorazioni\nlunari\ne viaggi sull\'Isola\ndelle Storie.\n\nNon ci sono profili utenti\nin honoo.\nE non ci sono i "mi piace".\nMa se trovi un honoo\nche ti piace,\npuoi salvarlo nel tuo cuore\ne,\nse ne hai voglia,\npuoi anche fare\nqualcosa in più.\n\nO molto di più.\n\nSe è come penso,\nl\'ultima volta\nche ci siamo visti\navevi gli occhi chiusi\ne hai fatto la scelta giusta.\n\nMi chiamo\nVenceslao Cembalo\ne se telefoni al\n3274920811,\npuoi sentire\nun’altra volta\nla mia voce\ne continuare il viaggio.\nle cose\nstanno\ndiversamente,\nclicca sull\’icona della\nhome\nin basso a sinistra.';
  final String textHome1 = 'Ti regaliamo la Luna.\nPer sempre.';
  final String textHome2 = 'Niente è per sempre,\ne nessuno può regalarti la Luna.\n\nÈ vero,\nma non per i poeti.\n\nVuoi essere un poeta di honoo?\n\nClicca sulla Bottiglia\ne componi il tuo honoo.\n\nOppure clicca sulla luna\ne guarda gli honoo degli altri.';
  final String chestText = 'A sinistra puoi trovare i tuoi honoo,\n\na destra quelli a cui hai risposto';
}
