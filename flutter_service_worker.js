'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "0557de9ccef249e4e2508a21c1e2ed63",
"version.json": "0800521d39734a9f01ff3e565f8869af",
"index.html": "5273f49f411b1fd317c7cf96136c4c73",
"/": "5273f49f411b1fd317c7cf96136c4c73",
"main.dart.js": "5c9f3280ad277331432e9778d55ccf18",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "ba00504ca96ba2e7fc00fa11f33cecef",
".git/config": "38881ccff4dc4e249623736f3cd97a15",
".git/objects/59/f3485b2f7d01944fe99e8f3e829a4c8f1b170c": "27ca1802420c62373ace4701ebed2c7a",
".git/objects/66/5bfaa6f23aaf2c0094267f622620bcac31f3d6": "19cb27c4fcdf3ddf16dab99083afa687",
".git/objects/57/61903e5e802635ddadc6f597c41a9dc31c8e05": "f30a12d486c7e29cd70554cd5426babf",
".git/objects/9b/d3accc7e6a1485f4b1ddfbeeaae04e67e121d8": "784f8e1966649133f308f05f2d98214f",
".git/objects/04/09e6a2a2a8a1aaf07f5354ca4fcbc5924c3307": "603e6cfb3b438dfbf5c6ba4ccb9aaf23",
".git/objects/32/b0eaa24edd887376545d1825c919fa29021512": "dd0e4727446fb407b062d19c682ca260",
".git/objects/93/94649ff23d59bf17ca1ea8e4040f7d6899447d": "032bc368c220789049ed182fc28d9978",
".git/objects/5f/7e9d10bd7636d0c9426013d8fb8efbf4314ca4": "f9f1c4720436c8c7341d093b9afaa883",
".git/objects/05/4040d90cdcd19ae3c63445c2050fb05332d914": "9dba5992e2c8d348a15f072bf0d0b9aa",
".git/objects/a4/53df4d9c1de371880ee709c0ffd617389778af": "25b9329ef4344b1046c4536cd4dbe146",
".git/objects/a3/f7753114972b17391223cb9a872e9f6ef6490b": "576cd577162b593df77c3c053e21479f",
".git/objects/d7/7cfefdbe249b8bf90ce8244ed8fc1732fe8f73": "9c0876641083076714600718b0dab097",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/e5/2660f016ebd3bc3f816b6b8984df03c5b7f068": "d86596260380677b11aae641853e2505",
".git/objects/f3/45ff358da2681d16f980e63ccf5e46fe9588c8": "d5992a53ce137c3f436e45bbb7253174",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/c0/c161927b3261989b9f2ab5d74b605dc19f2df2": "2c800c3f0c72adc30de2646b022a3455",
".git/objects/c0/785ad25bfe798c66bd6aab810ad9b7d7168d50": "82da8862c7924f8b408135d266a99e26",
".git/objects/ee/0e319c5539dbb17d9167d3b7194b5e1a963b42": "b8904b0dc33f998f23b01fa587059178",
".git/objects/c9/6a6a87532d31a468b01ba3ba9be3c7f5b36af3": "c4c5dd0f00a0b8f7e6eb216ace2c9c3f",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/f2/1b174f1ed6a2df58e4943194207c07290ee404": "cd8bc9cb883a1c72795b849b10e71003",
".git/objects/f5/9d5a689bd26dd85f65e3628383d157a85b5030": "28ee7a683e635137b359f2ad835ab131",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/objects/ca/b58dbd44763e50821eff7f7d115347c57e17ea": "592297f0b3b6b84b14665c378165dd50",
".git/objects/ca/73ea9b836ae2322c616630bcbb63997f9af1cb": "89f8b99443c8cbb536d49ae590522999",
".git/objects/c8/08fb85f7e1f0bf2055866aed144791a1409207": "92cdd8b3553e66b1f3185e40eb77684e",
".git/objects/fb/f2522d6f7987c7009ff9a8f23a4423f56536e6": "5de02e14c9eb82d87973d34acb5cfff6",
".git/objects/16/4fe10c8d5b454c7ea315b446ab07c1552273db": "1a64ea6f2fff74d1488485e0b33539ce",
".git/objects/89/d14461e8101134f70294ec9276835af2b1f07a": "ae7a6d1d94a7944e5f9f8d90f587a7bf",
".git/objects/73/c63bcf89a317ff882ba74ecb132b01c374a66f": "6ae390f0843274091d1e2838d9399c51",
".git/objects/1a/d7683b343914430a62157ebf451b9b2aa95cac": "94fdc36a022769ae6a8c6c98e87b3452",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/2f/dde0cbb24b8b247aa51faab3e82944a1229b53": "cc08b93785bc25feda2f1f8ea3f8fced",
".git/objects/43/4a2ae9f610fc03b619b9b53d391f5d028c989d": "1a1c3e6b7d7df4f26a0f6673b4399108",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/6b/5a2ec4b26f54223b67e224ee04a104c3464ee1": "4db2d526025ea9f1f5776437a8f62779",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/objects/07/46e210048eb52f7d9ac61b9d92a26e668eebd7": "619f59cc3f9c1e440ccdec204b3b58bb",
".git/objects/09/4f10588e7fae69aca143e3c88e7d35c7060b4c": "11a4321c2db9e6213646612738225d32",
".git/objects/98/a56bcd092c5bbb90c194c6542c8efff1830246": "df557f48cc26d823f95d3f0ef711ee23",
".git/objects/53/18a6956a86af56edbf5d2c8fdd654bcc943e88": "a686c83ba0910f09872b90fd86a98a8f",
".git/objects/53/3d2508cc1abb665366c7c8368963561d8c24e0": "4592c949830452e9c2bb87f305940304",
".git/objects/08/485f49aaf61a9efa9cd473a2f8b56c2a410697": "fd5a200bca4c3a9d6af2dc27ba379e3f",
".git/objects/55/85e6adcadce4a2d5906d55c0e2bbe3fb476341": "065ab21b765bb6b168c3e1550e0ba3f6",
".git/objects/0f/96c51b593905559ab4db6fc3756284f1789582": "e021dd13d8029fa111ed2368826bfced",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/ba/3a713fd01c87939c0d4f9bbda1f1449c348621": "d9257d1dae9aae715084e3e78663bbee",
".git/objects/dc/11fdb45a686de35a7f8c24f3ac5f134761b8a9": "761c08dfe3c67fe7f31a98f6e2be3c9c",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/a8/e3a8208e9fb0c05f74815a4ac10c66996f4a91": "d0c129fcb494350babbc74e363c784e3",
".git/objects/de/d9c908827c768d39f442293d664beecebeae48": "c3ef72df0560b64850f7f8485bf65d7d",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/b9/6a5236065a6c0fb7193cb2bb2f538b2d7b4788": "4227e5e94459652d40710ef438055fe5",
".git/objects/f0/6c76bbfa50aea9bec6b735574cdc6874d1f3d9": "2137ac13ee6ba6165cbbe878918b10c0",
".git/objects/fa/b31fffdcda6c0915c1d3acea661d2155d4c129": "8181cd1cb10026fd91f4a146d8624373",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/objects/e0/7ac7b837115a3d31ed52874a73bd277791e6bf": "74ebcb23eb10724ed101c9ff99cfa39f",
".git/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "2e52a767dc04391de7b4d0beb32e7fc4",
".git/objects/2c/115f73108e598039fa282239803fa6ab2014d1": "0e773d27620a51b6b6fb411138e59f1f",
".git/objects/70/a234a3df0f8c93b4c4742536b997bf04980585": "d95736cd43d2676a49e58b0ee61c1fb9",
".git/objects/70/5d2fb0e3d3413bd8ecd7bbef987f29c2a99f33": "dc3dc45b741d808fff8ba219f13b1ada",
".git/objects/70/a3b3cfcb1bbcce1fa85a38a9332b6e6e371706": "43de2665fcf2b07e67725a1224a61a86",
".git/objects/24/b16d90c09eafccb4edd21dd3cbceff3047a397": "290f314a3232238a736898aa25a209ac",
".git/objects/24/b5ee231d39ad3a11dc1de37781b246624dd34c": "dbd8ddf32641552407d96963f13c5149",
".git/objects/15/442ca5fed7d96cc7719f9522f269e4b04a64f7": "e82d730cc5873aea2d1756e6d37f59fd",
".git/objects/1c/8913c4c8000f05776577e85ac5de0494a8ed86": "f9ab2b6ad8708fb6a911131483a9a666",
".git/objects/49/d6defbc2af0eed6050c036f76d1b2dac9bbff0": "f1a91e222bce456656531afba62c891e",
".git/objects/49/d22bc8a8f2f2748078fcc0f4ef93b5d6ecf41c": "e80abfb278e3338ebf8ed07924505135",
".git/objects/2e/8c5bc335339e3618345ed93c7e4cdfb5cc829e": "cce5186f212e4b32dc2811c42feab58f",
".git/HEAD": "cf7dd3ce51958c5f13fece957cc417fb",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "afb92d6458d6cb93f1af809a50a9a9c6",
".git/logs/refs/heads/main": "afb92d6458d6cb93f1af809a50a9a9c6",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-commit.sample": "305eadbbcd6f6d2567e033ad12aabbc4",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/refs/heads/main": "73f17cf234a4f4cb4490ddea62f1b7a3",
".git/index": "1720bf2d8971a0f9586dd18ab7cee46f",
".git/COMMIT_EDITMSG": "d419aacfbffd8204b811f99f79ce36ad",
"assets/AssetManifest.json": "f079736cb11700c7bea14d0175993204",
"assets/NOTICES": "1df15fa8950698b2a4ad212990ac2dc7",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "9c13745bd9e9fca049a77c0b04a20bd1",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "d27ebbddef7206dd209cd7037d47c220",
"assets/fonts/MaterialIcons-Regular.otf": "3e44d97b9a9feb2b7379baa6092d15a6",
"assets/assets/login_illustration.png": "4a518b1ef72bcc0e3957f3c819f5d72c",
"assets/assets/hsh_logo.png": "bbbc6ac20ce8b6d89f6fd6688a5d92b1",
"assets/assets/blacklist.json": "56eb541c62971f2ef63f8078d29857b0",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
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
