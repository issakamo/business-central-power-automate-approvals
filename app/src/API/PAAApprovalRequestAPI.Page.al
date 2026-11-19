namespace PowerAutomateApprovals.Integration;

using Microsoft.Purchases.Vendor;

page 54120 "PAA Approval Request API"
{
    PageType = API;
    APIPublisher = 'issakamo';
    APIGroup = 'approvals';
    APIVersion = 'v1.0';
    EntityName = 'approvalRequest';
    EntitySetName = 'approvalRequests';
    EntityCaption = 'Approval Request';
    EntitySetCaption = 'Approval Requests';
    SourceTable = "PAA Approval Request";
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
                field(orderNo; Rec."Order No.")
                {
                    Caption = 'Order No.';
                }
                field(vendorNo; Rec."Vendor No.")
                {
                    Caption = 'Vendor No.';
                }
                field(vendorName; Rec."Vendor Name")
                {
                    Caption = 'Vendor Name';
                }
                field(vendorEmail; VendorEmail)
                {
                    Caption = 'Vendor Email';
                }
                field(riskLevel; Rec."Risk Level")
                {
                    Caption = 'Risk Level';
                }
                field(matchStatus; Rec."Match Status")
                {
                    Caption = 'Match Status';
                }
                field(matchStatusText; MatchStatusText)
                {
                    Caption = 'Match Status Text';
                }
                field(priceVariancePercent; Rec."Price Variance %")
                {
                    Caption = 'Price Variance %';
                }
                field(quantityVariancePercent; Rec."Quantity Variance %")
                {
                    Caption = 'Quantity Variance %';
                }
                field(amountOnHoldLCY; Rec."Amount on Hold (LCY)")
                {
                    Caption = 'Amount on Hold (LCY)';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(currentApproverEmail; Rec."Current Approver Email")
                {
                    Caption = 'Current Approver Email';
                }
                field(escalatedAt; Rec."Escalated At")
                {
                    Caption = 'Escalated At';
                }
                field(decidedBy; Rec."Decided By")
                {
                    Caption = 'Decided By';
                }
                field(decidedAt; Rec."Decided At")
                {
                    Caption = 'Decided At';
                }
                field(decisionComment; Rec."Decision Comment")
                {
                    Caption = 'Decision Comment';
                }
                field(vendorNotifiedAt; Rec."Vendor Notified At")
                {
                    Caption = 'Vendor Notified At';
                }
                field(createdAt; Rec.SystemCreatedAt)
                {
                    Caption = 'Created At';
                }
                field(lastModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified At';
                }
            }
        }
    }

    var
        VendorEmail: Text[80];
        MatchStatusText: Text[50];
        ApproverRequiredErr: Label 'approverEmail is required.';

    trigger OnAfterGetRecord()
    var
        Vendor: Record Vendor;
    begin
        VendorEmail := '';
        if Vendor.Get(Rec."Vendor No.") then
            VendorEmail := Vendor."E-Mail";
        MatchStatusText := CopyStr(Format(Rec."Match Status"), 1, MaxStrLen(MatchStatusText));
    end;

    [ServiceEnabled]
    procedure approve(var ActionContext: WebServiceActionContext; approverEmail: Text; comment: Text)
    var
        ApprovalMgt: Codeunit "PAA Approval Mgt";
    begin
        RequireApprover(approverEmail);
        ApprovalMgt.Approve(Rec, approverEmail, comment, Enum::"PAA Log Source"::Flow);
        SetUpdated(ActionContext);
    end;

    [ServiceEnabled]
    procedure reject(var ActionContext: WebServiceActionContext; approverEmail: Text; comment: Text)
    var
        ApprovalMgt: Codeunit "PAA Approval Mgt";
    begin
        RequireApprover(approverEmail);
        ApprovalMgt.Reject(Rec, approverEmail, comment, Enum::"PAA Log Source"::Flow);
        SetUpdated(ActionContext);
    end;

    [ServiceEnabled]
    procedure escalate(var ActionContext: WebServiceActionContext; newApproverEmail: Text)
    var
        ApprovalMgt: Codeunit "PAA Approval Mgt";
    begin
        ApprovalMgt.Escalate(Rec, newApproverEmail, Enum::"PAA Log Source"::Flow);
        SetUpdated(ActionContext);
    end;

    [ServiceEnabled]
    procedure markVendorNotified(var ActionContext: WebServiceActionContext)
    var
        ApprovalMgt: Codeunit "PAA Approval Mgt";
    begin
        ApprovalMgt.MarkVendorNotified(Rec, Enum::"PAA Log Source"::Flow);
        SetUpdated(ActionContext);
    end;

    local procedure RequireApprover(ApproverEmail: Text)
    begin
        if DelChr(ApproverEmail, '<>', ' ') = '' then
            Error(ApproverRequiredErr);
    end;

    local procedure SetUpdated(var ActionContext: WebServiceActionContext)
    begin
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"PAA Approval Request API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}