# Spec Delta

## Purpose

Installs and removes the plugin on an Omarchy system safely, so users can adopt it or drop it without hand-editing dotfiles or losing their own configuration.

## ADDED Requirements

### Requirement: Idempotent install
The installer SHALL place the command-line tool, the station list and the shell plugin so that they work, and running it again SHALL change nothing that is already correct.

#### Scenario: First install
- **WHEN** the user runs the installer on a system without the plugin
- **THEN** the command is on the user's PATH, the plugin is registered and enabled, and the widget appears in the bar

#### Scenario: Repeat install
- **WHEN** the user runs the installer a second time
- **THEN** it succeeds without duplicating bar entries, files or links

#### Scenario: Update in place
- **WHEN** the repo has changed and the user runs the installer again
- **THEN** the installed files reflect the new versions

### Requirement: Non-destructive to user configuration
The installer SHALL NOT overwrite or truncate the user's existing configuration. Changes to shell configuration SHALL be made only through Omarchy's own commands, and the installer SHALL refuse to replace an existing file it did not create.

#### Scenario: Existing bar layout
- **WHEN** the user has a customized bar layout
- **THEN** it is preserved and the widget is added alongside the existing widgets

#### Scenario: Name collision
- **WHEN** a different file already exists at an install path and was not created by this installer
- **THEN** the installer stops with an error and leaves that file untouched

### Requirement: Prerequisite check
The installer SHALL verify that the required tools and an Omarchy shell with plugin support are present before changing anything, and SHALL list what is missing.

#### Scenario: Missing tool
- **WHEN** a required tool is not installed
- **THEN** the installer exits non-zero, names the tool, and makes no changes

#### Scenario: Unsupported Omarchy
- **WHEN** the Omarchy plugin commands are not available
- **THEN** the installer exits non-zero with a message saying the plugin needs Omarchy's shell plugin support

### Requirement: Clean uninstall
The uninstaller SHALL stop playback, disable and remove the widget, and delete only the files the installer created, leaving all other user configuration intact. It SHALL be safe to run when the plugin is only partly installed or not installed.

#### Scenario: Full uninstall
- **WHEN** the user runs the uninstaller after an install
- **THEN** playback stops, the widget leaves the bar, and the installed command and plugin are gone

#### Scenario: Nothing to remove
- **WHEN** the user runs the uninstaller on a system without the plugin
- **THEN** it exits successfully and reports there was nothing to do

#### Scenario: Round trip
- **WHEN** the user installs and then uninstalls
- **THEN** the bar layout and the rest of the user's configuration match their state before the install
