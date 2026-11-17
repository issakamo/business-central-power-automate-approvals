namespace PowerAutomateApprovals.Integration;

codeunit 54101 "PAA Install"
{
    Subtype = Install;
    Access = Internal;

    trigger OnInstallAppPerCompany()
    var
        Setup: Record "PAA Setup";
    begin
        Setup.InsertIfNotExists();
    end;
}
