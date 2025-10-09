'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"version.json": "36ebf088e792919511c898d53ed38677",
"favicon.ico": "ed54c59b64878d2d06ec2bf2c1a3aa7d",
"index.html": "fbec61b327eaac13fffb1692760c1886",
"/": "fbec61b327eaac13fffb1692760c1886",
"main.dart.js": "592b3baf80383438fe38939dd9eee073",
"flutter.js": "6fef97aeca90b426343ba6c5c9dc5d4a",
"icons/honoo_icon-192.png": "35b2fb81cb2d422be558c6c7921f597a",
"icons/honoo_icon-48.png": "ef17724e0caeefe32b66eb71b36265a5",
"icons/honoo_icon-512.png": "9ffa8db87af77fe122309e4aeed54971",
"manifest.json": "68268adfd9ea5553746313cc93c5f887",
"assets/AssetManifest.json": "642dc93edef4b5a613ee153c637aa45f",
"assets/NOTICES": "2ab0c46a614a7817d23bd1739ecbbc40",
"assets/FontManifest.json": "533db2964f00aa0a56d9c03607f21c52",
"assets/packages/golden_toolkit/fonts/Roboto-Regular.ttf": "ac3f799d5bbaf5196fab15ab8de8431c",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "57d849d738900cfd590e9adc7e208250",
"assets/shaders/ink_sparkle.frag": "57f2f020e63be0dd85efafc7b7b25d80",
"assets/AssetManifest.bin": "3380c98be8e3619327c3ac0f531e044c",
"assets/fonts/MaterialIcons-Regular.otf": "67f4e02883483ee354f698b3e6dac0a9",
"assets/assets/images/hinoo_default_1080x1920.png": "7671d72a5b8f654e10c182fe2fbdb427",
"assets/assets/background.png": "951550fafcbfb802160ed022b9c42216",
"assets/assets/icons/isola.png": "9426dc43b2e85cb0e5ff45881a9534c9",
"assets/assets/icons/isoladellestorie/offUI.svg": "ab5650e199076fa1fbbb8e1bdafa9df8",
"assets/assets/icons/isoladellestorie/islandmap.svg": "dc7e9c34e0035dda2191053ea36bf001",
"assets/assets/icons/isoladellestorie/path.svg": "62d30695f471a980811fdae296dd2821",
"assets/assets/icons/isoladellestorie/button8.svg": "19ecd75a1634f3593b3d6f7874a8607d",
"assets/assets/icons/isoladellestorie/button9.svg": "97d5210e2d98475adbbcd76d4d709d32",
"assets/assets/icons/isoladellestorie/island.svg": "1463a00cf236806312fbabf43a420a2e",
"assets/assets/icons/isoladellestorie/gomitolo.svg": "d2cea44d73d2ccdf29c4d57d302a157d",
"assets/assets/icons/isoladellestorie/conchiglia.svg": "b3ed5a8c6417629f3f27d06d4df69096",
"assets/assets/icons/isoladellestorie/islandmap.jpg": "0128d059e28972dd58a85f55b93dfde6",
"assets/assets/icons/isoladellestorie/islandhome.svg": "d65e1eadae82ae66b216d6956f83324e",
"assets/assets/icons/isoladellestorie/backgrounds/7terzoanello.png": "800e978949bef5a1a67436b8bdd93dda",
"assets/assets/icons/isoladellestorie/backgrounds/7terzoanello.jpg": "c1a11fb6fee24c9a58a04770b05a3db7",
"assets/assets/icons/isoladellestorie/backgrounds/3pozzooracolo_old.png": "33eb8d4de28a3215e00d588d1bb399f2",
"assets/assets/icons/isoladellestorie/backgrounds/6secondoanello_old.png": "06daade7399af14c02d65c9d9296b899",
"assets/assets/icons/isoladellestorie/backgrounds/8quartoanello.jpg": "3137d508acb1af19523688f2ba3cb29c",
"assets/assets/icons/isoladellestorie/backgrounds/8quartoanello.png": "aea0b0a92ca1bfe6abac3a0210e905dd",
"assets/assets/icons/isoladellestorie/backgrounds/8quartoanello_old.png": "2fed4e48210f188c43b44f27602ef019",
"assets/assets/icons/isoladellestorie/backgrounds/4portaalabastro_old.png": "a2426155d0dee696fe34692884889777",
"assets/assets/icons/isoladellestorie/backgrounds/1grottarondini_old.png": "56748b0e9d60b67ee6821ce7489f1ac8",
"assets/assets/icons/isoladellestorie/backgrounds/7terzoanello_old.png": "946519bfbcc6d88305f557ad4b1bd80c",
"assets/assets/icons/isoladellestorie/backgrounds/9cunicololuce_old.png": "55f44bfa52624a1642f288660743d3ff",
"assets/assets/icons/isoladellestorie/backgrounds/5primoanello_old.png": "9140f938b9731c377a137552013c0885",
"assets/assets/icons/isoladellestorie/backgrounds/1grottarondini.jpg": "ba5a2729d073e8f10b6c3295c60e5bdf",
"assets/assets/icons/isoladellestorie/backgrounds/1grottarondini.png": "ade1cc4e12cfbfd2b1c3c8a1c893cc59",
"assets/assets/icons/isoladellestorie/backgrounds/2radurabacche.png": "0cfa290e376747da01135802e3f912fb",
"assets/assets/icons/isoladellestorie/backgrounds/2radurabacche.jpg": "f201618231bdc6c915ba66d618cf0ff1",
"assets/assets/icons/isoladellestorie/backgrounds/4portaalabastro.png": "65e88787daa0f3eab19d4396aeec5198",
"assets/assets/icons/isoladellestorie/backgrounds/4portaalabastro.jpg": "7fa8ba1567f125a857b3ac0f68dd532a",
"assets/assets/icons/isoladellestorie/backgrounds/5primoanello.png": "779576dfd091e24fab8656abc2530e38",
"assets/assets/icons/isoladellestorie/backgrounds/5primoanello.jpg": "897e3a0c2cf8421109337f7db93c64a4",
"assets/assets/icons/isoladellestorie/backgrounds/2radurabacche_old_next.png": "2ffeb28060b3e0f3ab388122f54b8790",
"assets/assets/icons/isoladellestorie/backgrounds/3pozzooracolo.png": "a9776b8353d4ff4418b1aa08781b9739",
"assets/assets/icons/isoladellestorie/backgrounds/3pozzooracolo.jpg": "35aa28bcd6e58140343d8660c6e2cfb5",
"assets/assets/icons/isoladellestorie/backgrounds/2radurabacche_old.png": "4f77290ee5c5a4f301bec33e3af7d79c",
"assets/assets/icons/isoladellestorie/backgrounds/2radurabacche_old.jpg": "4c39efbc70bf338d52323e952b6dedd1",
"assets/assets/icons/isoladellestorie/backgrounds/9cunicololuce.jpg": "a2bc67db2e26888783fbf6aff0e51017",
"assets/assets/icons/isoladellestorie/backgrounds/9cunicololuce.png": "6073a2f9479a56d28ac2e9fa62e5a066",
"assets/assets/icons/isoladellestorie/backgrounds/6secondoanello.jpg": "77348d0167212505561ea7186bfe4470",
"assets/assets/icons/isoladellestorie/backgrounds/6secondoanello.png": "01531622438754db252bd68fff8387c6",
"assets/assets/icons/isoladellestorie/button7.svg": "acbc2a2d8323d85985f93f930e65b1bd",
"assets/assets/icons/isoladellestorie/button6.svg": "268777fb8b3ebe0013de7efe22c94f81",
"assets/assets/icons/isoladellestorie/button4.svg": "b1961ac5022ed1c545d3e3085e38d0ae",
"assets/assets/icons/isoladellestorie/button5.svg": "f542c87e7d048a0c4135470e8eababe7",
"assets/assets/icons/isoladellestorie/button1.svg": "0d31b48744213477ca58dcec67e518d7",
"assets/assets/icons/isoladellestorie/garbuglio.svg": "33e838912236b0b9132f4235a2305b3a",
"assets/assets/icons/isoladellestorie/button2.svg": "a98c37bf77fff8b4e8ba6049d8e88222",
"assets/assets/icons/isoladellestorie/button3.svg": "704d940cf27bafcbc3a94341e6caecda",
"assets/assets/icons/reply.svg": "beb2a19eb7114f62db0e7120fe0942b3",
"assets/assets/icons/bottle.svg": "248ee70c164dc5e0e8a85e780f9cbc9c",
"assets/assets/icons/chest.svg": "0a9bd20d464d36b74f9a17915fd5ca04",
"assets/assets/icons/home.svg": "7e68e57c88d091c99c8a5799d269e84e",
"assets/assets/icons/home_onTertiary.svg": "790e0648b9a8ba278dca0ac4cbe4bcf9",
"assets/assets/icons/honoo_logo.svg": "8655ace5da458e5b5bdfb8718a4b09b0",
"assets/assets/icons/arrow_left.svg": "d2b022769c93054c77c83a19db611203",
"assets/assets/icons/logo_honoo.png": "6fc3f394a534ba1c912785a5a796ac11",
"assets/assets/icons/ok.svg": "24efae71b4f7c48802677d71be189005",
"assets/assets/icons/load.svg": "3c33988ef9b2d10c8d46a9e89cbfe338",
"assets/assets/icons/arrow_right.svg": "a9d8d72f80c1a1286340c302599bb81f",
"assets/assets/icons/dado_lightmode.svg": "83533a7cddd83e0f5e8722e2d62bbead",
"assets/assets/icons/broken_heart.svg": "87cb1338bda723bc19d61232e17492ab",
"assets/assets/icons/info.svg": "e158d4ccb73ad8ec56f0c971a985c906",
"assets/assets/icons/honoo_chest_red.svg": "c6a00ef39e359c2fbc598dc0a0ba6aed",
"assets/assets/icons/broken_heart_white.svg": "484c9308870afacabb216894c0c6ee81",
"assets/assets/icons/luna.png": "15b94d3950a0bc4c4d6946ee7f13c764",
"assets/assets/icons/dado.svg": "5a1811123e2a7977c935e5577dc7df55",
"assets/assets/icons/piuma.svg": "8135bf8799f92e9b1d115bcb17067d79",
"assets/assets/icons/performance.png": "ee1d62c63a3359c3b24162a4ac3a6dda",
"assets/assets/icons/share.svg": "eee5b28d1bd8f977a440834a0f70886d",
"assets/assets/icons/cancella.svg": "4f7ea0dba38777653af53448b3bbed64",
"assets/assets/icons/dice.svg": "018e1801c5968cb8c92c1fe0d5e773c6",
"assets/assets/icons/honoo_chest_white.svg": "fc1b9ad295c9bdcb6d9426bbb904bf4d",
"assets/assets/icons/dado.png": "bd34185ee999b54456ba78406edcc1e7",
"assets/assets/icons/honoo_chest_blue.svg": "00da73d7db3a1814acdb0068d62dc517",
"assets/assets/icons/splash.svg": "bae9998753275f1bbc39ec960935773e",
"assets/assets/icons/chest_home.svg": "d3037e301ca5e0d854053753712a4389",
"assets/assets/icons/moon.svg": "4e81047ce6770648b7c571808ec85523",
"assets/assets/icons/heart.svg": "4a438b0c5a1367772474e631a6cb4c25",
"assets/assets/sirenaepalombaro.jpg": "035c4a8fed4875fdea42ef29a6d95959",
"assets/assets/fotoprofilo.jpg": "2a212f3c69a17a442a05f3a68a5f1ac9",
"assets/assets/google_fonts/Lora-Italic.ttf": "0d467aed03479d0751e65ec040836bfd",
"assets/assets/google_fonts/Lora-Italic-VariableFont_wght.ttf": "0d467aed03479d0751e65ec040836bfd",
"assets/assets/google_fonts/Arvo-Regular.ttf": "afb50701726581f5f817faab8f7cf1b7",
"assets/assets/google_fonts/Arvo-Bold.ttf": "ab1dabbd8ffd289a5c35cb151879e987",
"assets/assets/google_fonts/Arvo-BoldItalic.ttf": "a53d4514f91e2a95842412c4d3954dd0",
"assets/assets/google_fonts/Lora-Bold.ttf": "e71368f221227338edf6af09034a5062",
"assets/assets/google_fonts/OFL-Lora.txt": "804cefa2a9ec3f1ff5a9af3882c18fab",
"assets/assets/google_fonts/LibreFranklin-Regular.ttf": "45607ae9472e0b80708bf53919bfed87",
"assets/assets/google_fonts/LibreFranklin-Bold.ttf": "45607ae9472e0b80708bf53919bfed87",
"assets/assets/google_fonts/LibreFranklin-Italic-VariableFont_wght.ttf": "72c9d0e8faa0b0532363d3f25fead170",
"assets/assets/google_fonts/LibreFranklin-SemiBold.ttf": "45607ae9472e0b80708bf53919bfed87",
"assets/assets/google_fonts/LibreFranklin-Italic.ttf": "72c9d0e8faa0b0532363d3f25fead170",
"assets/assets/google_fonts/Lora-VariableFont_wght.ttf": "e71368f221227338edf6af09034a5062",
"assets/assets/google_fonts/LibreFranklin-VariableFont_wght.ttf": "45607ae9472e0b80708bf53919bfed87",
"assets/assets/google_fonts/OFL-LibreFranklin.txt": "5af2455830b482248ef3fffaed4e4eda",
"assets/assets/google_fonts/LibreFranklin-Medium.ttf": "45607ae9472e0b80708bf53919bfed87",
"assets/assets/google_fonts/Arvo-Italic.ttf": "4d7f205bc8a4a7e98c219a1427999533",
"assets/assets/google_fonts/Lora-BoldItalic.ttf": "0d467aed03479d0751e65ec040836bfd",
"assets/assets/google_fonts/Lora-Regular.ttf": "e71368f221227338edf6af09034a5062",
"canvaskit/skwasm.js": "3dbd05be6db4a4154ce733ff194dcae7",
"canvaskit/skwasm.wasm": "f767200511478d7f7052f2b536d82875",
"canvaskit/chromium/canvaskit.js": "c5ff0f8767a7ea0962b15d1f1832002d",
"canvaskit/chromium/canvaskit.wasm": "c6b1144d5baffbdd9482ee820dbd7dc9",
"canvaskit/canvaskit.js": "3e7c7e90ff8e206f4023c12e31b0d058",
"canvaskit/canvaskit.wasm": "296ba26fdb37b50c239d4ead66144d01",
"canvaskit/skwasm.worker.js": "23be0fdafa5ddef67734292a576f8fe3"};
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
