namespace PowerAutomateApprovals.Integration;

enum 54100 "PAA Request Status"
{
    Extensible = false;

    value(0; Pending)
    {
        Caption = 'Pending';
    }
    value(1; Escalated)
    {
        Caption = 'Escalated';
    }
    value(2; Approved)
    {
        Caption = 'Approved';
    }
    value(3; Rejected)
    {
        Caption = 'Rejected';
    }
    value(4; Cancelled)
    {
        Caption = 'Cancelled';
    }
}
