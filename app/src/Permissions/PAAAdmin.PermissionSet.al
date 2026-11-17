namespace PowerAutomateApprovals.Integration;

permissionset 54100 "PAA Admin"
{
    Caption = 'Power Automate Approvals Admin';
    Assignable = true;

    Permissions =
        tabledata "PAA Setup" = RIM,
        table "PAA Setup" = X,
        page "PAA Setup" = X;
}
