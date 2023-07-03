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

  List<List<Honoo>> getChestHonoo () {
    List<Honoo> personalHonoo = getPersonalHonoo();
    List<Honoo> answerHonoo = getAnswerHonoo();
    return [personalHonoo, answerHonoo];
  }

  List<Honoo> getPersonalHonoo() {
    List<Honoo> personalHonoo = [
      Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.' , 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', '', HonooType.personal),
      Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.' , 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', '', HonooType.personal),
    ];
    return personalHonoo;
  }

  List<Honoo> getAnswerHonoo() {
    List<Honoo> answerHonoo = [
      Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.', 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', '', HonooType.moon),
      Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.', 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', '', HonooType.answer),
      Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.', 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', '', HonooType.answer),
    ];
    return answerHonoo;
  }

  List<Honoo> getHonooHistory(Honoo honoo) {
    //TODO: retrieve honoo history from db for user
    List<Honoo> honooHistory = [];
    honooHistory.add(Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.', 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', '', HonooType.personal));
    honooHistory.add(Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.', 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', '', HonooType.answer));
    honooHistory.add(Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.', 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', '', HonooType.personal));
    honooHistory.add(Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.', 'https://previews.123rf.com/images/zhannagazova/zhannagazova1909/zhannagazova190900039/130260967-gravel-texture-and-strip-grass-as-background.jpg', '', '', '', HonooType.answer));
    return honooHistory;
  }

}
