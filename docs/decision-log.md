# Decision Log: Exception Approvals and Notifications

| ID | Date | Decision | Reason | Status |
|---|---|---|---|---|
| D-001 | 2026-11-14 | Trigger flows with **external business events** raised in A-L, using the connector trigger **When a business event occurs**, not record-change triggers. | The event is raised exactly when the business condition happens, with a payload designed for the flow. Record-change triggers run through a job queue and do not fire for changes made by delegated admin accounts. | Agreed |
| D-002 | 2026-11-14 | Do not build invoice capture. | Business Central's Payables Agent already drafts purchase invoices from emailed vendor invoices. The value here is the match and risk logic and the approval routing on top of any invoice source. | Agreed |
| D-003 | 2026-11-14 | Leave out Copilot agents, the Business Central MCP server and Agent Designer. | Too new for a stable portfolio project; possible later project. | Agreed |
| D-004 | 2026-11-14 | **Teams adaptive cards** for internal approvals and alerts; **email** for vendors. | Approvers and warehouse staff work in Teams; vendors are external and have no Teams access. | Agreed |
| D-005 | 2026-11-14 | The purchase approval controls a **payment hold**, using the standard On Hold field on vendor ledger entries. Approve releases it; Reject keeps it and notifies the vendor. | Critical risk is usually detected after the invoice is posted, so payment is the remaining control point. Suggest Vendor Payments excludes entries on hold, which matches how AP teams handle disputed invoices. No change to posting code. | Agreed |
| D-006 | 2026-11-14 | Business Central applies the hold itself when it raises the event. The flow only releases or keeps it. | Fail safe: if the flow fails or is delayed, the invoice is still protected from the next payment run. | Agreed |
| D-007 | 2026-11-14 | Use **CRONUS USA, Inc.** as the client company. | PCX and WHX were built and demoed on CRONUS data, which already exists in the Dev sandbox. Keeps the Queen City Supply Co. migration company in its reconciled state. | Agreed |
| D-008 | 2026-11-14 | Build a **new app that depends on PCX and WHX**, reacting to their table events, instead of changing those apps. | Keeps the finished apps and their videos accurate; mirrors how partners build separate integration extensions; gives the flow connection one permission boundary. | Agreed |
| D-009 | 2026-11-14 | Repo `business-central-power-automate-approvals`, object prefix **PAA**. | Matches the naming of the other portfolio repos and puts the main technology in the name. | Agreed |
| D-010 | 2026-11-14 | Business Central is the **source of truth** for exception status; Planner tasks follow it one way. No resolve action from Planner. | Resolving in Business Central enforces Resolution Notes. Two-way sync would let a task completion bypass that rule. | Agreed |
| D-011 | 2026-11-14 | Flows live in a Power Platform **solution** with **environment variables** and **connection references**. | Lets the same solution move from Dev to Production with configuration only, and makes timeouts adjustable for testing. | Agreed |
| D-012 | 2026-11-16 | Split PCX and WHX each into a **main app** with no test dependencies and a separate **test app** (version 1.1.0.0, no business-logic changes). PCX done; WHX before the Production deployment. | Test libraries can only be installed in sandboxes, and Tests-TestLibraries is not available in the Dev sandbox (I-001). Main apps must install in any environment; tests run where the libraries exist. | Agreed |


