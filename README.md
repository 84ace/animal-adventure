# Animal World Adventures — Build Pack v1 (Agent-Ready)

This is a complete, *agent-friendly* build plan you can feed to Codex, Google Jules, or any codegen/automation agent. It includes:

* Environment setup & repo bootstrap
* Architecture & module contracts
* Data schemas (JSON Schema + examples)
* Godot 4 client + headless server stubs
* Networking protocol (messages, ticks)
* Safety/parental control hooks
* CI/CD pipeline (GitHub Actions)
* Docker for server
* QA test plans
* **Prompt packs** for agents (copy‑paste ready)
* **Issue tickets** with acceptance criteria & files to touch

> **Engine**: Godot 4.x (GDScript). Alternative Unity mapping callouts included where helpful.

---

## 0) Quick Start (TL;DR for Agents)

1. **Create repo** using the tree in §2.2.
2. **Paste** prompts from §10 into Codex/Jules per ticket.
3. **Run** the bootstrap script from §2.3.
4. **Export** desktop build with Godot, run the headless server, connect 2 clients (see §7).
5. **Green CI** should produce artifacts.

---

## 1) Architecture Overview

**Client** (Godot 4): presentation, input, prediction/interp, UI, local save.
**Server** (Godot 4 headless): authoritative sim, AI, world state, moderation logs.
**Data**: JSON-driven animals/abilities/quests/biomes.
**Networking**: UDP-like (Godot MultiplayerAPI WebSocket/ENet). 20–30 Hz tick server, client input at 30–60 Hz.

### 1.1 Module Map & Contracts

* **animal/**: locomotion, animation, abilities.

  * Contracts: `AnimalController`, `Ability` interface, `AbilityWheel` UI.
* **needs/**: hunger, energy, comfort (gentle fail → faint/recover).

  * Contracts: `NeedsComponent` with `tick(delta)` and signals.
* **social/**: pack/herd, buddy pet, emotes, follow/call.

  * Contracts: `SocialComponent`, `EmoteBus`.
* **build/**: snap-grid, place den/nest/dam parts, gather twigs/leaves/mud.

  * Contracts: `BuildSystem`, `BuildPiece`, `Inventory`.
* **world/**: biome gen, POIs, time/weather, chunk streaming.

  * Contracts: `WorldGenerator`, `Chunk`, `WeatherSystem`.
* **quests/**: kid quests, progression, unlocks (no monetization).

  * Contracts: `QuestSystem`, `Unlocks`.
* **net/**: lobby, session, replication, anti-cheat-lite.

  * Contracts: `NetServer`, `NetClient`, `Replicator`.
* **safety/**: chat filter, parental toggles, privacy; defaults to safe.

  * Contracts: `SafetyConfig`, `TextFilter`, `ModerationLog`.

---

## 2) Repository & Setup

### 2.1 Prerequisites

* Godot 4.x (editor + export templates)
* Python 3.10+ (tooling scripts)
* Git LFS (for binary assets)
* Xcode (for iOS export) — optional for first pass
* Docker (for headless server container)
* Node 18+ (optional: docs tooling)

### 2.2 Repo Tree

```
animal-world-adventures/
  /client/
    project.godot
    /scenes/
    /scripts/
      /animal/
      /needs/
      /social/
      /build/
      /world/
      /quests/
      /ui/
      /net/
      /safety/
    /assets/ (models, textures, audio)
    /data/
      animals/
      abilities/
      quests/
      biomes/
  /server/
    server.project.godot
    /scripts/
  /docs/
    GDD.md
    TECH_ARCH.md
    SAFETY.md
    ACCESSIBILITY.md
  /tools/
    bootstrap.sh
    content_packer.py
  /ci/
    godot-export.yml
  /docker/
    server.Dockerfile
    compose.yml
  /tests/
    /gut/ (Godot Unit Tests)
  README.md
  LICENSE
```

### 2.3 Bootstrap Script (tools/bootstrap.sh)

```bash
#!/usr/bin/env bash
set -euo pipefail

# 1) Git basics
git init
git lfs install

echo "*.png filter=lfs diff=lfs merge=lfs -text" >> .gitattributes

# 2) Create data directories
mkdir -p client/data/{animals,abilities,quests,biomes}
mkdir -p client/{scenes,scripts/{animal,needs,social,build,world,quests,ui,net,safety},assets}
mkdir -p server/scripts

# 3) Seed sample data
cat > client/data/animals/fox.json <<'JSON'
{
  "id": "fox",
  "abilities": ["pounce","scent_trail","dig_small"],
  "diet": ["small_prey","berries"],
  "biomes": ["forest","meadow"],
  "comfort_rules": {"shelter_bonus": 0.15, "pack_radius": 8},
  "move": {"walk": 5.5, "sprint": 8.0, "jump": 2.0}
}
JSON

cat > client/data/abilities/pounce.json <<'JSON'
{
  "id": "pounce",
  "cooldown": 3,
  "energy_cost": 5,
  "effect": "forward_leap_with_small_damage_or_tag"
}
JSON

echo "Bootstrapped repo. Next: open client/project.godot in Godot 4."
```

---

## 3) Data Schemas (JSON Schema + Examples)

### 3.1 Animal Schema (client/data/animals/\_schema.json)

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://awa/schemas/animal.json",
  "type": "object",
  "required": ["id", "abilities", "diet", "biomes", "move"],
  "properties": {
    "id": {"type": "string", "pattern": "^[a-z0-9_]+$"},
    "abilities": {"type": "array", "items": {"type": "string"}},
    "diet": {"type": "array", "items": {"enum": ["berries","plants","small_prey","fish","plankton"]}},
    "biomes": {"type": "array", "items": {"enum": ["forest","meadow","river","lake","cliffs","beach","reef","desert","snow"]}},
    "comfort_rules": {
      "type": "object",
      "properties": {
        "shelter_bonus": {"type": "number"},
        "pack_radius": {"type": "number"}
      },
      "additionalProperties": false
    },
    "move": {
      "type": "object",
      "required": ["walk","sprint","jump"],
      "properties": {
        "walk": {"type": "number"},
        "sprint": {"type": "number"},
        "jump": {"type": "number"}
      }
    }
  },
  "additionalProperties": false
}
```

### 3.2 Ability Schema (client/data/abilities/\_schema.json)

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://awa/schemas/ability.json",
  "type": "object",
  "required": ["id","cooldown","energy_cost","effect"],
  "properties": {
    "id": {"type": "string"},
    "cooldown": {"type": "number", "minimum": 0},
    "energy_cost": {"type": "number", "minimum": 0},
    "effect": {"type": "string"}
  },
  "additionalProperties": false
}
```

### 3.3 Quest Schema (client/data/quests/\_schema.json)

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://awa/schemas/quest.json",
  "type": "object",
  "required": ["id","title","steps","rewards"],
  "properties": {
    "id": {"type": "string"},
    "title": {"type": "string"},
    "steps": {"type": "array", "items": {"type": "string"}},
    "rewards": {"type": "array", "items": {"enum": ["unlock_animal","unlock_pattern","unlock_emote","materials"]}}
  }
}
```

---

## 4) Godot Client Stubs (GDScript)

### 4.1 AnimalController (client/scripts/animal/AnimalController.gd)

```gdscript
extends CharacterBody3D

class_name AnimalController

@export var walk_speed: float = 5.5
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var input_dir := Vector2.ZERO
var is_sprinting := false

signal did_jump
signal did_emote(emote_id)

func _physics_process(delta: float) -> void:
    var velocity3 = velocity
    if not is_on_floor():
        velocity3.y -= gravity * delta

    input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var cam = get_viewport().get_camera_3d()
    var forward = -cam.transform.basis.z
    var right = cam.transform.basis.x
    var move_dir = (forward * input_dir.y + right * input_dir.x).normalized()

    var speed = (is_sprinting) ? sprint_speed : walk_speed
    velocity3.x = move_dir.x * speed
    velocity3.z = move_dir.z * speed

    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity3.y = jump_velocity
        did_jump.emit()

    velocity = velocity3
    move_and_slide()

func set_sprinting(s: bool) -> void:
    is_sprinting = s
```

### 4.2 NeedsComponent (client/scripts/needs/NeedsComponent.gd)

```gdscript
extends Node

class_name NeedsComponent

@export var hunger: float = 100.0
@export var energy: float = 100.0
@export var comfort: float = 100.0

@export var decay_hunger: float = 0.5  # per second
@export var decay_energy: float = 0.2
@export var decay_comfort: float = 0.1

signal fainted
signal recovered

var fainted_state := false

func _process(delta: float) -> void:
    if fainted_state:
        return
    hunger = max(0.0, hunger - decay_hunger * delta)
    energy = max(0.0, energy - decay_energy * delta)
    comfort = max(0.0, comfort - decay_comfort * delta)

    if hunger <= 0.0 or energy <= 0.0 or comfort <= 0.0:
        fainted_state = true
        fainted.emit()
        get_tree().create_timer(3.0).timeout.connect(_recover)

func _recover() -> void:
    hunger = max(hunger, 30.0)
    energy = max(energy, 50.0)
    comfort = max(comfort, 50.0)
    fainted_state = false
    recovered.emit()
```

### 4.3 Ability Base & Registry

**client/scripts/animal/Ability.gd**

```gdscript
extends Resource
class_name Ability

@export var id: String
@export var cooldown: float = 3.0
@export var energy_cost: float = 5.0

func can_cast(owner: Node) -> bool:
    return true

func cast(owner: Node) -> void:
    # override in derived resources
    pass
```

**client/scripts/animal/abilities/Pounce.gd**

```gdscript
extends Ability
class_name PounceAbility

func cast(owner: Node) -> void:
    if not owner: return
    if owner.has_method("velocity"):
        var dir = owner.transform.basis.z * -1.0
        owner.velocity += dir * 6.0 + Vector3.UP * 2.0
```

### 4.4 World Generator (client/scripts/world/WorldGenerator.gd)

```gdscript
extends Node3D
class_name WorldGenerator

@export var size_x: int = 256
@export var size_z: int = 256
@export var scale: float = 12.0

var noise := FastNoiseLite.new()

func _ready() -> void:
    noise.noise_type = FastNoiseLite.TYPE_OPEN_SIMPLEX2
    _spawn_ground()

func _spawn_ground() -> void:
    var mesh := PlaneMesh.new()
    mesh.size = Vector2(size_x, size_z)
    var mi := MeshInstance3D.new()
    mi.mesh = mesh
    add_child(mi)
```

### 4.5 Minimal UI (client/scripts/ui/HUD.gd)

```gdscript
extends Control

@onready var hunger_bar = $Hunger
@onready var energy_bar = $Energy
@onready var comfort_bar = $Comfort

func set_needs(h,e,c):
    hunger_bar.value = h
    energy_bar.value = e
    comfort_bar.value = c
```

---

## 5) Server (Headless Godot) Stubs

### 5.1 Server Main (server/scripts/ServerMain.gd)

```gdscript
extends Node

class_name ServerMain

const TICK_RATE := 20.0
var tick_timer := 0.0
var peers := {}

func _ready():
    var peer := ENetMultiplayerPeer.new()
    peer.create_server(7777)
    multiplayer.multiplayer_peer = peer
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    print("Server listening on 7777")

func _process(delta):
    tick_timer += delta
    while tick_timer >= 1.0 / TICK_RATE:
        _tick()
        tick_timer -= 1.0 / TICK_RATE

func _tick():
    # TODO: update world, run AI, replicate snapshots
    pass

func _on_peer_connected(id):
    peers[id] = {"last_input": null}

func _on_peer_disconnected(id):
    peers.erase(id)
```

### 5.2 Replication Contract

* **Server owns**: entity positions/velocities, needs, weather, time, build pieces, quests state.
* **Client sends**: input (move vector, jump, sprint, ability triggers).
* **Tick**: 20 Hz server snapshot → compressed to include only nearby entities.
* **Messages** (names only, see §6): `JOIN`, `WELCOME`, `INPUT`, `SNAPSHOT`, `EMOTE`, `BUILD_PLACE`, `QUEST_EVENT`, `SAVE_REQ/RESP`, `MOD_EVENT`.

---

## 6) Networking Protocol (MVP)

### 6.1 Messages

* `JOIN { version, player_name, animal_id, parental_flags }`
* `WELCOME { session_id, world_seed, spawn }`
* `INPUT { seq, dt, move_vec, jump, sprint, ability_id? }`
* `SNAPSHOT { tick, entities:[{id, pos, vel, rot, needs}], weather, time }`
* `EMOTE { emote_id }`
* `BUILD_PLACE { piece_id, pos, rot }`
* `QUEST_EVENT { quest_id, step }`
* `MOD_EVENT { type, payload }` (server → log)

### 6.2 Interp/Prediction

* Client predicts own movement; reconcile on snapshot with small error-correction.

---

## 7) Running Locally

### 7.1 Server

```bash
godot4 --headless --path server --main-pack server.pck  # or --script scripts/ServerMain.gd
```

### 7.2 Client

```bash
godot4 --path client
```

### 7.3 Docker (docker/server.Dockerfile)

```dockerfile
FROM archlinux:latest
RUN pacman -Sy --noconfirm godot-headless
WORKDIR /app
COPY server/ /app/
CMD ["godot4", "--headless", "--path", "/app", "--script", "scripts/ServerMain.gd"]
```

**docker/compose.yml**

```yaml
services:
  server:
    build: ./
    ports:
      - "7777:7777/udp"
```

---

## 8) Safety/Parental Controls

* **Defaults**: Solo or friends-only; text chat OFF; emote-only ON; hunting off option.
* **SafetyConfig** (client/scripts/safety/SafetyConfig.gd): loads from profile; server enforces.
* **ModerationLog** (server): writes minimal events; no PII persistence beyond session.

---

## 9) CI/CD (GitHub Actions)

**ci/godot-export.yml**

```yaml
name: Build & Test
on: [push]
jobs:
  export-desktop:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Godot
        uses: firebelley/setup-godot@v1.4
        with:
          version: 4.3.0
          use-dotnet: false
      - name: Unit tests
        run: |
          echo "TODO: run GUT tests"
      - name: Export Client (Linux)
        run: |
          godot4 --headless --path client --export-release "Linux/X11" build/client.x86_64 || true
      - name: Export Server (Headless)
        run: |
          godot4 --headless --path server --export-release "Linux/X11" build/server.x86_64 || true
      - uses: actions/upload-artifact@v4
        with:
          name: awa-builds
          path: build/
```

---

## 10) Prompt Packs for Codex/Jules

> Paste these verbatim. Each yields small, testable code with files and acceptance criteria.

### 10.1 Create Godot Project Files

```
SYSTEM: You are a senior Godot 4 engineer. Prefer idiomatic GDScript, clear signals, small composable nodes. Generate only files requested, no commentary.
TASK: Create minimal Godot 4 project files for two projects in this repo: /client and /server. Include project.godot (and server.project.godot) with display defaults, input map for move_left/right/forward/back, jump, sprint, emote_wheel, ability_1..3. No assets. Ensure projects open in editor without errors.
OUTPUT: Write the files at paths /client/project.godot and /server/server.project.godot.
ACCEPTANCE: Godot opens both projects; InputMap contains actions; no missing resource warnings.
```

### 10.2 Implement AnimalController

```
SYSTEM: Senior Godot engineer.
TASK: Implement CharacterBody3D-based AnimalController per contract. Input actions map to movement; sprint toggle; jump; emit signals. Place at /client/scripts/animal/AnimalController.gd. Provide a sample scene /client/scenes/Animal.tscn with a Capsule + Camera3D following.
ACCEPTANCE: Pressing WASD + Space moves & jumps. Sprint works. Scene runs in editor.
```

### 10.3 NeedsComponent + HUD

```
SYSTEM: Senior Godot engineer.
TASK: Implement NeedsComponent.gd and HUD.gd as per §4.2 and §4.5. Wire Animal.tscn to update HUD every frame. Add simple “faint” simulation (disable input for 3 seconds, fade vignette overlay).
OUTPUT: /client/scripts/needs/NeedsComponent.gd, /client/scripts/ui/HUD.gd, update Animal.tscn
ACCEPTANCE: Bars decay; faint triggers; recover after 3s.
```

### 10.4 Ability Base + Pounce

```
SYSTEM: Senior Godot engineer.
TASK: Implement Ability.gd and PounceAbility.gd; add AbilityWheel UI with one button triggering Pounce. Ensure cooldowns and energy costs gate the use.
OUTPUT: /client/scripts/animal/Ability.gd, /client/scripts/animal/abilities/Pounce.gd, /client/scripts/ui/AbilityWheel.gd
ACCEPTANCE: Press ability button → short leap; disabled while on cooldown or energy low.
```

### 10.5 WorldGenerator Stub

```
SYSTEM: Senior Godot engineer.
TASK: Implement WorldGenerator.gd creating a simple meadow: ground plane, a few trees (MeshInstance3D), daylight cycle (DirectionalLight intensity changes), and a Spawn point. Place scene at /client/scenes/World.tscn.
ACCEPTANCE: Scene loads; 100x100m meadow; visible day/night 60s cycle.
```

### 10.6 Server Main + ENet Lobby

```
SYSTEM: Senior Godot network engineer.
TASK: Implement server headless with ENet. Accept clients, assign session_id, broadcast heartbeats, store last input per client. Paths: /server/scripts/ServerMain.gd; script autoload in server.project.godot. Add simple `/scripts/ProtoMessages.gd` with enums for message types.
ACCEPTANCE: `godot4 --headless --path server` prints "Server listening"; connecting a client prints peer ids.
```

### 10.7 Client NetClient

```
SYSTEM: Senior Godot network engineer.
TASK: Implement NetClient.gd that connects to localhost:7777, sends JOIN with version & player_name, sends INPUT at 20Hz, handles SNAPSHOT updates to local player transform.
OUTPUT: /client/scripts/net/NetClient.gd
ACCEPTANCE: Client can connect and receive periodic messages without errors.
```

### 10.8 SafetyConfig + Parental Toggles

```
SYSTEM: Senior gameplay/UI engineer.
TASK: Implement SafetyConfig.gd reading JSON from user://profile.json with flags {text_chat:false, emote_only:true, hunting_enabled:false, world_privacy:"friends_only"}. Provide a simple Settings UI to toggle these, saved to disk.
OUTPUT: /client/scripts/safety/SafetyConfig.gd, /client/scenes/Settings.tscn
ACCEPTANCE: Toggling persists; defaults match safe values.
```

### 10.9 Build System (snap-grid)

```
SYSTEM: Senior gameplay engineer.
TASK: Implement BuildSystem.gd with snap-to-grid placement of BuildPiece scenes (DenEntrance, DenTunnel). Materials (twigs/leaves) deducted from Inventory. Place sample pieces in /client/scenes/build/.
ACCEPTANCE: Place den entrance on ground; cannot overlap; inventory count decreases.
```

### 10.10 Buddy System (follow + fetch)

```
SYSTEM: AI engineer.
TASK: Implement Buddy.gd with leash radius follow of owner; simple fetch behavior for nearest Twig resource. Owner can whistle emote to call buddy.
ACCEPTANCE: Buddy follows within 6m; fetches single twig and returns.
```

---

## 11) Issue Tickets (paste into GitHub)

Each ticket includes **Definition of Done (DoD)**, **Files**, **Tests**.

### T-001 Project Init

* **DoD**: Projects open cleanly; InputMap set; README first-run steps.
* **Files**: /client/project.godot, /server/server.project.godot, README.md.
* **Tests**: Open both projects; no missing res.

### T-002 Animal Controller

* **DoD**: Move/jump/sprint; signals; sample scene.
* **Files**: AnimalController.gd, Animal.tscn.
* **Tests**: 60 FPS in empty meadow on mid laptop.

### T-003 Needs + HUD

* **DoD**: Needs decay; faint/recover; HUD bars.
* **Files**: NeedsComponent.gd, HUD.gd.
* **Tests**: Manual decay & recovery verified.

### T-004 Ability System

* **DoD**: Base Ability + Pounce; cooldowns & energy.
* **Files**: Ability.gd, Pounce.gd, AbilityWheel.gd.
* **Tests**: Pounce gated properly.

### T-005 World Meadow

* **DoD**: World.tscn with ground, trees, day/night.
* **Files**: WorldGenerator.gd, World.tscn.
* **Tests**: 60s cycle works; player spawns.

### T-006 Server ENet

* **DoD**: Headless server accepts connection.
* **Files**: ServerMain.gd, ProtoMessages.gd.
* **Tests**: Logs peer connect/disconnect.

### T-007 Client Net

* **DoD**: Client connects; sends input; receives snapshot.
* **Files**: NetClient.gd.
* **Tests**: No disconnects over 5 minutes idle.

### T-008 Safety Settings

* **DoD**: Parental toggles persisted; defaults safe.
* **Files**: SafetyConfig.gd, Settings.tscn.
* **Tests**: Restart app retains settings.

### T-009 Build System MVP

* **DoD**: Place den entrance; inventory decreases; no overlap.
* **Files**: BuildSystem.gd, scenes/build/\*.tscn.
* **Tests**: 10 placements in a row succeed/fail correctly.

### T-010 Buddy Follow

* **DoD**: Buddy follows owner; fetches twig.
* **Files**: Buddy.gd.
* **Tests**: Returns to within 2m after fetch.

---

## 12) QA Test Plan (Kid-Centric)

* **5-minute First Fun**: Spawn → move → eat snack → place den → emote.
* **Two-player Join**: Friends-only session, meet and play tag.
* **Faint Safety**: Purposely drain needs; faint & recover near den.

---

## 13) Unity Mapping (Optional)

* Replace GDScript with C#; use Netcode for GameObjects for replication; ScriptableObjects for data; Cinemachine for camera; Addressables for streaming.

---

## 14) Conventions

* Folder names lowercase; scripts `PascalCase.gd`.
* Signals prefixed `did_`.
* One responsibility per script; no 1k-line monoliths.

---

## 15) Next Steps

1. Run `tools/bootstrap.sh`
2. Feed **Prompt Packs** (§10) to agents in order T-001 → T-010.
3. Stand up server + client locally (§7).
4. Expand animals/biomes/quests using schemas (§3).

> When you’re ready, I can generate **dozens more tickets** for Sprint 2–4 (flight, swim, weather, families, Magic Meadow games) in the same agent-ready format.
