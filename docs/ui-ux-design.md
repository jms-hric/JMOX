# JMO Management System — UI/UX Design Specification

> UI/UX design for the React web application and Flutter Android application.
> Derived from: [requirements.md](requirements.md) · [context.md](context.md)

---

## 1. Design Principles

1. **Clean and professional** — Education management software, not a consumer app. Prioritize clarity, readability, and efficient task completion over visual novelty.
2. **Data-dense but scannable** — Teachers and admins work with tables, lists, and forms daily. Use good typography, whitespace, and consistent spacing rather than burying information behind clicks.
3. **Role-aware** — Navigation and available actions change based on role. Teachers see only their assigned batches; Admin sees everything.
4. **Responsive (web)** — Desktop-first design; tablet-usable. Mobile web is not a priority (that's what the Android app is for).
5. **Offline-aware (Android)** — Clearly indicate sync status, queued changes, and network state.
6. **Consistent terminology** — "Student", "Batch", "Session", "Olympiad", "Paper", "Section" — used identically across web and Android.

---

## 2. Web Application

### 2.1 Global Layout

```
┌─────────────────────────────────────────────────────────┐
│  Top Bar: Logo · Search · Notifications · User Menu     │
├──────────┬──────────────────────────────────────────────┤
│          │                                              │
│  Side    │             Main Content Area                │
│  Nav     │                                              │
│          │                                              │
│          │                                              │
│          │                                              │
│          │                                              │
│          │                                              │
└──────────┴──────────────────────────────────────────────┘
```

- **Sidebar:** Collapsible. Icons + labels. Grouped by function area.
- **Top bar:** Fixed. Global search, notification bell, user avatar + dropdown (Profile, Settings, Logout).
- **Main content:** Breadcrumb trail at top. Page title + action buttons. Content below.

### 2.2 Navigation Structure

#### Admin Navigation

| Group           | Item               | Route                    |
|-----------------|--------------------|--------------------------|
| **Overview**    | Dashboard          | `/dashboard`             |
| **People**      | Students           | `/students`              |
|                 | Teachers           | `/teachers`              |
|                 | Guardians          | `/guardians`             |
| **Academic**    | Academic Years     | `/academic-years`        |
|                 | Classes            | `/classes`               |
|                 | Batches            | `/batches`               |
|                 | Attendance         | `/attendance`            |
| **Assessment**  | Olympiads          | `/olympiads`             |
|                 | Papers             | `/papers`                |
|                 | Answer Keys        | `/answer-keys`           |
|                 | OMR Evaluation     | `/omr`                   |
|                 | Results            | `/results`               |
|                 | Rankings           | `/rankings`              |
| **Insights**    | Performance        | `/performance`           |
|                 | Reports            | `/reports`               |
|                 | Awards             | `/awards`                |
| **System**      | Users              | `/users`                 |
|                 | Custom Fields      | `/custom-fields`         |
|                 | Settings           | `/settings`              |
|                 | Audit Logs         | `/audit-logs`            |

#### Teacher Navigation

| Group           | Item               | Route                    |
|-----------------|--------------------|--------------------------|
| **Overview**    | Dashboard          | `/dashboard`             |
| **My Work**     | My Batches         | `/batches`               |
|                 | Students           | `/students`              |
|                 | Attendance         | `/attendance`            |
| **Assessment**  | Answer Entry       | `/answer-entry`          |
|                 | OMR Evaluation     | `/omr`                   |
|                 | Results            | `/results`               |
|                 | Rankings           | `/rankings`              |
| **Insights**    | Performance        | `/performance`           |

### 2.3 Pages

---

#### 2.3.1 Login

**Route:** `/login`

| Element                | Description                                             |
|------------------------|---------------------------------------------------------|
| Email input            | With validation                                         |
| Password input         | With show/hide toggle                                   |
| "Forgot password?" link| Opens password reset flow                               |
| Login button           | Disabled until both fields valid                        |
| Error display          | Inline below form: invalid credentials, account disabled |

No registration link — accounts are Admin-created only.

---

#### 2.3.2 Admin Dashboard

**Route:** `/dashboard` (Admin)

| Widget                  | Content                                                |
|-------------------------|--------------------------------------------------------|
| Stats cards             | Total students (active), Total teachers (active), Active batches, Upcoming olympiads |
| Recent activity         | Last 10 audit log entries                              |
| Attendance overview     | Today's attendance rate across batches (bar chart)      |
| Olympiad status         | Cards for in-progress and upcoming olympiads            |
| Quick actions           | "Add Student", "Create Olympiad", "Generate Report"    |

---

#### 2.3.3 Teacher Dashboard

**Route:** `/dashboard` (Teacher)

| Widget                  | Content                                                |
|-------------------------|--------------------------------------------------------|
| My batches              | Cards for each assigned batch with student count       |
| Today's sessions        | List of sessions to mark attendance for                |
| Pending OMR             | OMR submissions awaiting review                        |
| Quick actions           | "Mark Attendance", "Enter Answers", "Scan OMR"         |

---

#### 2.3.4 Students List

**Route:** `/students`

| Element              | Description                                               |
|----------------------|-----------------------------------------------------------|
| Search bar           | Search by name or public ID                               |
| Filters              | Class, Batch, Status (active/withdrawn), Academic Year    |
| Data table           | Columns: Public ID, Name, Class, Batch, Status, Actions   |
| Actions per row      | View Profile, Edit, Transfer (Admin), Withdraw (Admin)    |
| Bulk actions         | Export (PDF/Excel), Bulk import (CSV)                      |
| Pagination           | Page size selector (25/50/100), page navigation           |
| "+ Add Student" btn  | Admin only, top right                                     |

**Teacher view:** Filtered to students in assigned batches only. No Add/Transfer/Withdraw actions.

---

#### 2.3.5 Student Profile

**Route:** `/students/:id`

**Tab layout:**

| Tab              | Content                                                      |
|------------------|--------------------------------------------------------------|
| **Overview**     | Photo, personal info, guardian info, custom fields, public ID |
| **Enrollment**   | Current class/batch, enrollment history (timeline)           |
| **Attendance**   | Attendance rate, session-by-session record, calendar view    |
| **Results**      | Olympiad results table: olympiad, score, percentage, rank    |
| **Performance**  | Charts: score trend, section breakdown, topic strengths      |
| **Certificates** | List of awarded certificates with download links             |

---

#### 2.3.6 Student Registration / Edit

**Route:** `/students/new` · `/students/:id/edit`

**Form sections:**

1. **Personal Information:** Full name, Date of birth, Gender, Photo upload
2. **Contact:** Phone, Email
3. **Guardian:** Name, Relationship, Phone, Email (search existing or create new)
4. **Enrollment:** Class, Batch, Enrollment date
5. **Custom Fields:** Dynamic fields based on Admin configuration

**Validation:** Client-side + server-side. Required fields marked with asterisk. Inline errors below each field.

---

#### 2.3.7 Classes

**Route:** `/classes`

| Element              | Description                                               |
|----------------------|-----------------------------------------------------------|
| Academic year filter | Dropdown to switch academic year                          |
| Cards or table       | Class name, Batch count, Student count, Actions           |
| Actions              | View Batches, Edit, Delete (if no students)               |
| "+ Add Class" btn    | Admin only                                                |

---

#### 2.3.8 Batches

**Route:** `/batches`

| Element              | Description                                               |
|----------------------|-----------------------------------------------------------|
| Filters              | Class, Status (active/completed/archived)                 |
| Data table           | Batch name, Class, Teacher(s), Student count, Schedule, Status |
| Click row            | Navigate to batch detail                                  |
| Batch detail         | Roster tab, Attendance tab, Schedule tab, Teachers tab    |

---

#### 2.3.9 Teachers

**Route:** `/teachers` (Admin only)

| Element              | Description                                               |
|----------------------|-----------------------------------------------------------|
| Data table           | Public ID, Name, Email, Status, Assigned Batches, Actions |
| Actions              | View, Edit, Deactivate/Reactivate, Assign Batches        |
| "+ Create Teacher" btn | Opens form: Name, Email → sends invite email            |
| Status indicators    | Badge: Invited (yellow), Active (green), Disabled (red)  |

---

#### 2.3.10 Attendance

**Route:** `/attendance`

| Element              | Description                                               |
|----------------------|-----------------------------------------------------------|
| Batch selector       | Dropdown (Teacher: assigned batches only; Admin: all)     |
| Date selector        | Calendar date picker                                      |
| Session selector     | Session 1 / Session 2                                     |
| Attendance grid      | Student name, status radio (Present/Absent/Late/Excused)  |
| "Mark All Present"   | Bulk action button, then adjust individual                |
| Save button          | Saves with confirmation                                   |
| Statistics sidebar   | Present/Absent/Late counts for this session               |

**Read-only view** for past sessions with edit capability (audit-logged).

---

#### 2.3.11 Olympiads

**Route:** `/olympiads` (Admin only)

| Element              | Description                                               |
|----------------------|-----------------------------------------------------------|
| Data table           | Name, Date, Academic Year, Classes, Status, Actions       |
| Status badge         | Draft / Scheduled / In Progress / Completed               |
| Actions              | View, Edit, Manage Papers, View Results                   |
| "+ Create Olympiad"  | Form: Name, Description, Date, Academic Year, Target Classes |

---

#### 2.3.12 Papers

**Route:** `/olympiads/:id/papers/:paperId`

| Element              | Description                                               |
|----------------------|-----------------------------------------------------------|
| Paper info           | Olympiad, Class, Version, Total marks, Lock status        |
| Sections list        | Collapsible sections with question count per section      |
| Add Section btn      | If paper not locked                                       |
| Per section          | List of questions, "Add Question" button                  |
| Lock indicator       | Banner: "This paper is locked — results have been published" |

---

#### 2.3.13 Sections & Questions

Nested under Papers view.

| Element              | Description                                               |
|----------------------|-----------------------------------------------------------|
| Section header       | Name, Marks per question, Negative marks, Question count  |
| Question rows        | Number, Text (optional), Options (A/B/C/D), Marks, Negative marks |
| Inline editing       | Edit questions in place when paper is unlocked            |
| Reorder              | Drag-and-drop to reorder questions within a section       |

---

#### 2.3.14 Answer Keys

**Route:** `/olympiads/:id/papers/:paperId/answer-key`

| Element              | Description                                               |
|----------------------|-----------------------------------------------------------|
| Version selector     | Dropdown of answer key versions                           |
| Question grid        | Question number, Correct option (radio: A/B/C/D)         |
| Lock status          | Banner if locked                                          |
| "Save" / "New Version" | Save if unlocked; "Create New Version" if locked        |

---

#### 2.3.15 Manual Answer Entry

**Route:** `/answer-entry`

| Element              | Description                                               |
|----------------------|-----------------------------------------------------------|
| Olympiad selector    | Dropdown                                                  |
| Class selector       | Dropdown (filtered by olympiad)                           |
| Batch selector       | Dropdown (Teacher: assigned only)                         |
| Student selector     | Single student or batch mode toggle                       |
| Answer grid          | Question number × Option radio (A/B/C/D/Unanswered)      |
| Auto-save indicator  | Saves per answer change                                   |
| Submit button        | "Submit All Answers" with confirmation                    |

---

#### 2.3.16 OMR Evaluation

**Route:** `/omr`

| Element              | Description                                               |
|----------------------|-----------------------------------------------------------|
| Upload area          | Drag-and-drop or file picker for scanned OMR images       |
| Batch/Paper selector | Required before upload                                    |
| Submissions table    | Submission ID, Batch, Status, Uploaded by, Date, Actions  |
| Status badges        | Pending (gray), Processing (blue), Needs Review (orange), Completed (green), Failed (red) |
| Review screen        | Side-by-side: OMR image + extracted answers. Teacher corrects misreads, confirms. |

---

#### 2.3.17 Results

**Route:** `/results`

| Element              | Description                                               |
|----------------------|-----------------------------------------------------------|
| Olympiad filter      | Dropdown                                                  |
| Class filter         | Dropdown                                                  |
| Status filter        | Draft / Reviewed / Published                              |
| Results table        | Student, Score, Max, Percentage, Section scores, Status   |
| Admin actions        | "Publish Results" (batch), "Unpublish" (with confirmation)|
| Published badge      | Timestamp + published by                                  |
| Export               | PDF, Excel                                                |

---

#### 2.3.18 Rankings

**Route:** `/rankings`

| Element              | Description                                               |
|----------------------|-----------------------------------------------------------|
| Olympiad selector    | Required                                                  |
| Scope toggle         | "Per Class" / "Cross-Class"                               |
| Class filter         | Dropdown (for per-class view)                             |
| Rankings table       | Rank, Student Name, Public ID, Score/Percentage, Section Scores |
| Tied rank indicator  | Visual marker for tied ranks (e.g., "=" icon)             |
| Export               | PDF, Excel                                                |

---

#### 2.3.19 Student Performance

**Route:** `/performance`

| Element              | Description                                               |
|----------------------|-----------------------------------------------------------|
| Student search       | Autocomplete by name or public ID                         |
| Score trend chart    | Line chart: percentage across olympiads over time         |
| Section breakdown    | Stacked bar chart: section scores per olympiad            |
| Comparison           | vs. batch average, vs. class average (overlay lines)      |
| Attendance rate      | Correlation display with performance                      |
| Strengths/Weaknesses | Topic-level breakdown (if topics assigned to questions)   |

---

#### 2.3.20 Reports

**Route:** `/reports` (Admin: all; Teacher: assigned batches)

| Report Type          | Description                                               |
|----------------------|-----------------------------------------------------------|
| Batch Attendance     | Aggregate and per-session attendance for a date range     |
| Olympiad Results     | Results table per class/batch with summary statistics     |
| Student Progress     | Individual student report across olympiads                |
| Export options       | PDF, Excel                                                |
| Date range filter    | Start date, End date                                      |
| Generate button      | Generates report, shows preview, then allows download     |

---

#### 2.3.21 Awards

**Route:** `/awards` (Admin only)

| Element              | Description                                               |
|----------------------|-----------------------------------------------------------|
| Olympiad selector    | Required                                                  |
| Award criteria       | Table: Award name, Criteria (rank/percentage), Auto/Manual|
| Auto-assigned awards | Generated from published rankings, listed                 |
| Manual assign        | "Assign Award" button → select student, award type        |
| Certificate gen      | "Generate Certificates" button → bulk PDF generation      |

---

#### 2.3.22 Users (Admin Only)

**Route:** `/users`

| Element              | Description                                               |
|----------------------|-----------------------------------------------------------|
| Users table          | Public ID, Name, Email, Role, Status, Last Login, Actions |
| Actions              | Edit, Deactivate, Reactivate, Resend Invite               |
| Status badges        | Invited (yellow), Active (green), Disabled (red)          |

---

#### 2.3.23 Custom Fields (Admin Only)

**Route:** `/custom-fields`

| Element              | Description                                               |
|----------------------|-----------------------------------------------------------|
| Fields table         | Name, Type, Required, Active, Actions                     |
| Actions              | Edit, Deprecate (soft-delete — never hard delete)         |
| "+ Add Field" btn    | Form: Name, Type (text/number/date/dropdown), Required    |
| Dropdown config      | If type=dropdown: add/remove options                      |

---

#### 2.3.24 Settings (Admin Only)

**Route:** `/settings`

| Section              | Description                                               |
|----------------------|-----------------------------------------------------------|
| Institution info     | Name, logo, contact details                               |
| Academic year        | Manage academic years, set active                         |
| Default schedule     | Default sessions per week for new batches                 |
| Notification prefs   | Email notification settings                               |

---

#### 2.3.25 Audit Logs (Admin Only)

**Route:** `/audit-logs`

| Element              | Description                                               |
|----------------------|-----------------------------------------------------------|
| Filters              | Entity type, User, Date range, Action type, Conflict flag |
| Log table            | Timestamp, User, Action, Entity, Changes summary          |
| Expand row           | Shows before/after JSON diff                              |
| Conflict flag        | Orange indicator for offline sync conflicts               |
| Export               | CSV                                                       |

---

## 3. Android Application

### 3.1 Navigation Structure

**Bottom Navigation Bar** (4 tabs):

| Tab          | Icon         | Content                               |
|--------------|--------------|---------------------------------------|
| Dashboard    | Home         | Overview, quick actions, today's tasks |
| Batches      | People       | Assigned batches, student lists        |
| Assessment   | Edit/Pencil  | Answer entry, OMR, Results             |
| Profile      | Person       | Account info, settings, logout         |

### 3.2 Screens

---

#### 3.2.1 Login

- Email + password fields
- "Forgot Password?" link
- Login button
- JWT stored in Android Keystore (not SharedPreferences)

---

#### 3.2.2 Dashboard

- **Today's sessions** — list of sessions with "Mark Attendance" action
- **Pending reviews** — OMR submissions needing review (count badge)
- **Sync status** — indicator: "All synced" / "3 changes pending" with manual sync button
- **Quick stats** — students across assigned batches, today's attendance rate

---

#### 3.2.3 My Batches

- List of assigned batches as cards
- Each card: Batch name, Class, Student count, Schedule
- Tap → Batch detail (Students tab, Attendance tab)

---

#### 3.2.4 Student List

- Per batch
- Search bar at top
- List: Student photo (thumbnail), Name, Public ID
- Tap → Student Profile

---

#### 3.2.5 Student Profile

- Photo, name, public ID, class, batch, guardian info
- Tabs: Attendance summary, Results, Performance chart

---

#### 3.2.6 Attendance

- Batch + Session selector at top
- Student list with status toggle (Present / Absent / Late / Excused)
- "All Present" quick action
- **Offline capable:** 
  - Sync indicator: green (synced), yellow (pending), red (error)
  - Queue stored in local SQLite
  - Auto-syncs when network available
  - Manual "Sync Now" button
- Save button with confirmation

---

#### 3.2.7 Manual Answer Entry

- Olympiad → Paper → Student selector flow
- Answer grid: scrollable list of question numbers with option chips (A/B/C/D/Clear)
- Progress indicator: "28/40 answered"
- Submit with confirmation

---

#### 3.2.8 OMR Camera

- Camera viewfinder with alignment guide overlay
- Capture button
- Preview with crop/rotate
- "Upload for Processing" button
- Batch + Paper must be selected before camera opens

---

#### 3.2.9 OMR Review

- Split view: OMR image (zoomable) + extracted answers
- Per-question: highlight confidence (green = confident, orange = uncertain, red = failed)
- Tap to correct: option picker per question
- "Confirm All" button → creates StudentAnswer records
- Filters: "Show only uncertain" to speed up review

---

#### 3.2.10 Results

- Olympiad → Class filter
- Results list: Student, Score, Percentage, Rank
- Tap → detailed section breakdown
- Read-only (publishing is Admin web only)

---

#### 3.2.11 Student Performance

- Student selector (from assigned batches)
- Score trend chart (line)
- Section breakdown (bar)
- Attendance correlation

---

## 4. Reusable UI Components

### 4.1 Web Components

| Component          | Description                                                    |
|--------------------|----------------------------------------------------------------|
| `DataTable`        | Sortable, filterable, paginated table. Column config, row actions, bulk actions, export |
| `SearchInput`      | Debounced search with clear button and loading indicator       |
| `FilterBar`        | Horizontal filter chips/dropdowns, "Clear All" action          |
| `FormField`        | Label, input (text/select/date/radio), validation error, required indicator |
| `StatusBadge`      | Colored badge for entity statuses                              |
| `ConfirmDialog`    | Modal: title, message, Cancel + Confirm buttons                |
| `PageHeader`       | Breadcrumbs + title + action buttons                           |
| `StatsCard`        | Number + label + optional trend indicator                      |
| `EmptyState`       | Illustration + message + CTA button                            |
| `LoadingState`     | Skeleton loaders matching content layout                       |
| `ErrorState`       | Error message + retry button                                   |
| `Toast`            | Success/error/info notifications, auto-dismiss                 |
| `FileUpload`       | Drag-and-drop zone + file picker + progress bar                |
| `Chart`            | Line, bar, stacked bar chart wrapper                           |

### 4.2 Android Components

| Component          | Description                                                    |
|--------------------|----------------------------------------------------------------|
| `BatchCard`        | Batch summary card for list views                              |
| `StudentListItem`  | Photo + name + public ID row                                   |
| `AttendanceToggle` | 4-state toggle for attendance status                           |
| `AnswerChip`       | Selectable option chip (A/B/C/D)                               |
| `SyncIndicator`    | Green/yellow/red status with count                             |
| `OfflineBanner`    | Persistent banner when offline                                 |
| `ConfirmSheet`     | Bottom sheet confirmation dialog                               |

---

## 5. States

### 5.1 Loading States

- **Tables:** Skeleton rows (5–10 rows) matching column layout
- **Cards:** Skeleton cards matching card dimensions
- **Forms:** Individual field loading (rare; typically form loads instantly)
- **Charts:** Shimmer placeholder matching chart area

### 5.2 Empty States

| Context                  | Message                                    | CTA                    |
|--------------------------|--------------------------------------------|------------------------|
| No students              | "No students found"                        | "Add Student"          |
| No results for filters   | "No results match your filters"            | "Clear Filters"        |
| No attendance records    | "No attendance recorded for this session"  | "Mark Attendance"      |
| No olympiads             | "No olympiads created yet"                 | "Create Olympiad"      |
| No OMR submissions       | "No OMR scans uploaded"                    | "Upload Scans"         |

### 5.3 Error States

| Error Type         | Display                                                     |
|--------------------|-------------------------------------------------------------|
| Network error      | "Unable to connect. Check your internet and try again." + Retry |
| Server error (5xx) | "Something went wrong. Please try again." + Retry           |
| Not found (404)    | "The requested item was not found." + Back button           |
| Forbidden (403)    | "You don't have permission to access this." + Back          |
| Validation (422)   | Inline field-level errors                                   |

### 5.4 Confirmation Dialogs

Required before:

- Publishing results
- Unpublishing results
- Deactivating a teacher/user account
- Withdrawing a student
- Deleting any entity (where allowed)
- Submitting bulk attendance
- Confirming OMR review

Format: Modal with clear title ("Publish Results?"), description of consequences, Cancel + Confirm (destructive actions use red button).

---

## 6. Accessibility Requirements

| Requirement                  | Implementation                                         |
|------------------------------|--------------------------------------------------------|
| Keyboard navigation          | All interactive elements focusable and operable        |
| Screen reader support        | ARIA labels on all inputs, buttons, status indicators  |
| Color contrast               | WCAG 2.1 AA (4.5:1 for text, 3:1 for UI components)   |
| Focus indicators             | Visible focus rings on all interactive elements        |
| Form labels                  | Every input has an associated `<label>`                |
| Error announcements          | Validation errors announced via `aria-live`            |
| Table headers                | `<th scope="col">` / `<th scope="row">`                |
| Skip navigation              | "Skip to main content" link                            |

---

## 7. Responsive Behavior (Web)

| Breakpoint       | Layout                                                    |
|------------------|-----------------------------------------------------------|
| ≥ 1280px (lg)    | Full sidebar + main content                               |
| 1024–1279px (md) | Collapsed sidebar (icons only) + main content             |
| 768–1023px (sm)  | Hamburger menu, full-width content                        |
| < 768px          | Not a priority (use Android app). Basic usability only.   |

**Tables on smaller screens:** Horizontal scroll with fixed first column (student name/ID).

---

## 8. Teacher Workflow Optimization

The Android app and web interface are optimized for the teacher's most frequent workflows:

### 8.1 Attendance Workflow (Most Frequent)

1. Open app → Dashboard shows today's sessions
2. Tap session → Opens attendance with batch roster pre-loaded
3. "Mark All Present" → Adjust individuals
4. Save → Synced (or queued if offline)

**Target:** < 2 minutes for a 30-student batch.

### 8.2 OMR Workflow

1. Open app → Assessment tab → OMR Camera
2. Select Batch + Paper
3. Capture sheets (one per student, or batch scan)
4. Upload → Processing happens in background
5. Notification when ready for review
6. Review screen: fix uncertain answers → Confirm

**Target:** Review step < 30 seconds per student (mostly auto-correct).

### 8.3 Manual Answer Entry Workflow

1. Select Olympiad → Paper → Student
2. Enter answers via grid (A/B/C/D chips)
3. Progress indicator shows completion
4. Submit → auto-scored

**Target:** < 3 minutes for a 40-question paper per student.

---

*Cross-references: [requirements.md](requirements.md) · [architecture-api.md](architecture-api.md) · [database-design.md](database-design.md)*
