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
                field("Current Approver Email"; Rec."Current Approver Email")
                {
                    Caption = 'Current Approver Email';
                    ToolTip = 'Specifies the approver the request was escalated to.';
                }
                field("Decided By"; Rec."Decided By")
                {
                    Caption = 'Decided By';
                    ToolTip = 'Specifies who approved, rejected or cancelled the request.';
                }
                field("Decided At"; Rec."Decided At")
                {
                    Caption = 'Decided At';
                    ToolTip = 'Specifies when the request was approved, rejected or cancelled.';
                }
                field("Decision Comment"; Rec."Decision Comment")
                {
                    Caption = 'Decision Comment';
                    ToolTip = 'Specifies the comment given with the decision.';
                }
                field("Vendor Notified At"; Rec."Vendor Notified At")
                {
                    Caption = 'Vendor Notified At';
                    ToolTip = 'Specifies when the vendor was emailed about a rejected request.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Approve)
            {
                Caption = 'Approve';
                ToolTip = 'Approve the request and release the payment hold on its invoices. Use this when the Teams approval is unavailable.';
                Image = Approve;
                Enabled = IsOpenRequest;

                trigger OnAction()
                var
                    ApprovalMgt: Codeunit "PAA Approval Mgt";
                begin
                    if not Confirm(ApproveQst, false, Rec."Entry No.", Rec."Order No.") then
                        exit;
                    ApprovalMgt.Approve(Rec, UserId(), '', Enum::"PAA Log Source"::"Business Central");
                    CurrPage.Update(false);
                end;
            }
            action(Reject)
            {
                Caption = 'Reject';
                ToolTip = 'Reject the request. The payment hold stays on its invoices.';
                Image = Reject;
                Enabled = IsOpenRequest;

                trigger OnAction()
                var
                    ApprovalMgt: Codeunit "PAA Approval Mgt";
                    DecisionDialog: Page "PAA Decision Dialog";
                begin
                    DecisionDialog.SetCommentRequired(true);
                    if DecisionDialog.RunModal() <> Action::OK then
                        exit;
                    ApprovalMgt.Reject(Rec, UserId(), DecisionDialog.GetComment(), Enum::"PAA Log Source"::"Business Central");
                    CurrPage.Update(false);
                end;
            }
            action(CancelRequest)
            {
                Caption = 'Cancel Request';
                ToolTip = 'Cancel a request that can no longer be decided in Teams, and release its payment hold. A reason is required.';
                Image = Cancel;
                Enabled = IsOpenRequest;

                trigger OnAction()
                var
                    ApprovalMgt: Codeunit "PAA Approval Mgt";
                    DecisionDialog: Page "PAA Decision Dialog";
                begin
                    DecisionDialog.SetCommentRequired(true);
                    if DecisionDialog.RunModal() <> Action::OK then
                        exit;
                    ApprovalMgt.Cancel(Rec, UserId(), DecisionDialog.GetComment(), Enum::"PAA Log Source"::"Business Central");
                    CurrPage.Update(false);
                end;
            }
        }
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
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Approve_Promoted; Approve)
                {
                }
                actionref(Reject_Promoted; Reject)
                {
                }
                actionref(CancelRequest_Promoted; CancelRequest)
                {
                }
            }
            actionref(DecisionLog_Promoted; DecisionLog)
            {
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        IsOpenRequest := Rec.IsOpen();
    end;

    var
        IsOpenRequest: Boolean;
        ApproveQst: Label 'Approve request %1 for order %2 and release its payment hold?', Comment = '%1 = request entry number, %2 = purchase order number';
}