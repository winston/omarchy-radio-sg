# Spec Delta

## Purpose

Defines the curated list of Singapore radio stations the plugin can play, and the bar for admitting a station to it. The list is static and hand-verified so playback never depends on a third-party lookup service.

## ADDED Requirements

### Requirement: Static curated station list
The plugin SHALL ship its stations as a static data file in the repository, and SHALL NOT query any remote station directory at runtime.

#### Scenario: Offline listing
- **WHEN** the user lists stations with no network connection
- **THEN** the full list is shown from the local file

### Requirement: Station entry fields
Each station entry SHALL have a unique lowercase `id`, a display `name`, an FM `freq`, an `operator`, and a stream `url`.

#### Scenario: Valid entry
- **WHEN** the station file is validated
- **THEN** every entry has all required fields and no two entries share an `id`

#### Scenario: Malformed entry
- **WHEN** an entry is missing a required field or duplicates an `id`
- **THEN** validation fails and names the offending entry

### Requirement: Only verified streams are listed
A station SHALL be included only if its stream URL has been confirmed to respond with audio and to decode and play. Stations whose streams cannot be verified SHALL be omitted.

#### Scenario: Stream verification
- **WHEN** a station is added to the list
- **THEN** its URL has been checked for an audio response and played successfully

#### Scenario: Re-verification
- **WHEN** the user runs the check command
- **THEN** every station's URL is probed and any that fail are reported by name with a non-zero exit status

### Requirement: Stream URLs are used as published
The plugin SHALL use publicly published stream URLs and SHALL NOT depend on the private API of any station's official app.

#### Scenario: Public URLs only
- **WHEN** the station list is reviewed
- **THEN** every URL is a plain HTTP(S) audio stream reachable without authentication or app credentials

### Requirement: Machine-readable listing
The plugin SHALL be able to list the stations as JSON, giving each station's `id`, `name`, `freq` and `operator`, in the order of the station file, so other frontends need not parse text.

#### Scenario: JSON listing
- **WHEN** the user asks for the station list as JSON
- **THEN** a single JSON array is printed with one object per station with those fields
