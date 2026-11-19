namespace PowerAutomateApprovals.Integration;

using Microsoft.Finance.Currency;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Integration.Entity;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.Diagnostics;

permissionset 54102 "PAA Flow Integration"
{
    Caption = 'Power Automate Approvals Flow Integration';
    Assignable = true;

    Permissions =
        // PAA's own data
        tabledata "PAA Setup" = R,
        tabledata "PAA Approval Request" = RM,
        // Releasing the hold: header and ledger entries change only through PAA and codeunit 113
        tabledata "Purchase Header" = Rm,
        tabledata "Purch. Inv. Header" = R,
        tabledata "Vendor Ledger Entry" = Rm,
        tabledata Vendor = R,
        // Microsoft's purchase order API buffer, synced by codeunit 5497 when the header changes
        tabledata "Purchase Order Entity Buffer" = rim,
        tabledata "Purchase Line" = R,
        tabledata Currency = R,
        tabledata "Payment Terms" = R,
        tabledata "Shipment Method" = R,
        // Microsoft's invoice and credit memo API buffers, synced by codeunits 5529 and 5511 when a ledger entry changes
        tabledata "Purch. Inv. Entity Aggregate" = rm,
        tabledata "Purch. Cr. Memo Entity Buffer" = r,
        tabledata "Cancelled Document" = R,
        // Change log written by codeunit 423 for every ledger-entry hold change (codeunit 106 forces it)
        tabledata "Change Log Setup" = r,
        tabledata "Change Log Setup (Table)" = r,
        tabledata "Change Log Setup (Field)" = r,
        tabledata "Change Log Entry" = ri,
        // Objects
        table "PAA Approval Request" = X,
        page "PAA Approval Request API" = X,
        codeunit "PAA Approval Mgt" = X,
        codeunit "PAA Payment Hold Mgt" = X,
        codeunit "Vend. Entry-Edit" = X;
}