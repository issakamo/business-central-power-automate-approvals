namespace PowerAutomateApprovals.Integration;

table 54100 "PAA Setup"
{
    Caption = 'Power Automate Approvals Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(10; "Approvals Enabled"; Boolean)
        {
            Caption = 'Purchase Approvals Enabled';
            DataClassification = CustomerContent;
        }
        field(11; "Notifications Enabled"; Boolean)
        {
            Caption = 'Warehouse Notifications Enabled';
            DataClassification = CustomerContent;
        }
        field(20; "Hold Code"; Code[3])
        {
            Caption = 'Payment Hold Code';
            DataClassification = CustomerContent;
            InitValue = 'PAA';
            NotBlank = true;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure InsertIfNotExists()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert(true);
        end;
    end;
}
