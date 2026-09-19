# Security & Simulation Boundary Statement

HackerLife is a **fictional cybersecurity simulation**. This document states
exactly what the game does and does not do.

## What the game contains

- A simulated network (`TRAINING-NET 10.10.0.0/24`) made of plain GDScript
  dictionaries: three fictional hosts with fake services, fake banners,
  fake files and fake credentials (`student` / `learn3r` — a training login
  for a machine that does not exist).
- A terminal UI that reads and writes those dictionaries. Nothing more.

## What the game NEVER does

- Never opens a network socket. The project contains **zero** networking
  code; the game runs fully offline.
- Never scans, pings, contacts or references real IP addresses, domains or
  organizations.
- Never requests, stores or transmits real user credentials.
- Never reads or writes files outside its own save/settings directory
  (`user://`), apart from the optional `-- --capture` developer mode that
  writes screenshots to a build-time frames folder.
- Never executes shell commands, scripts or binaries on the player's OS.
- Never implements real exploit code, malware, persistence or anti-analysis
  techniques — simulated "attacks" are dictionary lookups and text output.

## Design rule

"Realistic in logic, fictional in infrastructure." Concepts (IPs, ports,
services, authentication, logs, evidence) are taught at a conceptual level
so that players learn *why* systems work the way they do — never actionable
instructions against real systems.

## For reviewers

A quick audit path:
1. `scripts/core/sim_network.gd` — the entire "cyber" data model.
2. `scripts/computer/terminal_app.gd` — the entire command surface.
3. Search the repo for networking primitives: there are none
   (no `HTTPRequest`, no `StreamPeerTCP`, no `PacketPeerUDP`).
