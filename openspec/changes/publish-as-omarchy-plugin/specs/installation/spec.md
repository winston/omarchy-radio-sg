# Spec Delta

## ADDED Requirements

### Requirement: Installable as an Omarchy plugin
The repository root SHALL be a valid Omarchy shell plugin folder with the id `winston.radio-sg`, so that `omarchy plugin add <repository> --enable` installs it with no further step, `omarchy plugin update` updates it and `omarchy plugin remove` removes it. The repository MAY be given as a URL or as the path of a local checkout.

#### Scenario: Valid plugin folder
- **WHEN** the repository root is checked with `omarchy plugin validate`
- **THEN** it passes: the manifest is at the root, its entry point exists, its id is not reserved and the folder contains no symlinks

#### Scenario: First install
- **WHEN** the user runs `omarchy plugin add` with `--enable` on the repository
- **THEN** the widget appears in the bar and playing a station works, with no other script run

#### Scenario: Install from a local checkout
- **WHEN** the user runs `omarchy plugin add` with the path of a local checkout
- **THEN** it installs the same way, using the committed content of that checkout

#### Scenario: Update
- **WHEN** the repository has new commits and the user runs `omarchy plugin update` and restarts the shell
- **THEN** the bar runs the new version and the user's bar layout is unchanged

### Requirement: Self-contained plugin folder
The widget SHALL find the command-line tool and the station list inside its own plugin folder, so that it works with nothing else installed and regardless of the user's PATH.

#### Scenario: Nothing else installed
- **WHEN** the plugin was added and no `omarchy-radio` command exists anywhere else on the system
- **THEN** the widget shows the playback state and controls playback

#### Scenario: PATH does not matter
- **WHEN** the directory of the user's own binaries is not on the PATH of the shell
- **THEN** the widget still works

### Requirement: Optional command-line access
The repository SHALL provide a helper that makes `omarchy-radio` available on the user's PATH by linking to the copy inside the plugin folder, and the helper SHALL be safe to run repeatedly.

#### Scenario: Link created
- **WHEN** the user runs the helper from the plugin folder
- **THEN** running `omarchy-radio` in a terminal runs the plugin's tool

#### Scenario: Repeat run
- **WHEN** the user runs the helper again
- **THEN** it succeeds and changes nothing

#### Scenario: Follows updates
- **WHEN** the plugin is updated with `omarchy plugin update`
- **THEN** the linked command runs the new version without re-running the helper

## MODIFIED Requirements

### Requirement: Non-destructive to user configuration
Adding, enabling and removing the plugin SHALL change the user's bar only by adding or removing this widget's own entry, and the helper SHALL NOT overwrite or truncate any file it did not create.

#### Scenario: Existing bar layout
- **WHEN** the user has a customized bar layout and adds the plugin
- **THEN** the layout is preserved and the widget is added alongside the existing widgets

#### Scenario: Name collision
- **WHEN** a different file already exists at the path the helper links to and was not created by the helper
- **THEN** the helper stops with an error and leaves that file untouched

### Requirement: Prerequisite check
The helper SHALL verify that the required tools and an Omarchy shell with plugin support are present before changing anything, and SHALL list what is missing. The documentation SHALL list the same requirements for users who do not run the helper.

#### Scenario: Missing tool
- **WHEN** a required tool is not installed
- **THEN** the helper exits non-zero, names the tool, and makes no changes

#### Scenario: Unsupported Omarchy
- **WHEN** the Omarchy plugin commands are not available
- **THEN** the helper exits non-zero with a message saying the plugin needs Omarchy's shell plugin support

### Requirement: Clean uninstall
Removing the plugin with `omarchy plugin remove` SHALL leave no widget entry in the bar. The uninstall helper SHALL stop playback and remove the link it created, and only that, and SHALL be safe to run when the plugin is only partly installed or not installed.

#### Scenario: Full uninstall
- **WHEN** the user runs the uninstall helper and then removes the plugin with `omarchy plugin remove`
- **THEN** playback stops, the widget leaves the bar and the linked command is gone

#### Scenario: Nothing to remove
- **WHEN** the user runs the uninstall helper on a system without the link
- **THEN** it exits successfully and reports there was nothing to do

#### Scenario: Round trip
- **WHEN** the user adds and then removes the plugin
- **THEN** the bar layout and the rest of the user's configuration match their state before the install

## REMOVED Requirements

### Requirement: Idempotent install
**Reason**: The scripts no longer copy files or register the plugin; Omarchy's own `plugin add`, `plugin update` and `plugin remove` do, and they refuse a duplicate add.
**Migration**: Install with `omarchy plugin add <repository> --enable`, update with `omarchy plugin update`. The new "Installable as an Omarchy plugin" requirement carries the first-install and update behavior.
