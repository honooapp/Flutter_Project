import 'package:flutter/material.dart';
import 'package:honoo/Entites/Honoo.dart';

class HonooController {
  static final HonooController _instance = HonooController._internal();

  factory HonooController() {
    return _instance;
  }

  HonooController._internal();

  List<Honoo> getMoonHonoo () {
    List<Honoo> honoo = [];
    honoo.add(Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.' , 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', '', HonooType.moon));
    honoo.add(Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.' , 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', '', HonooType.moon));
    honoo.add(Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.' , 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', '', HonooType.moon));
    honoo.add(Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.' , 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', '', HonooType.moon));
    return honoo;
  }

  List<List<List<Honoo>>> getChestHonoo () {
    List<List<Honoo>> personalHonoo = getPersonalHonoo();
    List<List<Honoo>> answerHonoo = getAnswerHonoo();
    return [personalHonoo, answerHonoo];
  }

  List<List<Honoo>> getPersonalHonoo() {
    List<Honoo> personalHonoo1 = [
      Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.' , 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', '', HonooType.personal),
      Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.' , 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', '', HonooType.answer),
      Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.' , 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', '', HonooType.personal),
    ];
    List<Honoo> personalHonoo2 = [
      Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.' , 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', '', HonooType.personal),
      Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.' , 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', '', HonooType.answer),
      Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.' , 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', '', HonooType.personal),
      Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.' , 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', '', HonooType.answer),
    ];
    return [personalHonoo1, personalHonoo2];
  }

  List<List<Honoo>> getAnswerHonoo() {
    List<Honoo> answerHonoo1 = [
      Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.', 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', '', HonooType.moon),
      Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.', 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', '', HonooType.personal),
    ];
    List<Honoo> answerHonoo2 = [
      Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.', 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', '', HonooType.moon),
      Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.', 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', '', HonooType.personal),
      Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.', 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', '', HonooType.answer),
    ];
    return [answerHonoo1, answerHonoo2];
  }

}
