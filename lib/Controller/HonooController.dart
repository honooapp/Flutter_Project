import 'package:flutter/material.dart';
import 'package:flutter_project/Entites/Honoo.dart';

class HonooController {
  static final HonooController _instance = HonooController._internal();

  factory HonooController() {
    return _instance;
  }

  HonooController._internal();

  List<Honoo> getMoonHonoo () {
    List<Honoo> honoo = [];
    honoo.add(Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.' , 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', ''));
    honoo.add(Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.' , 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', ''));
    honoo.add(Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.' , 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', ''));
    honoo.add(Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.' , 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', ''));
    return honoo;
  }

}
