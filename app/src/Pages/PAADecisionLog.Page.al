namespace PowerAutomateApprovals.Integration;

page 54102 "PAA Decision Log"
{
    ApplicationArea = All;
    Caption = 'Approval Decision Log';
    PageType = List;
    SourceTable = "PAA Decision Log";
    UsageCategory = History;
    Editable = false;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    Caption = 'Entry No.';
                    ToolTip = 'Specifies the number of the log entry.';
                }
                field("Request Entry No."; Rec."Request Entry No.")
                {
                    Caption = 'Request Entry No.';
                    ToolTip = 'Specifies the approval request the action belongs to.';
                }
                field("Log Action"; Rec."Log Action")
                {
                    Caption = 'Action';
                    ToolTip = 'Specifies what happened to the request.';
                }
                field(Source; Rec.Source)
                {
                    Caption = 'Source';
                    ToolTip = 'Specifies whether the action came from Business Central or from a flow.';
                }
                field("Performed By"; Rec."Performed By")
                {
                    Caption = 'Performed By';
                    ToolTip = 'Specifies the user or identity that performed the action.';
                }
                field("Performed At"; Rec."Performed At")
                {
                    Caption = 'Performed At';
                    ToolTip = 'Specifies when the action was performed.';
                }
                field(Comment; Rec.Comment)
                {
                    Caption = 'Comment';
                    ToolTip = 'Specifies details of the action.';
                }
            }
        }
    }
}