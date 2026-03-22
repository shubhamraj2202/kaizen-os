# 🤖 KAIZEN OS — Claude Code Agent Instructions

## How to Start Every Session

Paste this at the start of EVERY Claude Code session:

```
You are building "Kaizen OS" — a native iOS life operating system.
Read CLAUDE.md and FEATURES.md before doing ANYTHING else.

Your role: Senior iOS engineer. Write production-quality Swift/SwiftUI.
No placeholders. No TODOs. Finish what you start.
```

---

## Non-Negotiable Rules

### Code Rules
1. **Read CLAUDE.md first** — always, every session, no exceptions
2. **Read existing files before editing them** — never assume, always verify
3. **One feature per session** — go deep, not wide
4. **Write complete files** — never snippets, never partial edits
5. **Use `@Observable` macro** — NEVER `ObservableObject`
6. **Use SwiftData** — NEVER CoreData
7. **Zero third-party packages** — build everything natively
8. **No network calls** — except StoreKit receipt validation and (future) Gemini AI
9. **Dates always use** `Calendar.current.startOfDay(for:)` for comparisons
10. **Never persist computed values** — streak, score, completion rate are always calculated live

### Design Rules
11. **Match design/kaizenos-ui.jsx** — read it before writing any UI
12. **Dark navy background** `#090E1A`, teal accent `#00E5C8`
13. **SF Symbols only** — no custom icon libraries
14. **Rounded cards 24pt radius**, borders `rgba(255,255,255,0.07)`
15. **Dark mode only** — no light mode support in v1
16. **Screen padding 20pt horizontal**, card padding 16–20pt

### Session End Rules
17. **Always git commit** when a feature is complete — clear commit message describing what changed and why
18. **Always git push** after committing — so TestFlight build triggers automatically
19. **Always update CLAUDE.md** — add a session log entry under "Session Status"
20. **Always update FEATURES.md** — if any user-facing feature was added, changed, or removed
21. **Always mark features done** — update the "Next priorities" table in CLAUDE.md: mark ✅ Done + date when shipped
22. **Always log bugs under features** — if a bug is found in a shipped feature, add `🐛 Bug: [description] (found YYYY-MM-DD)` under that row; when fixed, update to ✅ Fixed + date

---

## Session Template (copy-paste each time)

```
Read CLAUDE.md and FEATURES.md before anything.

TODAY'S TASK:
"[One specific feature or fix — be precise]"

Do not build anything else today.
When done:
1. Git commit with a clear message
2. Git push to main
3. Update CLAUDE.md Session Status
4. Update FEATURES.md if user-facing features changed
```

---

## What to Update After Every Session

### CLAUDE.md — Session Status block
Add an entry like this:

```markdown
### Session (YYYY-MM-DD) — [Feature Name] [DONE]

**What was built:**
- **File.swift** — what changed and why
- **OtherFile.swift** — what changed and why

**Architecture notes:** (if relevant)
- Any patterns, decisions, or gotchas worth remembering
```

### FEATURES.md — User-facing doc
- Add new features in the relevant section
- Update existing descriptions if behaviour changed
- Remove features that were removed
- Keep language clear and non-technical — written for users, not engineers

### Git commit format
```
type: short description of what changed

- Bullet of key change 1
- Bullet of key change 2
- Why this was done (if not obvious)

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

Types: `feat` (new feature), `fix` (bug fix), `refactor`, `docs`, `chore`

---

## Recommended Session Order (Remaining Work)

| # | Task | Priority | Est. Time |
|---|------|----------|-----------|
| 1 | Keyboard dismiss bug (note TextField) | 🔴 Urgent | 30 min |
| 2 | Move Today's Note to Dashboard only (inline edit) | 🔴 Urgent | 1 hr |
| 3 | Enhanced Mindset — dynamic questions + past-day editing | 🟡 High | 2 hrs |
| 4 | Habit detail / history sheet (tap habit → full history) | 🟡 High | 2 hrs |
| 5 | Task history & summary sheet | 🟡 High | 1.5 hrs |
| 6 | Fix Tasks tab month display bug | 🟡 High | 30 min |
| 7 | Onboarding flow (name → first habit → done) | 🟢 Normal | 2 hrs |
| 8 | App Groups finalisation (widget live data) | 🟢 Normal | manual Xcode |
| 9 | App Store screenshots | 🟢 Normal | manual |

---

## Token-Saving Rules

```
❌ NEVER say: "Build the whole app"
✅ ALWAYS say: "Build ONLY [one view or fix]. Nothing else."

❌ NEVER re-explain the app each session
✅ ALWAYS say: "Read CLAUDE.md" — it has everything

❌ NEVER let Claude rewrite already-correct files
✅ ALWAYS specify the exact file path to edit

❌ NEVER use long chat threads for a single feature
✅ ALWAYS start a fresh session per feature

❌ NEVER skip reading existing code before editing
✅ ALWAYS read the file first — patterns matter
```

---

## Architecture Quick Reference

```
Models/           → @Model classes (Habit, HabitEntry, DailyTask, MindsetLog, UserProfile)
Views/
  Dashboard/      → DashboardView.swift
  Habits/         → HabitTrackerView, HabitRowView, AddHabitView, HeatmapView,
                     HabitAnalysisView, HabitTemplateView
  Tasks/          → TaskListView, AddTaskView
  Mindset/        → MindsetView
  Settings/       → SettingsView
Helpers/          → DateHelpers, StoreKitManager, NotificationManager, HealthKitManager
Widgets/          → KaizenWidget.swift (separate target)
```

### Key Patterns
```swift
// Always use startOfDay for date comparisons
let today = Calendar.current.startOfDay(for: Date())

// Always save after mutations
try? modelContext.save()

// Premium gate pattern
if profile?.isPremium != true && activeHabits.count >= UserProfile.freeHabitLimit {
    showPaywall = true; return
}

// Toggle habit (supports past dates)
if let existing = habit.entries.first(where: { cal.startOfDay(for: $0.date) == day }) {
    existing.isCompleted ? existing.uncomplete() : existing.complete()
} else {
    let entry = HabitEntry(date: day, habit: habit)
    entry.complete(); modelContext.insert(entry)
}
```

---

## Design System Quick Reference

```
Backgrounds:  #090E1A (primary)  #0D1321 (card)  #141C2E (elevated)
Accent:       #00E5C8 (teal)     #6450FF (purple) #FF8C42 (orange)  #FF6B6B (coral)
Text:         #FFFFFF (primary)  rgba(255,255,255,0.5) (secondary)  rgba(255,255,255,0.3) (tertiary)
Border:       rgba(255,255,255,0.07)

Radius: cards 24pt, rows 20pt, buttons 14pt
Padding: screen 20pt horizontal, cards 16-20pt
```

---

## How to Share UI Designs

**Option A — JSX file (best)**
```
design/kaizenos-ui.jsx is in the project.
Read it before writing any UI code.
```

**Option B — Screenshot**
Take a screenshot → drag into Claude Code → say "Match this design in SwiftUI"

**Option C — CLAUDE.md Design System**
Colors, spacing, and radii are documented — Claude reads them automatically on every session.

---

## Future Roadmap (Do NOT Build Without Approval)

### AI Assistant — "Kaizen Bot" (Gemini AI)
- Chat interface on Dashboard
- Reads full habit/task/mindset history to answer pattern questions
- e.g. "When am I most productive?", "How consistent is my gym habit?"
- Premium feature; free users get 5 queries/day
- Needs design wireframes → user approval → then build
- **Status: PLANNED — do not implement yet**

See CLAUDE.md "Future Roadmap" section for full spec.
