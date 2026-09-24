# Spec Delta

## Purpose

Shows what the radio is doing in the Omarchy bar and makes the common controls one mouse action away.

## ADDED Requirements

### Requirement: Now-playing display
The widget SHALL show the state and the station name while a station is playing, show a distinct paused state while paused, and show a radio icon only while stopped. It SHALL refresh within a few seconds of any state change, including changes made from the command line.

#### Scenario: Playing
- **WHEN** Class 95 is playing
- **THEN** the widget shows a playing icon and "Class 95"

#### Scenario: Paused
- **WHEN** the station is paused
- **THEN** the widget shows a paused icon, visually distinct from playing

#### Scenario: Stopped
- **WHEN** nothing is playing
- **THEN** the widget shows only the radio icon, so it remains clickable

#### Scenario: External change
- **WHEN** the user stops playback from a terminal
- **THEN** the widget shows the stopped state within a few seconds

### Requirement: Tooltip
The widget SHALL show a tooltip on hover with the station name, frequency, state and volume.

#### Scenario: Hover
- **WHEN** the user hovers over the widget while Gold 905 plays at volume 60
- **THEN** the tooltip shows the station, its frequency, that it is playing, and volume 60

### Requirement: Mouse interactions
The widget SHALL map left click to opening the station picker, scroll to changing volume, right click to stopping playback, and middle click to toggling pause.

#### Scenario: Left click
- **WHEN** the user left-clicks the widget
- **THEN** the station picker opens

#### Scenario: Scroll
- **WHEN** the user scrolls up or down over the widget
- **THEN** the volume rises or falls by one step

#### Scenario: Right click
- **WHEN** the user right-clicks while a station plays
- **THEN** playback stops and the widget shows the stopped state

#### Scenario: Middle click
- **WHEN** the user middle-clicks
- **THEN** playback pauses if playing, or resumes if paused

### Requirement: Bar orientation and theme
The widget SHALL work on horizontal and vertical bars, showing the icon only on vertical bars, and SHALL take its colors and fonts from the active Omarchy theme.

#### Scenario: Vertical bar
- **WHEN** the bar is on the left or right edge
- **THEN** the widget shows the icon without the station name
