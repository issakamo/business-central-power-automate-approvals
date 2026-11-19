namespace PowerAutomateApprovals.Integration;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;

codeunit 54102 "PAA Payment Hold Mgt"
{
    Access = Internal;
    Permissions = tabledata "Purchase Header" = rm;

    /// Puts the order header and its open posted-invoice entries on hold.
    /// Never overwrites a hold that someone else placed.
    procedure ApplyHold(OrderNo: Code[20]; HoldCode: Code[3]; var HeaderHeld: Boolean; var AmountOnHoldLCY: Decimal): Integer
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendEntryEdit: Codeunit "Vend. Entry-Edit";
        HeldCount: Integer;
    begin
        HeaderHeld := false;
        AmountOnHoldLCY := 0;

        // Holding the header makes any invoice posted from it later land on hold:
        // Purchase Header."On Hold" is copied to the vendor ledger entry at posting.
        if PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, OrderNo) then
            if PurchaseHeader."On Hold" = '' then begin
                PurchaseHeader."On Hold" := HoldCode;
                PurchaseHeader.Modify();
                HeaderHeld := true;
            end;

        PurchInvHeader.SetRange("Order No.", OrderNo);
        if PurchInvHeader.FindSet() then
            repeat
                if FindOpenInvoiceEntry(PurchInvHeader, VendorLedgerEntry) then
                    if VendorLedgerEntry."On Hold" = '' then begin
                        VendEntryEdit.SetOnHold(VendorLedgerEntry, HoldCode);
                        VendorLedgerEntry.CalcFields("Remaining Amt. (LCY)");
                        AmountOnHoldLCY += Abs(VendorLedgerEntry."Remaining Amt. (LCY)");
                        HeldCount += 1;
                    end;
            until PurchInvHeader.Next() = 0;

        exit(HeldCount);
    end;

    /// Clears only holds carrying this app's hold code, on the header and on
    /// every open posted-invoice entry of the order.
    procedure ReleaseHold(OrderNo: Code[20]; HoldCode: Code[3]): Integer
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendEntryEdit: Codeunit "Vend. Entry-Edit";
        ReleasedCount: Integer;
    begin
        if PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, OrderNo) then
            if PurchaseHeader."On Hold" = HoldCode then begin
                PurchaseHeader."On Hold" := '';
                PurchaseHeader.Modify();
            end;

        PurchInvHeader.SetRange("Order No.", OrderNo);
        if PurchInvHeader.FindSet() then
            repeat
                if FindOpenInvoiceEntry(PurchInvHeader, VendorLedgerEntry) then
                    if VendorLedgerEntry."On Hold" = HoldCode then begin
                        VendEntryEdit.SetOnHold(VendorLedgerEntry, '');
                        ReleasedCount += 1;
                    end;
            until PurchInvHeader.Next() = 0;

        exit(ReleasedCount);
    end;

    local procedure FindOpenInvoiceEntry(PurchInvHeader: Record "Purch. Inv. Header"; var VendorLedgerEntry: Record "Vendor Ledger Entry"): Boolean
    begin
        VendorLedgerEntry.Reset();
        VendorLedgerEntry.SetCurrentKey("Document No.", "Document Type", "Vendor No.");
        VendorLedgerEntry.SetRange("Document No.", PurchInvHeader."No.");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("Vendor No.", PurchInvHeader."Pay-to Vendor No.");
        VendorLedgerEntry.SetRange(Open, true);
        exit(VendorLedgerEntry.FindFirst());
    end;
}