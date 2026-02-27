'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.json": "c0847aea3e8dad05c5397d4f001a8a6d",
"assets/assets/sirenaepalombaro.jpg": "035c4a8fed4875fdea42ef29a6d95959",
"assets/assets/stanza.jpg": "29933221212632dff6ad52334cc9da6a",
"assets/assets/campanello2.png": "0b9d2091f671d1fe68ad893ca10e2d3d",
"assets/assets/google_fonts/LibreFranklin-VariableFont_wght.ttf": "45607ae9472e0b80708bf53919bfed87",
"assets/assets/google_fonts/Arvo-BoldItalic.ttf": "a53d4514f91e2a95842412c4d3954dd0",
"assets/assets/google_fonts/Arvo-Regular.ttf": "afb50701726581f5f817faab8f7cf1b7",
"assets/assets/google_fonts/LibreFranklin-Italic-VariableFont_wght.ttf": "72c9d0e8faa0b0532363d3f25fead170",
"assets/assets/google_fonts/Arvo-Italic.ttf": "4d7f205bc8a4a7e98c219a1427999533",
"assets/assets/google_fonts/Arvo-Bold.ttf": "ab1dabbd8ffd289a5c35cb151879e987",
"assets/assets/campanello1.png": "951fcdb376470a09e93ea478eaa37087",
"assets/assets/background.png": "951550fafcbfb802160ed022b9c42216",
"assets/assets/images/casa_palombaro_con_scrigno.png": "c71739b1d8c0f5eb8c9a750fe00da64b",
"assets/assets/images/casa_sirena.png": "a3ab38b4f9cd15a2114155d86b0d20bd",
"assets/assets/images/casa_palombaro.png": "aec3daa2984255e1d0dd2ec57d2db3d6",
"assets/assets/images/hinoo_default_1080x1920.png": "7671d72a5b8f654e10c182fe2fbdb427",
"assets/assets/stanza-02_carta.jpg": "2cf530faa9cecfc2fcc33b3fb86ee3d9",
"assets/assets/icons/load.svg": "3c33988ef9b2d10c8d46a9e89cbfe338",
"assets/assets/icons/arrow_left.svg": "d2b022769c93054c77c83a19db611203",
"assets/assets/icons/dado.png": "bd34185ee999b54456ba78406edcc1e7",
"assets/assets/icons/piuma.svg": "8135bf8799f92e9b1d115bcb17067d79",
"assets/assets/icons/ok.svg": "24efae71b4f7c48802677d71be189005",
"assets/assets/icons/honoo_chest_red.svg": "c6a00ef39e359c2fbc598dc0a0ba6aed",
"assets/assets/icons/reply.svg": "beb2a19eb7114f62db0e7120fe0942b3",
"assets/assets/icons/share.svg": "eee5b28d1bd8f977a440834a0f70886d",
"assets/assets/icons/chest.svg": "0a9bd20d464d36b74f9a17915fd5ca04",
"assets/assets/icons/dado_lightmode.svg": "83533a7cddd83e0f5e8722e2d62bbead",
"assets/assets/icons/feste.png": "b8771d2ef1c9171664f0f7d37ff6698e",
"assets/assets/icons/info.svg": "e158d4ccb73ad8ec56f0c971a985c906",
"assets/assets/icons/dado.svg": "fda077b3e0626db7e6a2ea589c197f42",
"assets/assets/icons/honoo_chest_white.svg": "fc1b9ad295c9bdcb6d9426bbb904bf4d",
"assets/assets/icons/campanello_bianco.png": "5fb572452ceb5ac9ebec5fbe07013038",
"assets/assets/icons/broken_heart.svg": "87cb1338bda723bc19d61232e17492ab",
"assets/assets/icons/isola.png": "9426dc43b2e85cb0e5ff45881a9534c9",
"assets/assets/icons/honoo_logo.svg": "8655ace5da458e5b5bdfb8718a4b09b0",
"assets/assets/icons/chest_home.svg": "d3037e301ca5e0d854053753712a4389",
"assets/assets/icons/isoladellestorie/button5.svg": "f542c87e7d048a0c4135470e8eababe7",
"assets/assets/icons/isoladellestorie/conchiglia.svg": "b3ed5a8c6417629f3f27d06d4df69096",
"assets/assets/icons/isoladellestorie/button7.svg": "acbc2a2d8323d85985f93f930e65b1bd",
"assets/assets/icons/isoladellestorie/islandmap.jpeg": "808b2e69a84b30e962da8031851a552f",
"assets/assets/icons/isoladellestorie/islandmap.svg": "dc7e9c34e0035dda2191053ea36bf001",
"assets/assets/icons/isoladellestorie/island.svg": "686e0d9f9c71555d7541d4c5ce8af551",
"assets/assets/icons/isoladellestorie/button9.svg": "97d5210e2d98475adbbcd76d4d709d32",
"assets/assets/icons/isoladellestorie/islandhome.svg": "d65e1eadae82ae66b216d6956f83324e",
"assets/assets/icons/isoladellestorie/garbuglio.svg": "33e838912236b0b9132f4235a2305b3a",
"assets/assets/icons/isoladellestorie/button4.svg": "b1961ac5022ed1c545d3e3085e38d0ae",
"assets/assets/icons/isoladellestorie/gomitolo.svg": "d2cea44d73d2ccdf29c4d57d302a157d",
"assets/assets/icons/isoladellestorie/path.svg": "62d30695f471a980811fdae296dd2821",
"assets/assets/icons/isoladellestorie/button1.svg": "0d31b48744213477ca58dcec67e518d7",
"assets/assets/icons/isoladellestorie/backgrounds/3pozzooracolo.jpg": "35aa28bcd6e58140343d8660c6e2cfb5",
"assets/assets/icons/isoladellestorie/backgrounds/5primoanello.jpg": "897e3a0c2cf8421109337f7db93c64a4",
"assets/assets/icons/isoladellestorie/backgrounds/2radurabacche.jpg": "f201618231bdc6c915ba66d618cf0ff1",
"assets/assets/icons/isoladellestorie/backgrounds/1grottarondini.png": "ade1cc4e12cfbfd2b1c3c8a1c893cc59",
"assets/assets/icons/isoladellestorie/backgrounds/5primoanello.png": "779576dfd091e24fab8656abc2530e38",
"assets/assets/icons/isoladellestorie/backgrounds/4portaalabastro.png": "65e88787daa0f3eab19d4396aeec5198",
"assets/assets/icons/isoladellestorie/backgrounds/2radurabacche_old_next.png": "2ffeb28060b3e0f3ab388122f54b8790",
"assets/assets/icons/isoladellestorie/backgrounds/1grottarondini_old.png": "56748b0e9d60b67ee6821ce7489f1ac8",
"assets/assets/icons/isoladellestorie/backgrounds/1grottarondini.jpg": "ba5a2729d073e8f10b6c3295c60e5bdf",
"assets/assets/icons/isoladellestorie/backgrounds/2radurabacche_old.jpg": "4c39efbc70bf338d52323e952b6dedd1",
"assets/assets/icons/isoladellestorie/backgrounds/8quartoanello.png": "aea0b0a92ca1bfe6abac3a0210e905dd",
"assets/assets/icons/isoladellestorie/backgrounds/2radurabacche_old.png": "4f77290ee5c5a4f301bec33e3af7d79c",
"assets/assets/icons/isoladellestorie/backgrounds/3pozzooracolo_old.png": "33eb8d4de28a3215e00d588d1bb399f2",
"assets/assets/icons/isoladellestorie/backgrounds/5primoanello_old.png": "9140f938b9731c377a137552013c0885",
"assets/assets/icons/isoladellestorie/backgrounds/8quartoanello_old.png": "2fed4e48210f188c43b44f27602ef019",
"assets/assets/icons/isoladellestorie/backgrounds/8quartoanello.jpg": "3137d508acb1af19523688f2ba3cb29c",
"assets/assets/icons/isoladellestorie/backgrounds/6secondoanello.jpg": "77348d0167212505561ea7186bfe4470",
"assets/assets/icons/isoladellestorie/backgrounds/6secondoanello.png": "01531622438754db252bd68fff8387c6",
"assets/assets/icons/isoladellestorie/backgrounds/7terzoanello_old.png": "946519bfbcc6d88305f557ad4b1bd80c",
"assets/assets/icons/isoladellestorie/backgrounds/7terzoanello.jpg": "c1a11fb6fee24c9a58a04770b05a3db7",
"assets/assets/icons/isoladellestorie/backgrounds/6secondoanello_old.png": "06daade7399af14c02d65c9d9296b899",
"assets/assets/icons/isoladellestorie/backgrounds/4portaalabastro_old.png": "a2426155d0dee696fe34692884889777",
"assets/assets/icons/isoladellestorie/backgrounds/9cunicololuce.jpg": "a2bc67db2e26888783fbf6aff0e51017",
"assets/assets/icons/isoladellestorie/backgrounds/3pozzooracolo.png": "a9776b8353d4ff4418b1aa08781b9739",
"assets/assets/icons/isoladellestorie/backgrounds/9cunicololuce_old.png": "55f44bfa52624a1642f288660743d3ff",
"assets/assets/icons/isoladellestorie/backgrounds/9cunicololuce.png": "6073a2f9479a56d28ac2e9fa62e5a066",
"assets/assets/icons/isoladellestorie/backgrounds/4portaalabastro.jpg": "7fa8ba1567f125a857b3ac0f68dd532a",
"assets/assets/icons/isoladellestorie/backgrounds/7terzoanello.png": "800e978949bef5a1a67436b8bdd93dda",
"assets/assets/icons/isoladellestorie/backgrounds/2radurabacche.png": "0cfa290e376747da01135802e3f912fb",
"assets/assets/icons/isoladellestorie/offUI.svg": "ab5650e199076fa1fbbb8e1bdafa9df8",
"assets/assets/icons/isoladellestorie/button2.svg": "a98c37bf77fff8b4e8ba6049d8e88222",
"assets/assets/icons/isoladellestorie/button8.svg": "19ecd75a1634f3593b3d6f7874a8607d",
"assets/assets/icons/isoladellestorie/button3.svg": "704d940cf27bafcbc3a94341e6caecda",
"assets/assets/icons/isoladellestorie/button6.svg": "268777fb8b3ebe0013de7efe22c94f81",
"assets/assets/icons/isoladellestorie/islandmap.jpg": "0128d059e28972dd58a85f55b93dfde6",
"assets/assets/icons/home.svg": "7e68e57c88d091c99c8a5799d269e84e",
"assets/assets/icons/laboratori_teatrali.png": "20d069272bc89b3dd9c614aa3f3ad2d2",
"assets/assets/icons/dice.svg": "018e1801c5968cb8c92c1fe0d5e773c6",
"assets/assets/icons/moon.svg": "4e81047ce6770648b7c571808ec85523",
"assets/assets/icons/logo_honoo.png": "6fc3f394a534ba1c912785a5a796ac11",
"assets/assets/icons/performance.png": "9145612bc2188110672faae48de648a9",
"assets/assets/icons/bottle.svg": "248ee70c164dc5e0e8a85e780f9cbc9c",
"assets/assets/icons/luna.png": "15b94d3950a0bc4c4d6946ee7f13c764",
"assets/assets/icons/broken_heart_white.svg": "484c9308870afacabb216894c0c6ee81",
"assets/assets/icons/honoo_chest_blue.svg": "00da73d7db3a1814acdb0068d62dc517",
"assets/assets/icons/heart.svg": "4a438b0c5a1367772474e631a6cb4c25",
"assets/assets/icons/venceslao.png": "c7dbdca53b01b7cd4759b390cf79a1c0",
"assets/assets/icons/arrow_right.svg": "a9d8d72f80c1a1286340c302599bb81f",
"assets/assets/icons/cancella.svg": "4f7ea0dba38777653af53448b3bbed64",
"assets/assets/icons/scrigno_di_carta.png": "52cd740d95fb4e95977785dfb277d80e",
"assets/assets/icons/home_onTertiary.svg": "790e0648b9a8ba278dca0ac4cbe4bcf9",
"assets/assets/icons/splash.svg": "bae9998753275f1bbc39ec960935773e",
"assets/assets/icons/ching/svg/ching_49.svg": "06f079022c37a3928304215cd421e35e",
"assets/assets/icons/ching/svg/ching_57.svg": "ed0480e3b73a59d2e69c3c2b3bc80b5f",
"assets/assets/icons/ching/svg/ching_11.svg": "07544798790028fc733c9ee632edbfc9",
"assets/assets/icons/ching/svg/ching_52.svg": "5145ea35d50fef55bd04c437ff8ed7ab",
"assets/assets/icons/ching/svg/ching_14.svg": "9ea7fdf925eab90fb56d28b354a3ef47",
"assets/assets/icons/ching/svg/ching_18.svg": "dd01ab0ea3d0463c02e2dd4bb6c3d584",
"assets/assets/icons/ching/svg/ching_55.svg": "60ff1e17681e578103660ed65c36a8c1",
"assets/assets/icons/ching/svg/ching_44.svg": "8d8d706ae108cccd16436b586bf9cad5",
"assets/assets/icons/ching/svg/ching_32.svg": "a729c37d61a7a7ee88bcd17df721ac47",
"assets/assets/icons/ching/svg/ching_41.svg": "a2dfb1abd7aa121614dccaf2a01c68aa",
"assets/assets/icons/ching/svg/ching_58.svg": "d2434cba404df405da0f3241abecae6d",
"assets/assets/icons/ching/svg/ching_56.svg": "7cd2d93c9d074d4da87a99f1503816d0",
"assets/assets/icons/ching/svg/ching_54.svg": "32705c533e7f53f991089dcf71ce30ef",
"assets/assets/icons/ching/svg/ching_23.svg": "db58b585537b7f7f30b11a242751b2dd",
"assets/assets/icons/ching/svg/ching_46.svg": "3149fe7d3efb6e48c64d4ed3182475d6",
"assets/assets/icons/ching/svg/ching_63.svg": "6ebc074f20e7b0afcbdf353f999cfc08",
"assets/assets/icons/ching/svg/ching_36.svg": "49570b95e27c31dcb45ad31d2fb10b51",
"assets/assets/icons/ching/svg/ching_2.svg": "e2c5f41971359ced257b33299d2e22c4",
"assets/assets/icons/ching/svg/ching_60.svg": "3360c12b45d68608ef818d63f989114a",
"assets/assets/icons/ching/svg/ching_42.svg": "65eac66481f8740f6862b4d907545959",
"assets/assets/icons/ching/svg/ching_40.svg": "c310bdceb829641e6376c2639428e27c",
"assets/assets/icons/ching/svg/ching_47.svg": "6caec2101c28928c228824b696cdfb3e",
"assets/assets/icons/ching/svg/ching_13.svg": "8b73f4f9977b3c9d19f104b6e4e82cec",
"assets/assets/icons/ching/svg/ching_24.svg": "7106f3843b73e19f54f8a91e89db5f94",
"assets/assets/icons/ching/svg/ching_64.svg": "23afe089a3eeff31321098977eb58771",
"assets/assets/icons/ching/svg/ching_53.svg": "d83752d003e6c83442c1284ab4c47e0a",
"assets/assets/icons/ching/svg/ching_16.svg": "b11221c14cdd7d60fb11d089f5fda9da",
"assets/assets/icons/ching/svg/ching_48.svg": "1b6603b0809cb532c2a623733088940a",
"assets/assets/icons/ching/svg/ching_34.svg": "a97ccdc7bb95fdfa60bef6a75a83667f",
"assets/assets/icons/ching/svg/ching_35.svg": "229895b6365b5f456ef1a9a49a1dfb90",
"assets/assets/icons/ching/svg/ching_62.svg": "bacae5c5e08dec89cfc48b0711515842",
"assets/assets/icons/ching/svg/ching_5.svg": "ade6c26d0ff92ca7c2cf43ff4515f45f",
"assets/assets/icons/ching/svg/ching_15%2520.svg": "b11221c14cdd7d60fb11d089f5fda9da",
"assets/assets/icons/ching/svg/ching_28.svg": "941552f45b15c1cc0f2ced4d73a686e6",
"assets/assets/icons/ching/svg/ching_31.svg": "a5bac124fe2a18206fb31b9ba9adef72",
"assets/assets/icons/ching/svg/ching_1.svg": "089ed7517b97fadd1fb4fcd31ffddd5b",
"assets/assets/icons/ching/svg/ching_38.svg": "65583fc43fcb99b46bb74b83301b4f9e",
"assets/assets/icons/ching/svg/ching_45.svg": "13791e24eeecd0a79497dfc4b3508c04",
"assets/assets/icons/ching/svg/ching_12.svg": "d14071c3b5d695f28f0a793ab29b2403",
"assets/assets/icons/ching/svg/ching_17.svg": "b88f81e52e9e52901e800a628532e368",
"assets/assets/icons/ching/svg/ching_33.svg": "cbb6a3b2693b687ad86ca515d8a6d6e2",
"assets/assets/icons/ching/svg/ching_19.svg": "96d4a8d234829ff91000deb41ce95a22",
"assets/assets/icons/ching/svg/ching_9.svg": "76cc3d466b0f26eced9d06ac85a4ad3b",
"assets/assets/icons/ching/svg/ching_37.svg": "823a221ffc2ce05dd01b07a3923598fe",
"assets/assets/icons/ching/svg/ching_29.svg": "1ede8ee30f99430569f3f279d534a791",
"assets/assets/icons/ching/svg/ching_7.svg": "78df465f3a3289ce3c33cf9e117d0435",
"assets/assets/icons/ching/svg/ching_4.svg": "0ae9685144649258ec934986f8d10298",
"assets/assets/icons/ching/svg/ching_43.svg": "0c48dac4eaacd5d474fad064cc0a4edb",
"assets/assets/icons/ching/svg/ching_50.svg": "e39e09cf701b14e4fd2a59c22c700129",
"assets/assets/icons/ching/svg/ching_39.svg": "02a3a3af9306d8bcf43cc44dfc6de15d",
"assets/assets/icons/ching/svg/ching_51.svg": "b2ac48e8dedc950b14230d2471be7255",
"assets/assets/icons/ching/svg/ching_21.svg": "64b518b58b441cca889b20490e203015",
"assets/assets/icons/ching/svg/ching_30.svg": "2b63dda1e4d152519677a9ce66ea4d23",
"assets/assets/icons/ching/svg/ching_26.svg": "5e54c122a8007034e74898f79f584d64",
"assets/assets/icons/ching/svg/ching_8.svg": "6d97779fd53988de90a1e5f362a58459",
"assets/assets/icons/ching/svg/ching_61.svg": "f0482ff85ca0963a9f94335e9410aeb8",
"assets/assets/icons/ching/svg/ching_3.svg": "a86f6e5d9a6a7199df371e9d7dc16bd7",
"assets/assets/icons/ching/svg/ching_27.svg": "04ac06880c719d11bd7ea48c8f510c56",
"assets/assets/icons/ching/svg/ching_10.svg": "e6e30eef78226c0dabb7def8292a5b4f",
"assets/assets/icons/ching/svg/ching_22.svg": "1c9585ea9372aefdf133871472ca5395",
"assets/assets/icons/ching/svg/ching_59.svg": "4e6795817dbb2394e8c204eabf737140",
"assets/assets/icons/ching/svg/ching_20.svg": "aaa790b01fc05e549ec9ab90aa2c9aec",
"assets/assets/icons/ching/svg/ching_6.svg": "bf72e64fe6d908cb4fcbe15725c2fa90",
"assets/assets/icons/ching/svg/ching_25.svg": "a1aeed2a8e24687c680455f93748b8d0",
"assets/assets/icons/ching/png/ching_2_Il%2520Ricettivo.png": "d002cae03883a80c332d3ddf99569d7c",
"assets/assets/icons/ching/png/ching_63_Dopo%2520il%2520compimento.png": "5faf68609b5e5302552fd6885bd0b024",
"assets/assets/icons/ching/png/ching_64_Prima%2520del%2520compimento.png": "28b4a46e2cc4a49f03d50f0a07464658",
"assets/assets/icons/ching/png/ching_37_La%2520Casata.png": "b6eaafa8bf3906bb62ed21d5056a0f78",
"assets/assets/icons/ching/png/ching_48_Il%2520Pozzo.png": "3105daa86efe5f0b8e0504bc9f7c28fd",
"assets/assets/icons/ching/png/ching_36_L'Ottenebramento%2520della%2520luce.png": "d5569e489eac68710624c51a3f1909ef",
"assets/assets/icons/ching/png/ching_22_L'Avvenenza.png": "cce0c98c37783d2c973fc7ffe2c43575",
"assets/assets/icons/ching/png/ching_27_Gli%2520Angoli%2520della%2520bocca%2520(il%2520Sostenta-mento).png": "87230cb535bbb05e9361c577abfc2379",
"assets/assets/icons/ching/png/ching_42_L'Accrescimento.png": "b744c5bcc15594df0141b4e3119f8f37",
"assets/assets/icons/ching/png/ching_12_Il%2520Ristagno.png": "3f4379c629c87a77881a4725479c4283",
"assets/assets/icons/ching/png/ching_32_La%2520Durata.png": "5a3486ba47d9976444efd6adb49a8892",
"assets/assets/icons/ching/png/ching_6_La%2520Lite.png": "e95895ff3f4eec45e6536b188fc06a77",
"assets/assets/icons/ching/png/ching_60_La%2520Delimitazione.png": "7e5839394583a9dc12b0f30c71bd2c74",
"assets/assets/icons/ching/png/ching_23_La%2520Frantumazione.png": "5d693667c1ca2203fd691fff9f5f5cfd",
"assets/assets/icons/ching/png/ching_52_L'Arresto%2520(la%2520Quiete,%2520il%2520Monte).png": "a8ebe7ce241ce3d7a3d2f30964faf15b",
"assets/assets/icons/ching/png/ching_24_Il%2520Ritorno%2520(la%2520Svolta).png": "debe1310b302a7caf3f9dab162d9746e",
"assets/assets/icons/ching/png/ching_11_La%2520Pace.png": "9215ad024af1d7237e2be9bafa203a6f",
"assets/assets/icons/ching/png/ching_17_Il%2520Seguire.png": "2fad7339717e1fa31ca90817caab95e7",
"assets/assets/icons/ching/png/ching_7_L'Esercito.png": "dc50d3418d578e89f9c163625a9fe4ab",
"assets/assets/icons/ching/png/ching_50_Il%2520Crogiolo.png": "e1ff9956937143230a834b5859d4a141",
"assets/assets/icons/ching/png/ching_28_La%2520Preponderanza%2520del%2520grande.png": "bbead78c933e152aaa569040e89b531a",
"assets/assets/icons/ching/png/ching_16_Il%2520Fervore.png": "003d1d46282180f48dfa85527cad34ad",
"assets/assets/icons/ching/png/ching_44_Il%2520Farsi%2520incontro.png": "1cf3372fd92c5bee1813947677b510fc",
"assets/assets/icons/ching/png/ching_45_La%2520Raccolta.png": "b61af4b970cf6ed0cc4d58b8049100e8",
"assets/assets/icons/ching/png/ching_40_La%2520Liberazione.png": "579d459d6f54bf98f2879a78e7cdc55d",
"assets/assets/icons/ching/png/ching_55_L'Abbondanza.png": "a2d19cb10eb796ccdd0d4cc01c3e882e",
"assets/assets/icons/ching/png/ching_8_La%2520Solidariet%25C3%25A0.png": "3598aeda905553dc670734e96ba32bf3",
"assets/assets/icons/ching/png/ching_10_Il%2520Procedere.png": "7af760c60bbf988b42892517ac0fd361",
"assets/assets/icons/ching/png/ching_25_L'Innocenza%2520(l'Inaspettato).png": "7c7b31ad701981dc7333d96e3452a302",
"assets/assets/icons/ching/png/ching_13_L'Associazione%2520tra%2520uomini.png": "cd277aa6371864f07a6208ec3c82da62",
"assets/assets/icons/ching/png/ching_58_Il%2520Sereno,%2520il%2520Lago.png": "f0a0892c6cbff05dd9f708d1cb47375b",
"assets/assets/icons/ching/png/ching_38_La%2520Contrapposizione.png": "463446deb82739113b552758ac83cb57",
"assets/assets/icons/ching/png/ching_1_Il%2520Creativo.png": "c2503b16a5a76ef7f7bc8626a481f000",
"assets/assets/icons/ching/png/ching_3_La%2520Difficolt%25C3%25A0%2520Iniziale.png": "d7f043ff6dc40ff92ed012194c7a05ec",
"assets/assets/icons/ching/png/ching_54_La%2520Ragazza%2520che%2520si%2520sposa.png": "2414cad484fc94f0d1cb593970624bf4",
"assets/assets/icons/ching/png/ching_59_La%2520Dissoluzione%2520(la%2520Dispersione).png": "9a409fb25b2e998eb3322b2430861c6a",
"assets/assets/icons/ching/png/ching_26_La%2520Forza%2520domatrice%2520del%2520grande.png": "7d22ea6fa0999e502ef95d828748a0dd",
"assets/assets/icons/ching/png/ching_47_L'Assillo%2520(l'Esaurimento).png": "26b519f92b520f9579d6cb66ac3cc191",
"assets/assets/icons/ching/png/ching_9_La%2520Forza%2520domatrice%2520del%2520piccolo.png": "a5af8f6d04fb5f41ab807825874dca61",
"assets/assets/icons/ching/png/ching_14_Il%2520Possesso%2520grande.png": "a06c8b67fd803e6d692e68466aaf446d",
"assets/assets/icons/ching/png/ching_15_La%2520Modestia.png": "7f8952c90053ece0edfac383dafb7e7a",
"assets/assets/icons/ching/png/ching_41_La%2520Diminuzione.png": "3e57992c024055ce86f9bb6a7d274cee",
"assets/assets/icons/ching/png/ching_56_Il%2520Viandante.png": "8fb54438c38a87b850d06e72562372ea",
"assets/assets/icons/ching/png/ching_43_Lo%2520Straripamento%2520(la%2520Risolutezza).png": "1b30c161fff13ede4dd7953a04d02fa7",
"assets/assets/icons/ching/png/ching_19_L'Avvicinamento.png": "e3879bc95cb4ce1a5c45908198ffc3c2",
"assets/assets/icons/ching/png/ching_34_La%2520Potenza%2520del%2520grande.png": "57e5a86512b5cddf220485cc7aca0ead",
"assets/assets/icons/ching/png/ching_51_L'Eccitante%2520(lo%2520Scuotimento,%2520il--%2520Tuono).png": "bad621344480d6db279d198ae2c1650c",
"assets/assets/icons/ching/png/ching_33_La%2520Ritirata.png": "cab888db67ebebf6d8b29d57a9ff772e",
"assets/assets/icons/ching/png/ching_30_L'Aderente%2520(il%2520Fuoco).png": "6e9d6352c5c48d363e54865a914d73f0",
"assets/assets/icons/ching/png/ching_4_La%2520Stoltezza%2520giovanile.png": "62ac04ed4f04d703b7ea9ae1bf799ce9",
"assets/assets/icons/ching/png/ching_57_Il%2520Mite%2520(il%2520Penetrante,%2520il%2520Vento).png": "97689030e0421d64bed05675818cea5b",
"assets/assets/icons/ching/png/ching_62_La%2520Preponderanza%2520del%2520piccolo.png": "e90601583f11bd3af010a83b4e8261bd",
"assets/assets/icons/ching/png/ching_21_Il%2520Morso%2520che%2520spezza.png": "dcb5712c66554fcda8ae8fddbba498c3",
"assets/assets/icons/ching/png/ching_61_La%2520Verit%25C3%25A0%2520interiore.png": "1687510163fc5ebc89386840ce4fca07",
"assets/assets/icons/ching/png/ching_5_L'Attesa.png": "6687becd57845278ad8a2aabc5ba1ee7",
"assets/assets/icons/ching/png/ching_53_Lo%2520Sviluppo%2520(il%2520Progresso%2520graduale).png": "970fe855e43d59bd441ddc2ed29243a0",
"assets/assets/icons/ching/png/ching_20_La%2520Contemplazione%2520(la%2520Visione).png": "4f89c65c2366154cc800ffe74e41e03b",
"assets/assets/icons/ching/png/ching_39_L'Impedimento.png": "7f19b23ec70028ca06f4d371c707dddd",
"assets/assets/icons/ching/png/ching_49_Il%2520Sovvertimento%2520(la%2520Muta).png": "2ac3f80d21026daf9e02c04421038bf4",
"assets/assets/icons/ching/png/ching_46_L'Ascendere.png": "16093de62a217cb0f09ec998541424e8",
"assets/assets/icons/ching/png/ching_18_L'Emendamento%2520delle%2520cose%2520guaste.png": "5a4efdd65b34d3211c9b7c8a7b554570",
"assets/assets/icons/ching/png/ching_29_L'Abissale%2520(l'Acqua).png": "d478fe49dff5a9713c12eab1ea4b6440",
"assets/assets/icons/ching/png/ching_35_Il%2520Progresso.png": "fe9f0a8ba2431b310a4dba914b581f2a",
"assets/assets/icons/ching/png/ching_31_La%2520Stimolazione%2520(la%2520Domanda%2520di-matrimonio).png": "aabafa9f897ff0a34605638bdda935de",
"assets/NOTICES": "c14256c1cf39ad2e12e0add7de2e57db",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "57d849d738900cfd590e9adc7e208250",
"assets/packages/golden_toolkit/fonts/Roboto-Regular.ttf": "ac3f799d5bbaf5196fab15ab8de8431c",
"assets/fonts/MaterialIcons-Regular.otf": "67f4e02883483ee354f698b3e6dac0a9",
"assets/shaders/ink_sparkle.frag": "f8b80e740d33eb157090be4e995febdf",
"assets/AssetManifest.bin": "3d56dbf2049086910b8f26fca647f19c",
"assets/FontManifest.json": "533db2964f00aa0a56d9c03607f21c52",
"index.html": "8d1d14464e2b32085559ac93aeca793e",
"/": "8d1d14464e2b32085559ac93aeca793e",
"manifest.json": "68268adfd9ea5553746313cc93c5f887",
"main.dart.js": "b68fee23f63b2a99bc8693ef3b1562db",
"favicon.ico": "ed54c59b64878d2d06ec2bf2c1a3aa7d",
"flutter.js": "6fef97aeca90b426343ba6c5c9dc5d4a",
"canvaskit/canvaskit.wasm": "f48eaf57cada79163ec6dec7929486ea",
"canvaskit/skwasm.js": "1df4d741f441fa1a4d10530ced463ef8",
"canvaskit/skwasm.wasm": "6711032e17bf49924b2b001cef0d3ea3",
"canvaskit/canvaskit.js": "76f7d822f42397160c5dfc69cbc9b2de",
"canvaskit/skwasm.worker.js": "19659053a277272607529ef87acf9d8a",
"canvaskit/chromium/canvaskit.wasm": "fc18c3010856029414b70cae1afc5cd9",
"canvaskit/chromium/canvaskit.js": "8c8392ce4a4364cbb240aa09b5652e05",
"version.json": "575fb5da6a11e323046ad3d14f89769a",
"icons/honoo_icon-512.png": "9ffa8db87af77fe122309e4aeed54971",
"icons/honoo_icon-192.png": "35b2fb81cb2d422be558c6c7921f597a",
"icons/honoo_icon-48.png": "ef17724e0caeefe32b66eb71b36265a5"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"assets/AssetManifest.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
