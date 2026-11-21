namespace PowerAutomateApprovals.Integration;

enum 54104 "PAA Source Type"
{
    Extensible = true;

    value(0; None)
    {
        Caption = 'None';
    }
    value(1; ApprovalRequest)
    {
        Caption = 'Approval Request';
    }
    value(2; InventoryException)
    {
        Caption = 'Inventory Exception';
    }
}