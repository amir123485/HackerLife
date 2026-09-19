# HackerLife

**An original 3D hacker-life simulation — first playable vertical slice (v0.1.0).**

You are **Ari**, a 16-year-old who just got an old computer running in a small
apartment bedroom. A mysterious mentor named *Ghost* invites you into the
**OpenShell Academy CyberLab** — a safe, simulated training network where you
learn real cybersecurity *concepts* without ever touching a real system.

> 🔒 **Security / sandbox statement:** every network, host, service, file and
> credential in HackerLife is **fictional and simulated entirely inside the
> game**. The game never scans real IPs, never contacts real systems, never
> collects real credentials and contains no real-world attack code.

---

## Features (this prototype)

- **3D apartment** — a procedurally built night-time bedroom with a city
  skyline outside the window, neon accents and cinematic lighting
  (Godot 4.7, Compatibility renderer — runs on modest hardware).
- **Third-person character** — walk, run, interact; day/night life goes on.
- **NyxOS in-game computer** — a fictional desktop OS with:
  - **Terminal** — 14 working commands (`help`, `whoami`, `network`,
    `scan`, `connect`, `ls`, `read`, `submit`, …) with login flow, history,
    and colored output.
  - **Files** — beginner notes, mission briefing, journal, lab guide.
  - **NyxNet browser** — fictional sites (OpenShell Academy, NexaCorp,
    BugHunt teaser) and a simulated search.
  - **Messages** — story mail from Ghost (and Mom).
  - **CyberLab** — interactive lessons with quizzes (IPs, ports, logs) that
    award XP, plus lab machine status.
  - **About** — version info and the security statement.
- **First mission: FIRST CONNECTION** — a 10-objective guided exercise:
  find the computer → read notes → learn commands → inspect the network →
  scan → connect → inspect files → find the token → complete the lab →
  earn rewards. Roughly **10–20 minutes** of first-session play.
- **Simulated lab network** — `TRAINING-NET 10.10.0.0/24` with three
  fictional machines (`TEST-PC-01` open; `TEST-WEB-01` / `TEST-SRV-01`
  locked for future updates), services, banners and logs.
- **Life simulation** — game clock (1 real second ≈ 1 game minute),
  energy, hunger, school schedule (Mon–Fri, sleep to skip), snacks from the
  fridge, school attendance, money.
- **Skills & XP** — Linux / Networking / Web / Forensics with levels;
  actions and lessons grant XP.
- **Inventory** — snacks, energy drinks, USB drive; use consumables (Tab).
- **Consequence architecture** — evidence/risk values exist from day one
  (the lab shows "Evidence: 0% (training environment)"); future builds grow
  this into the full police/court system.
- **Save / load** — versioned JSON saves (`user://saves/save_1.json`),
  auto-save on mission completion, manual save from the pause menu.
- **Menus & settings** — main menu, pause menu, settings (display, VSync,
  shadows, glow, anti-aliasing, mouse sensitivity, volumes), credits.
- **Original audio** — procedurally generated music loop, ambience, UI and
  interaction sounds. No third-party or copyrighted assets anywhere.

## Controls

| Action | Key |
|---|---|
| Move | `W A S D` / arrows |
| Sprint | `Shift` |
| Interact | `E` |
| Stats & inventory panel | `Tab` |
| Pause / close computer | `Esc` |
| Mouse | orbit camera |

On the computer: click icons, type in the terminal, `Esc` leaves the computer.

## Installation

### Windows
1. Extract `HackerLife_Windows.zip`.
2. Run `HackerLife.exe` (the `.pck`/assets are embedded).
3. If Windows SmartScreen warns about an unknown publisher, choose
   *More info → Run anyway*. The game is fully offline.

### Linux
1. Extract the archive, `chmod +x HackerLife.x86_64`.
2. Run `./HackerLife.x86_64`.

### Android
1. Download `HackerLife.apk` (arm64-v8a) from the
   [v0.1.0 release](https://github.com/amir123485/HackerLife/releases) or the
   *Actions → Build Android APK* artifact.
2. On the device, allow *Install unknown apps* for your file manager, then
   install the APK (it is signed with a debug keystore — normal
   side-load warning applies).
3. Controls: joystick (bottom-left) to move, drag the right side of the
   screen to orbit the camera, **E** to interact, **RUN** toggles sprint,
   **||** pauses. Tapping works everywhere in menus and the in-game
   computer; tapping a text field opens the on-screen keyboard.

### Building from source
1. Install [Godot 4.7.x](https://godotengine.org/download) (standard build).
2. Open the project folder (`project.godot`) in Godot.
3. `Project → Export` requires the matching **4.7.2 export templates**.
4. CLI export: `godot --headless --export-release "Windows" builds/windows/HackerLife.exe`
5. Android APK builds run automatically on GitHub Actions
   (`.github/workflows/android.yml`) on every push to `main`.

## How to play (first 10 minutes)

1. **New Game** → you wake up in the room. Walk to the **desk**, press `E`.
2. In **Messages**, read Ghost's mail — the mission starts.
3. Open **Files** → read `notes.txt` (it contains the lab login).
4. Open the **Terminal** and follow the briefing:
   `help` → `whoami` → `network` → `scan TEST-PC-01` →
   `connect TEST-PC-01` → (login `student` / `learn3r`) →
   `ls` → `read flag.txt` → `submit HL{...}`.
5. Mission complete: **+50 credits, +XP, skill-ups** — and the tracker
   clears for the next update.
6. Life goes on: sleep in the bed, attend school through the door,
   grab snacks from the fridge, read a book, check the CyberLab lessons.

## System requirements

- **OS:** Windows 10/11 x64 or Linux x64
- **GPU:** any OpenGL 3.3-capable GPU (integrated graphics is fine)
- **RAM:** 2 GB
- **Disk:** ~200 MB
- **Display:** 1280×720 or larger

## Development setup

```
git clone <repo-url>
cd HackerLife
godot --editor .        # open project in Godot 4.7
```

Run automated tests (headless):

```
godot --headless --path . res://tests/test_main.tscn
```

56 automated tests cover: game state, economy, inventory, skills, time
progression, the simulated network, the full terminal/mission flow and
save/load roundtrips.

## Project structure

```
HackerLife/
├── project.godot            # Godot 4.7 project (GL Compatibility)
├── export_presets.cfg       # Windows + Linux presets
├── assets/
│   ├── audio/               # 10 original procedural WAVs
│   └── icon/                # original generated icon set
├── scenes/
│   └── main.tscn            # single bootstrap scene
├── scripts/
│   ├── core/                # autoloads: events, game state, time, sim net,
│   │                        # missions, save system, audio, settings
│   ├── player/              # 3rd-person controller + interactions
│   ├── world/               # procedural apartment builder
│   ├── computer/            # NyxOS desktop + 6 apps (terminal, files, …)
│   ├── ui/                  # HUD, menus, settings, credits
│   ├── capture/             # scripted gameplay capture director
│   └── main.gd              # game flow orchestrator
├── tests/                   # 56 automated headless tests
├── docs/                    # security statement, screenshots
├── builds/                  # export output (gitignored)
├── README.md
├── LICENSE
└── CHANGELOG.md
```

## Architecture notes (future scaling)

- All gameplay state lives in small autoload singletons (`Game`, `TimeSys`,
  `Sim`, `Missions`) communicating through an event bus (`Events`) — ready
  for open-world content, more missions and legal/criminal career paths.
- The world is generated by code from primitives; swapping in imported
  3D assets later does not require touching gameplay code.
- The simulated network (`Sim`) is pure data + logic, so future missions,
  BugHunt programs and multiplayer shared labs can reuse it directly.
- Saves are versioned JSON; a migration hook is already in `save_system.gd`.

## Troubleshooting

- **Black window / GPU errors** — the game uses the GL Compatibility
  renderer; update your GPU drivers, or run with
  `HackerLife.exe --rendering-method gl_compatibility`.
- **No sound** — check the master/music volume in Settings; the game is
  fully offline and never touches the network.
- **Save file location**
  - Windows: `%APPDATA%\Godot\app_userdata\HackerLife\saves\`
  - Linux: `~/.local/share/godot/app_userdata/HackerLife/saves/`
- **Reset progress** — delete `save_1.json` in the folder above.

## Known limitations (v0.1.0, honest list)

- One mission, one room; the open city, vehicles, jobs, BugHunt programs,
  police/court/prison systems and aging are **not** in this slice — the
  architecture for them is in place.
- `TEST-WEB-01` and `TEST-SRV-01` are intentionally locked.
- The Windows executable is unsigned (SmartScreen may warn).
- The Android APK is signed with a **debug keystore** (fine for personal
  install/tests; Play Store publishing would need a proper release key).
- Android targets arm64-v8a devices (any phone from ~2016 onward).
- Software-rendered capture (this trailer) can look softer than live play.

## Licensing

- **Code, art, audio, story:** released under the MIT License (see `LICENSE`).
- **Engine:** Godot Engine 4.7.2, MIT License — © Godot Engine contributors.
- **Third-party assets:** none. Everything is original & procedurally
  generated for this project.

## Credits

- Design, code, 3D environments, UI, audio: built with the **Super Z AI
  assistant (Z.ai)** for the HackerLife project.
- Inspired by the general *mood* of open-world hacking games; contains no
  assets, story, code or branding from any existing game.

*Learn, don't harm.*
