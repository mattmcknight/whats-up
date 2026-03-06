---
shaping: true
---

# What's Up - Shaping

## Requirements (R)

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | Always-visible indicator of what I should be doing right now | Core goal |
| R1 | When a meeting is active, aggressively escalate: sound, flashing, color change - alarm-style | Must-have |
| R2 | Auto-launch Zoom link when meeting starts | Must-have |
| R3 | Show current/next meeting from calendar | Must-have |
| R4 | Pull calendar data from macOS Calendar (has both M365 and Gmail synced) | Must-have |
| R5 | Works when absorbed - must break through focus, not sit passively | Must-have |
| R6 | Keep alarming until I actually join (Zoom) or acknowledge (in-person) | Must-have |
| R7 | Distinguish Zoom vs in-person meetings - Zoom auto-launches, in-person just needs acknowledgment | Must-have |
| R8 | Snooze/dismiss for meetings I intentionally skip | Must-have |
| R9 | macOS native | Must-have |
| R10 | Basic "currently working on" display | Nice-to-have |
| R11 | Task queue / order-up style view | Nice-to-have |

---

## Shapes Considered

### A: SwiftUI Menu Bar App (Selected)

Native macOS menu bar app. Calm icon shows next meeting countdown. At meeting time, spawns an always-on-top floating panel with alarm sound.

| Part | Mechanism |
|------|-----------|
| **A1** | Menu bar icon with countdown to next meeting |
| **A2** | Click menu bar -> dropdown shows agenda, current task |
| **A3** | At meeting time: floating always-on-top panel (red, flashing) + alarm sound |
| **A4** | Panel has Join Zoom / Acknowledge (in-person) / Skip buttons |
| **A5** | Zoom detection: parse event URL/notes for Zoom links, auto-launch on Join |
| **A6** | Read events via macOS EventKit framework (native Calendar API) |
| **A7** | Alarm loop: sound repeats + panel pulses until interacted with |

### B: Persistent Screen-Edge Bar (Electron) - Not selected

Thin bar pinned to top of screen. Calendar access via icalBuddy (flagged unknown). Failed R4 - unreliable calendar access.

### C: Python Daemon + Native macOS Alerts - Not selected

Lightweight background daemon using osascript. Failed R0, R1, R5, R6 - no persistent UI, uncertain alarm mechanisms.

---

## Fit Check: R x A

| Req | Requirement | Status | A |
|-----|-------------|--------|---|
| R0 | Always-visible indicator of what I should be doing right now | Core goal | Pass |
| R1 | Aggressively escalate: sound, flashing, color change, alarm-style | Must-have | Pass |
| R2 | Auto-launch Zoom link when meeting starts | Must-have | Pass |
| R3 | Show current/next meeting from calendar | Must-have | Pass |
| R4 | Pull from macOS Calendar (M365 + Gmail synced) | Must-have | Pass |
| R5 | Break through focus - not passive | Must-have | Pass |
| R6 | Keep alarming until join/acknowledge | Must-have | Pass |
| R7 | Distinguish Zoom vs in-person | Must-have | Pass |
| R8 | Snooze/dismiss for intentional skips | Must-have | Pass |
| R9 | macOS native | Must-have | Pass |
| R10 | Basic "currently working on" display | Nice-to-have | Pass |
| R11 | Task queue / order-up style view | Nice-to-have | Pass |

All requirements addressed. No flagged unknowns.

---

## Detail A: Breadboard

### Places

| # | Place | Description |
|---|-------|-------------|
| P1 | Menu Bar Icon | Always-visible icon + countdown text in macOS menu bar |
| P2 | Menu Bar Popover | Click menu bar icon -> popover with agenda and current task |
| P3 | Alarm Panel | Always-on-top floating window, appears when meeting is active |
| P4 | Background | Timer loop, calendar polling, sound - no UI |

### UI Affordances

| # | Place | Affordance | Control | Wires Out | Returns To |
|---|-------|------------|---------|-----------|------------|
| U1 | P1 | Menu bar icon (SF Symbol: calendar/clock) | render | - | - |
| U2 | P1 | Countdown text ("12m" / "NOW") | render | - | - |
| U3 | P1 | Icon color (green -> yellow -> red) | render | - | - |
| U4 | P1 | Click menu bar icon | click | -> P2 | - |
| U5 | P2 | Next meeting card (title, time, location) | render | - | - |
| U6 | P2 | Today's remaining meetings list | render | - | - |
| U7 | P2 | "Currently working on" text field | type | -> N12 | - |
| U8 | P2 | Meeting row | click | -> N8 | - |
| U9 | P2 | Quit button | click | -> N13 | - |
| U10 | P3 | Meeting title (large) | render | - | - |
| U11 | P3 | Meeting time + "started X min ago" | render | - | - |
| U12 | P3 | Flashing red background | render | - | - |
| U13 | P3 | "Join Zoom" button (Zoom meetings only) | click | -> N9 | - |
| U14 | P3 | "On my way" button (in-person meetings only) | click | -> N10 | - |
| U15 | P3 | "Skip" button | click | -> N11 | - |
| U16 | P3 | Meeting type badge ("Zoom" / "In-person") | render | - | - |

### Code Affordances

| # | Place | Affordance | Control | Wires Out | Returns To |
|---|-------|------------|---------|-----------|------------|
| N1 | P4 | `CalendarService.fetchEvents()` - EventKit query for today's events | call | - | -> S1 |
| N2 | P4 | `CalendarService.pollTimer` - re-fetch every 5 min | timer | -> N1 | - |
| N3 | P4 | `MeetingMonitor.tick()` - every-second timer, checks S1 against now | timer | -> N4, -> N5 | -> U2, U3 |
| N4 | P4 | `MeetingMonitor.shouldAlarm()` - meeting started + not acknowledged? | call | -> N5 | - |
| N5 | P4 | `AlarmController.trigger()` - show P3, start sound loop | call | -> P3, -> N6 | - |
| N6 | P4 | `SoundPlayer.loopAlarm()` - repeating alert sound | call | - | - |
| N7 | P4 | `ZoomDetector.extractLink(event)` - parse URL from event notes/location/URL field | call | - | -> S2 |
| N8 | P2 | `joinMeeting(event)` - manual join from popover row | call | -> N9 or -> N14 | - |
| N9 | P3 | `joinZoom()` - open Zoom link via `NSWorkspace.open()`, dismiss alarm | call | -> N15, -> N6 | - |
| N10 | P3 | `acknowledgeMeeting()` - mark as acknowledged, dismiss alarm | call | -> N15 | - |
| N11 | P3 | `skipMeeting()` - mark as skipped, dismiss alarm | call | -> N15 | - |
| N12 | P2 | `TaskStore.setCurrentTask(text)` | call | -> S3 | - |
| N13 | P2 | `NSApp.terminate()` | call | - | - |
| N14 | - | `NSWorkspace.open(url)` - opens Zoom link in browser/app | call | - | - |
| N15 | P4 | `AlarmController.dismiss()` - hide P3, stop sound, update S4 | call | -> S4 | - |

### Data Stores

| # | Place | Store | Description |
|---|-------|-------|-------------|
| S1 | P4 | `todayEvents: [CalendarEvent]` | Today's events from EventKit, refreshed on poll |
| S2 | P4 | `zoomLinks: [EventID: URL]` | Extracted Zoom links keyed by event |
| S3 | P2 | `currentTask: String` | Free-text "currently working on" |
| S4 | P4 | `eventState: [EventID: State]` | Per-event state: pending / joined / acknowledged / skipped |
