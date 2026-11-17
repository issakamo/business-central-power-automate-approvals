# Privacy Statement: Business Central Power Automate Approvals

> Portfolio project. This app is not a commercial product and is demonstrated only with Microsoft's CRONUS USA, Inc. demo data.

## Summary

Business Central Power Automate Approvals (PAA) stores approval and notification records inside your Business Central environment. It sends no data to the publisher, collects no telemetry, and contacts no external service itself. Data leaves Business Central only through business events and APIs that your own Power Automate flows subscribe to and call, inside your own Microsoft 365 and Power Platform tenant.

## Data the app stores

All data is stored in your Business Central environment, per company.

| Table | What it holds | Personal data |
|---|---|---|
| PAA Setup | On/off switches and the payment hold code | None |
| PAA Approval Request | Purchase order number, vendor number and name, risk level, match status, variance percentages, amount on hold, request status, decision comment | Approver email address, name of the person who decided |
| PAA Decision Log | Each action on a request: what happened, when, any comment, and whether it came from Business Central or a flow | Name or email of the person or identity that performed the action |
| PAA Exception Tracking | Warehouse exception number, last status reported, Planner task and Teams message references | None |
| PAA Flow Run Log | Flow name, run ID, result and error message for each flow run | None directly; an error message could contain data from the record being processed |

Fields that hold an email address or user name are classified as end-user identifiable information in the app's data classification, so they are handled correctly by Business Central's data classification and privacy tools.

## Data that leaves Business Central

PAA itself makes no outbound calls. Data leaves Business Central only in these ways, all configured and owned by you:

- **Business events.** When a purchase order becomes Critical or a high-priority warehouse exception is raised or closed, PAA raises a business event. Power Automate flows that you have subscribed receive a small payload: record identifiers, order or item numbers, vendor number and name, location, and risk or priority level.
- **APIs.** Your flows call PAA's APIs to read the full request or exception, record decisions, and log run results. These calls are authenticated with your own Microsoft Entra ID identities and limited by the PAA Flow Integration permission set.
- **Your flows.** What the flows do with the data, such as posting Teams cards, creating Planner tasks, or emailing a vendor (using the vendor's email address from the vendor card), happens in your own Microsoft 365 tenant under your control.

## Data the publisher receives

None. The publisher has no access to your environment, your flows, or any data processed by the app.

## Retention and removal

Records remain in Business Central until you delete them. When the app is uninstalled, Business Central keeps extension data by default; you can remove it by choosing to delete the extension's data during uninstall. Holds that PAA placed on vendor ledger entries use the hold code shown in PAA Setup (default `PAA`) and can be found and cleared by filtering on that code.

## Questions

Open an issue in the GitHub repository: https://github.com/issakamo/business-central-power-automate-approvals/issues

