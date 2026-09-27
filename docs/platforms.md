# Platforms — Web, itch.io (butler), Android for Godot 4.7

A checked reference for `game-bootstrap` (platform decision), `game-release` (builds), `game-ui-accessibility`
(touch) and `game-save` (web saves). Desktop export is covered in `game-release`.

**Sources:**
- Godot docs **4.7 branch** (the gry-wiedza copy `BAZA-AI/fala-05/zrodla/godotengine--godot-docs-4.7`). File paths
  below are relative to that copy.
- itch.io's official docs, read 2026-09-27.
- The `BAZA-AI/zrodla/godotengine--godot-docs` copy is **master (4.8-dev)**. Its Android pages already differ from
  4.7 (SDK versions, automatic SDK setup, R8 minification), so don't cite it for 4.7.

**Rules that don't change per platform:**
- Publishing and logging in (itch.io, Play Console, butler, keystores) are the human's acts.
- Never type, store or log a password, API key or keystore password.
- Prepare commands; the human runs the ones that publish.

## Web (HTML5)

### Decide early (it constrains the whole game)
- **Renderer:** web runs only the **Compatibility** renderer (WebGL 2). Forward+/Mobile projects must switch, so
  decide at bootstrap. Source: `tutorials/export/exporting_for_web.rst` "WebGL version".
- **No C#** on web in Godot 4, so our GDScript default is fine. Source: `exporting_for_web.rst` intro.
- **Networking:** no ENet or low-level sockets. Only `HTTPRequest`/`HTTPClient`, WebSocket (as a client) and WebRTC
  work. Multiplayer means `WebSocketMultiplayerPeer` or `WebRTCMultiplayerPeer` (recipes 39, 46: same RPC and
  sync code). Source: `exporting_for_web.rst` "Networking".
- **Threads:** since 4.3 the default and recommended export is **single-threaded** (`variant/thread_support` =
  false). It needs only HTTPS and works on itch.io, Poki and CrazyGames. With threads on, the server must send
  `Cross-Origin-Opener-Policy: same-origin` + `Cross-Origin-Embedder-Policy: require-corp`, or **the game does not
  start at all**. A PWA export (`progressive_web_app/enabled` with `ensure_cross_origin_isolation_headers`) can fake
  those headers with a service worker. Source: `exporting_for_web.rst` "Thread and extension support", "Serving
  the files"; `classes/class_editorexportplatformweb.rst` `variant/thread_support`.
- **GDExtension** needs `variant/extensions_support`, a web build of the extension, and the same headers.

### Behaviour differences to design for
- **Audio:** since 4.3 web plays in **Sample** mode by default. That means no AudioEffects (bus reverb, filters),
  no doppler and no procedural `AudioStreamGenerator`. To get them, set *Audio → General → Default Playback
  Type.web* = Stream or `playback_type` = Stream per player, at the cost of latency. Browsers block autoplay, so
  start audio after the first click or key (a title screen does this naturally). Source: `exporting_for_web.rst`
  "Audio", "Audio autoplay". The measurement in `gb shot --movie` is the desktop engine, so a human checks web
  sound.
- **Saves:** `user://` lives in the browser's **IndexedDB**. It is lost in private windows or when site data is
  blocked or cleared. Inside an iframe (itch.io embeds) third-party storage must be allowed. `OS.is_userfs_persistent()`
  checks this but can give false positives. Tell the player, and offer export/import of a save for anything
  valuable (`game-save`). Source: `exporting_for_web.rst` "Using cookies for data persistence";
  `tutorials/io/data_paths.rst`.
- **Fullscreen and mouse capture** only work when requested from inside an input event (`_input`,
  `_unhandled_input`, a button press), never from `_ready()` or a timer. An FPS on web needs "click to play" before
  `MOUSE_MODE_CAPTURED`. Source: `exporting_for_web.rst` "Full screen and mouse capture".
- **Background tab:** `_process`/`_physics_process` stop while the tab is hidden, so pause gracefully and expect
  network disconnects. Source: `exporting_for_web.rst` "Background processing".
- **Gamepads** appear only after a button press, and mappings can be wrong per browser. Keep keyboard input
  complete. Source: `exporting_for_web.rst` "Gamepads".
- **Detecting a phone:** `OS.has_feature("mobile")` is **false** in a web build even on a phone. Use
  `OS.has_feature("web_android") or OS.has_feature("web_ios")`. Source: `tutorials/export/feature_tags.rst`.

### Build, serve, size
- `gb export --preset "Web"` (the scaffold's preset is single-threaded). The main file is `index.html`. Don't
  rename the other exported files; they reference each other.
- Serve `.wasm` as `application/wasm` (a wrong MIME type costs startup optimisation). Source:
  `exporting_for_web.rst` "Serving the files".
- **Compression:** gzip shrinks `.wasm` to about ¼. **itch.io does no on-the-fly compression** (GitHub Pages does),
  so keep the `.pck` small: import settings, no unused assets. `gb lint` flags big textures.
- **Local test (human):**
  - the editor's one-click **Run in Browser** (localhost only, needs the Web export template); or
  - Godot's `platform/web/serve.py` script in the export folder.

  After testing several projects, a stale service worker can serve the old game: DevTools → Application →
  Unregister. Source: `tutorials/export/one-click_deploy.rst`, `exporting_for_web.rst` "Troubleshooting".
- **Useful preset options:**
  - `html/canvas_resize_policy` (Adaptive fills the page, Project keeps the project size);
  - `html/focus_canvas_on_start` (keyboard works without a click);
  - `html/custom_html_shell` (the only safe way to change the page — edits to the generated HTML are overwritten);
  - `vram_texture_compression/for_desktop` / `for_mobile` (both is more compatible but bigger).

## itch.io + butler

### The page (human, in the itch.io dashboard)
- Upload a **ZIP with `index.html` at the root** (not .rar/.7z/.tar.gz). Limits:
  - ≤1000 files;
  - ≤500 MB extracted;
  - ≤200 MB per file;
  - paths ≤240 characters;
  - names are case-sensitive.

  Source: https://itch.io/docs/creators/html5
- Kind of project = **HTML**, and mark the upload as "played in the browser".
- **Embed options:**
  - viewport size = the game's window size (e.g. 1280×720 for a 640×360 ×2 game);
  - Fullscreen button on;
  - *Mobile friendly* only if touch works.
- **SharedArrayBuffer support** (Embed options → Frame options) is needed **only for a threaded export**. Our
  default single-threaded build doesn't need it. Turning it on has side effects: other embeds on the page (videos,
  widgets) break. Safari still needs a separate window, while Firefox now plays embedded, per itch.io's update in
  that thread. Source: https://itch.io/t/2025776/experimental-sharedarraybuffer-support
- Browser games can only take donations. Selling means a downloadable build. Source: itch.io HTML5 docs.

### butler (commands the agent may prepare; the human runs the push)
- Install: download from https://itchio.itch.io/butler, unzip, put it on PATH, check with `butler version`.
  Source: https://itch.io/docs/butler/installing.html
- **`butler login` is the human's** (browser authorisation; credentials are stored in the user's profile). In CI,
  use the `BUTLER_API_KEY` secret. The agent never sees it, and a key that appears in a public log is burned.
  Source: https://itch.io/docs/butler/login.html
- Push:
  - `butler push build/web <user>/<game>:html5 --userversion <version>`
  - `butler push build/windows <user>/<game>:windows --userversion <version>`

  Useful flags and checks:
  - `--dry-run` lists what would be sent;
  - `butler push-preview` compares against the channel's last build;
  - channel names with `win`/`linux`/`mac`/`android` tag the platform, and the HTML channel is chosen on the page.

  Source: https://itch.io/docs/butler/pushing.html
- butler uploads only differences (a patch), so updates are small.
- **UNCONFIRMED:** the exact syntax of `butler status`. Check `butler --help` before scripting it.

## Android

### Setup (human, once per machine) — Godot 4.7
1. **OpenJDK 17**. Higher versions work, but 17 is recommended. In 4.7 there's no automatic SDK setup (that
   arrives in 4.8).
2. **Android SDK** (Android Studio or `sdkmanager`). In the 4.7 docs:
   - Platform-Tools ≥ 35.0.0;
   - Build-Tools 35.0.1;
   - Platform 35;
   - cmdline-tools latest;
   - CMake 3.10.2.4988404;
   - NDK r28b (28.1.13356709).
3. *Editor Settings → Export → Android*: **Java SDK Path**, **Android SDK Path** (the folder that has
   `platform-tools/adb`).
4. **Export templates** for 4.7 (*Editor → Manage Export Templates*), as for Web.

Source: `tutorials/export/exporting_for_android.rst` "Setup on Windows, macOS, and Linux".

### Preset essentials (`classes/class_editorexportplatformandroid.rst`)
- `package/unique_name`: reverse-DNS, lowercase, every part starts with a letter (`com.example.8game` is invalid).
  Changing it later makes a new app with new save data. It must be unique on Google Play.
- `version/code` (an integer, +1 for every store upload) and `version/name` (falls back to
  `application/config/version`).
- Architectures: `architectures/arm64-v8a` (phones), `architectures/armeabi-v7a` (old 32-bit), x86/x86_64
  (emulators).
- Permissions are one bool each, e.g. `permissions/internet` for online play. Ask only for what the game uses.
- Icons: `launcher_icons/main_192x192`, `adaptive_foreground_432x432`, `adaptive_background_432x432` (keep the
  critical content inside the central 66 dp circle).
- Screen: `screen/immersive_mode`; with `screen/edge_to_edge`, keep the UI inside
  `DisplayServer.get_display_safe_area()`.
- **Orientation:** the project setting `display/window/handheld/orientation`. It does **not** swap the viewport
  size; set portrait width/height yourself.

### Signing, APK vs AAB
- The **debug** keystore fields fall back to editor-wide settings, so one-click deploy works without a release
  keystore. Whether Godot creates the debug keystore automatically on first export is **UNCONFIRMED** from the
  docs. The human sees it in *Editor Settings → Export → Android*.
- **Release:** the human creates the keystore
  (`keytool -v -genkey -keystore mygame.keystore -alias mygame -keyalg RSA -validity 10000`) and types the passwords
  themselves. The keystore password and the key password currently **must be the same**. The docs also *suggest*
  letters and digits only, because special characters may cause errors. Then:
  - uncheck *Export With Debug*;
  - pass the path, alias and password through the environment variables `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`,
    `…_RELEASE_USER` and `…_RELEASE_PASSWORD`.

  **The human (or a CI secret store) sets these variables.** The agent only names them in the prepared export
  command, never types or echoes their values. **Never write them into `export_presets.cfg` or any committed
  file.** Source: `exporting_for_android.rst` "Exporting for Google Play Store", "Environment variables".
- **Google Play needs AAB** (for new uploads since August 2021). AAB needs a **Gradle build**:
  1. *Project → Install Android Build Template* (creates `res://android/build`);
  2. set `gradle_build/use_gradle_build` = true;
  3. set `gradle_build/export_format` = AAB.

  An APK without Gradle is fine for itch.io or sideloading. Gradle pitfall: files inside a **folder** whose name
  starts with `_` are left out of the package. Source: `tutorials/export/android_gradle_build.rst`.
- For store builds keep `gradle_build/compress_native_libraries` = false (it slows start-up).

### Test on a device (human)
- Developer options → USB debugging (or Wireless debugging with `adb pair`). `adb devices` must list the phone as
  authorised; if adb can't see it, Godot can't either.
- Mark one Android preset **Runnable**, then use the editor's one-click deploy (a debug build, with remote debug).
  "Could not install to device" usually means the same package signed with another key is installed, so uninstall
  it first. Source: `tutorials/export/one-click_deploy.rst`.
- **Renderer:** Mobile is the default for phones. Compatibility reaches older and low-end devices, and the same
  project can then also go to the web.
- **Touch:** `input_devices/pointing/emulate_mouse_from_touch` (default on) makes simple tap-as-click UIs work.
  Real touch controls (virtual stick, swipe) are a spec item with their own scenario (`game-ui-accessibility`).

## Feature tags for platform branches (`tutorials/export/feature_tags.rst`)
- `OS.has_feature(...)`:
  - platform: `web`, `android`, `windows`, `linux`, `macos`, `ios`;
  - form: `pc`, `mobile`;
  - build: `debug`/`release`, `editor`/`template`;
  - threading: `threads`/`nothreads`.
- A web build on a phone is `web_android` / `web_ios` (see above).
- Custom tags per export preset apply only to exported builds, never in the editor.
- Settings overridden per tag (`key.debug`, `key.web`) are read with `ProjectSettings.get_setting_with_override()`.
  A plain `get_setting()` ignores the override.

## What a machine can and can't prove here
| Check | Who |
|---|---|
| The web build exports; the scaffold preset is single-threaded | `gb export --preset "Web"` (needs templates) |
| The web build runs, has sound after a click, saves survive a reload | **human** in a browser (local serve or an itch draft page) |
| The desktop build runs | `gb export --smoke` |
| The Android build installs and plays; touch, orientation, performance on a real phone | **human** with a device |
| The store page, pushes, signing | **human** |
