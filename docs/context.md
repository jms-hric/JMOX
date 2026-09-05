# JMO Management System — Context File Audit (Consolidated)

## Confirmed Decisions

- **Hosting: Vercel.** Production must be cloud-hosted on Vercel + a custom domain. This is a firm architectural decision — it constrains the backend to Vercel's serverless execution model (stateless functions, no long-lived background processes, per-request execution time limits). Design the backend around this model rather than assuming a traditional always-on server.
- **Teacher accounts are created only by Admin — no teacher self-registration.** Matches Section 51's "Create Teachers" step. A Teacher account starts in an `invited` state and is activated by the teacher via a time-limited emailed link before first login.

---

## Drop-in text patches for CONTEXT.md

**Section 4 (Deployment)** — replace the hedge with a firm statement:
```
Production must be cloud-hosted on Vercel + a custom domain. This is
a firm architectural decision, not one option among several — it
constrains the backend to Vercel's serverless execution model
(stateless functions, no long-lived background processes, per-request
execution time limits). Design the backend around this model rather
than assuming a traditional always-on server. See Critical items
#16–#18 below for what this rules out.
```

**Section 41 (Authentication)** — add:
```
Account provisioning: Teacher and Admin accounts are created
exclusively by Admin. There is no public sign-up endpoint for any
role, on web or Android. A Teacher account starts in an `invited`
state and is activated by the teacher via a time-limited emailed
link before first login (see item #20).
```

**Section 7 (Admin capabilities)** — footnote the existing "Manage
teachers" bullet: *"includes sole authority to create teacher
accounts — see Section 41."*

---

## 🔴 CRITICAL

### 1. Real production IP leaked inside the "don't hardcode" example (Section 5)
The doc says "Never hard-code: `49.244.136.23`" — but that's an actual
former production IP, sitting in plaintext in a file that will likely
end up in a git repo or shared with contractors/an AI assistant.

**Fix:** Redact it. Replace with a placeholder:
```
Never hard-code IP addresses, ports, or local network paths
(e.g. 192.0.2.10). All endpoints must resolve via PUBLIC_BASE_URL.
```
If `49.244.136.23` is still a live/reachable host anywhere (router,
old VPS, camera, etc.), treat this as a secrets leak and rotate/retire
it, not just delete the line.

### 2. RBAC is required (Sec 45) but only 2 roles exist and no Role/Permission entities (Sec 7, 43, 60)
Section 7 gives Admin the power to "Manage permissions," Section 45
mandates "Role-based access control," but Section 43's core data
models list no `Role` or `Permission` entity — access is implicitly
hardcoded to `Admin` / `Teacher`. This is internally inconsistent:
either permission management isn't real in v1, or the data model is
incomplete.

"Who creates accounts" is now settled (Admin only). The separate
question — whether permissions stay fixed to Admin/Teacher (Option A)
or need a real `Role`/`Permission` model (Option B) — is still open.

**Fix — pick one and state it explicitly:**
- **Option A (recommended for v1):** Drop "Manage permissions" from
  Admin's list for now. Two fixed roles, enforced server-side via a
  `role` enum on `User`. Simple, matches Section 60's confirmed scope.
- **Option B:** Add `Role` and `Permission` (+ join table) to Section
  43 and define what "custom permission" actually means (per-batch
  overrides? feature flags?). Don't leave it implied.

### 3. "Overall" ranking mixes classes with different max marks (Sec 29 vs Sec 16/18)
Section 16 says each class can have a different paper (different
question count/marks). Section 18's sample is 40 marks for Class 1;
Class 2/3 papers aren't guaranteed to also total 40. But Section 29's
"Overall" ranking example ranks Student A (Class 1, score 38) above
Student B (Class 2, score 37) using **raw score** — which is invalid
if the papers don't share the same total marks. This is a real
scoring bug baked into the spec's own example.

**Fix:** Define "Overall" ranking as either:
- ranked by **percentage**, not raw score, whenever classes/papers
  have different max marks; or
- scoped to be **per-Olympiad-per-class only**, and rename the
  ambiguous "Overall" ranking to "Cross-class ranking (by %)" if it's
  still wanted.
State this explicitly in Section 29 and Section 30 (tie-breaking must
also then operate on normalized section scores, not raw, if classes
differ in marks-per-question).

### 4. No snapshotting of class/batch/paper at exam time (Sec 14, 28, 31, 43)
`AssessmentResult` / `StudentAnswer` are only listed as referencing
`Student`, `Olympiad`, `Paper`, `Question` — implicitly via live FKs
to the student's *current* class/batch. But Section 14 requires that
moving a student to a new class must never change historical results.
If the result record doesn't **snapshot** the class/batch/paper-version
the student sat under at the time, a batch/class transfer or an
answer-key edit later will silently corrupt historical rankings —
directly violating Section 44 ("Published results cannot silently
change").

**Fix — add to Section 43:**
```
AssessmentResult must store (not just reference):
  - class_at_time_of_exam
  - batch_at_time_of_exam
  - paper_version_id (see #5 below)
These are immutable once the result is Published.
```

### 5. Questions/answer keys are mutable after publication (Sec 19, 22, 28, 44)
Nothing stops Admin from editing a question or answer key that
already has Published results attached. Editing in place after
publication silently changes historical correctness — contradicts
Section 44 directly.

**Fix:** Papers/Sections/Questions/AnswerKeys become **immutable once
any linked result is Published**. Further changes require creating a
new version (`paper_version`), never in-place edit. Add `version` and
`locked_at` fields to `OlympiadPaper` and `AnswerKey` in Section 43.

### 16. OMR processing can't run inside a Vercel serverless function
Vercel serverless functions are billed and capped per-invocation —
the default execution window is short (single-digit seconds unless
you raise it), and even the extended limits available on paid plans
are meant for typical request/response work, not image-processing
pipelines. Bubble detection across a whole batch's scanned sheets is
exactly the workload that blows through this. The Section 3
architecture diagram wires "OMR Engine" directly off the backend like
a normal in-process call — that shape doesn't survive contact with
Vercel.

**Fix:** OMR processing runs as a **separate, non-Vercel worker**
(a small always-on service on Fly.io/Railway/Render, or a
serverless-native queue like Inngest/Trigger.dev/QStash that's built
for exactly this). Vercel functions only *enqueue* a job and return
immediately; the teacher-facing UI polls `OMRSubmission.status`.

### 17. No database connection pooling specified — this will break under real concurrent load
Vercel functions are stateless and scale by spinning up many
concurrent invocations. Each one that opens its own Postgres
connection, under load (e.g. a whole batch submitting attendance at
once, or bulk OMR review), will exhaust Postgres's connection limit.
This is the single most common way Vercel + Postgres deployments
break in production, and the doc doesn't mention it at all.

**Fix:** Pick a serverless-friendly Postgres provider with built-in
pooling (Neon, Supabase, or Vercel Postgres) and use its pooled
connection string (or PgBouncer) for all serverless function
connections — never a direct unpooled connection.

### 18. Nothing in the doc accounts for Vercel functions sharing no memory
Session state, rate-limit counters, and OMR job status all implicitly
assume "the server remembers this" — but there is no persistent
server process on Vercel; every invocation is its own isolated
instance. Section 45's "session management" and "rate limiting," and
Section 40's offline-sync idempotency, all need an **external** store
to work at all (a DB table, or a fast store like Upstash Redis, which
is the common serverless-native pairing with Vercel).

**Fix:** State explicitly that sessions, rate-limit counters, and job
status live in the database or an external Redis-compatible store —
never in function memory.

### 19. Cookie-based auth (Sec 45) doesn't map onto the Android client
"HTTP-only authentication" works naturally for the web app. Android
has no cookie jar in the same sense — it needs a token-based scheme.
Section 41 requires identical permissions across web and Android, but
never says the two platforms will authenticate differently, so this
will get built inconsistently unless it's named now.

**Fix:** Web uses an HTTP-only, Secure, SameSite session cookie.
Android uses a short-lived access token + refresh token, with the
refresh token stored in Android Keystore-backed encrypted storage
(never plain SharedPreferences). Both paths resolve to the same
server-side role/permission check — one authorization layer, two
credential-delivery mechanisms.

---

## 🟠 IMPORTANT

### 6. Tie-break rank numbering isn't defined (Sec 30)
"If still tied, same rank" — okay, but what does the *next* student's
rank become? Standard competition ranking has two common conventions
(1-2-2-4, skipping, vs 1-2-2-3, dense). The doc never picks one, so
two developers will implement it two different ways.

**Fix:** State explicitly: *"Use standard competition ranking
(1-2-2-4): tied students share the lower rank number, and the next
distinct score skips ranks equal to the number of students tied
above it."* (Or pick dense ranking if that's actually wanted — just
name it.)

### 7. Negative marking is never addressed (Sec 25, 26)
Olympiad-style MCQ exams frequently penalize wrong answers. The spec
only defines Correct / Incorrect / Unanswered with marks coming "from
the question configuration," but never says whether Incorrect can
subtract marks.

**Fix:** Add to Section 25: `Question` needs an optional
`negative_marks` field (default 0), and scoring must explicitly
support negative marking per-section or per-question, since this
changes total score, section score, and therefore ranking tie-breaks.

### 8. OMR Engine shown as synchronous, no job/queue model (Sec 22–24, architecture diagram)
The architecture diagram wires OMR Engine directly off the backend
like a normal service call. Bulk OMR scanning (a whole batch's sheets
uploaded at once) is not going to be fast enough to be request/response.

**Note:** Vercel's execution model makes this mandatory, not just best
practice. See item #16.

**Fix:** OMR processing must be async: upload → job queued → status
(`pending/processing/needs_review/failed`) → teacher polls or gets
notified → review screen. Add `OMRSubmission.status` and
`OMRSubmission.job_id` to Section 43.

### 9. Offline sync conflict resolution is unspecified (Sec 40)
"Idempotent, no duplicates" is stated, but not what happens when the
same student's attendance for the same session is recorded differently
on two devices before either syncs (e.g., teacher marks Present
offline, admin corrects to Absent online, then the offline record
syncs later and overwrites it).

**Fix:** Define a policy explicitly, e.g.: *server timestamp wins on
conflict; a losing offline write is not discarded but logged to
AuditLog and flagged for manual review, never silently dropped.*

### 10. `OMR_STORAGE_PATH` env var contradicts the "no local storage" rule (Sec 5 vs Sec 6)
Section 6 bans depending on local filesystem paths for production
persistence, but Section 5's example env vars include
`OMR_STORAGE_PATH=...`, which reads like a filesystem path.

**Note:** Now unambiguous — Vercel functions can't durably write to
local disk at all (only an ephemeral `/tmp`), so this must be an
object-storage key prefix, full stop.

**Fix:** Rename to `OMR_STORAGE_PREFIX` (an object-storage key prefix,
e.g. `omr-scans/`), not a filesystem path, to remove the ambiguity.

### 11. No CSRF protection mentioned despite cookie-based sessions (Sec 45)
"HTTP-only authentication" + "secure session management" is listed,
but CSRF isn't — and HTTP-only cookies are exactly the case that
needs CSRF tokens on state-changing requests (attendance edits,
result publication, etc.).

**Fix:** Add "CSRF protection on all state-changing endpoints" to
Section 45's required list.

### 12. Enumerable/guessable identifiers risk (Sec 45 "secure generated identifiers")
This is stated but vague. If `Student ID` (Section 12) doubles as the
public-facing identifier and is sequential, batches/rosters become
enumerable by any authenticated teacher account, or leak participant
counts externally.

**Fix:** Separate **internal DB primary key** (sequential is fine)
from **external/public identifier** (UUID or similarly non-sequential),
explicitly, in Section 43.

### 20. No account-activation flow for Admin-created accounts
If Admin creates the account, how does the teacher get their first
password? Admin **setting** a teacher's password directly is a
security anti-pattern — it means Admin can log in as any teacher.

**Fix:** Admin creates the account shell (name, email) only. The
system emails a time-limited invite link; the teacher sets their own
password on first use. Add `User.status`: `invited / active / disabled`.

### 21. No password-reset flow exists anywhere in the doc
Since there's no self-registration to fall back on, self-service
"forgot password" (emailed reset link) isn't optional — without it,
every lockout becomes a support ticket to Admin.

**Fix:** Add a standard email-based reset-link flow to Section 41,
same time-limited-token pattern as the invite flow above.

### 22. Teacher deactivation isn't addressed
When a teacher leaves, Admin needs to disable login without deleting
the account — hard-deleting would orphan every `AuditLog`,
`Attendance`, and `OMRSubmission.reviewed_by` row that references
"who did this." This is the exact historical-preservation principle
Section 14 already applies to students, just not yet applied to
`User`.

**Fix:** `User.status = disabled` on offboarding. Never a hard delete.

### 23. Teacher has no public-facing ID separate from the internal database key
Student already gets a `Student ID` (Section 12). Teacher doesn't.
For the same reason as item #12 (don't expose sequential internal
PKs), Teacher should get the same pattern for consistency, especially
since these accounts are all Admin-provisioned and worth tracking by
a stable human-facing ID (e.g. on printed OMR review sheets, reports).

**Fix:** Add `Teacher.public_id`, generated at creation, separate
from the internal primary key.

---

## 🟡 WORTH FLAGGING (scope/clarity gaps, not bugs yet)

### 13. Children's personal data, no privacy/retention policy (Sec 12, "real institutional use")
Student photos, DOB, guardian contact info, phone/email are all
collected for minors. The spec has no data-retention, access-scoping,
or consent language at all, despite being explicit that this is for
real institutional use.

**Fix (at minimum, add to Section 45):** who can view/export guardian
contact info and student photos beyond assigned teachers/admin, and
how long data is retained after a student leaves.

### 14. Session/schedule generation is undefined (Sec 10, 11)
"Week 1 / Session 1, 2" implies a recurring schedule, but nothing
says whether sessions are auto-generated (e.g. every Tue/Thu for a
batch) or manually created one at a time by a teacher. This affects
the Attendance data model directly.

**Fix:** State it — recommend auto-generating sessions from a
per-batch weekly schedule (2 sessions/week per Section 10), with
manual override for holidays/cancellations.

### 15. Custom field schema changes vs historical CustomFieldValue records (Sec 13, 14)
If Admin deletes or retypes a custom field (e.g. changes "Emergency
Contact" from text to a structured type), existing
`CustomFieldValue` rows for withdrawn/past students could become
orphaned or misread — conflicting with Section 14's "never destroy
historical data" rule.

**Fix:** Custom fields should be soft-deleted/deprecated, never hard
deleted, and type changes should create a new field rather than
mutate an existing one with historical values attached.

### 24. Object storage provider still isn't picked, and Vercel doesn't include one
Section 5's env vars (`STORAGE_ENDPOINT/ACCESS_KEY/SECRET_KEY`) read
as generic S3-compatible config. If you instead use Vercel Blob
(simplest native integration with a Vercel deployment), the
credential shape is different (`BLOB_READ_WRITE_TOKEN`, no endpoint/
access/secret triplet). Decide now so the env var spec in Section 5
actually matches what gets built — Vercel Blob vs. an S3-compatible
option (Cloudflare R2, AWS S3, Supabase Storage) are both reasonable,
but the doc currently assumes the latter shape without saying so.

### 25. Vercel Cron has plan-tied limits
If session auto-generation (item #14) or any nightly job (backups,
academic-year rollover) ends up needed, confirm the Vercel plan
supports the required frequency — lower tiers restrict cron to
infrequent runs. If more than that is needed, use an external
scheduler triggering a Vercel endpoint rather than assuming unlimited
in-platform cron.

---

## Summary of concrete data-model additions (Section 43 patch, cumulative)

```
Add:
  Role, Permission              (only if RBAC Option B — see #2)
  OlympiadPaper.version, .locked_at
  AnswerKey.version, .locked_at
  AssessmentResult.class_at_time_of_exam
  AssessmentResult.batch_at_time_of_exam
  AssessmentResult.paper_version_id
  OMRSubmission.status, .job_id
  Question.negative_marks
  Student.public_id              (separate from internal PK)
  Teacher.public_id              (separate from internal PK)
  User.status                    (invited / active / disabled)
```

---

## Priority order to fix these

1. **#17 + #18** — DB pooling and an external session/rate-limit/job
   store. These are Phase 1 (Foundation) decisions; get them wrong and
   every later phase inherits the mistake.
2. **#16** — OMR worker architecture, decided before Phase 1's backend
   shape is finalized (even though OMR itself is built in Phase 5).
3. **#19** — Android token auth vs. web cookie auth, decided during
   Phase 1's auth work, not bolted on in Phase 9.
4. **#4 + #5** — result snapshotting and paper/answer-key immutability,
   before Phase 5/6.
5. **#3** — ranking normalization across classes, before Phase 6.
6. **#2 + #20 + #21 + #22** — account lifecycle (roles, invite, reset,
   deactivate), before Phase 1 auth work ships.
7. **#1** — leaked IP, fix immediately, independent of build phase.
8. Everything else — incremental, no schema-migration risk.
