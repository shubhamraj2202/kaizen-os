# Kaizen OS — Feature Guide

Everything the app can do, and how it works.

---

## Habits

### Building a Habit
- Give your habit a name, pick an emoji from the quick-select grid or type any emoji from your keyboard
- Habits are private, offline, and never leave your device

### Scheduling
- **Every day** — habit appears in your list daily (default)
- **Specific days** — choose which days of the week (e.g. Mon/Wed/Fri only)
- Rest days don't count against you — the app knows the difference between a day off and a missed day

### Streaks & How They're Counted
- A streak counts how many consecutive *scheduled* days you've completed a habit
- **Rest days are skipped** — if your habit runs Mon–Fri, Saturday and Sunday don't break your streak
- Your streak only resets if you miss a day you were actually supposed to do the habit
- Longest streak is also tracked so you can see your personal best
- Streaks are calculated live — nothing is stored that could get out of sync

### Duration / Challenges
- **Forever** — habit runs indefinitely (default)
- **21 days** — classic habit-formation challenge
- **90 days** — deep commitment challenge
- **1 year** — long-term lifestyle habit
- **Custom** — pick any end date you want
- When a challenge ends, the habit auto-archives. Your history is preserved — you can review past data but the habit no longer shows in your daily list

### Reminders
- Toggle a reminder on per habit
- Set the exact time you want to be notified
- Choose how early: at the time, 5 min before, 10 min before, 15 min before, or 30 min before
- You can select multiple lead times (e.g. both 10 min before AND at time)
- Reminders automatically fire only on the days the habit is scheduled — no alerts on rest days

### Habit Limit
- **Free:** up to 5 active habits
- **Premium:** unlimited habits

### Editing & Archiving
- Swipe left on any habit row to edit or archive it
- Archived habits disappear from your daily list but their history is kept
- Edit any habit at any time — name, emoji, schedule, duration, reminder

### Past Date Editing
- Use the ◀ ▶ arrows above the habit list to navigate to any past date
- Tap a habit to mark/unmark completion for that day — useful if you forgot to check off

---

## Heatmap

- Shows your current calendar month at a glance
- Each cell = one day; color shows how many habits you completed
- Navigate between Week / Month / Year views
- **Year view** — GitHub-style contribution graph for the full year, color-coded by completion

---

## Habit Analysis

- Scroll below your habit list to see the Analysis section
- Each active habit shows a completion rate bar (last 30 scheduled days)
- Color-coded: teal = strong (≥70%), orange = building (40–69%), coral = needs work (<40%)
- Sorted highest to lowest so you can see what's sticking

---

## Habit Templates

- Tap "Templates" next to the + button
- 20 pre-built habits across 5 categories: Health, Fitness, Mind, Focus, Finance
- Tapping a template pre-fills the name and emoji in the Add Habit form — you can still edit everything before saving

---

## Tasks

### Adding Tasks
- Tap + to add a task; give it a title and optionally a description/notes
- Assign a priority: **Top 3** (your most important tasks) or **Normal**
- Assign a category: Work, Health, Planning, Personal, Finance, Other
- Pick a date — tasks can be scheduled for today, tomorrow, next week, or any past date

### Calendar Views
- Switch between **Week**, **Month**, and **Year** views using the toggle at the top
- Week view: 7-day strip, navigate with ◀ ▶
- Month view: full calendar grid
- Year view: contribution graph, color shows how many tasks you completed each day
- Tapping any day in any view jumps to that day's task list

### Top 3 Priority System
- Mark up to 3 tasks as Top 3 — these appear in a highlighted card at the top
- The idea: pick your 3 most important tasks each day and do those first
- Progress bar shows how many tasks for the selected day are done

### Task Notes
- Add a description to any task (e.g. a shopping list, meeting agenda, instructions)
- Notes appear below the task title in the list as a 2-line preview

---

## Mindset Check-In

- Log how you're feeling each day: Energy, Focus, Mood (each 0–100)
- Add a free-text note if you want to capture what's on your mind
- Your overall score = average of the three (shown as a ring on the dashboard)
- One log per day — opening Mindset again on the same day lets you update it

### Health Tracking
- **Sleep:** log how many hours you slept (slider, 0–12 hrs, 0.5 step)
- **Wake time:** log what time you woke up
- **Steps:** manually enter your step count

### HealthKit Sync (Premium)
- Premium users can tap "Sync from Health" to auto-fill sleep, wake time, and steps from the Apple Health app
- Requires HealthKit permission (prompted on first use)

---

## Dashboard

- **Day score ring** — percentage of today's habits completed
- **Habit preview** — tap any habit row to toggle it directly from the dashboard
- **Streak card** — your longest active streak across all habits
- **Mindset ring** — today's overall mindset score
- Tap "See all →" to jump to the full Habits tab
- Tap "Log now" to jump to Mindset check-in

---

## Widgets

- **Small widget** — shows your day score ring
- **Medium widget** — shows day score ring + current top streak
- Add via long-press on your home screen → Widgets → Kaizen OS

---

## Notifications

### Per-Habit Reminders
- Set individually on each habit
- Fires only on days the habit is scheduled (rest days = no alert)
- Supports multiple lead times per habit

### Daily Check-In Reminder
- A single daily nudge to open the app and log your mindset
- Toggle on/off and set the time in Settings → Notifications

---

## Premium ($4.99, one-time)

| Feature | Free | Premium |
|---------|------|---------|
| Active habits | 5 max | Unlimited |
| Tasks | Unlimited | Unlimited |
| Mindset tracking | Full | Full |
| Health (manual) | Yes | Yes |
| HealthKit sync | — | Yes |
| Rich widget | — | Yes |
| CSV export | — | Coming soon |

- One-time purchase, no subscription
- Unlocks immediately after purchase
- Restore purchases available in Settings

---

## Privacy

- **100% offline** — no account, no server, no cloud sync
- All data lives only on your device
- HealthKit data is read-only and never stored in the app's database — it's used to fill in today's log and that's it
- Deleting the app deletes all data

---

## Principles

### Habits aren't always daily
A habit is a recurring behaviour at a regular interval — not necessarily every single day. Kaizen OS respects this:
- You define the schedule; the app holds you to *that* schedule, not a daily one
- Missing a rest day never penalises you
- Your streak reflects real consistency, not calendar compliance

### Streaks measure scheduled consistency
A 14-day streak on a Mon/Wed/Fri habit means you've done it 14 times in a row on the days you committed to — which is exactly as meaningful as a 14-day daily streak on an every-day habit.

### Nothing is over-counted
Completion rates look at your *scheduled* days in the window, not all calendar days. A Mon–Fri habit where you hit every session shows 100%, not 71%.
