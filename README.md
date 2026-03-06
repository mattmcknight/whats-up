# What's Up

A macOS menu bar app that makes sure you never miss a meeting again.

macOS Calendar notifications are easy to miss when you're deep in work. What's Up lives in your menu bar, counts down to your next meeting, and fires an aggressive alarm — flashing red panel, looping sound — that won't stop until you act on it.

## Features

- **Menu bar countdown** — Always-visible timer to your next meeting, with color that shifts from green → yellow → red as it approaches
- **Meeting alarm** — Flashing red always-on-top panel with looping sound when a meeting starts
- **Zoom auto-launch** — Detects Zoom links in your calendar events and opens them with one click
- **In-person meetings** — "On My Way" button for meetings without a Zoom link
- **Skip/dismiss** — Skip meetings you don't need to attend; alarm won't re-fire
- **Today's agenda** — Click the menu bar icon to see all remaining meetings
- **Current task** — Simple text field to track what you're working on (persists across launches)
- **Calendar sync** — Reads from macOS Calendar via EventKit, so it works with Google Calendar, Microsoft 365, or any calendar synced to your Mac

## Requirements

- macOS 14.0+
- Xcode 16.0+ (for building)
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Install

### From source

```bash
# Clone
git clone https://github.com/mattmcknight/whats-up.git
cd whats-up

# Generate Xcode project and build
cd WhatsUp
xcodegen generate
xcodebuild -project WhatsUp.xcodeproj -scheme WhatsUp -configuration Release build

# Copy to Applications
cp -R ~/Library/Developer/Xcode/DerivedData/WhatsUp-*/Build/Products/Release/WhatsUp.app ~/Applications/
```

### Launch

```bash
open ~/Applications/WhatsUp.app
```

On first launch, grant calendar access when prompted.

### Start on login

System Settings → General → Login Items → add WhatsUp.

## Development

```bash
cd WhatsUp

# Regenerate Xcode project after changing project.yml
xcodegen generate

# Build (debug)
xcodebuild -project WhatsUp.xcodeproj -scheme WhatsUp -configuration Debug build

# Run
open ~/Library/Developer/Xcode/DerivedData/WhatsUp-*/Build/Products/Debug/WhatsUp.app
```

Or open `WhatsUp.xcodeproj` in Xcode.

## How it works

The app polls macOS Calendar (EventKit) every 5 minutes and ticks every second to update the countdown. When a meeting's start time passes:

1. An always-on-top red flashing panel appears
2. An alarm sound loops every 8 seconds
3. The panel shows "Join Zoom" (if a Zoom link is detected) or "On My Way" (for in-person meetings)
4. The alarm continues until you click Join, On My Way, or Skip

Zoom links are detected by scanning the event's URL, location, and notes fields for `zoom.us` URLs.

At midnight, the app resets and fetches the new day's schedule.
