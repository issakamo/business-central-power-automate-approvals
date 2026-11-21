# Architecture: Exception Approvals and Notifications (PAA)

This document describes the Business Central side of Project C: the PAA app, which raises business events for Power Automate, applies and releases payment holds, records every decision, and exposes the APIs the flows call back into. The flows themselves are designed in Part 2.

Source facts were checked against the PCX 1.1.0.0 and WHX 1.0.0.0 source and the Business Central 28.3 and 29.0 Base Application source. Section 10 lists what was verified and how.

## 1. Overview

```
 PCX (risk assessment inserted) ──┐                       ┌──> Teams approval card ──┐
                                  ├─> PAA app ─ business ─┤                          │
 WHX (exception inserted/changed)─┘     │       events    └──> Teams post + Planner  │
                                        │                                            │
                                        └──< API bound actions (approve, reject, <───┘
                                             escalate, mark vendor notified,
                                             set Planner task) and flow run log
```

| App | Role | Changed by Project C? |
|---|---|---|
| Purchase Control (PCX) 1.1.0.0 | Risk assessment and 3-way match | No (packaging split only, D-012) |
| Warehouse Control (WHX) 1.0.0.0 | Inventory exception detection | No (packaging split before Production, D-012, I-003) |
| Power Automate Approvals (PAA) 1.0.0.0 | Events, holds, decisions, APIs | New app |

PAA depends on PCX and WHX and reacts only to their table events. Neither app knows PAA exists.

## 2. App identity

| Property | Value |
|---|---|
| Name | Business Central Power Automate Approvals |
| Prefix | PAA (enforced by AppSourceCop) |
| Namespace | `PowerAutomateApprovals.Integration` |
| Object IDs | 54100–54149 (test app: 54150–54199) |
| Runtime / application | 17.0 / 28.3; runs in the BC 28.3 container and the BC 29.0 sandbox (D-020) |
| Dependencies | PCX 1.1.0.0, WHX 1.0.0.0 |
| Structure | `app/` and `test/` projects (D-012); `internalsVisibleTo` names the test app only (D-026) |
| API route | `/api/issakamo/approvals/v1.0/` |

## 3. Purchase approvals

### 3.1 Detecting "became Critical"

PCX writes every risk assessment as a new row in `PCX Purchase Risk Assessment` with `Insert(true)` and skips a row that would repeat the previous one. PAA subscribes to that table's `OnAfterInsertEvent` and opens a request when all of these are true:

1. The new row's `Risk Level` is `Critical`.
2. The order's previous assessment row is not `Critical`, or there is none.
3. No request for the order is `Pending` or `Escalated`.
4. Purchase Approvals is enabled in PAA Setup.

The comparison uses stored rows, never `xRec` (D-013).

**When an order can become Critical.** PCX scores 50 % or more variance as Critical, 20 % High, 5 % Medium, and raises a quantity-and-price mismatch one more level. On **release** nothing has been received, so the match status is "Not Yet Received" (Low, or Medium if overdue): **an order cannot become Critical on release.** Requests open on **receipt** (quantity variance) or **invoice** (price variance).

### 3.2 Transactions

`Purch.-Post` commits (`CommitAndUpdateAnalysisVeiw`) **before** it raises `OnAfterPostPurchaseDoc`, the event PCX uses. PCX's assessment and PAA's request and hold therefore run in a new transaction after the posting is saved. If PCX or PAA failed there, the receipt or invoice would remain posted without a request or hold (I-006). PAA's code is defensive and its writes use inherent permissions, which keeps that unlikely; Part 4 adds a scheduled check for Critical orders without a request to close the gap.

### 3.3 The order header may not exist

Business Central deletes an order once it is fully received and invoiced, often when a price mismatch is found. Requests store the order number, vendor and assessment entry and never require the header (D-014).

### 3.4 Payment hold

Verified in the 29.0 source:

- `Vendor Ledger Entry."On Hold"` is `Code[3]`; `Suggest Vendor Payments` filters it to blank.
- Codeunit 113 `Vend. Entry-Edit`, `SetOnHold(var VendorLedgerEntry, NewOnHold)`, holds the modify permission. It binds codeunit 106, which forces Business Central's Change Log to record every hold change, giving an independent audit record.
- `Purchase Header."On Hold"` is copied to `Gen. Journal Line` and then to the new ledger entry at posting.
- `Purch. Inv. Header."Order No."` links a posted invoice to its order.

**Applying** (when a request opens): hold the order header if its `On Hold` is blank, so later invoices land on hold; hold each open posted-invoice entry of the order whose `On Hold` is blank. A non-blank hold placed by someone else is never overwritten.

**Releasing** (approve or cancel): clear only the header and entries whose `On Hold` equals the hold code (D-016).

**Hold code:** `PAA` from PAA Setup. It cannot be blank, and cannot be changed while requests are open.

### 3.5 Request lifecycle

```
            open                approve
  (none) ─────────> Pending ──────────────> Approved   (hold released)
                      │   └───────────────> Rejected   (hold kept; vendor can be marked notified)
                      │ escalate
                      v       approve / reject
                   Escalated ─────────────> Approved / Rejected
  Pending or Escalated ── cancel (PAA Admin) ──> Cancelled (hold released)
```

Rules enforced in AL for every caller (pages and API):

- Each decision locks and re-reads the request; only `Pending` or `Escalated` accepts a decision, so simultaneous decisions cannot both succeed.
- Reject requires a comment; cancel requires a reason.
- Escalate only from `Pending`; mark vendor notified only on `Rejected`.
- Every action is logged with its source (Business Central or Flow) and who performed it. For flow decisions this is the approver's email address, which the API requires.
- Decisions use real permissions, not inherent ones: only PAA Admin or the flow identity can decide.

The escalation timer lives in the flow (Part 2).

## 4. Warehouse notifications

### 4.1 Raised

PAA notifies an exception when it is open, `High` or `Critical`, not yet tracked, and notifications are enabled. This is checked:

- on `OnAfterInsertEvent`: WHX's creators set `Priority` before `Insert(true)`;
- on `OnAfterModifyEvent` for untracked exceptions: `Priority` is editable on the WHX card, so an exception raised to High later is notified then.

### 4.2 Closed

In WHX, `Status` changes through the **Resolve** action (`Status` is not editable on the card). PAA compares the exception's status with the last status stored in its tracking row, not `xRec` (D-017). The first time a tracked exception reaches `Resolved` or `Cancelled`, PAA records the time and raises the closed event. It is raised only once; reopening a resolved exception is out of scope.

Business Central is the source of truth; Planner follows it one way (D-010), and the flows cannot change WHX exceptions.

### 4.3 Switch

Turning off Warehouse Notifications stops both events. Planner tasks open at that moment are not closed automatically (deployment guide).

## 5. Data model

| ID | Table | Purpose |
|---|---|---|
| 54100 | PAA Setup | Approvals Enabled and Notifications Enabled (both off at install), Hold Code (`PAA`) |
| 54101 | PAA Approval Request | One row per request: order, vendor, assessment, risk snapshot, amount on hold, status, approver, decision, vendor notified |
| 54102 | PAA Decision Log | Append-only audit of every request action: action, source, performed by, time, comment |
| 54103 | PAA Exception Tracking | One row per notified exception (key = exception entry number): last notified status, Planner task and Teams message references, notified and closed times |
| 54104 | PAA Flow Run Log | Every flow run: flow name, run ID, source type and entry, result, message; `Logged At` set by the server |

Enums: 54100 PAA Request Status and 54101 PAA Log Action (both non-extensible, because they drive the state rules), 54102 PAA Log Source, 54103 PAA Run Result, 54104 PAA Source Type (`None`, `ApprovalRequest`, `InventoryException`: no spaces, because flows send these values). Enum extension 54100 adds two `EventCategory` values in PAA's range.

Fields holding an email address or user name are classified `EndUserIdentifiableInformation`.

## 6. Business events

Thin payloads (identifiers and a few display values, as Guid, Code, Text and Integer); every flow reads the record back through the API and stops if it is missing or no longer pending (D-018). Text values such as `riskLevel`, `priority` and `newStatus` are enum **names**, not captions, so flow conditions don't depend on the user's language. The events are declared `local` and raised through internal wrappers, so only PAA can raise them; all are version `1.0`.

| Name | Category | Raised when | Payload |
|---|---|---|---|
| `paaapprovalrequested` | Purchase Approvals | A request opens (3.1) | requestId, requestEntryNo, orderNo, vendorNo, vendorName, riskLevel |
| `paaexceptionraised` | Warehouse Exceptions | An exception is first notified (4.1) | exceptionId, exceptionEntryNo, itemNo, locationCode, exceptionType, priority |
| `paaexceptionclosed` | Warehouse Exceptions | A tracked exception first reaches Resolved or Cancelled (4.2) | exceptionId, exceptionEntryNo, newStatus, plannerTaskId |

Because receipt and invoice postings commit before the events are raised (3.2), a rolled-back posting cannot raise them. Whether Preview Posting raises them is V-01.

## 7. APIs

Publisher `issakamo`, group `approvals`, version `v1.0`, keyed on `SystemId`. None of the pages allows modify or delete; the only way to change data is a bound action that runs PAA's rules.

| Page | Entity | Access | Bound actions |
|---|---|---|---|
| 54120 PAA Approval Request API | `approvalRequests` | Read; includes `vendorEmail` (read live from the vendor card) and `matchStatusText` | `approve(approverEmail, comment)`, `reject(approverEmail, comment)`, `escalate(newApproverEmail)`, `markVendorNotified()` |
| 54121 PAA Exception API | `inventoryExceptions` (WHX table) | Read; includes `exceptionTypeText`, `plannerTaskId` and `teamsMessageId` from tracking; filterable on status for the daily digest | `setPlannerTask(plannerTaskId, teamsMessageId)` |
| 54122 PAA Flow Run API | `flowRuns` | Insert and read only | none |

A successful bound action returns 200 with the record's location; a refused one returns 400 with PAA's message. Readable text fields sit next to enums whose values contain spaces, because OData encodes spaces in enum member names. On page 54121, the parameter names deliberately match the field names (the API contract), with AA0245 suppressed for that one procedure.

## 8. Permissions

| Permission set | Scope | For | Contents |
|---|---|---|---|
| PAA User | System (in AL) | Business Central users | Read requests, decision log and flow run log; their pages |
| PAA Admin | System (in AL) | Administrators | Includes PAA User; setup; decide and cancel from Business Central |
| PAA Flow Integration | System (in AL) | The flow identity | See below |
| PAA FLOW BASE | Tenant (created in the client) | The flow identity | Execute on all codeunits and table objects (Object ID 0); no data access (D-023) |

**PAA Flow Integration**, traced against the BC 29.0 source (D-019, D-024):

| Group | Permissions | Why |
|---|---|---|
| PAA data | Setup R; Approval Request RM; Exception Tracking RM; Flow Run Log RI | PAA's own tables; no access to the decision log, which is written through inherent permission |
| Hold release | Purchase Header Rm; Vendor Ledger Entry Rm; Purch. Inv. Header R; Vendor R | Lowercase = indirect: the header changes only through PAA's codeunit, entries only through codeunit 113 |
| Purchase order API buffer | Purchase Order Entity Buffer rim; Purchase Line, Currency, Payment Terms, Shipment Method R | Codeunit 5497 resyncs Microsoft's buffer when a header changes |
| Invoice and credit memo API buffers | Purch. Inv. Entity Aggregate rm; Purch. Cr. Memo Entity Buffer r; Cancelled Document R | Codeunits 5529 and 5511 react when a ledger entry changes |
| Change log | Change Log Setup, Setup (Table), Setup (Field) r; Change Log Entry ri | Codeunit 423 records every hold change (forced by codeunit 106) |
| Warehouse | WHX Inventory Exception R; Item R | Read only: flows cannot resolve exceptions (D-010) |

Posting users need no PAA permission set: the procedures that write PAA tables during posting and warehouse changes use `[InherentPermissions]` for PAA's own tables only (D-021).

PAA FLOW BASE exists because platform code such as codeunits 7233 and 36951 runs in every writing session, and codeunit 7233 is not in the AL symbols, so it cannot be referenced in AL (I-005). It must be created in each environment (deployment guide).

## 9. Tests

The test app depends on **Application Test Library**, not Tests-TestLibraries: in 28.3, `Library - Purchase`, `Library - Inventory` and `Library - Random` moved there, and it can be installed in SaaS sandboxes (D-025). Each test sets PAA Setup itself and creates its own vendor and item. Because posting commits before PCX and PAA run, every `asserterror` is the last step of its test (I-006).

| Codeunit | Tests | Covers |
|---|---|---|
| 54150 PAA Approval Request Tests | 10 | Critical on invoice with the header deleted; Critical on receipt with a later invoice held; no second request; foreign holds untouched; approve; reject with and without a comment; approve twice; cancel without a reason; approvals off |
| 54151 PAA Exception Notif. Tests | 4 | Only High and Critical tracked; raised to High later; closed only once; notifications off |

All 14 pass in the BC 28.3 container.

## 10. Verification items

| ID | Item | Result |
|---|---|---|
| V-01 | Does Preview Posting raise business events? | Open. Test with a live flow subscription (Part 1, step 7). |
| V-02 | Does codeunit 113's `Permissions` property work for an identity with indirect permission only? | **Confirmed** via the API with an Entra app holding only the flow permission sets (I-005). |
| V-03 | Does holding the header inside PCX's run cause a "record changed" conflict? | **Confirmed safe** for receipt and invoice by tests S1–S4; release cannot produce Critical (3.1). |
| V-04 | Can users without a PAA permission set post? | Documentation confirms `[InherentPermissions]`; to prove with a second user in Part 2. |
| V-05 | Which connector action calls a bound action? | Open (Part 2). |
