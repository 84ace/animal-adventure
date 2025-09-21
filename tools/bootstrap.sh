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
