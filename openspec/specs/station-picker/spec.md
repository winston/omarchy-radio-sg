# station-picker Specification

## Purpose

Lets the user choose a station from a keyboard-driven list in the Omarchy menu, without a browser or a separate app. It is a standalone command, so it can be bound to a key or run from a terminal; the bar widget offers its own popup card instead.

## Requirements

### Requirement: Picker lists stations
The picker SHALL show every station in the list by display name and frequency, in the order of the station file.

#### Scenario: Open picker
- **WHEN** the user opens the picker
- **THEN** all stations are shown and can be filtered by typing

### Requirement: Selection plays the station
Choosing a station SHALL start playing it, replacing any current station.

#### Scenario: Choose station
- **WHEN** the user selects "Class 95" in the picker
- **THEN** Class 95 starts playing and the picker closes

### Requirement: Dismissal is harmless
Dismissing the picker without choosing SHALL leave playback unchanged.

#### Scenario: Cancel
- **WHEN** the user closes the picker with Escape while a station is playing
- **THEN** the station keeps playing

### Requirement: Current station is marked
The picker SHALL mark the station that is currently playing or paused.

#### Scenario: Marker
- **WHEN** Gold 905 is playing and the user opens the picker
- **THEN** the Gold 905 row is visibly marked

### Requirement: Standalone command
The picker SHALL be openable by a single command, independent of the bar widget.

#### Scenario: Open from a terminal or keybinding
- **WHEN** the user runs the pick command from a terminal or a keybinding
- **THEN** the picker opens and behaves as described above
