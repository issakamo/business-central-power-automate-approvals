namespace PowerAutomateApprovals.Integration;

page 54101 "PAA Approval Requests"
{
    ApplicationArea = All;
    Caption = 'Payment Approval Requests';
    PageType = List;
    SourceTable = "PAA Approval Request";
    UsageCategory = Lists;
    Editable = false;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Requests)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    Caption = 'Entry No.';
                    ToolTip = 'Specifies the number of the approval request.';
                }
                field("Order No."; Rec."Order No.")
                {
                    Caption = 'Order No.';
                    ToolTip = 'Specifies the purchase order that became Critical.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    Caption = 'Vendor No.';
                    ToolTip = 'Specifies the vendor on the purchase order.';
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    Caption = 'Vendor Name';
                    ToolTip = 'Specifies the name of the vendor.';
                }
                field(Status; Rec.Status)
                {
                    Caption = 'Status';
                    ToolTip = 'Specifies whether the request is pending, escalated, approved, rejected or cancelled.';
                }
                field("Match Status"; Rec."Match Status")
                {
                    Caption = 'Match Status';
                    ToolTip = 'Specifies the 3-way match result that made the order Critical.';
                }
                field("Price Variance %"; Rec."Price Variance %")
                {
                    Caption = 'Price Variance %';
                    ToolTip = 'Specifies the price variance when the request was opened.';
                }
                field("Quantity Variance %"; Rec."Quantity Variance %")
                {
                    Caption = 'Quantity Variance %';
                    ToolTip = 'Specifies the quantity variance when the request was opened.';
                }
                field("Amount on Hold (LCY)"; Rec."Amount on Hold (LCY)")
                {
                    Caption = 'Amount on Hold (LCY)';
                    ToolTip = 'Specifies the remaining amount of the invoice entries put on hold when the request was opened.';
                }
                field("Decided By"; Rec."Decided By")
                {
                    Caption = 'Decided By';
                    ToolTip = 'Specifies who approved or rejected the request.';
                }
                field("Decided At"; Rec."Decided At")
                {
                    Caption = 'Decided At';
                    ToolTip = 'Specifies when the request was approved or rejected.';
                }
                field("Decision Comment"; Rec."Decision Comment")
                {
                    Caption = 'Decision Comment';
                    ToolTip = 'Specifies the comment given with the decision.';
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(DecisionLog)
            {
                Caption = 'Decision Log';
                ToolTip = 'View every action recorded for the selected request.';
                Image = Log;
                RunObject = page "PAA Decision Log";
                RunPageLink = "Request Entry No." = field("Entry No.");
            }
        }
        area(Promoted)
        {
            actionref(DecisionLog_Promoted; DecisionLog)
            {
            }
        }
    }
}