# Changelog

All notable changes to HackerLife are documented here.
Format based on Keep a Changelog; versioning: SemVer-ish (prototype).

## [0.1.0] - 2026-09-19 — first playable vertical slice

### Added
- 3D apartment scene (procedural): room, furniture, desk setup, night city
  skyline, neon accents, cinematic lighting, day/night ambience.
- Third-person player controller with sprint, interaction prompts, footsteps.
- NyxOS 2.1 in-game computer: desktop, taskbar, clock, six apps
  (Terminal, Files, NyxNet browser, Messages, CyberLab, About).
- Terminal with 14 commands, multi-step authentication flow, command
  history, colored output, local + remote file reading.
- Simulated training network (TRAINING-NET 10.10.0.0/24) with three
  fictional hosts, services, banners, files and auth logs.
- Mission "FIRST CONNECTION" with 10 tracked objectives and rewards
  (50 credits, 60 XP), auto-save on completion.
- CyberLab lessons (IPs & networks, ports & services, authentication &
  logs) with quizzes granting XP.
- Life simulation: game clock, energy/hunger drains, school schedule and
  attendance, sleep, fridge snacks, book reading.
- Skills & XP system (Linux, Networking, Web, Forensics) with levels.
- Inventory with usable consumables (Tab panel).
- Consequence-system foundation: evidence/risk tracking (displayed in lab
  results as "Evidence: 0%").
- Versioned JSON save/load with migration hook; continue from main menu.
- Main menu, pause menu, settings (display/VSync/shadows/glow/AA/sensitivity/
  volumes), credits.
- Original procedural audio: music loop, room ambience, keyboard, footsteps,
  door, notifications, success/fail stingers.
- Original generated icon set (1024/256/128/64).
- 56 automated headless tests (state, economy, inventory, skills, time,
  sim network, full mission flow via terminal, save/load).
- Scripted gameplay capture mode (`-- --capture`) used to produce the
  release trailer.

### Notes
- Android build intentionally not produced (no Android toolchain in the
  build environment); documented in README instead of shipping an
  unverified APK.
