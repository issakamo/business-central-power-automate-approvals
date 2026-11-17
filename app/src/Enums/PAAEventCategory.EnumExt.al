namespace PowerAutomateApprovals.Integration;

using System.Integration;

enumextension 54100 "PAA Event Category" extends EventCategory
{
    value(54100; "PAA Purchase Approvals")
    {
        Caption = 'Purchase Approvals';
    }
    value(54101; "PAA Warehouse Exceptions")
    {
        Caption = 'Warehouse Exceptions';
    }
}
