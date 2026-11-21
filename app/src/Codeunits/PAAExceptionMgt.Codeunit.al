namespace PowerAutomateApprovals.Integration;

using WarehouseControl.Warehouse;

codeunit 54105 "PAA Exception Mgt"
{
    Access = Internal;

    var
        NotTrackedErr: Label 'Inventory exception %1 has not been notified, so there is no Planner task to link.', Comment = '%1 = exception entry number';

    [InherentPermissions(PermissionObjectType::TableData, Database::"PAA Setup", 'R')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"PAA Exception Tracking", 'RI')]
    procedure HandleNewException(var InventoryException: Record "WHX Inventory Exception")
    begin
        if InventoryException.IsTemporary() then
            exit;
        NotifyIfQualifies(InventoryException);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"PAA Setup", 'R')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"PAA Exception Tracking", 'RIM')]
    procedure HandleModifiedException(var InventoryException: Record "WHX Inventory Exception")
    var
        Tracking: Record "PAA Exception Tracking";
        BusinessEvents: Codeunit "PAA Business Events";
    begin
        if InventoryException.IsTemporary() then
            exit;

        if not Tracking.Get(InventoryException."Entry No.") then begin
            // Created on the card (inserted while still Low) or priority raised later.
            NotifyIfQualifies(InventoryException);
            exit;
        end;

        // Compare with the status PAA last stored, not xRec (D-017).
        if Tracking."Closed Notified At" <> 0DT then
            exit;
        if InventoryException.Status = Tracking."Last Notified Status" then
            exit;
        if not NotificationsEnabled() then
            exit;

        Tracking."Last Notified Status" := InventoryException.Status;
        if InventoryException.Status in [InventoryException.Status::Resolved, InventoryException.Status::Cancelled] then begin
            Tracking."Closed Notified At" := CurrentDateTime();
            Tracking.Modify();
            BusinessEvents.RaiseExceptionClosed(InventoryException.SystemId, InventoryException."Entry No.",
                StatusName(InventoryException.Status), Tracking."Planner Task Id");
        end else
            Tracking.Modify();
    end;

    procedure SetPlannerTask(ExceptionEntryNo: Integer; PlannerTaskId: Text; TeamsMessageId: Text)
    var
        Tracking: Record "PAA Exception Tracking";
    begin
        // Real permissions: only the flow identity links tasks.
        if not Tracking.Get(ExceptionEntryNo) then
            Error(NotTrackedErr, ExceptionEntryNo);
        Tracking."Planner Task Id" := CopyStr(PlannerTaskId, 1, MaxStrLen(Tracking."Planner Task Id"));
        Tracking."Teams Message Id" := CopyStr(TeamsMessageId, 1, MaxStrLen(Tracking."Teams Message Id"));
        Tracking.Modify(true);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"PAA Exception Tracking", 'RI')]
    local procedure NotifyIfQualifies(var InventoryException: Record "WHX Inventory Exception")
    var
        Tracking: Record "PAA Exception Tracking";
        BusinessEvents: Codeunit "PAA Business Events";
    begin
        if not NotificationsEnabled() then
            exit;
        if not (InventoryException.Priority in [InventoryException.Priority::High, InventoryException.Priority::Critical]) then
            exit;
        if InventoryException.Status in [InventoryException.Status::Resolved, InventoryException.Status::Cancelled] then
            exit;
        if Tracking.Get(InventoryException."Entry No.") then
            exit;

        Tracking.Init();
        Tracking."Exception Entry No." := InventoryException."Entry No.";
        Tracking."Last Notified Status" := InventoryException.Status;
        Tracking."Notified At" := CurrentDateTime();
        Tracking.Insert(true);

        BusinessEvents.RaiseExceptionRaised(InventoryException.SystemId, InventoryException."Entry No.",
            InventoryException."Item No.", InventoryException."Location Code",
            TypeName(InventoryException."Exception Type"), PriorityName(InventoryException.Priority));
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"PAA Setup", 'R')]
    local procedure NotificationsEnabled(): Boolean
    var
        Setup: Record "PAA Setup";
    begin
        if not Setup.Get() then
            exit(false);
        exit(Setup."Notifications Enabled");
    end;

    // Enum names, not captions, so flow conditions don't depend on the user's language.
    local procedure PriorityName(Priority: Enum "WHX Exception Priority"): Text[30]
    begin
        exit(CopyStr(Priority.Names().Get(Priority.Ordinals().IndexOf(Priority.AsInteger())), 1, 30));
    end;

    local procedure StatusName(Status: Enum "WHX Exception Status"): Text[30]
    begin
        exit(CopyStr(Status.Names().Get(Status.Ordinals().IndexOf(Status.AsInteger())), 1, 30));
    end;

    local procedure TypeName(ExceptionType: Enum "WHX Exception Type"): Text[50]
    begin
        exit(CopyStr(ExceptionType.Names().Get(ExceptionType.Ordinals().IndexOf(ExceptionType.AsInteger())), 1, 50));
    end;
}