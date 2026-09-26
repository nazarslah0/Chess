# Stockfish engine

This app uses the Flutter `stockfish` package (`1.8.1`), which bundles the native Stockfish 18 engine and communicates with it through Dart FFI. The engine runs locally on the device; the app does not download an engine at runtime.

The official Stockfish project has since released Stockfish 19. This project intentionally uses Stockfish 18 because that is the newest stable Stockfish version currently provided by the Flutter FFI package used here. Upgrading to Stockfish 19 requires updating/rebuilding the native Flutter plugin against the Stockfish 19 source; it should not be claimed as Stockfish 19 merely by changing a version string.

License: Stockfish is GPL-3.0. Keep the corresponding license/attribution when redistributing the app.


## Current build note

This project uses `stockfish: ^1.8.1`. According to the package changelog, version 1.8.0 moved the bundled engine to Stockfish 18 and 1.8.1 fixed that release. The package communicates with the native engine through Dart FFI, so the Android application does not need to download a Stockfish executable at runtime.

Stockfish 19 is now the latest official Stockfish release, but this Flutter package does not yet expose Stockfish 19. Moving to Stockfish 19 requires a dedicated native integration rather than changing a Dart version number.
