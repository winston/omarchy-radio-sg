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
The widget SHALL map left click to opening or closing the popup card, scroll to changing volume, right click to stopping playback, and middle click to toggling pause.

#### Scenario: Left click
- **WHEN** the user left-clicks the widget while the popup card is closed
- **THEN** the popup card opens

#### Scenario: Left click again
- **WHEN** the user left-clicks the widget while the popup card is open
- **THEN** the popup card closes

#### Scenario: Scroll
- **WHEN** the user scrolls up or down over the widget
- **THEN** the volume rises or falls by one step

#### Scenario: Right click
- **WHEN** the user right-clicks while a station plays
- **THEN** playback stops and the widget shows the stopped state

#### Scenario: Middle click
- **WHEN** the user middle-clicks
- **THEN** playback pauses if playing, or resumes if paused

### Requirement: Popup card
The widget SHALL open a popup card, styled like Omarchy's other bar popups (network, audio, power) and following the active theme, containing a now-playing header, a play/pause button, a volume slider and the list of stations. The header SHALL show the station name and frequency, the state (playing, paused or stopped) and, when the stream reports one, the current song title. The card SHALL stay up to date while it is open, and SHALL close when the user clicks elsewhere or presses Escape.

#### Scenario: Now-playing header
- **WHEN** Class 95 is playing a song and the user opens the popup card
- **THEN** the header shows "Class 95", "95.0 FM", the playing state and the song title

#### Scenario: Stopped header
- **WHEN** nothing is playing and the user opens the popup card
- **THEN** the header shows that the radio is stopped and no song title

#### Scenario: Play/pause button
- **WHEN** a station is playing and the user presses the play/pause button, then presses it again
- **THEN** playback pauses, then resumes, and the button icon reflects the state

#### Scenario: Play/pause button while stopped
- **WHEN** nothing is playing
- **THEN** the play/pause button is disabled and pressing it does nothing

#### Scenario: Volume slider
- **WHEN** the user drags the volume slider to 30
- **THEN** the volume becomes 30 and the slider shows 30 whenever the volume changes, including from scrolling or the command line

#### Scenario: Choose a station
- **WHEN** the user clicks "Gold 905" in the station list
- **THEN** Gold 905 starts playing, replacing any current station, and the popup card stays open

#### Scenario: Current station marked
- **WHEN** Gold 905 is playing or paused
- **THEN** its row in the station list is visibly highlighted

#### Scenario: Live update
- **WHEN** the popup card is open and playback is changed from a terminal
- **THEN** the card reflects the change within a couple of seconds

#### Scenario: Dismiss
- **WHEN** the user clicks outside the popup card or presses Escape
- **THEN** the card closes and playback is unchanged

### Requirement: Bar orientation and theme
The widget SHALL work on horizontal and vertical bars, showing the icon only on vertical bars, and SHALL take its colors and fonts from the active Omarchy theme.

#### Scenario: Vertical bar
- **WHEN** the bar is on the left or right edge
- **THEN** the widget shows the icon without the station name
