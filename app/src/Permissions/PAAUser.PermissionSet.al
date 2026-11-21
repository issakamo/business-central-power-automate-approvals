namespace PowerAutomateApprovals.Integration;

permissionset 54101 "PAA User"
{
    Caption = 'Power Automate Approvals User';
    Assignable = true;

    Permissions =
        tabledata "PAA Approval Request" = R,
        tabledata "PAA Decision Log" = R,
        tabledata "PAA Flow Run Log" = R,
        table "PAA Approval Request" = X,
        table "PAA Decision Log" = X,
        table "PAA Flow Run Log" = X,
        page "PAA Approval Requests" = X,
        page "PAA Decision Log" = X,
        page "PAA Flow Run Log" = X;
}