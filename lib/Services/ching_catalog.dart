import 'dart:math';
import '../IsolaDelleStorie/Entities/ching.dart';

class ChingCatalog {
  ChingCatalog._();

  static const String _baseSvgPath = 'assets/icons/ching/svg/';

  static String _asset(int n) => '${_baseSvgPath}ching_$n.svg';

  static final Random _rng = Random();

  /// Lista 1..64, con stringhe modificabili (titoli/hanzi) e asset link esplicito.
  static final List<Ching> all = [
    Ching(number: 1, hanzi: '乾', titleIt: 'Il Creativo', assetPath: _asset(1)),
    Ching(number: 2, hanzi: '坤', titleIt: 'Il Ricettivo', assetPath: _asset(2)),
    Ching(
        number: 3,
        hanzi: '屯',
        titleIt: 'La Difficoltà Iniziale',
        assetPath: _asset(3)),
    Ching(
        number: 4,
        hanzi: '蒙',
        titleIt: 'La Stoltezza giovanile',
        assetPath: _asset(4)),
    Ching(number: 5, hanzi: '需', titleIt: "L'Attesa", assetPath: _asset(5)),
    Ching(number: 6, hanzi: '訟', titleIt: 'La Lite', assetPath: _asset(6)),
    Ching(number: 7, hanzi: '師', titleIt: "L'Esercito", assetPath: _asset(7)),
    Ching(
        number: 8, hanzi: '比', titleIt: 'La Solidarietà', assetPath: _asset(8)),
    Ching(
        number: 9,
        hanzi: '小畜',
        titleIt: 'La Forza domatrice del piccolo',
        assetPath: _asset(9)),
    Ching(
        number: 10, hanzi: '履', titleIt: 'Il Procedere', assetPath: _asset(10)),
    Ching(number: 11, hanzi: '泰', titleIt: 'La Pace', assetPath: _asset(11)),
    Ching(
        number: 12, hanzi: '否', titleIt: 'Il Ristagno', assetPath: _asset(12)),
    Ching(
        number: 13,
        hanzi: '同人',
        titleIt: "L'Associazione tra uomini",
        assetPath: _asset(13)),
    Ching(
        number: 14,
        hanzi: '大有',
        titleIt: 'Il Possesso grande',
        assetPath: _asset(14)),
    Ching(
        number: 15, hanzi: '謙', titleIt: 'La Modestia', assetPath: _asset(15)),
    Ching(
        number: 16, hanzi: '豫', titleIt: "L'Entusiasmo", assetPath: _asset(16)),
    Ching(number: 17, hanzi: '隨', titleIt: 'Il Seguire', assetPath: _asset(17)),
    Ching(
        number: 18,
        hanzi: '蠱',
        titleIt: "L'Emendamento delle cose guaste",
        assetPath: _asset(18)),
    Ching(
        number: 19,
        hanzi: '臨',
        titleIt: "L'Avvicinamento",
        assetPath: _asset(19)),
    Ching(
        number: 20,
        hanzi: '觀',
        titleIt: 'La Contemplazione (la Visione)',
        assetPath: _asset(20)),
    Ching(
        number: 21,
        hanzi: '噬嗑',
        titleIt: 'Il Morso che spezza',
        assetPath: _asset(21)),
    Ching(
        number: 22, hanzi: '賁', titleIt: "L'Avvenenza", assetPath: _asset(22)),
    Ching(
        number: 23,
        hanzi: '剝',
        titleIt: 'La Frantumazione',
        assetPath: _asset(23)),
    Ching(
        number: 24,
        hanzi: '復',
        titleIt: 'Il Ritorno (la Svolta)',
        assetPath: _asset(24)),
    Ching(
        number: 25, hanzi: '無妄', titleIt: "L'Innocenza", assetPath: _asset(25)),
    Ching(
        number: 26,
        hanzi: '大畜',
        titleIt: 'La Forza domatrice del grande',
        assetPath: _asset(26)),
    Ching(
        number: 27,
        hanzi: '頤',
        titleIt: "Gli Angoli della bocca (il Sostenta-mento)",
        assetPath: _asset(27)),
    Ching(
        number: 28,
        hanzi: '大過',
        titleIt: 'La Preponderanza del grande',
        assetPath: _asset(28)),
    Ching(
        number: 29,
        hanzi: '坎',
        titleIt: "L'Abissale (l'Acqua)",
        assetPath: _asset(29)),
    Ching(
        number: 30,
        hanzi: '離',
        titleIt: "L'Aderente (il Fuoco)",
        assetPath: _asset(30)),
    Ching(
        number: 31,
        hanzi: '咸',
        titleIt: 'La Stimolazione (la Domanda di-matrimonio)',
        assetPath: _asset(31)),
    Ching(number: 32, hanzi: '恆', titleIt: 'La Durata', assetPath: _asset(32)),
    Ching(
        number: 33, hanzi: '遯', titleIt: 'La Ritirata', assetPath: _asset(33)),
    Ching(
        number: 34,
        hanzi: '大壯',
        titleIt: 'La Potenza del grande',
        assetPath: _asset(34)),
    Ching(
        number: 35, hanzi: '晉', titleIt: 'Il Progresso', assetPath: _asset(35)),
    Ching(
        number: 36,
        hanzi: '明夷',
        titleIt: "L'Ottenebramento della luce",
        assetPath: _asset(36)),
    Ching(number: 37, hanzi: '家人', titleIt: 'La Casata', assetPath: _asset(37)),
    Ching(
        number: 38,
        hanzi: '睽',
        titleIt: 'La Contrapposizione',
        assetPath: _asset(38)),
    Ching(
        number: 39,
        hanzi: '蹇',
        titleIt: "L'Impedimento",
        assetPath: _asset(39)),
    Ching(
        number: 40,
        hanzi: '解',
        titleIt: 'La Liberazione',
        assetPath: _asset(40)),
    Ching(
        number: 41,
        hanzi: '損',
        titleIt: 'La Diminuzione',
        assetPath: _asset(41)),
    Ching(
        number: 42,
        hanzi: '益',
        titleIt: "L'Accrescimento",
        assetPath: _asset(42)),
    Ching(
        number: 43,
        hanzi: '夬',
        titleIt: 'Lo Straripamento (la Risolutezza)',
        assetPath: _asset(43)),
    Ching(
        number: 44,
        hanzi: '姤',
        titleIt: 'Il Farsi incontro',
        assetPath: _asset(44)),
    Ching(
        number: 45, hanzi: '萃', titleIt: 'La Raccolta', assetPath: _asset(45)),
    Ching(
        number: 46, hanzi: '升', titleIt: "L'Ascendere", assetPath: _asset(46)),
    Ching(
        number: 47,
        hanzi: '困',
        titleIt: "L'Assillo (l'Esaurimento)",
        assetPath: _asset(47)),
    Ching(number: 48, hanzi: '井', titleIt: 'Il Pozzo', assetPath: _asset(48)),
    Ching(
        number: 49,
        hanzi: '革',
        titleIt: 'Il Sovvertimento (la Muta)',
        assetPath: _asset(49)),
    Ching(
        number: 50, hanzi: '鼎', titleIt: 'Il Crogiolo', assetPath: _asset(50)),
    Ching(
        number: 51,
        hanzi: '震',
        titleIt: "L'Eccitante (lo Scuotimento, il Tuono)",
        assetPath: _asset(51)),
    Ching(
        number: 52,
        hanzi: '艮',
        titleIt: "L'Arresto (la Quiete, il Monte)",
        assetPath: _asset(52)),
    Ching(
        number: 53,
        hanzi: '漸',
        titleIt: "Lo Sviluppo (il Progresso graduale)",
        assetPath: _asset(53)),
    Ching(
        number: 54,
        hanzi: '歸妹',
        titleIt: 'La Ragazza che si sposa',
        assetPath: _asset(54)),
    Ching(
        number: 55, hanzi: '豐', titleIt: "L'Abbondanza", assetPath: _asset(55)),
    Ching(
        number: 56, hanzi: '旅', titleIt: 'Il Viandante', assetPath: _asset(56)),
    Ching(
        number: 57,
        hanzi: '巽',
        titleIt: "Il Mite (il Penetrante, il Vento)",
        assetPath: _asset(57)),
    Ching(
        number: 58,
        hanzi: '兌',
        titleIt: 'Il Sereno, il Lago',
        assetPath: _asset(58)),
    Ching(
        number: 59,
        hanzi: '渙',
        titleIt: 'La Dissoluzione (la Dispersione)',
        assetPath: _asset(59)),
    Ching(
        number: 60,
        hanzi: '節',
        titleIt: 'La Delimitazione',
        assetPath: _asset(60)),
    Ching(
        number: 61,
        hanzi: '中孚',
        titleIt: 'La Verità interiore',
        assetPath: _asset(61)),
    Ching(
        number: 62,
        hanzi: '小過',
        titleIt: 'La Preponderanza del piccolo',
        assetPath: _asset(62)),
    Ching(
        number: 63,
        hanzi: '既濟',
        titleIt: 'Dopo il compimento',
        assetPath: _asset(63)),
    Ching(
        number: 64,
        hanzi: '未濟',
        titleIt: 'Prima del compimento',
        assetPath: _asset(64)),
  ];

  static Ching pickRandom() => all[_rng.nextInt(all.length)];

  static Ching? byNumber(int n) {
    if (n < 1 || n > 64) return null;
    return all[n - 1];
  }
}
