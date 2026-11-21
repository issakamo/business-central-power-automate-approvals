namespace PowerAutomateApprovals.Integration;

table 54104 "PAA Flow Run Log"
{
    Caption = 'Flow Run Log';
    DataClassification = CustomerContent;
    LookupPageId = "PAA Flow Run Log";
    DrillDownPageId = "PAA Flow Run Log";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(10; "Flow Name"; Text[100])
        {
            Caption = 'Flow Name';
            DataClassification = SystemMetadata;
        }
        field(11; "Run Id"; Text[100])
        {
            Caption = 'Run Id';
            DataClassification = SystemMetadata;
        }
        field(20; "Source Type"; Enum "PAA Source Type")
        {
            Caption = 'Source Type';
            DataClassification = SystemMetadata;
        }
        field(21; "Source Entry No."; Integer)
        {
            Caption = 'Source Entry No.';
            DataClassification = SystemMetadata;
        }
        field(30; Result; Enum "PAA Run Result")
        {
            Caption = 'Result';
            DataClassification = SystemMetadata;
        }
        field(31; Message; Text[2048])
        {
            Caption = 'Message';
            DataClassification = CustomerContent;
        }
        field(40; "Logged At"; DateTime)
        {
            Caption = 'Logged At';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Source; "Source Type", "Source Entry No.")
        {
        }
    }

    trigger OnInsert()
    begin
        Rec."Logged At" := CurrentDateTime();
    end;
}