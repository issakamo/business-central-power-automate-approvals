namespace PowerAutomateApprovals.Integration;

enum 54101 "PAA Log Action"
{
    Extensible = false;

    value(0; Requested)
    {
        Caption = 'Requested';
    }
    value(1; "Hold Applied")
    {
        Caption = 'Hold Applied';
    }
    value(2; Escalated)
    {
        Caption = 'Escalated';
    }
    value(3; Approved)
    {
        Caption = 'Approved';
    }
    value(4; Rejected)
    {
        Caption = 'Rejected';
    }
    value(5; "Hold Released")
    {
        Caption = 'Hold Released';
    }
    value(6; "Vendor Notified")
    {
        Caption = 'Vendor Notified';
    }
    value(7; Cancelled)
    {
        Caption = 'Cancelled';
    }
}
