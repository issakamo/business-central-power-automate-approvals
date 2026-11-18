namespace PowerAutomateApprovals.Integration;

using Microsoft.Purchases.Vendor;
using PurchaseControl.Purchasing;

codeunit 54103 "PAA Approval Mgt"
{
    Access = Internal;

    var
        RequestedTxt: Label 'Risk became Critical (%1) in assessment entry %2.', Comment = '%1 = match status, %2 = assessment entry number';
        HoldAppliedTxt: Label '%1 open invoice entries put on hold with code %2. Order header held: %3.', Comment = '%1 = number of entries, %2 = hold code, %3 = Yes or No';

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
        LogAction(Request."Entry No.", Enum::"PAA Log Action"::Requested,
            StrSubstNo(RequestedTxt, Format(Request."Match Status"), Request."Assessment Entry No."));

        HeldCount := HoldMgt.ApplyHold(Request."Order No.", Setup."Hold Code", HeaderHeld, AmountOnHoldLCY);
        Request."Amount on Hold (LCY)" := AmountOnHoldLCY;
        Request.Modify();
        LogAction(Request."Entry No.", Enum::"PAA Log Action"::"Hold Applied",
            StrSubstNo(HoldAppliedTxt, HeldCount, Setup."Hold Code", Format(HeaderHeld)));

        BusinessEvents.RaisePurchaseApprovalRequested(Request.SystemId, Request."Entry No.", Request."Order No.",
            Request."Vendor No.", Request."Vendor Name", RiskLevelName(Request."Risk Level"));
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"PAA Decision Log", 'I')]
    procedure LogAction(RequestEntryNo: Integer; LogAction: Enum "PAA Log Action"; Comment: Text)
    var
        DecisionLog: Record "PAA Decision Log";
    begin
        DecisionLog.Init();
        DecisionLog."Request Entry No." := RequestEntryNo;
        DecisionLog."Log Action" := LogAction;
        DecisionLog.Source := DecisionLog.Source::"Business Central";
        DecisionLog."Performed By" := CopyStr(UserId(), 1, MaxStrLen(DecisionLog."Performed By"));
        DecisionLog."Performed At" := CurrentDateTime();
        DecisionLog.Comment := CopyStr(Comment, 1, MaxStrLen(DecisionLog.Comment));
        DecisionLog.Insert(true);
    end;

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