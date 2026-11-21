namespace PowerAutomateApprovals.Integration;

using WarehouseControl.Warehouse;

page 54121 "PAA Exception API"
{
    PageType = API;
    APIPublisher = 'issakamo';
    APIGroup = 'approvals';
    APIVersion = 'v1.0';
    EntityName = 'inventoryException';
    EntitySetName = 'inventoryExceptions';
    EntityCaption = 'Inventory Exception';
    EntitySetCaption = 'Inventory Exceptions';
    SourceTable = "WHX Inventory Exception";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(entryNo; Rec."Entry No.")
                {
                    Caption = 'Entry No.';
                }
                field(itemNo; Rec."Item No.")
                {
                    Caption = 'Item No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }
                field(binCode; Rec."Bin Code")
                {
                    Caption = 'Bin Code';
                }
                field(exceptionType; Rec."Exception Type")
                {
                    Caption = 'Exception Type';
                }
                field(exceptionTypeText; ExceptionTypeText)
                {
                    Caption = 'Exception Type Text';
                }
                field(priority; Rec.Priority)
                {
                    Caption = 'Priority';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(expectedQuantity; Rec."Expected Quantity")
                {
                    Caption = 'Expected Quantity';
                }
                field(actualQuantity; Rec."Actual Quantity")
                {
                    Caption = 'Actual Quantity';
                }
                field(difference; Rec.Difference)
                {
                    Caption = 'Difference';
                }
                field(resolutionNotes; Rec."Resolution Notes")
                {
                    Caption = 'Resolution Notes';
                }
                field(createdDate; Rec."Created Date")
                {
                    Caption = 'Created Date';
                }
                field(resolvedDate; Rec."Resolved Date")
                {
                    Caption = 'Resolved Date';
                }
                field(plannerTaskId; PlannerTaskId)
                {
                    Caption = 'Planner Task Id';
                }
                field(teamsMessageId; TeamsMessageId)
                {
                    Caption = 'Teams Message Id';
                }
                field(lastModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified At';
                }
            }
        }
    }

    var
        ExceptionTypeText: Text[50];
        PlannerTaskId: Text[100];
        TeamsMessageId: Text[100];

    trigger OnAfterGetRecord()
    var
        Tracking: Record "PAA Exception Tracking";
    begin
        ExceptionTypeText := CopyStr(Format(Rec."Exception Type"), 1, MaxStrLen(ExceptionTypeText));
        PlannerTaskId := '';
        TeamsMessageId := '';
        if Tracking.Get(Rec."Entry No.") then begin
            PlannerTaskId := Tracking."Planner Task Id";
            TeamsMessageId := Tracking."Teams Message Id";
        end;
    end;

    [ServiceEnabled]
    procedure setPlannerTask(var ActionContext: WebServiceActionContext; plannerTaskId: Text; teamsMessageId: Text)
    var
        ExceptionMgt: Codeunit "PAA Exception Mgt";
    begin
        ExceptionMgt.SetPlannerTask(Rec."Entry No.", plannerTaskId, teamsMessageId);
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"PAA Exception API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}