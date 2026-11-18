namespace PowerAutomateApprovals.Integration;

using Microsoft.Purchases.Vendor;
using PurchaseControl.Purchasing;

codeunit 54103 "PAA Approval Mgt"
{
    Access = Internal;

    var
        RequestedTxt: Label 'Risk became Critical (%1) in assessment entry %2.', Comment = '%1 = match status, %2 = assessment entry number';
        HoldAppliedTxt: Label '%1 open invoice entries put on hold with code %2. Order header held: %3.', Comment = '%1 = number of entries, %2 = hold code, %3 = Yes or No';
        HoldReleasedTxt: Label '%1 open invoice entries released from hold code %2.', Comment = '%1 = number of entries, %2 = hold code';
        EscalatedTxt: Label 'Escalated to %1.', Comment = '%1 = new approver email address';
        NotOpenErr: Label 'Approval request %1 is %2 and can no longer be decided.', Comment = '%1 = request entry number, %2 = request status';
        NotPendingErr: Label 'Approval request %1 is %2. Only a pending request can be escalated.', Comment = '%1 = request entry number, %2 = request status';
        NotRejectedErr: Label 'Approval request %1 is %2. The vendor is notified only for a rejected request.', Comment = '%1 = request entry number, %2 = request status';
        CommentRequiredErr: Label 'A comment is required to reject approval request %1.', Comment = '%1 = request entry number';
        CancelReasonRequiredErr: Label 'A reason is required to cancel approval request %1.', Comment = '%1 = request entry number';
        ApproverRequiredErr: Label 'An approver email address is required to escalate approval request %1.', Comment = '%1 = request entry number';

    // ---------- Opening a request (runs inside purchase posting) ----------

    [InherentPermissions(PermissionObjectType::TableData, Database::"PAA Setup", 'R')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"PAA Approval Request", 'RIM')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"PAA Decision Log", 'I')]
    procedure HandleNewAssessment(var Assessment: Record "PCX Purchase Risk Assessment")
    var
        Setup: Record "PAA Setup";
        Request: Record "PAA Approval Request";
        HoldMgt: Codeunit "PAA Payment Hold Mgt";
        BusinessEvents: Codeunit "PAA Business Events";
        HeaderHeld: Boolean;
        AmountOnHoldLCY: Decimal;
        HeldCount: Integer;
    begin
        if Assessment.IsTemporary() then
            exit;
        if Assessment."Risk Level" <> Assessment."Risk Level"::Critical then
            exit;
        if not Setup.Get() then
            exit;
        if not Setup."Approvals Enabled" then
            exit;
        if PreviousAssessmentWasCritical(Assessment) then
            exit;
        if HasOpenRequest(Assessment."Document No.") then
            exit;

        CreateRequest(Assessment, Request);
        LogAction(Request."Entry No.", Enum::"PAA Log Action"::Requested, Enum::"PAA Log Source"::"Business Central", UserId(),
            StrSubstNo(RequestedTxt, Format(Request."Match Status"), Request."Assessment Entry No."));

        HeldCount := HoldMgt.ApplyHold(Request."Order No.", Setup."Hold Code", HeaderHeld, AmountOnHoldLCY);
        Request."Amount on Hold (LCY)" := AmountOnHoldLCY;
        Request.Modify();
        LogAction(Request."Entry No.", Enum::"PAA Log Action"::"Hold Applied", Enum::"PAA Log Source"::"Business Central", UserId(),
            StrSubstNo(HoldAppliedTxt, HeldCount, Setup."Hold Code", Format(HeaderHeld)));

        BusinessEvents.RaisePurchaseApprovalRequested(Request.SystemId, Request."Entry No.", Request."Order No.",
            Request."Vendor No.", Request."Vendor Name", RiskLevelName(Request."Risk Level"));
    end;

    // ---------- Decisions (from Business Central pages or from flows) ----------

    procedure Approve(var Request: Record "PAA Approval Request"; DecidedBy: Text; Comment: Text; Source: Enum "PAA Log Source")
    begin
        Decide(Request, Request.Status::Approved, DecidedBy, Comment, Source);
    end;

    procedure Reject(var Request: Record "PAA Approval Request"; DecidedBy: Text; Comment: Text; Source: Enum "PAA Log Source")
    begin
        if DelChr(Comment, '<>', ' ') = '' then
            Error(CommentRequiredErr, Request."Entry No.");
        Decide(Request, Request.Status::Rejected, DecidedBy, Comment, Source);
    end;

    procedure Cancel(var Request: Record "PAA Approval Request"; CancelledBy: Text; Comment: Text; Source: Enum "PAA Log Source")
    begin
        if DelChr(Comment, '<>', ' ') = '' then
            Error(CancelReasonRequiredErr, Request."Entry No.");
        Decide(Request, Request.Status::Cancelled, CancelledBy, Comment, Source);
    end;

    procedure Escalate(var Request: Record "PAA Approval Request"; NewApproverEmail: Text; Source: Enum "PAA Log Source")
    var
        Current: Record "PAA Approval Request";
    begin
        if DelChr(NewApproverEmail, '<>', ' ') = '' then
            Error(ApproverRequiredErr, Request."Entry No.");

        Current.LockTable();
        Current.Get(Request."Entry No.");
        if Current.Status <> Current.Status::Pending then
            Error(NotPendingErr, Current."Entry No.", Format(Current.Status));

        Current.Status := Current.Status::Escalated;
        Current."Current Approver Email" := CopyStr(NewApproverEmail, 1, MaxStrLen(Current."Current Approver Email"));
        Current."Escalated At" := CurrentDateTime();
        Current.Modify(true);
        LogAction(Current."Entry No.", Enum::"PAA Log Action"::Escalated, Source, UserId(), StrSubstNo(EscalatedTxt, NewApproverEmail));

        Request := Current;
    end;

    procedure MarkVendorNotified(var Request: Record "PAA Approval Request"; Source: Enum "PAA Log Source")
    var
        Current: Record "PAA Approval Request";
    begin
        Current.LockTable();
        Current.Get(Request."Entry No.");
        if Current.Status <> Current.Status::Rejected then
            Error(NotRejectedErr, Current."Entry No.", Format(Current.Status));

        Current."Vendor Notified At" := CurrentDateTime();
        Current.Modify(true);
        LogAction(Current."Entry No.", Enum::"PAA Log Action"::"Vendor Notified", Source, UserId(), '');

        Request := Current;
    end;

    local procedure Decide(var Request: Record "PAA Approval Request"; NewStatus: Enum "PAA Request Status"; DecidedBy: Text; Comment: Text; Source: Enum "PAA Log Source")
    var
        Current: Record "PAA Approval Request";
        Setup: Record "PAA Setup";
        HoldMgt: Codeunit "PAA Payment Hold Mgt";
        ReleasedCount: Integer;
    begin
        // Lock and re-read: a decision arriving at the same moment from Teams
        // and from Business Central must not both succeed.
        Current.LockTable();
        Current.Get(Request."Entry No.");
        if not Current.IsOpen() then
            Error(NotOpenErr, Current."Entry No.", Format(Current.Status));

        Current.Status := NewStatus;
        Current."Decided By" := CopyStr(DecidedBy, 1, MaxStrLen(Current."Decided By"));
        Current."Decided At" := CurrentDateTime();
        Current."Decision Comment" := CopyStr(Comment, 1, MaxStrLen(Current."Decision Comment"));
        Current.Modify(true);
        LogAction(Current."Entry No.", StatusToLogAction(NewStatus), Source, DecidedBy, Comment);

        if NewStatus in [NewStatus::Approved, NewStatus::Cancelled] then begin
            Setup.Get();
            ReleasedCount := HoldMgt.ReleaseHold(Current."Order No.", Setup."Hold Code");
            LogAction(Current."Entry No.", Enum::"PAA Log Action"::"Hold Released", Source, DecidedBy,
                StrSubstNo(HoldReleasedTxt, ReleasedCount, Setup."Hold Code"));
        end;

        Request := Current;
    end;

    local procedure StatusToLogAction(Status: Enum "PAA Request Status"): Enum "PAA Log Action"
    begin
        case Status of
            Status::Approved:
                exit(Enum::"PAA Log Action"::Approved);
            Status::Rejected:
                exit(Enum::"PAA Log Action"::Rejected);
            Status::Cancelled:
                exit(Enum::"PAA Log Action"::Cancelled);
        end;
    end;

    // ---------- Log ----------

    [InherentPermissions(PermissionObjectType::TableData, Database::"PAA Decision Log", 'I')]
    procedure LogAction(RequestEntryNo: Integer; ActionToLog: Enum "PAA Log Action"; Source: Enum "PAA Log Source"; PerformedBy: Text; Comment: Text)
    var
        DecisionLog: Record "PAA Decision Log";
    begin
        DecisionLog.Init();
        DecisionLog."Request Entry No." := RequestEntryNo;
        DecisionLog."Log Action" := ActionToLog;
        DecisionLog.Source := Source;
        DecisionLog."Performed By" := CopyStr(PerformedBy, 1, MaxStrLen(DecisionLog."Performed By"));
        DecisionLog."Performed At" := CurrentDateTime();
        DecisionLog.Comment := CopyStr(Comment, 1, MaxStrLen(DecisionLog.Comment));
        DecisionLog.Insert(true);
    end;

    // ---------- Helpers ----------

    local procedure PreviousAssessmentWasCritical(Assessment: Record "PCX Purchase Risk Assessment"): Boolean
    var
        Previous: Record "PCX Purchase Risk Assessment";
    begin
        // Compare with the order's previous stored row, not xRec (D-013).
        Previous.SetRange("Document No.", Assessment."Document No.");
        Previous.SetFilter("Entry No.", '<%1', Assessment."Entry No.");
        if not Previous.FindLast() then
            exit(false);
        exit(Previous."Risk Level" = Previous."Risk Level"::Critical);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"PAA Approval Request", 'R')]
    local procedure HasOpenRequest(OrderNo: Code[20]): Boolean
    var
        Request: Record "PAA Approval Request";
    begin
        Request.SetCurrentKey("Order No.", Status);
        Request.SetRange("Order No.", OrderNo);
        Request.SetFilter(Status, '%1|%2', Request.Status::Pending, Request.Status::Escalated);
        exit(not Request.IsEmpty());
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"PAA Approval Request", 'I')]
    local procedure CreateRequest(Assessment: Record "PCX Purchase Risk Assessment"; var Request: Record "PAA Approval Request")
    var
        Vendor: Record Vendor;
    begin
        Request.Init();
        Request."Order No." := Assessment."Document No.";
        Request."Vendor No." := Assessment."Vendor No.";
        if Vendor.Get(Assessment."Vendor No.") then
            Request."Vendor Name" := Vendor.Name;
        Request."Assessment Entry No." := Assessment."Entry No.";
        Request."Risk Level" := Assessment."Risk Level";
        Request."Match Status" := Assessment."Match Status";
        Request."Quantity Variance %" := Assessment."Quantity Variance %";
        Request."Price Variance %" := Assessment."Price Variance %";
        Request.Status := Request.Status::Pending;
        Request.Insert(true);
    end;

    local procedure RiskLevelName(RiskLevel: Enum "PCX Risk Level"): Text[30]
    begin
        // The enum value's name, not its caption, so flow conditions don't depend on the user's language.
        exit(CopyStr(RiskLevel.Names().Get(RiskLevel.Ordinals().IndexOf(RiskLevel.AsInteger())), 1, 30));
    end;
}