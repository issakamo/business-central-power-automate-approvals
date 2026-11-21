namespace PowerAutomateApprovals.Integration;

page 54122 "PAA Flow Run API"
{
    PageType = API;
    APIPublisher = 'issakamo';
    APIGroup = 'approvals';
    APIVersion = 'v1.0';
    EntityName = 'flowRun';
    EntitySetName = 'flowRuns';
    EntityCaption = 'Flow Run';
    EntitySetCaption = 'Flow Runs';
    SourceTable = "PAA Flow Run Log";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
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
                    Editable = false;
                }
                field(flowName; Rec."Flow Name")
                {
                    Caption = 'Flow Name';
                }
                field(runId; Rec."Run Id")
                {
                    Caption = 'Run Id';
                }
                field(sourceType; Rec."Source Type")
                {
                    Caption = 'Source Type';
                }
                field(sourceEntryNo; Rec."Source Entry No.")
                {
                    Caption = 'Source Entry No.';
                }
                field(result; Rec.Result)
                {
                    Caption = 'Result';
                }
                field(message; Rec.Message)
                {
                    Caption = 'Message';
                }
                field(loggedAt; Rec."Logged At")
                {
                    Caption = 'Logged At';
                    Editable = false;
                }
            }
        }
    }
}