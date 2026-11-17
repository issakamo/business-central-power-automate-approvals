namespace PowerAutomateApprovals.Integration;

using System.Integration;

codeunit 54100 "PAA Business Events"
{
    Access = Internal;

    procedure RaisePurchaseApprovalRequested(RequestId: Guid; RequestEntryNo: Integer; OrderNo: Code[20]; VendorNo: Code[20]; VendorName: Text[100]; RiskLevel: Text[30])
    begin
        PurchaseApprovalRequested(RequestId, RequestEntryNo, OrderNo, VendorNo, VendorName, RiskLevel);
    end;

    procedure RaiseExceptionRaised(ExceptionId: Guid; ExceptionEntryNo: Integer; ItemNo: Code[20]; LocationCode: Code[10]; ExceptionType: Text[50]; Priority: Text[30])
    begin
        WarehouseExceptionRaised(ExceptionId, ExceptionEntryNo, ItemNo, LocationCode, ExceptionType, Priority);
    end;

    procedure RaiseExceptionClosed(ExceptionId: Guid; ExceptionEntryNo: Integer; NewStatus: Text[30]; PlannerTaskId: Text[100])
    begin
        WarehouseExceptionClosed(ExceptionId, ExceptionEntryNo, NewStatus, PlannerTaskId);
    end;

    [ExternalBusinessEvent('paaapprovalrequested', 'Purchase approval requested', 'Raised when a purchase order becomes Critical and a payment approval request is opened.', EventCategory::"PAA Purchase Approvals", '1.0')]
    local procedure PurchaseApprovalRequested(requestId: Guid; requestEntryNo: Integer; orderNo: Code[20]; vendorNo: Code[20]; vendorName: Text[100]; riskLevel: Text[30])
    begin
    end;

    [ExternalBusinessEvent('paaexceptionraised', 'Warehouse exception raised', 'Raised when a High or Critical inventory exception is created.', EventCategory::"PAA Warehouse Exceptions", '1.0')]
    local procedure WarehouseExceptionRaised(exceptionId: Guid; exceptionEntryNo: Integer; itemNo: Code[20]; locationCode: Code[10]; exceptionType: Text[50]; priority: Text[30])
    begin
    end;

    [ExternalBusinessEvent('paaexceptionclosed', 'Warehouse exception closed', 'Raised when a notified inventory exception is resolved or cancelled.', EventCategory::"PAA Warehouse Exceptions", '1.0')]
    local procedure WarehouseExceptionClosed(exceptionId: Guid; exceptionEntryNo: Integer; newStatus: Text[30]; plannerTaskId: Text[100])
    begin
    end;
}
