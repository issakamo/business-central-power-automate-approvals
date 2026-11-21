namespace PowerAutomateApprovals.Integration;

using PurchaseControl.Purchasing;
using WarehouseControl.Warehouse;

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

    [EventSubscriber(ObjectType::Table, Database::"WHX Inventory Exception", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertInventoryException(var Rec: Record "WHX Inventory Exception"; RunTrigger: Boolean)
    var
        ExceptionMgt: Codeunit "PAA Exception Mgt";
    begin
        ExceptionMgt.HandleNewException(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"WHX Inventory Exception", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyInventoryException(var Rec: Record "WHX Inventory Exception"; var xRec: Record "WHX Inventory Exception"; RunTrigger: Boolean)
    var
        ExceptionMgt: Codeunit "PAA Exception Mgt";
    begin
        ExceptionMgt.HandleModifiedException(Rec);
    end;
}