namespace PowerAutomateApprovals.Integration;

using PurchaseControl.Purchasing;

codeunit 54104 "PAA Event Subscribers"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"PCX Purchase Risk Assessment", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertRiskAssessment(var Rec: Record "PCX Purchase Risk Assessment"; RunTrigger: Boolean)
    var
        ApprovalMgt: Codeunit "PAA Approval Mgt";
    begin
        ApprovalMgt.HandleNewAssessment(Rec);
    end;
}