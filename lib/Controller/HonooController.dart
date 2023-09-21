import 'package:honoo/Entites/Honoo.dart';

class HonooController {
  static final HonooController _instance = HonooController._internal();

  factory HonooController() {
    return _instance;
  }

  HonooController._internal();

  List<Honoo> getMoonHonoo () {
    List<Honoo> honoo = [];
    honoo.add(Honoo(0,'Ricambio\nil tuo sorriso malizioso.\nLe nostre arie da reduci\nnon ci incantano.' , 'https://i.imgur.com/o0uGbQr.png', '', '', '', HonooType.moon));
    honoo.add(Honoo(0,'Solo una foto,\nnessuna domanda.\nMa so che ricordi\nla vecchia risposta.\n' , 'https://i.imgur.com/F2Udf4s.png', '', '', '', HonooType.moon));
    honoo.add(Honoo(0,'Papà,\nma tu mi vuoi bene?\n' , 'https://i.imgur.com/0yMYcNp.png', '', '', '', HonooType.moon));
    honoo.add(Honoo(0,'Gli abissi degli altri\nsembrano sempre\no\nfrivoli\no\nincomprensibili.\n' , 'https://i.imgur.com/IzA73qo.png', '', '', '', HonooType.moon));
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
