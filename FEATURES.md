# Kaizen OS — Feature Guide

Everything the app can do, and how it works. Last updated: 2026-03-22.

---

## Habits

### Building a Habit
- Give your habit a name, pick an emoji from the quick-select grid — or open your iOS emoji keyboard and type any emoji you want
- Habits are private, offline, and never leave your device

### Scheduling
- **Every day** — habit appears in your list daily (default)
- **Specific days** — choose which days of the week (e.g. Mon/Wed/Fri only)
- Rest days don't count against you — the app knows the difference between a day off and a missed day

### Streaks & How They're Counted
- A streak counts how many consecutive *scheduled* days you've completed a habit
- **Rest days are skipped** — if your habit runs Mon–Fri, Saturday and Sunday are invisible to the streak counter
- **Skipped days are skipped** — intentionally skipping a day doesn't break your streak either
- Your streak only resets if you miss a day you were actually supposed to do the habit
- Longest streak is also tracked so you can see your personal best
- Streaks are calculated live — nothing is stored that could get out of sync

### Duration / Challenges
- **Forever** — habit runs indefinitely (default)
- **21 days** — classic habit-formation challenge
- **90 days** — deep commitment challenge
- **1 year** — long-term lifestyle habit
- **Custom** — pick any end date you want
- When a challenge ends, the habit auto-retires. Your history is preserved — you can review past data but the habit no longer shows in your daily list
- A countdown badge ("18d left", "1d left", "🎉 Done!") appears on the habit row

### Habit Lifecycle — Full Control
Long-press any habit row to see all options:

| Action | What it does |
|--------|-------------|
| **Edit Habit** | Change name, emoji, schedule, reminder, duration |
| **Skip Today** | Mark today as intentionally skipped — streak stays intact |
| **Undo Skip** | Remove the skip if you changed your mind |
| **Pause…** | Pick a resume date — habit goes dormant, all scheduled days auto-skipped, streak frozen |
| **Resume Now** | End the pause early — habit returns immediately |
| **Retire Habit** | Hide from daily list, all history preserved, recoverable |
| **Delete & Erase History** | Permanently remove habit + every completion record |

You can also swipe left on a habit row for quick Edit / Retire.

### Retired Habits
- Retired habits appear in a collapsible "RETIRED" section at the bottom of the Habits tab
- Tap **Restore** to bring a habit back to your active list
- Tap the trash icon to permanently delete it

### Reminders
- Toggle a reminder on per habit
- Set the exact time you want to be notified
- Choose how early to be notified: at the time, 5 min before, 10 min before, 15 min before, or 30 min before
- You can select **multiple lead times** (e.g. both 10 min before AND at time — two separate notifications)
- Reminders automatically fire **only on the days the habit is scheduled** — no alerts on rest days or during a pause

### Habit Limit
- **Free:** up to 5 active habits
- **Premium:** unlimited habits

### Past Date Editing
- Use the ◀ ▶ arrows above the habit list to navigate to any past date
- Tap a habit to mark/unmark completion for that day — useful if you forgot to check off

---

## Heatmap

- Shows your habits at a glance in three zoom levels
- **Week view** — 7 large cells, completion fill bar per day, percentage label
- **Month view** — full calendar grid, date numbers in each cell, today highlighted
- **Year view** — GitHub-style contribution graph for the entire year
  - Teal = all habits done that day
  - Teal 45% = some done
  - Orange = had habits, none done
  - Dim = no habit data
- Navigate between periods with ◀ ▶ arrows
- Tap any day in year view to jump to that date

---

## Habit Analysis

- Scroll below your habit list to see the Analysis section
- Each active habit shows a **30-day completion rate bar** (based on scheduled days only — rest days excluded)
- Color-coded performance: teal ≥70%, orange 40–69%, coral <40%
- Sorted highest to lowest so you can see what's sticking vs what needs attention

---

## Habit Templates

- Tap **Templates** next to the + button
- 20 pre-built habits across 5 categories: Health, Fitness, Mind, Focus, Finance
- Tapping a template pre-fills the name and emoji in the Add Habit form — edit everything before saving

---

## Tasks

### Adding Tasks
- Tap + to add a task; give it a title and optionally a description (shopping list, agenda, instructions, anything)
- Assign a priority: **Top 3** (your most important tasks) or **Normal**
- Assign a category: Work, Health, Planning, Personal, Finance, Other
- Pick any date — past, today, or future

### Calendar Views
Switch between three views using the toggle at the top:

- **Week** — 7-day strip, ◀ ▶ to move weeks, dot indicator shows days with tasks
- **Month** — full calendar grid, ◀ ▶ to move months, dot indicators
- **Year** — GitHub-style contribution graph
  - Teal = all tasks completed
  - Teal 45% = partially done
  - Orange = tasks exist, none done
  - Dim = no tasks
- Tapping any cell in any view jumps to that day's task list

### Top 3 Priority System
- Mark up to 3 tasks as Top 3 — they appear in a highlighted teal card at the top
- The idea: pick the 3 most important things each day and do those first
- Progress bar shows what fraction of the selected day's tasks are done

### Task Notes
- Add a description to any task during creation
- Notes appear as a 2-line preview below the task title in the list

---

## Today's Note

- A freeform daily scratchpad — brain dump, reminders, anything on your mind
- Lives on the **Dashboard** as an orange card (no need to go to Mindset tab)
- Tap the card to expand it inline and start typing — no separate screen
- "Done" button (or drag the scroll view) dismisses the keyboard and saves instantly
- Shows a preview of your note when not editing; "Tap to add a note…" if empty
- One note per day, automatically linked to that day's mindset log

---

## Mindset Check-In

- Log how you're feeling each day: **Energy**, **Focus**, **Mood** (each 0–100)
- Animated custom slider bars (no system Slider — fully custom)
- Your overall score = average of the three, shown as a ring
- One log per day — opening Mindset again on the same day updates it

### Health Tracking (manual)
- **Sleep** — slider, 0–12 hours in 0.5 steps
- **Wake time** — time picker (hour + minute)
- **Steps** — numeric text field (optional)

### HealthKit Sync (Premium)
- Tap "Sync from Health" to auto-fill sleep, wake time, and steps from Apple Health
- Requires HealthKit permission on first use
- Data is read-only — nothing is written back to Health

---

## Dashboard

- **Personalised greeting** — "Good morning, [Your Name]!" changes based on time of day
- **Avatar** — tap the avatar in the top-right to choose from 18 emoji (people, animals, fun icons); shows your initial if no emoji is picked
- **Day score ring** — percentage of today's habits done, with a glow effect
- **Stats row** — Best Streak (🔥), This Week % (📊), Total Wins (⚡)
- **Today's Note card** — tap to write inline, "Done" saves and collapses
- **Today's Habits preview** — tap any habit to toggle it without leaving Dashboard
- **Mindset CTA** — "Log now" banner to jump straight to check-in

---

## Widgets

- **Small widget** — day score ring with percentage
- **Medium widget** — day score ring + current top streak
- Add from your home screen: long-press → Widgets → Kaizen OS
- Widget data updates when you use the app

---

## Notifications

### Per-Habit Reminders
- Set per habit in the Add/Edit Habit form
- Fires only on scheduled days (rest days and paused periods = no alert)
- Multiple lead times per habit supported

### Daily Check-In Reminder
- One daily nudge to open the app and log your mindset
- Toggle on/off and set the time in **Settings → Notifications**

---

## Settings

- View and edit your profile name
- Premium status and purchase/restore
- Notifications: daily reminder on/off + time
- App version info

---

## Premium ($4.99, one-time)

| Feature | Free | Premium |
|---------|------|---------|
| Active habits | 5 max | Unlimited |
| Tasks | Unlimited | Unlimited |
| Mindset tracking | Full | Full |
| Today's Note | Yes | Yes |
| Health (manual) | Yes | Yes |
| HealthKit auto-sync | — | ✓ |
| Rich widget (ring + streak) | — | ✓ |
| CSV export | — | Coming soon |

- One-time purchase, no subscription, no recurring charges
- Unlocks instantly after purchase
- Restore purchases available in Settings if you reinstall

---

## Privacy

- **100% offline** — no account, no server, no cloud sync required
- All data lives only on your device in SwiftData (Apple's local database)
- HealthKit data is read-only — it fills today's health card and is never stored permanently
- Deleting the app deletes all data

---

## Principles

### Habits aren't always daily
A habit is a recurring behaviour at a regular interval — not necessarily every day. Kaizen OS respects this:
- You define the schedule; the app holds you to *that* schedule, not a daily one
- Missing a rest day never penalises you
- Intentionally skipping a day never penalises you
- Your streak reflects real consistency with your own commitment

### Streaks measure scheduled consistency
A 14-day streak on a Mon/Wed/Fri habit means you've completed it 14 consecutive times on the days you committed to — exactly as meaningful as a 14-day daily streak.

### Nothing is over-counted
Completion rates use *scheduled non-skipped days* as the denominator. A Mon–Fri habit where you hit every session shows 100%, not 71%.

### You own your history
Retiring a habit hides it from your daily flow but keeps every data point. You can restore it or permanently delete it — your choice, your data.
