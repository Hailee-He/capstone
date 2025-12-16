Where the Light End

Where the Light End is a small 2D action–survival platform game made in Godot 4.5 for the Capstone Game Project (Advanced Game Design – Systems Thinking).
A full playthrough usually takes about 5–10 minutes.

Goal

You are trapped in a world where darkness is dangerous.

Stay in the light to be safe.

Use your flashlight to create safe space and survive long enough to reach the end.

Core Systems
Light / Darkness (Safety System)

This is the main system of the game.

Flashlight ON = safe area

Flashlight OFF = higher danger

The level is designed so players learn naturally that light changes risk, not just visibility.

Health (HP) & Death

The player has HP and takes damage from enemies/hazards.

When HP reaches 0:

The player dies and the current scene reloads.

Items

Items can be picked up and used.

Using an item can change the situation quickly (ex: such as invisibility, healing, boom/explosion, and speed boost).

This creates a small risk/reward decision:

use now for safety vs. save for later.

Variety Enemy includes:

Flying enemies that are afraid of flashlight beams

Ground enemies that pressure movement

A larger “tank” enemy

A special enemy that becomes more aggressive under flashlight exposure

Enemy Pressure

Enemies apply constant pressure, especially when you are not in light.

The interaction between player movement + light control + enemy distance creates tense moments without needing overly complex rules.

HUD & Feedback

Health bar updates immediately when taking damage or healing.

Flashlight visibly changes the player’s safety area.

UI and gameplay actions have SFX feedback (ex: click / hit).

BGM is different per scene/level to support progression and mood.

Controls

Move: A / D or ← / →

Jump: W

Flashlight Toggle: Q

Menu Flow

Main Menu

Start Game

How To Play

Quit

How To Play

Explains movement + the “light is safe” rule

Back returns to Main Menu

Systems Thinking Notes

This project focuses on a simple set of rules that combine into meaningful gameplay:

Light ↔ Survival

Light acts like a “resource” you control.

Being in light reduces danger, encouraging safe positioning.

Light ↔ Movement

You can’t just stand still and win.

You use movement to stay inside safe areas and avoid threats.

Enemies ↔ Light Choice

Enemies feel much more threatening when you lose safe space.

This creates emergent behavior like:

“panic toggling” the flashlight

choosing safer routes vs. faster routes

Teaching Through Play

Instead of a long tutorial, the game teaches by:

visible light safety changes,

clear HP feedback,

sound cues for important interactions.

Export / Build

Built in Godot 4.5

Export targets:

Windows: .exe + .pck

macOS: .app / .dmg (depending on export preset)

Asset Credits

Music: BGM pack from TowDownGame and Ninja Adventure - Asset Pack

SFX / Sprites: assets from previous assignments, GoNNER_assets and craftpix-891154-night-city-street-game-background-tiles

