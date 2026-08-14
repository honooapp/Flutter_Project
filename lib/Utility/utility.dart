import 'dart:math';

class Utility {
  static final Utility _instance = Utility._internal();

  factory Utility() {
    return _instance;
  }

  Utility._internal();

  final String appName = 'honoo';
  // final String text1 = """Io lo scrivo sempre così:\nsenza virgolette\ne iniziale minuscola.\nE lo pronuncio "onù",\nsenza aspirazione iniziale.\n\nhonoo\nè un progetto multimediale,\narticolato in\n\nperformance\ne laboratori teatrali\n\nesplorazioni lunari\n\ne\nviaggi sull'Isola delle Storie.\n\nNon ci sono profili utenti\nin honoo.\nE non ci sono i "mi piace".\nMa se trovi un honoo\nche ti piace,\npuoi salvarlo nel tuo cuore\ne,\nse ne hai voglia,\npuoi anche fare\nqualcosa in più.\n\nO molto di più.\n\nSe è come penso,\nl'ultima volta\nche ci siamo visti\n\navevi gli occhi chiusi\ne hai fatto la scelta giusta.\n\nMi chiamo\nVenceslao Cembalo\ne se telefoni al\n3274920811,\npuoi sentire\nun’altra volta\nla mia voce\ne continuare il viaggio.\n\n Se le cose\nstanno\ndiversamente,\nclicca sull’icona della\nhome\nin basso a sinistra.\n\nIn alto\nal centro\ndi ogni schermata\nc'è il logo\nhonoo:\nse ci clicchi sopra,\ntorni qui\na questa pagina.\n""";
  final String text1First =
      """Io lo scrivo sempre così:\nsenza virgolette\ne iniziale minuscola\nE lo pronuncio "onù",\nsenza aspirazione iniziale\n\nhonoo\nè un progetto multimediale,\narticolato in""";
  final String text1Second = """\n\nesplorazioni lunari\n""";
  final String text1Third = """\n\nviaggi sull'Isola delle Storie\n""";
  final String text1Fourth =
      """\n\nNon ci sono profili utenti\nin honoo\nE non ci sono i "mi piace"\nMa se trovi un honoo\nche ti piace,\npuoi salvarlo nel tuo cuore\ne,\nse ne hai voglia,\npuoi anche fare\nqualcosa di più\n\nO molto di più\n\nSe è come penso,\nl'ultima volta\nche ci siamo visti\n\n""";
  final String text1Fifth =
      """\n\navevi gli occhi chiusi\ne hai fatto la scelta giusta\n\nMi chiamo\nVenceslao Cembalo\ne se telefoni al\n3274920811,\npuoi sentire\nun’altra volta\nla mia voce\ne continuare il viaggio\n\n Se le cose\nstanno\ndiversamente,\nclicca sull’icona della\nhome\nin basso a sinistra\n\nIn alto\nal centro\ndi ogni schermata\nc'è il logo\n\n""";
  final String text1Six =
      """\n\nse ci clicchi sopra,\ntorni qui\na questa pagina\n\n""";
  final String sostieniText =
      '\nVuoi collaborare\na questo progetto?\n\nScrivimi a\nvenceslao.cembalo@gmail.com\n\nSe fai la dichiarazione\ndei redditi,\npuoi scegliere\ndi destinare\nil 5 per mille\na honoo\n\nNon è una donazione in più\nNon costa nulla\n\nÈ una parte\ndelle tue imposte\nche puoi decidere\na chi destinare\n\nFirma\nnel riquadro\ndedicato agli Enti\ndel Terzo Settore\ne scrivi\nil codice fiscale\ndi honoo\n\nCodice fiscale di\nhonoo - laboratorio multimediale:\n95349850636\n\nSe ti va,\nclicca qui:\n\nhttps://ko-fi.com/honoo2026\n\nper offrire\nun bicchiere di Idromele\nagli Gnometti delle Idee\n\nOppure\nun paio di fiaschi\n\nI risultati\nsaranno scintillanti:\ngli Gnometti delle Idee\nsono sconsideratamente generosi\ncon chi è generoso\n\nProva\ne di me dirai\nche gli amici\nli consiglio bene\n\n';
  final String textHome1 = 'Ti regaliamo la Luna.\nPer sempre.';
  final String textHome2 =
      'Niente è per sempre,\ne nessuno può regalarti la Luna.\n\nÈ vero,\nma non per i poeti.\n\nVuoi essere un poeta di honoo?\n\nClicca sulla Bottiglia,\ne componi i tuoi honoo e hinoo.\n\nOppure sulla Luna,\ne guarda gli honoo\ne gli hinoo degli altri.\n\nO sull’Isola,\ne inizia il viaggio\nverso le tue storie.';
  final String podcastDiretteText =
      'honoo\nsi ascolta\ne si guarda.\n\nÈ voce.\nÈ immagine.\n\nUn canale YouTube.\nUn podcast.\nUn account Twitch.\n\nSe vuoi,\npuoi ascoltare,\nguardare\ne partecipare.\n\n';
  final String libriText =
      'Sto preparando\nle versioni cartacee\ndei miei libri\n\nHo acquistato\ni codici ISBN\ne una licenza\nInDesign\n\nÈ un lavoro lento\nArtigianale\n\nQui troverai la notizia,\nquando saranno pronti:\n\nIsola delle Storie\n\nIsole delle Storie\n(con illustrazioni di Joel Folda)\n\nImmacolato\n\nI limoni sono finiti\n\nAlmeno\navresti potuto\ncambiare i nomi\n\nPapà,\nma tu mi vuoi bene?\n';
  final String campanelliText =
      'In questa parte dell’Isola\nci sono case\n\nVuoi scoprire chi ci abita?\n\nScorrendo verso destra\npuoi leggere\nciò che ogni abitante\nha scelto di raccontarti\n\nSe vuoi,\nprova a bussare:\nmagari ti fa entrare';
  final String campanelloExample1Text =
      'Ti piace\nascoltare musica\nin compagnia?\n\nE ballare in casa,\ncome si fa alle feste?\n\nQuesto è il campanello\ndi casa mia\n\nPuoi bussare,\nse vuoi\n\nMagari sono a casa\nMagari sto ascoltando musica\nMagari è musica che ti piace';
  final String campanelloExample2Text =
      'Ti piace\nfare colazione in compagnia,\nin un terrazzo esposto a Sud?\n\nQuesto è il campanello di casa mia\n\nPuoi bussare,\nse vuoi\n\nMagari sono sul terrazzo\nMagari c’è il sole\nMagari sto facendo colazione';
  final String chestHeader = 'Il tuo Cuore custodisce';
  final String chestSubHeader1 = 'gli honoo\nsalvati dalla luna';
  final String chestSubHeader2 = 'gli honoo\nscritti da te';
  final String chestSubHeader3 = 'gli honoo\nche hai ricevuto';
  final String heartHeader =
      'Fra poco\npotrai salvare \nnel tuo Cuore\ngli <b>honoo<b> che vuoi.';
  final String answerHonooHeader =
      'Fra poco\npotrai rispondere\ncon un tuo <b>honoo<b>\nagli <b>honoo<b> degli altri.';
  final String honooInsertTemporary =
      'Fra poco qui\npotrai spedire\nil tuo <b>honoo<b>\nsulla Luna.'; //ok
  final String readMoonHeader =
      'Fra poco qui\npotrai vedere\ngli <b>honoo<b> degli altri.'; //ok
  final String sendMoonHeader =
      'Fra poco\npotrai spedire\nquesto <b>honoo<b>\nsulla Luna.';
  final String replyMoonHeader =
      'Se per te guardare\nnon è abbastanza,\nfra poco\npotrai fare di più.\nO molto di più.\n';
  final String heartMoonHeader =
      'Fra poco\npotrai salvare\nnel tuo Cuore\nquello che ti piace.\n';
  final String chestRightHeader =
      'Fra poco qui\npotrai vedere\ngli <b>honoo<b> che hai salvato\ne\ngli <b>honoo<b> che hai ricevuto.';
  final String answerHonooHeader2 =
      'Fra poco\npotrai rispondere\na questo <b>honoo<b>\ncon un tuo <b>honoo<b>.';
  final String honooConversationHeader =
      'Fra poco qui\npotrai accedere,\nscrollando in verticale,\nalla cronologia\ndi conversazioni fra <b>honoo<b>.';
  final String yourHonooHeader =
      'Fra poco qui\npotrai trovare\nuna copia\ndi tutti gli <b>honoo<b> scritti da te.';
  final String dadoTemporary =
      'Fra poco\npotrai trovare qui\nil tuo esagramma\nscelto a caso.'; //ok
  final String dadoTemporaryM =
      'Fra poco\npotrai trovare qui\nla tua missione\nscelta a caso.'; //missione
  final String dadoTemporaryL =
      'Fra poco\npotrai trovare qui\nla tua lettera\nscelta a caso.'; //lettera
  final String chestHeaderTemporary =
      'Fra poco qui\npotrai vedere\ngli <b>honoo<b> che hai scritto,\nche hai salvato dalla Luna,\nche hai ricevuto.'; //ok
  final String honooHinooHeader =
      'Fra poco qui\npotrai accedere\nai format\nper scrivere\ni tuoi <b>honoo<b> e i tuoi <b>hinoo<b>.'; //ok
  final String othersHonooHinooHeader =
      'Fra poco qui\npotrai vedere\ngli <b>honoo<b> e gli <b>hinoo<b>\ndegli altri.'; //ok
  final String shakespeare =
      'Quanto poveri\nsono coloro\nche non hanno pazienza!\n\nQuale ferita\nsi è mai guarita\nse non per gradi?';
  final String bibliography =
      'William Shakespeare, Otello, 1604, \natto II, scena III, vv. 360 - 361 ';

  dynamic getRandomElement(dynamic start, dynamic end) {
    if (start is int && end is int) {
      if (start > end) {
        throw ArgumentError(
          "Invalid range: start should be less than or equal to end.",
        );
      }
      return Random().nextInt(end - start + 1) + start;
    } else if (start is String && end is String) {
      if (start.length != 1 || end.length != 1) {
        throw ArgumentError(
          "Invalid range: start and end should be single characters.",
        );
      }
      int startCharCode = start.codeUnitAt(0);
      int endCharCode = end.codeUnitAt(0);
      if (startCharCode > endCharCode) {
        throw ArgumentError(
          "Invalid range: start should be less than or equal to end.",
        );
      }
      int randomCharCode =
          Random().nextInt(endCharCode - startCharCode + 1) + startCharCode;
      return String.fromCharCode(randomCharCode);
    } else {
      throw ArgumentError(
        "Invalid range: start and end should be either both integers or both characters.",
      );
    }
  }
}
