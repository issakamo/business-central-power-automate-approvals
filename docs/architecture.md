# Architecture: Exception Approvals and Notifications (PAA)

This document describes the Business Central side of Project C: the PAA app, which raises business events for Power Automate, applies and releases payment holds, records every decision, and exposes the APIs the flows call back into. The flows themselves are designed in Part 2.

Source facts below were checked against the PCX 1.1.0.0 and WHX 1.0.0.0 source and the Business Central 29.0 Base Application source. Items not yet verified are listed in section 9.

## 1. Overview

```
 PCX (risk assessment inserted) ──┐                       ┌──> Teams approval card ──┐
                                  ├─> PAA app ─ business ─┤                          │
 WHX (exception inserted/changed)─┘     │       events    └──> Teams post + Planner  │
                                        │                                            │
                                        └──< API bound actions (approve, reject, <───┘
                                             escalate, log run result, set task)
```

| App | Role | Changed by Project C? |
|---|---|---|
| Purchase Control (PCX) 1.1.0.0 | Risk assessment and 3-way match | No (packaging split only, D-012) |
| Warehouse Control (WHX) 1.0.0.0 | Inventory exception detection | No (packaging split before Production, D-012) |
| Power Automate Approvals (PAA) | Events, holds, decisions, APIs | New app |

PAA depends on PCX and WHX and reacts only to their table events. Neither app knows PAA exists.

## 2. App identity

| Property | Value |
|---|---|
| Name | Business Central Power Automate Approvals |
| Prefix | PAA |
| Object IDs | 54100–54149 (test app: 54150–54199) |
| Runtime / application | 17.0 / 28.3 (same as PCX and WHX; runs in the BC 28.3 container and the BC 29.0 sandbox) |
| Dependencies | PCX 1.1.0.0, WHX 1.0.0.0 |
| Structure | `app/` and `test/` projects from the start (D-012) |
| API route | `/api/issakamo/approvals/v1.0/` |

## 3. Purchase approvals

### 3.1 Detecting "became Critical"

PCX writes every risk assessment as a new row in `PCX Purchase Risk Assessment` with `Insert(true)`, and skips a row that would repeat the previous one (`IsRedundantAssessment`).

PAA subscribes to that table's `OnAfterInsertEvent`. An approval request opens when all of these are true:

1. The new row's `Risk Level` is `Critical`.
2. The order's previous assessment row (the highest `Entry No.` below the new one, same `Document No.`) is not `Critical`, or there is no previous row.
3. No request for that order is already `Pending` or `Escalated`.
4. Approvals are enabled in PAA Setup.

**Why this table, not the purchase header:** each row stores the risk level at that moment, so PAA compares two stored rows and never depends on `xRec`, which is not reliable when code modifies a record.

### 3.2 The order header may not exist

Business Central deletes a purchase order once it is fully received and fully invoiced, which is often exactly when a price mismatch is found (PCX notes this in `AssessPurchaseOrder`). The approval request therefore stores the order number, vendor and assessment entry itself and never requires the header to exist.

### 3.3 Payment hold

Verified in the 29.0 source:

- `Vendor Ledger Entry."On Hold"` is a `Code[3]`.
- `Suggest Vendor Payments` filters `"On Hold"` to blank, so held entries are not suggested for payment.
- Codeunit 113 `"Vend. Entry-Edit"` has a public procedure `SetOnHold(var VendorLedgerEntry, NewOnHold: Code[3])`. The codeunit holds `TableData "Vendor Ledger Entry" = m` and records the change through change tracking.
- `Purchase Header."On Hold"` is copied to `Gen. Journal Line."On Hold"` at posting, and from there to `Vendor Ledger Entry."On Hold"`.
- `Purch. Inv. Header."Order No."` links a posted invoice to its order.

**Applying the hold** (when a request opens):

1. If the order header exists and its `On Hold` is blank, set it to the hold code. Any invoice posted from the order later then lands on hold automatically.
2. For each posted invoice whose `Order No.` is the order, find its open vendor ledger entry. If `On Hold` is blank, call `SetOnHold` with the hold code.
3. A non-blank hold placed by someone else is never overwritten.

**Releasing the hold** (on approve): the same search, but only entries and a header whose `On Hold` equals the hold code are cleared. A hold an AP clerk placed for another reason stays.

**Hold code:** `PAA`, from PAA Setup. The code itself marks which holds PAA owns, so no separate table of held entries is needed.

### 3.4 Request lifecycle

```
            open                approve
  (none) ─────────> Pending ──────────────> Approved   (hold released)
                      │   └───────────────> Rejected   (hold kept, vendor emailed)
                      │ escalate
                      v       approve / reject
                   Escalated ─────────────> Approved / Rejected
  Pending or Escalated ── cancel (admin, in BC) ──> Cancelled (hold released)
```

Rules enforced in AL, not in the flow:

- Only a `Pending` or `Escalated` request accepts a decision. A second decision is refused with an error, so a request cannot be decided twice.
- Reject requires a comment.
- Escalate is only allowed from `Pending`.
- Every state change writes a row to the decision log.

The 24-hour escalation timer lives in the flow (Part 2). Business Central only records that escalation happened and to whom.

## 4. Warehouse notifications

### 4.1 New exceptions

Both WHX creators (`CreateStockException`, `CreateReceivingException`) set `Priority` before `Insert(true)`. PAA subscribes to `WHX Inventory Exception.OnAfterInsertEvent`. For priority `High` or `Critical` (and notifications enabled), it creates a tracking row and raises the "exception raised" event.

### 4.2 Closed exceptions

Status can change through the **Resolve** action (`Validate` + `Modify(true)`) or by editing **Status** directly on the card, and `Cancelled` also exists. PAA subscribes to `OnAfterModifyEvent` and compares the record's `Status` with the **last status stored in its own tracking row**, not with `xRec`. When an exception moves to `Resolved` or `Cancelled` for the first time, PAA updates the tracking row and raises the "exception closed" event. Repeated saves raise nothing.

Business Central is the source of truth; Planner follows it one way (D-010).

## 5. Data model

| ID | Table | Purpose | Key fields |
|---|---|---|---|
| 54100 | PAA Setup | Single record: switches and hold code | Approvals Enabled, Exception Notifications Enabled, Hold Code (default `PAA`) |
| 54101 | PAA Approval Request | One row per request | Entry No. (PK), Order No., Vendor No., Vendor Name, Assessment Entry No., Risk Level, Match Status, Price Variance %, Quantity Variance %, Amount on Hold, Status, Current Approver Email, Escalated At, Decided By, Decided At, Decision Comment, Vendor Notified At |
| 54102 | PAA Decision Log | Append-only audit of every request action | Entry No. (PK), Request Entry No., Action, Performed By, Performed At, Comment, Source (Business Central or Flow) |
| 54103 | PAA Exception Tracking | One row per notified WHX exception | Exception Entry No. (PK), Last Notified Status, Planner Task Id, Teams Message Id, Notified At, Closed Notified At |
| 54104 | PAA Flow Run Log | Result of every flow run | Entry No. (PK), Flow Name, Run Id, Source Type, Source Entry No., Result, Message, Logged At |

Enums: 54100 PAA Request Status (Pending, Escalated, Approved, Rejected, Cancelled); 54101 PAA Log Action (Requested, Hold Applied, Escalated, Approved, Rejected, Hold Released, Vendor Notified, Cancelled); 54102 PAA Log Source; 54103 PAA Run Result (Succeeded, Failed). Enum extension 54100 extends `EventCategory` with two values in our own range.

## 6. Business events

All events are thin: identifiers plus a few display values, using only the types shown in Microsoft's examples (Guid, Code, Text, Integer). Each flow then reads the full record through the API (section 7). This means:

- A flow never acts on data that was rolled back: if the record isn't there, or isn't pending, the flow stops (D-018).
- Payloads stay stable while the API can grow.

| Name | Display name | Raised when | Payload |
|---|---|---|---|
| `paaapprovalrequested` | Purchase approval requested | A request opens (3.1) | requestId (Guid, SystemId), requestEntryNo, orderNo, vendorNo, vendorName, riskLevel |
| `paaexceptionraised` | Warehouse exception raised | A High or Critical exception is inserted (4.1) | exceptionId (Guid, SystemId), exceptionEntryNo, itemNo, locationCode, exceptionType, priority |
| `paaexceptionclosed` | Warehouse exception closed | An exception first reaches Resolved or Cancelled (4.2) | exceptionId, exceptionEntryNo, newStatus, plannerTaskId |

All events start at version `1.0`. A later breaking change adds a new version and obsoletes the old one rather than changing it.

## 7. APIs

Publisher `issakamo`, group `approvals`, version `v1.0`, keyed on `SystemId`.

| Page | Entity | Access | Bound actions |
|---|---|---|---|
| 54120 PAA Approval Request API | `approvalRequest` | Read | `approve(approverEmail, comment)`, `reject(approverEmail, comment)`, `escalate(newApproverEmail)`, `markVendorNotified()` |
| 54121 PAA Exception API | `inventoryException` (WHX table, read-only, with tracking fields added) | Read, filterable on status for the daily digest | `setPlannerTask(plannerTaskId, teamsMessageId)` |
| 54122 PAA Flow Run API | `flowRun` | Insert only | none |

The request API also returns the vendor's email address so the reject flow can write to the vendor.

Bound actions call the same AL procedures as the Business Central pages, so the rules in 3.4 apply whichever way a decision arrives.

## 8. Permissions

| Permission set | For | Contents |
|---|---|---|
| PAA Flow Integration | The identity the flows connect as | Read on approval requests, tracking and WHX exceptions; modify on requests and tracking; insert on decision log and flow run log; execute on the API pages; indirect modify on Vendor Ledger Entry and Purchase Header (hold release). Nothing else. |
| PAA Approvals User | Business Central users | Read on all PAA tables and pages; Setup and Cancel for the manager role |

Posting users do not need a PAA permission set. The procedures that write PAA tables during posting declare `[InherentPermissions]` for PAA's own tables only, scoped to that procedure (runtime 9.0 or later; allowed only for objects in the same extension). Base-app changes such as the payment hold go through codeunit 113, which posting users can already run.

## 9. Open verification items

| ID | Item | How we verify | When |
|---|---|---|---|
| V-01 | Are business events still delivered if the transaction that raised them rolls back (for example during Preview Posting)? | Run Preview Posting on a mismatched invoice with a flow subscribed; record the result. The design is safe either way (D-018). | Part 1, after publishing |
| V-02 | Does a codeunit's `Permissions` property (codeunit 113) require the user to hold indirect permission on the table? | Approve a request as a user holding only PAA Flow Integration. | Part 1 |
| V-03 | Does setting the header's `On Hold` inside PCX's assessment run cause a "record changed" conflict on release, receipt or invoice posting? | Automated tests for each of PCX's three triggers. | Part 1 |
| V-04 | Can PAA's tables be written during posting by users without a PAA permission set? | Documentation confirms `[InherentPermissions]` on methods, for objects in the same extension. Still to prove: post as a user without PAA permission sets. | Part 1, after publishing |
| V-05 | Which Business Central connector action calls a bound action? | Check in the flow designer. | Part 2 |

## 10. Test plan

Automated (test app, BCLocalDev container):

| ID | Test |
|---|---|
| T-01 | Low to Critical opens one request, holds the open invoice entry with `PAA`, and holds the order header. |
| T-02 | A new Critical row after Critical (for example a different match status) opens no second request. |
| T-03 | An entry already on hold with another code is neither overwritten nor released. |
| T-04 | Approve releases only `PAA` holds, sets status Approved, and logs it. |
| T-05 | Reject keeps the hold, requires a comment, and logs it. |
| T-06 | A second decision on a decided request raises an error. |
| T-07 | A request still opens and holds the entry when the order header has been deleted. |
| T-08 | An invoice posted while a request is pending lands on hold. |
| T-09 | A High exception creates a tracking row; a Low one does not. |
| T-10 | Resolving through the action and through the Status field each produce exactly one closed notification. |

Manual (Dev sandbox): V-01, V-02, V-04, the events appearing in the connector trigger, and Suggest Vendor Payments skipping a held invoice and including it after approval.

