# Kaizen OS — Claude Code Context

This file provides Claude Code with project context, coding patterns, and constraints for the Kaizen OS iOS app.

## Project Summary

**App:** Kaizen OS (iOS 17+, SwiftUI + SwiftData)
**Purpose:** Native daily life OS for habits, tasks, and mindset tracking
**Bundle ID:** com.shubh.kaizenos
**Monetization:** Free (5 habits max) → $4.99 premium unlock via StoreKit 2

## Tech Stack (Non-Negotiable)

- **UI Framework:** SwiftUI (iOS 17+) — use `@Observable` macro, never `ObservableObject`
- **Data Persistence:** SwiftData only — NO CoreData
- **State Management:** `@Observable` macro with `@Query` for fetching
- **External Packages:** ZERO — no CocoaPods, no SPM dependencies
- **Icons:** SF Symbols only
- **Backend:** None — fully offline-first
- **Notifications:** UserNotifications framework
- **IAP:** StoreKit 2

## Hard Constraints

1. **NO CoreData** — SwiftData models only
2. **NO ObservableObject** — @Observable macro only
3. **NO third-party packages** — build everything natively
4. **NO network calls** — except StoreKit receipt validation
5. **Streak logic** — always use `Calendar.current.startOfDay(for:)` for date comparison
6. **Computed properties only** — never persist streak, score, or completion rate to DB
7. **Free tier:** Enforce 5-habit hard cap before insert in ViewModel
8. **Dark mode only** — no light mode in v1

## Architecture Pattern

```
Models/          → @Model classes (Habit, HabitEntry, DailyTask, MindsetLog, UserProfile)
Views/           → SwiftUI views organized by feature
ViewModels/      → @Observable classes handling business logic
Helpers/         → Utility functions (DateHelpers, StoreKitManager, NotificationManager)
Widgets/         → WidgetKit files
```

### Data Flow

1. **Views** → @Observable ViewModels (business logic)
2. **ViewModels** → @Query/@Environment ModelContext (SwiftData)
3. **Models** → Relationships with @Relationship(deleteRule: .cascade)
4. **Entry Point** → KaizenOSApp.swift sets up ModelContainer

## SwiftData Models

### Core Models

- **Habit:** Name, emoji, colorHex, isActive, reminderTime, reminderDays, entries[]
  - Computed: `currentStreak`, `longestStreak`, `completionRate30Days`
  - Method: `isCompleted(on: Date) -> Bool`

- **HabitEntry:** date (startOfDay), isCompleted, completedAt, note
  - Methods: `complete()`, `uncomplete()`
  - Inverse relationship to Habit

- **DailyTask:** title, date, priority (top3/normal), category, isCompleted, completedAt
  - Enum: TaskPriority, TaskCategory
  - Method: `toggle()`

- **MindsetLog:** date (startOfDay), energy (0–100), focus (0–100), mood (0–100), note
  - Computed: `overallScore` = (energy + focus + mood) / 3

- **UserProfile:** name, isPremium, premiumPurchaseDate, onboardingCompleted, settings
  - Static: `freeHabitLimit = 5`

## Common Code Patterns

### Toggle Habit Today
```swift
func toggleHabit(_ habit: Habit, context: ModelContext) {
    let today = Calendar.current.startOfDay(for: Date())
    if let existing = habit.entries.first(where: {
        Calendar.current.startOfDay(for: $0.date) == today
    }) {
        existing.isCompleted ? existing.uncomplete() : existing.complete()
    } else {
        let entry = HabitEntry(date: today, habit: habit)
        entry.complete()
        context.insert(entry)
    }
    try? context.save()
}
```

### Fetch Today's Tasks
```swift
var todayStart: Date { Calendar.current.startOfDay(for: Date()) }
var todayEnd: Date { Calendar.current.date(byAdding: .day, value: 1, to: todayStart)! }

@Query var allTasks: [DailyTask]
var todaysTasks: [DailyTask] {
    allTasks
        .filter { $0.date >= todayStart && $0.date < todayEnd }
        .sorted { $0.sortOrder < $1.sortOrder }
}
```

### Calculate Day Score
```swift
var dayScore: Double {
    let active = habits.filter { $0.isActive }
    guard !active.isEmpty else { return 0 }
    let done = active.filter { $0.isCompleted(on: Date()) }.count
    return Double(done) / Double(active.count)
}
```

### Enforce Free Tier Limit
```swift
guard !profile.isPremium, activeHabits.count >= UserProfile.freeHabitLimit else {
    // Can proceed
    return
}
// Present PaywallView as .sheet
```

## Design System

### Colors (Reference: kaizenos-ui.jsx)
```
Primary:    #00E5C8 (teal, checkmarks, rings)
Secondary:  #6450FF (purple, mindset)
Warning:    #FF6B6B (coral, incomplete)
Accent:     #FF8C42 (orange, energy, streaks)

Backgrounds:
  Primary:   #090E1A
  Card:      #0D1321
  Elevated:  #141C2E

Text:
  Primary:   #FFFFFF
  Secondary: #FFFFFF80 (50% opacity)
  Tertiary:  #FFFFFF4D (30% opacity)

Borders:    #FFFFFF12 (7% opacity)
```

### Spacing & Sizing
- Screen padding: 20pt horizontal
- Card padding: 16–20pt
- Card radius: 24pt
- Row radius: 20pt
- Button radius: 14pt
- Gap between elements: 10pt

### Typography
- Hero numbers: .black, 32+ pt
- Section titles: .bold, 26pt
- Row labels: .semibold, 15pt
- Captions: .medium, 12pt
- System font: SF Pro

## Tab Structure

```
Tab 1: Dashboard  (house.fill)    — Day score ring, stat cards, mindset CTA
Tab 2: Habits     (checkmark.circle.fill) — Heatmap grid, habit rows
Tab 3: Tasks      (list.bullet)   — Top 3 card, task list
Tab 4: Mindset    (waveform.path) — Sliders, ring row, trend chart
Tab 5: Settings   (gearshape.fill) — Profile, premium, notifications
```

## Feature Gates

### Free Tier
- Max 5 active habits (enforced hard cap)
- Unlimited tasks
- Full mindset tracking
- Basic widget (streak only)

### Premium ($4.99 one-time, Product ID: com.shubh.kaizenos.premium)
- Unlimited habits
- Rich widget
- HealthKit sync
- CSV export
- Product ID: `com.shubh.kaizenos.premium`

## Key Development Rules

1. **Dates:** Always use `Calendar.current.startOfDay(for:)` for comparisons
2. **Computed Values:** Never persist streak, score, or rates — calculate live
3. **Relationships:** Use `@Relationship(deleteRule: .cascade)` for habit entries
4. **Free Tier Check:** Always gate habit creation with `isPremium` check before inserting
5. **Dark Mode:** All colors assume dark background (no light mode support)
6. **Notifications:** Use UserNotifications framework, respect user permissions
7. **Testing:** Test streak logic, free tier enforcement, and date boundaries carefully

## File Structure Reference

```
KaizenOS/
├── KaizenOSApp.swift              # App entry, ModelContainer setup
├── ContentView.swift              # Root TabView
├── Models/
│   ├── Habit.swift
│   ├── HabitEntry.swift
│   ├── DailyTask.swift
│   ├── MindsetLog.swift
│   └── UserProfile.swift
├── Views/
│   ├── Dashboard/DashboardView.swift
│   ├── Habits/HabitTrackerView.swift
│   ├── Tasks/TaskListView.swift
│   ├── Mindset/MindsetView.swift
│   └── Settings/SettingsView.swift
├── ViewModels/
│   ├── HabitViewModel.swift
│   ├── TaskViewModel.swift
│   └── MindsetViewModel.swift
├── Helpers/
│   ├── DateHelpers.swift
│   ├── StoreKitManager.swift
│   └── NotificationManager.swift
└── Widgets/
    └── KaizenWidget.swift
```

## Code Style Guidelines

- Use trailing closures and SwiftUI view builders
- Prefer `guard` for early returns
- Use computed properties for derived data
- Keep ViewModels observable with `@Observable`
- Use `@Query` for SwiftData fetching
- Always call `try? context.save()` after mutations
- Group related properties and methods with `// MARK:`
- Use descriptive property names (prefer `reminderTime` over `time`)

## Testing Priorities

1. Streak calculation logic (edge cases: gaps, multiple completions)
2. Free tier enforcement (5-habit cap before insert)
3. Date boundary handling (start/end of day, month boundaries)
4. Habit completion status (toggle, uncomplete)
5. Task priority and category filtering
6. Mindset score calculation
7. Premium IAP validation

## Common Tasks for Claude Code

**Add a new habit:**
- Create HabitEntry in HabitViewModel
- Toggle isCompleted
- Save via ModelContext
- Update DashboardView

**Mark task complete:**
- Toggle DailyTask.isCompleted
- Update completedAt timestamp
- Recalculate day score
- Save changes

**Add mindset entry:**
- Create/fetch MindsetLog for today (one per day)
- Update energy, focus, mood
- Save via ModelContext

**Implement premium feature:**
- Check `profile.isPremium`
- If false, present PaywallView
- Use StoreKitManager for purchase
- Update UserProfile on success

## References

- **Design Source:** design/kaizenos-ui.jsx (all screen designs here)
- **Apple SwiftData Docs:** https://developer.apple.com/documentation/swiftdata
- **SwiftUI:** https://developer.apple.com/documentation/swiftui
- **StoreKit 2:** https://developer.apple.com/documentation/storekit

## Current State (as of 2026-03-22)

### What's fully built & working

#### Core App
- All 5 tabs: Dashboard, Habits, Tasks, Mindset, Settings
- SwiftData models: Habit, HabitEntry, DailyTask, MindsetLog, UserProfile

#### Habits
- Habit tracker with heatmap (Week / Month / Year views, date numbers, past-date editing)
- Habit templates (20 templates, 5 categories)
- Per-habit analysis bar chart (30-day completion rate, color-coded teal/orange/coral)
- Custom emoji picker (grid + free-type from keyboard)
- Duration / challenge mode (Forever / 21d / 90d / 1yr / Custom end date)
- Schedule: Every day or specific weekdays (M T W T F S S)
- Reminders: per-habit, time + multi-select lead time (At time / 5 / 10 / 15 / 30 min before)
- Reminder fires only on scheduled days (no alerts on rest days)
- Habit lifecycle: Skip Today, Pause (with resume date + auto-resume), Retire, Delete, Restore
- Edit existing habit: long-press context menu or swipe left
- Schedule-aware streaks: rest days never break streak; only missed scheduled days reset it
- Completion rate uses scheduled days as denominator (Mon–Fri habit can hit 100%)
- Auto-retire habits past their end date on app open

#### Tasks
- Task list with Week / Month / Year calendar (tappable cells, dot indicators)
- Future + past task scheduling (any date)
- Task notes/description field (shown inline below title)
- Top 3 priority system + category tags
- Progress bar for selected day
- Year view: GitHub-style contribution graph (teal=all done, partial, pending, empty)

#### Mindset
- Energy / Focus / Mood sliders (0–100) with animated custom bars
- Health card: sleep hours, wake time, steps (manual entry)
- HealthKit sync (premium): auto-fills sleep, steps, wake time from Apple Health
- 7-day ring row + weekly trend chart

#### Dashboard
- Day score ring (% of today's habits done)
- Stats row: best streak, this week %, total wins
- Today's habits preview (tap to toggle from Dashboard)
- Today's Note card: shows today's note, tap to edit inline, navigates to Mindset

#### Daily Note / Scratchpad
- One freeform note per day, stored on MindsetLog.note
- Visible on Dashboard as TodayNoteCard (orange accent)
- Also editable in Mindset tab

#### Infrastructure
- Notifications: per-habit reminders + daily check-in reminder
- StoreKit 2 paywall ($4.99, product ID: `com.shubh.kaizenos.premium`)
- WidgetKit: small + medium widget (day score ring + streak)
- FEATURES.md: user-facing feature documentation

### Pending manual Xcode steps
- App Groups (`group.com.shubh.kaizenos`) — add to both main target + widget extension via Signing & Capabilities (needed for widget live data)
- Bundle ID change: `com.shubh.kaizenos` → `com.shubh.zenshin` (App Store listing name is "Zenshin")

### App Store Connect
- App Apple ID: `6760590233`
- Current build: 7 (Xcode Cloud auto-builds on push to `main`)
- Last rejection fixed: ITMS-90683 `NSHealthUpdateUsageDescription` missing (commit `091f913`)
- Build 7 resubmitted — awaiting result

### Next priorities (approved, pending implementation)
1. **Keyboard dismiss bug** — note TextField traps keyboard, tabs disappear; fix with @FocusState + Done toolbar button + .scrollDismissesKeyboard
2. **Move Today's Note to Dashboard only** — remove from MindsetView, make inline-editable on Dashboard card
3. **Enhanced Mindset** — dynamic rotating questions based on mood/energy/focus scores + ◀ ▶ past-day editing
4. **Habit detail / history sheet** — tap a habit → full history calendar, streak timeline, best month
5. **Task history & summary** — completed tasks grouped by week, category breakdown, overall stats
6. **Fix Tasks tab month display** — investigate and fix UI glitch in month calendar
7. App Groups finalisation (widget live data)
8. Onboarding flow
9. App Store screenshots

---

## Future Roadmap (Long-Term, Needs Design Approval Before Build)

### AI Assistant — "Kaizen Bot"
A conversational AI assistant embedded in the Dashboard. Powered by **Gemini AI** (free tier for users, optional API key for premium).

**What it knows:**
- Full habit history: which days completed, streaks, patterns, best/worst days
- Task history: what was done, categories, completion rates by week
- Mindset logs: energy/focus/mood trends, daily notes, sleep + steps
- User's own writing (daily notes act as a journal the AI can reference)

**What users can ask:**
- *"How consistent have I been with gym this month?"*
- *"What day of the week am I most productive?"*
- *"When did I have my best mindset score?"*
- *"What habits did I do on the day I felt most energized?"*
- *"Give me a weekly summary"*

**Technical approach:**
- `GeminiManager.swift` — `@Observable` helper, sends structured context payload to Gemini API
- Context payload: last 30 days of habits, tasks, mindset as JSON summary (not raw data — pre-summarised to stay within token limits)
- Premium feature: free users get 5 queries/day; premium = unlimited
- No data ever leaves device without explicit user action (user initiates the query)
- All AI responses are read-only suggestions — the AI never mutates app data

**New model needed:**
- `AIConversation.swift` — stores conversation history per session (date, messages array)

**UI:**
- Dashboard: floating "Ask Kaizen" button (bottom left, purple, brain icon)
- Opens a chat sheet: scrollable message history + input bar
- AI responses include quick-tap follow-ups ("Tell me more", "Show chart")

**Design approval required before building.** Do not implement until user reviews wireframes.

---

### Session (2026-03-20) — Habit UX: Custom Emoji + Duration + Reminder Lead Time + Bell Icon [DONE]

**What was built:**

- **Habit.swift** — Added `reminderLeadMinutes: Int?` (nil = at time) and `endDate: Date?` (nil = unlimited). Added `durationBadge` computed property: returns "18d left" / "1d left" / "🎉 Done!" based on days remaining.

- **AddHabitView.swift** — Three new sections added:
  1. **Custom emoji input** — below the 15-emoji quick-pick grid, a "Or type any emoji →" row with a `TextField`. User opens iOS emoji keyboard and types any emoji. `onChange` captures last 2 characters (emoji can be multi-scalar). Custom emoji overrides grid selection.
  2. **Duration section** — Horizontal chip row: Forever / 21 days / 90 days / 1 year / Custom. "Custom" reveals a `DatePicker`. Shows "Auto-archives on …" preview for non-forever options. Saves to `habit.endDate`.
  3. **Reminder lead time** — New "Notify me" chip row when reminder is toggled on: At time / 5 min before / 10 min before / 15 min before / 30 min before. Saves to `habit.reminderLeadMinutes`.

- **NotificationManager.swift** — `scheduleHabitReminder` now accepts `leadMinutes: Int = 0`. Subtracts lead time from `reminderTime` before scheduling `UNCalendarNotificationTrigger`. Existing callers unaffected (default = 0).

- **HabitRowView.swift** — Subtitle row now shows:
  - `bell.fill` (teal, 9pt) if habit has a reminder set
  - Duration badge from `habit.durationBadge` (purple "18d left" or orange "🎉 Done!")

- **HabitTrackerView.swift** — Added `autoArchiveExpiredHabits()` called `.onAppear`. Iterates active habits; if `endDate` is in the past, sets `isActive = false` and saves. Habit disappears from active list automatically when challenge is complete.

---

## Session Status

### Session (2026-03-13) — Bug Fixes + WidgetKit + Polish

**What was built:**
- **ContentView.swift** — Fixed iOS 18-only `Tab(value:)` API → now uses `.tabItem` + `.tag` (iOS 17 compatible); swapped to custom tab bar icons
- **DashboardView.swift** — Fixed 3 broken buttons: "See all →" (navigates to Habits tab), "Log now" (navigates to Mindset tab), habit preview rows (now toggle habits with haptics); added empty state
- **HabitTrackerView.swift** — Added haptic feedback on toggle via `.sensoryFeedback`; added empty state
- **TaskListView.swift** — Added haptic feedback on task toggle; added empty state; progress bar animation
- **KaizenWidget.swift** (new) — Full WidgetKit small + medium widget with day score ring and streak; uses App Group shared store
- **KaizenOSApp.swift** — Updated ModelContainer to use App Group URL so widget can read live data; falls back gracefully if App Groups not configured yet
- **StoreKitManager.swift** — Fixed Swift 6 actor isolation error: `checkVerified` marked `nonisolated`
- **Assets.xcassets** — AppIcon (1024×1024 PNG from AppIcon-Primary.svg) + 5 custom tab bar icons (TabIcon-Dashboard/Habits/Tasks/Mindset/Settings) at @1x/@2x/@3x

**Widget Xcode setup — COMPLETE:**
- KaizenWidgetExtension target created
- `KaizenWidget.swift` assigned to extension target only
- `Habit.swift`, `HabitEntry.swift`, `Color+Theme.swift` added to extension target
- Boilerplate Xcode-generated files deleted (`KaizenWidget/` folder cleaned to Info.plist + Assets.xcassets only)
- App Groups still pending (`group.com.shubh.kaizenos`) — add via Signing & Capabilities on both targets

**Icon assets location:**
- Source SVGs: `Design/kaizenos-icons/` (AppIcon/, TabBar/, Widgets/)
- Generated PNGs: `Kaizen OS/Assets.xcassets/` (AppIcon.appiconset, TabIcon-*.imageset)

**Next steps:**
- Session 10: App Store screenshots, onboarding polish, App Groups finalisation

### Session (2026-03-16) — UX Features: Future Tasks + Heatmap + Templates + Analysis + Health [DONE]

**What was built:**

- **HeatmapView.swift** — Switched from rolling-28-day window to actual calendar month; date numbers shown in each cell; proper weekday alignment (leadingBlanks offset, Mon=0); today highlighted with teal border; future days dimmed
- **TaskListView.swift** — Added horizontal date strip (7 days back + today + 7 days forward); `selectedDate` state drives task filter; date pill shows weekday letter + day number + teal dot for today; empty state text adapts to selected day
- **AddTaskView.swift** — Added `initialDate` param + `DatePicker` row; tasks can be scheduled for any date (past or future); `DailyTask.init` normalises to `startOfDay` as before
- **HabitRowView.swift** — Added `date: Date` parameter; `isCompleted` now uses the passed date instead of hardcoded `Date()`
- **HabitTrackerView.swift** — Added `viewingDate` state with ◀ ▶ navigation arrows; HabitRowView rows reflect past-date completion; "Browse Templates" Capsule button alongside FAB; `HabitAnalysisView` section below habit rows; sheets managed for templates → AddHabit pre-fill flow
- **AddHabitView.swift** — Added `init(prefillName:prefillEmoji:)` for template pre-fill support
- **HabitTemplateView.swift** (new) — 20 habit templates across 5 categories (Health, Fitness, Mind, Focus, Finance); tapping selects and dismisses, then opens AddHabitView pre-filled
- **HabitAnalysisView.swift** (new) — Per-habit horizontal bar chart sorted by 30-day completion rate; bars animate in; teal ≥70%, orange 40–69%, coral <40%
- **MindsetLog.swift** — Added `sleepHours: Double?`, `wakeTime: Date?`, `stepsManual: Int?` (all optional, SwiftData handles migration automatically)
- **MindsetView.swift** — Added Health card (sleep slider, wake time picker, steps text field); premium users see "Sync from Health" button; non-premium sees lock badge
- **HealthKitManager.swift** (new) — `@Observable` premium helper; reads `sleepAnalysis`, `stepCount`; returns `HealthSnapshot`; **requires HealthKit entitlement in Xcode Signing & Capabilities**

**HealthKit setup — COMPLETE:**
- HealthKit entitlement added (`Kaizen OS/Kaizen OS.entitlements`)
- `NSHealthShareUsageDescription` + `NSHealthUpdateUsageDescription` both in `project.pbxproj` (Debug + Release)
- ITMS-90683 App Store Connect rejection fixed (commit `091f913`)

### Session (2026-03-16) — Notifications [DONE]

**What was built:**
- **AddHabitView.swift** — Added reminder section: toggle to enable, `DatePicker` for time, weekday selector (S M T W T F S buttons); calls `NotificationManager.shared.scheduleHabitReminder` on save after requesting auth; sets `habit.reminderTime` and `habit.reminderDays`
- **SettingsView.swift** — Notifications row now shows "On"/"Off" status from `UserProfile.dailyReminderEnabled`; tapping opens `NotificationSettingsView` sheet; added `UserNotifications` import
- **NotificationSettingsView** (inside SettingsView.swift) — New sheet: daily check-in reminder toggle + time picker; persists to `UserProfile.dailyReminderEnabled` / `dailyReminderTime` via SwiftData; calls `NotificationManager.shared.scheduleDailyReminder` or removes it on save

**Architecture:**
- Per-habit reminders: set in `AddHabitView`, stored on `Habit.reminderTime` + `Habit.reminderDays`, scheduled via `NotificationManager.scheduleHabitReminder`
- Daily reminder: set in `NotificationSettingsView`, stored on `UserProfile`, scheduled via `NotificationManager.scheduleDailyReminder`

### Session (2026-03-22) — Habit Scheduling + Week/Month Task Calendar [DONE]

**What was built:**

- **Habit.swift** — Added `scheduledWeekdays: [Int]` field (empty = every day; non-empty = only those weekdays, 0=Sun…6=Sat); initialised to `[]` in `init`
- **HabitTrackerView.swift** — Added `habitsForDate` computed property that filters active habits by `scheduledWeekdays` for the current `viewingDate`; replaced direct `habits.filter(\.isActive)` usage with `habitsForDate`; empty state now distinguishes "no habits at all" (🌱 No habits yet) vs "rest day" (😌 Rest day — No habits scheduled for this day)
- **AddHabitView.swift** — Added Schedule section UI between Duration and Reminder: "Every day" / "Specific days" toggle; weekday selector grid (S M T W T F S) shown when "Specific days" selected; warning shown when no days selected; save button disabled when specific-days mode has zero days selected; `applySchedule(to:)` helper persists choice to `habit.scheduledWeekdays`; edit mode pre-populates schedule state from existing habit
- **TaskListView.swift** — Full rewrite replacing the horizontal date strip with a Week/Month calendar switcher; Week view: Mon-anchored 7-day row with ◀ ▶ week navigation, task-dot indicator, today highlight; Month view: full month grid with Mon-anchored weekday headers, ◀ ▶ month navigation, task-dot indicators; `calendarAnchor` state drives both views independently; `datesWithTasks` computed set powers the dot indicators; `WeekDayCell` and `MonthDayCell` private structs added; all existing TaskRow/OtherTaskRow logic preserved unchanged

**Architecture notes:**
- `scheduledWeekdays` uses 0=Sun…6=Sat convention (matching `Calendar.component(.weekday) - 1`)
- Empty `scheduledWeekdays` means "show every day" — backwards compatible with all existing habits
- `calendarAnchor` and `selectedDate` are separate states: anchor drives which week/month is visible, selectedDate drives which day's tasks are shown

### Session (2026-03-22) — Habit Lifecycle: Skip / Pause / Retire / Delete / Restore [DONE]

**What was built:**

- **HabitEntry.swift** — Added `isSkipped: Bool` field (default false). Added `skip()` method. `complete()` now clears `isSkipped`. Skipped entries are transparent — they don't count toward streak and don't break it.
- **Habit.swift** — Added `pausedUntil: Date?` + `isPaused: Bool` computed. Made `isScheduled(on:)` internal. Updated `currentStreak`, `longestStreak`, `completionRate30Days` to skip over `isSkipped` entries rather than treating them as missed days.
- **HabitRowView.swift** — Shows paused state (purple pause icon + "Paused until [date]"), skipped state (orange forward icon + "Skipped today"), or normal state. Paused rows disable tap-to-toggle.
- **HabitTrackerView.swift** — Full context menu: Edit, Skip Today/Undo Skip, Pause/Resume Now, Retire, Delete with confirmation alert. `PauseHabitSheet` (graphical calendar date picker, purple). Retired habits section (collapsible "RETIRED (N)" with Restore + Delete). `autoManageHabits()` auto-retires past endDate AND auto-resumes past pausedUntil on appear.

**Principles encoded:**
- Rest days (unscheduled) never break streak
- Skipped days (intentional) never break streak
- Only missed scheduled days reset streak
- Delete = permanent (cascade). Retire = reversible (isActive toggle).

### Session (2026-03-22) — Reminder UX + Schedule-Aware Streaks + Daily Note [DONE]

**What was built:**

- **AddHabitView.swift** — Renamed "Daily Reminder" → "Reminder". Removed the duplicate "Repeat" weekday picker from reminder section. Reminders now auto-follow the habit schedule (no separate day configuration). Shows a read-only "Repeats: Every day / N days per week" summary.
- **Habit.swift** — `currentStreak` and `longestStreak` rewritten to skip non-scheduled (rest) days when walking backwards/forwards. `completionRate30Days` denominator changed from hardcoded 30 to count of scheduled non-skipped days in window.
- **MindsetView.swift** — Added "TODAY'S NOTE" scratchpad textarea (orange accent, multiline). Loads/saves via `MindsetLog.note`. Border glows orange when text present.
- **DashboardView.swift** — Added `TodayNoteCard` between stats and habits. Shows note preview (3 lines) or "Tap to add a note…" prompt. Tapping navigates to Mindset tab. Queries `MindsetLog` for today.
- **FEATURES.md** (new) — User-facing feature documentation covering all features and the streak principle.

### Session (2026-03-15) — Naming Decision [DONE]

**Decision:** Keep "Kaizen OS" branding throughout the app (in-app text, onboarding, paywall, bundle IDs).
All code reverted to original "Kaizen OS" strings.

**App Store workaround:** "Kaizen OS" name is taken on the App Store.
- App Store listing name → **Zenshin** (com.shubh.zenshin bundle ID)
- Device home screen / in-app display name → **Kaizen OS** (unchanged)
- These are independent: App Store Connect name ≠ CFBundleDisplayName

**Still required in Xcode (manual — one-time):**
- Bundle ID: change `com.shubh.kaizenos` → `com.shubh.zenshin` in target settings
- Display Name: keep as **Kaizen OS** in General → Identity
