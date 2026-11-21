namespace PowerAutomateApprovals.Integration;

using WarehouseControl.Warehouse;

table 54103 "PAA Exception Tracking"
{
    Caption = 'Exception Notification Tracking';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Exception Entry No."; Integer)
        {
            Caption = 'Exception Entry No.';
            TableRelation = "WHX Inventory Exception"."Entry No.";
            DataClassification = SystemMetadata;
        }
        field(10; "Last Notified Status"; Enum "WHX Exception Status")
        {
            Caption = 'Last Notified Status';
            DataClassification = CustomerContent;
        }
        field(20; "Planner Task Id"; Text[100])
        {
            Caption = 'Planner Task Id';
            DataClassification = SystemMetadata;
        }
        field(21; "Teams Message Id"; Text[100])
        {
            Caption = 'Teams Message Id';
            DataClassification = SystemMetadata;
        }
        field(30; "Notified At"; DateTime)
        {
            Caption = 'Notified At';
            DataClassification = SystemMetadata;
        }
        field(31; "Closed Notified At"; DateTime)
        {
            Caption = 'Closed Notified At';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Exception Entry No.")
        {
            Clustered = true;
        }
    }
}