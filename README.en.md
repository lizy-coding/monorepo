# ble_chat_flutter

Flutter multi-package workspace managed by Melos: the `app/` directory hosts the primary application, while `packages/` gathers reusable core modules. Starting with Melos 3, install workspace dependencies from the repo root via `dart pub get`, then run the common flows with `dart run melos bootstrap`, `dart run melos run gen`, and `dart run melos run test` (see `README_MELOS.md` for details).

## Repository Structure

```
app/                             # Flutter app (run flutter commands from here)
├── analysis_options.yaml
├── android/
├── lib/
│   ├── main.dart                # Entry point
│   └── src/
│       ├── app/                 # Shell + router (app.dart, router.dart)
│       ├── core/                # Shared services (ble/domain/storage/foreground/notifications)
│       └── features/            # Feature screens (chat/devices)
├── test/                        # Unit & widget tests mirroring lib/src
└── windows/                     # Windows host shell
packages/
├── core_ble/                    # BLE orchestration
├── core_domain/                 # DTOs + serializers
├── core_foreground/             # Foreground service glue
├── core_notifications/          # Notification helpers
└── core_storage/                # Local storage / Isar
tool/                            # Cross-platform helper scripts
melos.yaml                       # Workspace definition
README_MELOS.md                  # Melos usage guide
```

## Generate `.g.dart` Inside `app/`

1. **Enter the app package and fetch dependencies**  
   ```bash
   cd app
   flutter pub get
   ```  
   Ensure `build_runner`, `json_serializable`, and friends are resolved.

2. **One-off build**  
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```  
   - `build_runner` scans `lib/src/core/domain` and any file declaring `part 'xxx.g.dart';`.  
   - `--delete-conflicting-outputs` cleans stale artifacts to prevent write conflicts.  
   - Success prints `Succeeded after ... with ... outputs`; failures point to the exact Dart line.

3. **Watch mode (optional)**  
   ```bash
   dart run build_runner watch --delete-conflicting-outputs
   ```  
   Ideal during development—DTO edits retrigger generation; exit with `Ctrl+C`.

> To regenerate across the entire workspace, run `melos run gen` or `./tool/gen_all.sh`; both run builds for `app/` and every `packages/*` entry.

