namespace PowerAutomateApprovals.Integration;

page 54104 "PAA Flow Run Log"
{
    ApplicationArea = All;
    Caption = 'Flow Run Log';
    PageType = List;
    SourceTable = "PAA Flow Run Log";
    UsageCategory = History;
    Editable = false;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Runs)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    Caption = 'Entry No.';
                    ToolTip = 'Specifies the number of the log entry.';
                }
                field("Logged At"; Rec."Logged At")
                {
                    Caption = 'Logged At';
                    ToolTip = 'Specifies when the flow reported the run.';
                }
                field("Flow Name"; Rec."Flow Name")
                {
                    Caption = 'Flow Name';
                    ToolTip = 'Specifies which flow ran.';
                }
                field(Result; Rec.Result)
                {
                    Caption = 'Result';
                    ToolTip = 'Specifies whether the run succeeded or failed.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    Caption = 'Source Type';
                    ToolTip = 'Specifies whether the run was about an approval request or an inventory exception.';
                }
                field("Source Entry No."; Rec."Source Entry No.")
                {
                    Caption = 'Source Entry No.';
                    ToolTip = 'Specifies the entry number of the approval request or inventory exception.';
                }
                field(Message; Rec.Message)
                {
                    Caption = 'Message';
                    ToolTip = 'Specifies details of the run, such as an error message.';
                }
                field("Run Id"; Rec."Run Id")
                {
                    Caption = 'Run Id';
                    ToolTip = 'Specifies the Power Automate run ID, for finding the run in the flow''s run history.';
                }
            }
        }
    }
}