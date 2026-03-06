---
shaping: true
---

# What's Up - Slices

## Slice Summary

| # | Slice | Parts | Demo |
|---|-------|-------|------|
| V1 | Menu bar with countdown | A1, A6 | "Icon in menu bar counts down to next meeting, color shifts green->yellow->red" |
| V2 | Popover with agenda | A2 | "Click icon, see today's schedule with next meeting highlighted" |
| V3 | Alarm fires | A3, A7 | "Meeting starts -> red flashing panel + alarm sound -> click 'On My Way' to dismiss" |
| V4 | Zoom detection + join | A5 | "Zoom meeting shows 'Join Zoom' button, clicking opens Zoom app" |
| V5 | Current task + manual join | A2, A4 | "Type what you're working on in popover, click any meeting to join it" |

V1-V3 = core (working meeting alarm). V4 = Zoom convenience. V5 = phase-two nice-to-have.

---

## V1: Menu Bar with Countdown

The foundation. Gets EventKit working, proves the timer loop, puts something visible in the menu bar.

### Affordances

| # | Affordance | Control | Wires Out | Returns To |
|---|------------|---------|-----------|------------|
| U1 | Menu bar icon | render | - | - |
| U2 | Countdown text ("12m" / "NOW") | render | - | - |
| U3 | Icon color (green->yellow->red) | render | - | - |
| N1 | `fetchEvents()` - EventKit query | call | - | -> S1 |
| N2 | `pollTimer` (5 min) | timer | -> N1 | - |
| N3 | `tick()` (every sec) | timer | - | -> U2, U3 |
| S1 | `todayEvents` | store | - | -> N3 |

### Demo

"Look at the menu bar - it says 12m until my next meeting. Watch the color change as it gets closer."

---

## V2: Popover with Agenda

Click the icon, see your day. No alarm yet - just awareness.

### Affordances

| # | Affordance | Control | Wires Out | Returns To |
|---|------------|---------|-----------|------------|
| U4 | Click menu bar icon | click | -> P2 | - |
| U5 | Next meeting card | render | - | - |
| U6 | Today's remaining meetings list | render | - | - |
| U9 | Quit button | click | -> N13 | - |
| N13 | `NSApp.terminate()` | call | - | - |

### Demo

"Click the icon - here's my next meeting at 2pm, and the rest of my day below it."

---

## V3: Alarm Fires

The core value. This is the slice that solves the actual problem.

### Affordances

| # | Affordance | Control | Wires Out | Returns To |
|---|------------|---------|-----------|------------|
| U10 | Meeting title (large) | render | - | - |
| U11 | Time + "started X min ago" | render | - | - |
| U12 | Flashing red background | render | - | - |
| U14 | "On My Way" button | click | -> N10 | - |
| U15 | "Skip" button | click | -> N11 | - |
| U16 | Meeting type badge | render | - | - |
| N4 | `shouldAlarm()` | call | -> N5 | - |
| N5 | `AlarmController.trigger()` | call | -> P3, -> N6 | - |
| N6 | `SoundPlayer.loopAlarm()` | call | - | - |
| N10 | `acknowledgeMeeting()` | call | -> N15 | - |
| N11 | `skipMeeting()` | call | -> N15 | - |
| N15 | `AlarmController.dismiss()` | call | -> S4 | - |
| S4 | `eventState` | store | - | -> N4 |

### Demo

"It's 2pm - alarm fires, red panel flashing, sound blaring. I click 'On My Way', it stops. Next meeting at 3pm, I click 'Skip', it stops and doesn't re-alarm."

---

## V4: Zoom Detection + Join

Upgrades the alarm panel for Zoom meetings - the auto-launch promise.

### Affordances

| # | Affordance | Control | Wires Out | Returns To |
|---|------------|---------|-----------|------------|
| U13 | "Join Zoom" button | click | -> N9 | - |
| N7 | `extractZoomLink(event)` | call | - | -> S2 |
| N9 | `joinZoom()` | call | -> N14, -> N15 | - |
| N14 | `NSWorkspace.open(url)` | call | - | - |
| S2 | `zoomLinks` | store | - | -> U16, N9 |

### Demo

"Alarm fires for my Zoom standup - panel shows 'Join Zoom' instead of 'On My Way'. Click it, Zoom opens, alarm dismisses."

---

## V5: Current Task + Manual Join

The nice-to-have layer - ambient task awareness and convenience joins from the popover.

### Affordances

| # | Affordance | Control | Wires Out | Returns To |
|---|------------|---------|-----------|------------|
| U7 | "Working on" text field | type | -> N12 | - |
| U8 | Meeting row click | click | -> N8 | - |
| N8 | `joinMeeting(event)` | call | -> N14 or -> N10 | - |
| N12 | `setCurrentTask(text)` | call | -> S3 | - |
| S3 | `currentTask` | store | - | -> U7 |

### Demo

"I type 'fixing auth bug' in the popover - it shows under the countdown. I click my 3pm meeting to join early."
