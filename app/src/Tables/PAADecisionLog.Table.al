namespace PowerAutomateApprovals.Integration;

table 54102 "PAA Decision Log"
{
    Caption = 'Approval Decision Log';
    DataClassification = CustomerContent;
    LookupPageId = "PAA Decision Log";
    DrillDownPageId = "PAA Decision Log";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(10; "Request Entry No."; Integer)
        {
            Caption = 'Request Entry No.';
            TableRelation = "PAA Approval Request"."Entry No.";
            DataClassification = SystemMetadata;
        }
        field(20; "Log Action"; Enum "PAA Log Action")
        {
            Caption = 'Action';
            DataClassification = CustomerContent;
        }
        field(21; Source; Enum "PAA Log Source")
        {
            Caption = 'Source';
            DataClassification = CustomerContent;
        }
        field(30; "Performed By"; Text[250])
        {
            Caption = 'Performed By';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(31; "Performed At"; DateTime)
        {
            Caption = 'Performed At';
            DataClassification = SystemMetadata;
        }
        field(40; Comment; Text[250])
        {
            Caption = 'Comment';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Request; "Request Entry No.")
        {
        }
    }
}