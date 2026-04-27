# ROARTrigger

ROARTrigger is a Project Epoch addon for the Wrath 3.3.5 client.

It triggers battle emotes when configured action bar slots are pressed.

This addon does not detect confirmed successful spell casts. It detects action bar usage. If an ability is out of range, on cooldown, lacks resources, or fails for another reason, the addon may still trigger.

## Requirements

- Project Epoch
- Wrath 3.3.5 client
- AddOns enabled in the character select screen

## Installation

Place the addon folder here:

```text
epoch-live\Interface\AddOns\ROARTrigger
```

The folder must contain:

```text
ROARTrigger.toc
ROARTrigger.lua
README.md
```

The folder name, `.toc` file name, and Lua file reference must match:

```toc
## Interface: 30300
## Title: ROARTrigger
## Notes: Triggers battle emotes when you press specific action bar slots. Supports multiple per-character profiles and per-slot cooldown/chance.
## Version: 1.32-Epoch
## SavedVariables: ROGUDB

ROARTrigger.lua
```

After installation, restart the game or type:

```text
/reload
```

## Purpose

ROARTrigger exists for roleplay flavor, guild atmosphere, and combat noise.

It is not a rotation addon.
It is not a combat parser.
It is not a performance tool.
It does not make decisions for you.

It presses no buttons.
It casts no spells.
It only reacts when you press configured action bar slots.

## Core Features

- Triggers emotes from configured action bar slots
- Supports multiple slot setups
- Supports per-slot trigger chance
- Supports per-slot cooldowns
- Supports a low-chance fallback trigger
- Supports per-character profiles
- Stores settings through `ROGUDB`
- Includes `<ROAR>` guild recruitment messages
- Tracks basic roar statistics

## Basic Setup

Enable watch mode:

```text
/rogu watch
```

Press the action bar button you want to track.

The addon will print the slot number.

Assign that slot to instance 1:

```text
/rogu slot1 <slot>
```

Set the trigger chance:

```text
/rogu chance1 100
```

Set the cooldown:

```text
/rogu timer1 2
```

Now that action bar slot can trigger an emote when pressed.

## Example Setup

If watch mode says:

```text
pressed slot 5
```

Use:

```text
/rogu slot1 5
/rogu chance1 100
/rogu timer1 2
```

This means:

- instance 1 watches action slot 5
- it has a 100% trigger chance
- it has a 2 second cooldown

## Commands

### Help

```text
/rogu help
```

Shows the command list.

### Info

```text
/rogu info
```

Shows addon version, profile, enabled state, emote count, fallback settings, slot settings, and roar stats.

### Enable / Disable

```text
/rogu on
/rogu off
```

Turns the addon on or off.

### Watch Mode

```text
/rogu watch
```

Toggles slot watch mode.

Use this to find action bar slot numbers.

Turn it off after setup.

### Manual Roar

```text
/rogu roar
```

Immediately performs the `ROAR` emote.

### Rested XP

```text
/rogu rexp
```

Shows rested XP in bubbles and raw XP.

### Invite Message

```text
/rogu invite <channel>
```

Sends a random `<ROAR>` recruitment message to the selected channel number.

Example:

```text
/rogu invite 1
```

This sends to channel 1.

Use the correct channel number. The addon does not guess your server’s channel layout.

## Slot Configuration

Each slot setup is called an instance.

Use `slot1`, `slot2`, `slot3`, and so on.

### Set watched slot

```text
/rogu slot1 <slot>
```

Example:

```text
/rogu slot1 5
```

### Set trigger chance

```text
/rogu chance1 <0-100>
```

Example:

```text
/rogu chance1 50
```

This gives instance 1 a 50% chance to trigger when the watched slot is pressed.

### Set cooldown

```text
/rogu timer1 <seconds>
```

Example:

```text
/rogu timer1 8
```

This gives instance 1 an 8 second cooldown.

## Emote Configuration

The addon has a shared emote list.

Default emote:

```text
ROAR
```

### Add an emote

```text
/rogu emote <TOKEN>
```

Example:

```text
/rogu emote CHEER
```

The token must be a valid WoW emote token.

Examples:

```text
ROAR
CHEER
LAUGH
FLEX
CHARGE
```

If the client does not support a token, it will not behave correctly.

### List emotes

```text
/rogu emote list
```

Shows all saved emotes and their IDs.

### Assign emotes to an instance

```text
/rogu emote1 <id>
```

Example:

```text
/rogu emote1 2
```

Adds emote ID 2 to instance 1.

### Remove an emote from an instance

```text
/rogu emote1 -<id>
```

Example:

```text
/rogu emote1 -2
```

Removes emote ID 2 from instance 1.

### Clear instance emotes

```text
/rogu emote1 clear
```

Resets instance 1 back to emote ID 1.

### List instance emotes

```text
/rogu emote1 list
```

Shows which emotes instance 1 can use.

## Fallback System

The fallback system is a low-chance global trigger.

It can trigger from any valid action slot press.

Default chance:

```text
5 / 1000
```

That means 0.5%.

### Set fallback chance

```text
/rogu fallback chance <0-1000>
```

Example:

```text
/rogu fallback chance 5
```

Use low values. High values will make the addon noisy.

### Set fallback cooldown

```text
/rogu fallback timer <seconds>
```

Example:

```text
/rogu fallback timer 2
```

## Reset Commands

### Reset all configured slot instances

```text
/rogu reset
```

Clears all watched slot setups.

This does not delete the shared emote list.

### Reset cooldowns

```text
/rogu resetcd
```

Clears cooldown gates for configured slots, fallback, and reminder timers.

## Saved Variables

ROARTrigger uses:

```text
ROGUDB
```

Settings are saved per character profile using:

```text
Character-Realm
```

The shared emote list is account-wide inside the saved variable table.

## Important Behavior

ROARTrigger reacts to action bar slot usage.

It does not confirm:

- successful spell cast
- successful melee ability
- valid target
- sufficient rage, mana, or energy
- range
- cooldown availability
- line of sight
- macro success

This is intentional.

The addon is built for flavor, not precision.

## Troubleshooting

### The addon does not appear in the AddOns list

Check the folder structure.

Correct:

```text
Interface\AddOns\ROARTrigger\ROARTrigger.toc
Interface\AddOns\ROARTrigger\ROARTrigger.lua
```

Wrong:

```text
Interface\AddOns\ROARTrigger\ROARTrigger\ROARTrigger.toc
```

Nested folders will break loading.

### The addon loads but nothing happens

Run:

```text
/rogu info
```

If it prints addon information, the addon is loaded.

Then run:

```text
/rogu watch
```

Press action bar buttons and check if slot numbers appear.

### Watch mode shows slots but no emotes trigger

Configure a slot:

```text
/rogu slot1 <slot>
/rogu chance1 100
/rogu timer1 2
```

Then press that same action button.

### Emote does not work

Check the emote token.

Use:

```text
/rogu emote list
```

Default should be:

```text
1: ROAR
```

Test manually:

```text
/rogu roar
```

If `/rogu roar` does not work, the client may not support the expected emote behavior.

### Invite sends to the wrong chat

Channel numbers are client-side and can vary.

Check your chat channel numbers in-game before using:

```text
/rogu invite <channel>
```

## Recommended First Test

Use this exact order:

```text
/reload
/rogu info
/rogu watch
```

Press a button.

If the addon prints:

```text
pressed slot 5
```

Run:

```text
/rogu slot1 5
/rogu chance1 100
/rogu timer1 2
```

Press slot 5 again.

## Release Notes

Version:

```text
1.32-Epoch
```

Client target:

```text
Project Epoch / Wrath 3.3.5
```

Interface:

```text
30300
```

SavedVariables:

```text
ROGUDB
```

## Guild Note

Made for `<ROAR>`.

Characters are not loadouts.
They are stories in motion.
