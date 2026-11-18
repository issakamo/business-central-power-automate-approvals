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

            trigger OnValidate()
            var
                Request: Record "PAA Approval Request";
            begin
                if Rec."Hold Code" = xRec."Hold Code" then
                    exit;
                Request.SetFilter(Status, '%1|%2', Request.Status::Pending, Request.Status::Escalated);
                if not Request.IsEmpty() then
                    Error(OpenRequestsErr, xRec."Hold Code");
            end;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    var
        OpenRequestsErr: Label 'You cannot change the hold code while approval requests are open, because holds placed with code %1 would no longer be released.', Comment = '%1 = current hold code';

    procedure InsertIfNotExists()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert(true);
        end;
    end;
}