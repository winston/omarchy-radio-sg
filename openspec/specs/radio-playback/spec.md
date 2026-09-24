# radio-playback Specification

## Purpose

Defines how the plugin plays, controls and reports the state of a radio station through a headless player, so the bar widget, the picker and the command line all share one source of truth.

## Requirements

### Requirement: Headless single-instance playback
The plugin SHALL play at most one station at a time, with no video window, and playback SHALL continue independently of the terminal or process that started it.

#### Scenario: Start a station
- **WHEN** the user plays a station by id while nothing is playing
- **THEN** audio starts for that station and no window opens

#### Scenario: Survive the caller
- **WHEN** the command that started playback exits
- **THEN** audio keeps playing

#### Scenario: Switch station
- **WHEN** the user plays a different station while one is playing
- **THEN** the new station replaces the old one and only one stream is audible

#### Scenario: Unknown station
- **WHEN** the user plays an id that is not in the station list
- **THEN** the command fails with an error naming the id, and any current playback is unchanged

### Requirement: Pause and resume
The plugin SHALL provide a toggle that pauses playing audio and resumes paused audio, and SHALL do nothing when nothing is playing.

#### Scenario: Pause then resume
- **WHEN** the user toggles while a station is playing, then toggles again
- **THEN** audio pauses, then resumes

#### Scenario: Toggle while stopped
- **WHEN** the user toggles while no station is loaded
- **THEN** nothing starts and the command exits successfully

### Requirement: Volume control
The plugin SHALL support absolute and relative volume changes, clamped to 0–100, and SHALL apply them to the running player.

#### Scenario: Relative step
- **WHEN** the volume is 50 and the user steps up by 5
- **THEN** the volume becomes 55

#### Scenario: Clamping
- **WHEN** the volume is 98 and the user steps up by 5
- **THEN** the volume becomes 100

#### Scenario: No player
- **WHEN** the user changes volume while nothing is playing
- **THEN** the command exits successfully and starts nothing

### Requirement: Stop
The plugin SHALL provide a stop command that ends playback and releases the player, and that is safe to run repeatedly.

#### Scenario: Stop playing station
- **WHEN** the user stops while a station is playing
- **THEN** audio ends and no player process or control socket remains

#### Scenario: Stop when idle
- **WHEN** the user stops while nothing is playing
- **THEN** the command exits successfully

### Requirement: Machine-readable status
The plugin SHALL print the current state as a single line of JSON containing a `class` of `playing`, `paused` or `stopped`, a short `text`, a `tooltip`, and, when a station is loaded, its `station` id and `name`, its `freq`, the current `volume` and, when the stream reports one, the current song `title`. Status SHALL be fast and read-only.

#### Scenario: Playing
- **WHEN** a station is playing
- **THEN** status reports class `playing` with that station's id, name and volume

#### Scenario: Song title
- **WHEN** the stream reports the current song
- **THEN** status includes it as `title`, and omits `title` when the stream reports none

#### Scenario: Stopped
- **WHEN** nothing is playing
- **THEN** status reports class `stopped` and exits successfully

#### Scenario: Stale control socket
- **WHEN** the player was killed and left its control socket behind
- **THEN** status reports `stopped`, and the next play command starts cleanly

### Requirement: Missing dependencies
The plugin SHALL report a clear error naming any required tool that is not installed, instead of failing silently.

#### Scenario: Player not installed
- **WHEN** the user plays a station and the player binary is absent
- **THEN** the command fails with a message naming the missing tool
