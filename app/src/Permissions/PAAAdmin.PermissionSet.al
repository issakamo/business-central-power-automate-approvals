namespace PowerAutomateApprovals.Integration;

permissionset 54100 "PAA Admin"
{
    Caption = 'Power Automate Approvals Admin';
    Assignable = true;
    IncludedPermissionSets = "PAA User";

    Permissions =
        tabledata "PAA Setup" = RIM,
        tabledata "PAA Approval Request" = RM,
        table "PAA Setup" = X,
        page "PAA Setup" = X,
        page "PAA Decision Dialog" = X;
}