namespace PowerAutomateApprovals.Integration;

page 54100 "PAA Setup"
{
    ApplicationArea = All;
    Caption = 'Power Automate Approvals Setup';
    PageType = Card;
    SourceTable = "PAA Setup";
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Approvals Enabled"; Rec."Approvals Enabled")
                {
                    Caption = 'Purchase Approvals Enabled';
                    ToolTip = 'Specifies whether a payment approval request is opened, and the related invoices are put on hold, when a purchase order becomes Critical.';
                }
                field("Notifications Enabled"; Rec."Notifications Enabled")
                {
                    Caption = 'Warehouse Notifications Enabled';
                    ToolTip = 'Specifies whether business events are raised when a High or Critical inventory exception is created or closed.';
                }
                field("Hold Code"; Rec."Hold Code")
                {
                    Caption = 'Payment Hold Code';
                    ToolTip = 'Specifies the On Hold code placed on vendor ledger entries by this app. Approval releases only holds with this code.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.InsertIfNotExists();
    end;
}
