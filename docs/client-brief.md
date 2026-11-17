# Client Brief: Exception Approvals and Notifications

> Portfolio project. CRONUS USA, Inc. is Microsoft's Business Central demo company. The scenario, people and requirements below are invented for this project.

## The business

| | |
|---|---|
| **Company** | CRONUS USA, Inc. (Business Central online, US localization) |
| **Already in use** | Purchase Control (PCX): 3-way match and purchase order risk scoring. Warehouse Control (WHX): inventory exception detection. |
| **Collaboration tools** | Microsoft Teams, Planner and Outlook (Microsoft 365) |
| **Environments** | Business Central Dev sandbox and Production (version 29.0) |

## The problem

1. **Critical purchase orders are only visible inside Business Central.** Purchase Control flags a purchase order as Critical, for example after an invoice is posted at a different price than ordered. But nobody is told, and the invoice can still be picked up by the next payment run.
2. **Critical risk is often detected after the invoice is posted.** The 3-way match compares the order with posted receipts and posted invoices. So the control point that still exists at that moment is payment, not invoicing.
3. **Warehouse exceptions wait for someone to open the Role Center.** Warehouse staff work from Teams, not from Business Central. Exceptions have no owner or task, and nothing chases the ones left open.
4. **Decisions are not recorded.** When a manager approves an exception by email or in conversation, there is no record in Business Central of who decided, when, or why.

## People involved

| Role | What they do in this process |
|---|---|
| Purchasing manager | First approver for Critical purchase orders, in Teams |
| Finance controller | Second approver when the purchasing manager does not respond in time |
| AP clerk | Runs vendor payments; relies on held invoices being excluded |
| Warehouse lead | Receives exception alerts and tasks; resolves exceptions in Business Central |
| Vendor (external) | Receives an email when an invoice is rejected |
| Business Central administrator | Deploys the app and the flows; receives failure alerts |

## Requirements

### Purchase approvals (Purchase Control)

| ID | Requirement |
|---|---|
| R-01 | When a purchase order's current risk level changes to Critical, Business Central raises an external business event. The payload identifies the order, vendor, risk level, match status, amount and the risk assessment that caused it. |
| R-02 | At the same moment, Business Central places the order's open invoices on payment hold, and any invoice posted for that order while the approval is pending is also held. |
| R-03 | The purchasing manager receives a Teams adaptive card with the order details and Approve and Reject buttons. A comment is required to reject. |
| R-04 | Approve: the payment hold is released. Reject: the hold stays, and the vendor receives an email asking for a corrected invoice or a credit memo. |
| R-05 | If there is no response within a configurable time (24 hours in production), the request escalates to the finance controller, and the first card no longer accepts a decision. |
| R-06 | Decisions are written back to Business Central through an A-P-I bound action. Business Central accepts a decision only while the request is pending, so a request cannot be decided twice. |
| R-07 | Each request and decision is logged in Business Central: who, when, decision, comment and escalation, and it is visible from the purchase order. |

### Warehouse notifications and tasks (Warehouse Control)

| ID | Requirement |
|---|---|
| R-08 | When an inventory exception is created with priority High or Critical, Business Central raises an external business event. |
| R-09 | The flow posts the exception to a warehouse Teams channel and creates a Planner task. The task reference is stored back in Business Central. |
| R-10 | When the exception is resolved in Business Central, the Planner task is completed and the Teams post gets a reply with the resolution notes. |
| R-11 | On weekdays at a configurable time, a digest of all open exceptions is posted to the warehouse channel. |

### Quality and operations

| ID | Requirement |
|---|---|
| R-12 | All flows live in one Power Platform solution, using environment variables (Business Central environment and company, approvers, Teams team and channel, timeouts) and connection references. |
| R-13 | Business Central calls use retries; failures send an alert to the administrator; each flow run's result is logged back to Business Central. |
| R-14 | The flow connection uses a least-privilege permission set from the PAA app. |
| R-15 | The exported solution is committed to the repo, with a deployment guide from Dev to Production. |
| R-16 | The A-L logic (events, holds, decision validation) is covered by automated tests. |

## Out of scope

- **Invoice capture.** Business Central's Payables Agent already drafts purchase invoices from emailed PDFs. This project works on top of whatever created the invoice.
- **Copilot agents, the Business Central MCP server and Agent Designer.** Possible later project.
- **Approval before an order is released, and amount-based approval matrices.** This project handles risk-triggered exceptions with one escalation step.
- **Two-way Planner sync.** Completing a Planner task does not resolve the exception; Business Central stays the source of truth.
- **Reading vendor replies.** Vendors are notified by email; their replies are handled by people.
- **Multiple companies.** One company, CRONUS USA, Inc.

## Success criteria

1. Posting an invoice that makes a purchase order Critical produces a Teams card and an invoice on hold, with no manual step.
2. After Approve, Suggest Vendor Payments includes the invoice. After Reject, it still excludes it and the vendor email has been sent.
3. With the timeout set to a few minutes, an unanswered request escalates to the second approver.
4. Every decision appears in the Business Central log, and a second decision on the same request is refused.
5. A High or Critical exception creates a channel post and a Planner task; resolving it in Business Central completes the task.
6. The daily digest lists the same open exceptions as Business Central's exception list.
7. A failed Business Central call produces an administrator alert and a failed run in the log, not a silent failure.
8. The solution is deployed to a second environment using only the deployment guide, by setting environment variables and connections, with no flow edits.
9. All A-L tests pass.

## Open questions

- How the Business Central connector authenticates, and which identity the flows run as.
- How the Teams "wait for a response" action handles timeouts, and the escalation design that follows from it.
- A second Microsoft 365 user is needed to demo the second approver.
- How many Power Platform environments are needed to demonstrate a Dev to Production deployment.
- PCX and WHX versions and runtime compared with Business Central 29.0, before publishing them to the Dev sandbox.
