namespace PowerAutomateApprovals.Integration.Tests;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using PowerAutomateApprovals.Integration;
using PurchaseControl.Purchasing;
using System.TestLibraries.Utilities;

codeunit 54150 "PAA Approval Request Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        ApprovalMgt: Codeunit "PAA Approval Mgt";
        PAAHoldCode: Code[3];

    // Note: purchase posting commits before PCX and PAA run (I-006), and asserterror
    // rolls back to the last commit. So every asserterror is the last step of its test.

    // S1 (T-01, T-07): Critical on invoice; the order header is already deleted.
    [Test]
    procedure CriticalOnInvoiceOpensRequestAndHoldsInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        Request: Record "PAA Approval Request";
        OrderNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [GIVEN] Approvals enabled, an order for 10 received in full at 100
        Initialize(true);
        CreateOrder(PurchaseHeader, 10);
        OrderNo := PurchaseHeader."No.";
        Receive(PurchaseHeader, 10);

        // [WHEN] All 10 are invoiced at 160 (60% price variance: Critical)
        InvoiceNo := InvoiceAtUnitCost(PurchaseHeader, 10, 160);

        // [THEN] One pending request, the invoice entry is held, the header is gone
        FindOnlyRequest(OrderNo, Request);
        Assert.IsTrue(Request.Status = Request.Status::Pending, 'The request should be Pending.');
        Assert.AreEqual(PAAHoldCode, InvoiceEntryHold(InvoiceNo), 'The invoice entry should be on hold with the PAA code.');
        Assert.IsFalse(PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, OrderNo), 'A fully received and invoiced order should be deleted.');
        Assert.IsTrue(LogContains(Request."Entry No.", Enum::"PAA Log Action"::Requested), 'Requested should be logged.');
        Assert.IsTrue(LogContains(Request."Entry No.", Enum::"PAA Log Action"::"Hold Applied"), 'Hold Applied should be logged.');
    end;

    // S2 (V-03 receipt trigger, T-08): Critical on receipt; a later invoice lands on hold.
    [Test]
    procedure CriticalOnReceiptHoldsHeaderAndLaterInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        Request: Record "PAA Approval Request";
        OrderNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [GIVEN] Approvals enabled, an order for 10
        Initialize(true);
        CreateOrder(PurchaseHeader, 10);
        OrderNo := PurchaseHeader."No.";

        // [WHEN] Only 4 are received (60% quantity variance: Critical)
        Receive(PurchaseHeader, 4);

        // [THEN] A request is open and the order header is held
        FindOnlyRequest(OrderNo, Request);
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, OrderNo);
        Assert.AreEqual(PAAHoldCode, PurchaseHeader."On Hold", 'The order header should be on hold with the PAA code.');

        // [WHEN] The 4 received are invoiced at the original price while the request is pending
        InvoiceNo := InvoiceAtUnitCost(PurchaseHeader, 4, 100);

        // [THEN] The new invoice entry lands on hold through the header
        Assert.AreEqual(PAAHoldCode, InvoiceEntryHold(InvoiceNo), 'An invoice posted while the request is pending should land on hold.');
    end;

    // S3 (T-02): a second Critical assessment opens no second request.
    [Test]
    procedure SecondCriticalAssessmentOpensNoSecondRequest()
    var
        PurchaseHeader: Record "Purchase Header";
        Request: Record "PAA Approval Request";
        Assessment: Record "PCX Purchase Risk Assessment";
        OrderNo: Code[20];
    begin
        // [GIVEN] An order that became Critical on receipt (4 of 10)
        Initialize(true);
        CreateOrder(PurchaseHeader, 10);
        OrderNo := PurchaseHeader."No.";
        Receive(PurchaseHeader, 4);

        // [WHEN] The 4 are invoiced at 160: a new Critical row (quantity and price mismatch)
        InvoiceAtUnitCost(PurchaseHeader, 4, 160);

        // [THEN] PCX recorded two Critical assessments, but there is still one request
        Assessment.SetRange("Document No.", OrderNo);
        Assessment.SetRange("Risk Level", Assessment."Risk Level"::Critical);
        Assert.RecordCount(Assessment, 2);
        Request.SetRange("Order No.", OrderNo);
        Assert.RecordCount(Request, 1);
    end;

    // S4 (T-03): a hold placed by someone else is never overwritten or released.
    [Test]
    procedure ForeignHoldIsNeverOverwrittenOrReleased()
    var
        PurchaseHeader: Record "Purchase Header";
        Request: Record "PAA Approval Request";
        OrderNo: Code[20];
        InvoiceNo: Code[20];
        ForeignHoldCode: Code[3];
    begin
        // [GIVEN] An order that AP has put on hold with code ABC
        Initialize(true);
        ForeignHoldCode := 'ABC';
        CreateOrder(PurchaseHeader, 10);
        OrderNo := PurchaseHeader."No.";
        PurchaseHeader."On Hold" := ForeignHoldCode;
        PurchaseHeader.Modify();

        // [WHEN] It becomes Critical on receipt, an invoice is posted, and the request is approved
        Receive(PurchaseHeader, 4);
        FindOnlyRequest(OrderNo, Request);
        InvoiceNo := InvoiceAtUnitCost(PurchaseHeader, 4, 100);
        ApprovalMgt.Approve(Request, 'tester', '', Enum::"PAA Log Source"::"Business Central");

        // [THEN] The ABC hold is untouched on both the header and the invoice entry
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, OrderNo);
        Assert.AreEqual(ForeignHoldCode, PurchaseHeader."On Hold", 'The header hold placed by AP should be kept.');
        Assert.AreEqual(ForeignHoldCode, InvoiceEntryHold(InvoiceNo), 'The invoice hold placed by AP should be kept.');
    end;

    // S5 (T-04): approve releases the PAA hold and logs it.
    [Test]
    procedure ApproveReleasesHold()
    var
        Request: Record "PAA Approval Request";
        InvoiceNo: Code[20];
    begin
        // [GIVEN] An order that became Critical on invoice
        Initialize(true);
        CreateCriticalOnInvoice(Request, InvoiceNo);

        // [WHEN] The request is approved
        ApprovalMgt.Approve(Request, 'tester', '', Enum::"PAA Log Source"::"Business Central");

        // [THEN] Approved, the hold is released, both actions logged
        Assert.IsTrue(Request.Status = Request.Status::Approved, 'The request should be Approved.');
        Assert.IsTrue(InvoiceEntryHold(InvoiceNo) = '', 'The invoice entry should be released from hold.');
        Assert.IsTrue(LogContains(Request."Entry No.", Enum::"PAA Log Action"::Approved), 'Approved should be logged.');
        Assert.IsTrue(LogContains(Request."Entry No.", Enum::"PAA Log Action"::"Hold Released"), 'Hold Released should be logged.');
    end;

    // S6a (T-05): reject without a comment is refused.
    [Test]
    procedure RejectWithoutCommentIsRefused()
    var
        Request: Record "PAA Approval Request";
        InvoiceNo: Code[20];
    begin
        // [GIVEN] An order that became Critical on invoice
        Initialize(true);
        CreateCriticalOnInvoice(Request, InvoiceNo);

        // [WHEN] Rejected without a comment [THEN] Refused
        asserterror ApprovalMgt.Reject(Request, 'tester', '', Enum::"PAA Log Source"::"Business Central");
        Assert.ExpectedError('A comment is required');
    end;

    // S6b (T-05): reject with a comment keeps the hold.
    [Test]
    procedure RejectKeepsHold()
    var
        Request: Record "PAA Approval Request";
        InvoiceNo: Code[20];
    begin
        // [GIVEN] An order that became Critical on invoice
        Initialize(true);
        CreateCriticalOnInvoice(Request, InvoiceNo);

        // [WHEN] Rejected with a comment
        ApprovalMgt.Reject(Request, 'tester', 'Price exceeds the contract.', Enum::"PAA Log Source"::"Business Central");

        // [THEN] Rejected, and the hold stays
        Assert.IsTrue(Request.Status = Request.Status::Rejected, 'The request should be Rejected.');
        Assert.AreEqual(PAAHoldCode, InvoiceEntryHold(InvoiceNo), 'A rejected invoice should stay on hold.');
        Assert.IsTrue(LogContains(Request."Entry No.", Enum::"PAA Log Action"::Rejected), 'Rejected should be logged.');
    end;

    // S7a (T-06): a decided request can't be decided again.
    [Test]
    procedure ApproveTwiceIsRefused()
    var
        Request: Record "PAA Approval Request";
        InvoiceNo: Code[20];
    begin
        // [GIVEN] An approved request
        Initialize(true);
        CreateCriticalOnInvoice(Request, InvoiceNo);
        ApprovalMgt.Approve(Request, 'tester', '', Enum::"PAA Log Source"::"Business Central");

        // [WHEN] Approved again [THEN] Refused
        asserterror ApprovalMgt.Approve(Request, 'tester', '', Enum::"PAA Log Source"::"Business Central");
        Assert.ExpectedError('can no longer be decided');
    end;

    // S7b: cancel without a reason is refused.
    [Test]
    procedure CancelWithoutReasonIsRefused()
    var
        Request: Record "PAA Approval Request";
        InvoiceNo: Code[20];
    begin
        // [GIVEN] A pending request
        Initialize(true);
        CreateCriticalOnInvoice(Request, InvoiceNo);

        // [WHEN] Cancelled without a reason [THEN] Refused
        asserterror ApprovalMgt.Cancel(Request, 'tester', '', Enum::"PAA Log Source"::"Business Central");
        Assert.ExpectedError('A reason is required');
    end;

    // S8: with approvals switched off, nothing happens.
    [Test]
    procedure NoRequestWhenApprovalsDisabled()
    var
        PurchaseHeader: Record "Purchase Header";
        Request: Record "PAA Approval Request";
        OrderNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [GIVEN] Approvals switched off
        Initialize(false);
        CreateOrder(PurchaseHeader, 10);
        OrderNo := PurchaseHeader."No.";
        Receive(PurchaseHeader, 10);

        // [WHEN] The order becomes Critical on invoice
        InvoiceNo := InvoiceAtUnitCost(PurchaseHeader, 10, 160);

        // [THEN] No request and no hold
        Request.SetRange("Order No.", OrderNo);
        Assert.RecordCount(Request, 0);
        Assert.IsTrue(InvoiceEntryHold(InvoiceNo) = '', 'Nothing should be held when approvals are off.');
    end;

    // ---------- Helpers ----------

    local procedure Initialize(ApprovalsEnabled: Boolean)
    var
        Setup: Record "PAA Setup";
    begin
        PAAHoldCode := 'PAA';
        Setup.InsertIfNotExists();
        Setup.Get();
        Setup."Approvals Enabled" := ApprovalsEnabled;
        Setup."Hold Code" := PAAHoldCode;
        Setup.Modify();
    end;

    local procedure CreateOrder(var PurchaseHeader: Record "Purchase Header"; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), Quantity);
        PurchaseLine.Validate("Direct Unit Cost", 100);
        PurchaseLine.Modify(true);
    end;

    local procedure Receive(var PurchaseHeader: Record "Purchase Header"; QtyToReceive: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        FindLine(PurchaseHeader, PurchaseLine);
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure InvoiceAtUnitCost(var PurchaseHeader: Record "Purchase Header"; QtyToInvoice: Decimal; UnitCost: Decimal): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Posting released the order, and the unit cost can only change on an open order.
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        FindLine(PurchaseHeader, PurchaseLine);
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Validate("Qty. to Invoice", QtyToInvoice);
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
    end;

    local procedure CreateCriticalOnInvoice(var Request: Record "PAA Approval Request"; var InvoiceNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        OrderNo: Code[20];
    begin
        CreateOrder(PurchaseHeader, 10);
        OrderNo := PurchaseHeader."No.";
        Receive(PurchaseHeader, 10);
        InvoiceNo := InvoiceAtUnitCost(PurchaseHeader, 10, 160);
        FindOnlyRequest(OrderNo, Request);
    end;

    local procedure FindLine(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
    end;

    local procedure FindOnlyRequest(OrderNo: Code[20]; var Request: Record "PAA Approval Request")
    begin
        Request.SetRange("Order No.", OrderNo);
        Assert.RecordCount(Request, 1);
        Request.FindFirst();
    end;

    local procedure InvoiceEntryHold(InvoiceNo: Code[20]): Code[3]
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("Document No.", InvoiceNo);
        VendorLedgerEntry.FindFirst();
        exit(VendorLedgerEntry."On Hold");
    end;

    local procedure LogContains(RequestEntryNo: Integer; ActionToFind: Enum "PAA Log Action"): Boolean
    var
        DecisionLog: Record "PAA Decision Log";
    begin
        DecisionLog.SetRange("Request Entry No.", RequestEntryNo);
        DecisionLog.SetRange("Log Action", ActionToFind);
        exit(not DecisionLog.IsEmpty());
    end;
}