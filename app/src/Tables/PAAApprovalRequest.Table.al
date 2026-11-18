namespace PowerAutomateApprovals.Integration;

using Microsoft.Purchases.Vendor;
using PurchaseControl.Purchasing;

table 54101 "PAA Approval Request"
{
    Caption = 'Payment Approval Request';
    DataClassification = CustomerContent;
    LookupPageId = "PAA Approval Requests";
    DrillDownPageId = "PAA Approval Requests";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(10; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            DataClassification = CustomerContent;
        }
        field(11; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor."No.";
            DataClassification = CustomerContent;
        }
        field(12; "Vendor Name"; Text[100])
        {
            Caption = 'Vendor Name';
            DataClassification = CustomerContent;
        }
        field(20; "Assessment Entry No."; Integer)
        {
            Caption = 'Assessment Entry No.';
            TableRelation = "PCX Purchase Risk Assessment"."Entry No.";
            DataClassification = SystemMetadata;
        }
        field(21; "Risk Level"; Enum "PCX Risk Level")
        {
            Caption = 'Risk Level';
            DataClassification = CustomerContent;
        }
        field(22; "Match Status"; Enum "PCX Match Status")
        {
            Caption = 'Match Status';
            DataClassification = CustomerContent;
        }
        field(23; "Quantity Variance %"; Decimal)
        {
            Caption = 'Quantity Variance %';
            DecimalPlaces = 0 : 2;
            DataClassification = CustomerContent;
        }
        field(24; "Price Variance %"; Decimal)
        {
            Caption = 'Price Variance %';
            DecimalPlaces = 0 : 2;
            DataClassification = CustomerContent;
        }
        field(25; "Amount on Hold (LCY)"; Decimal)
        {
            Caption = 'Amount on Hold (LCY)';
            AutoFormatType = 1;
            DataClassification = CustomerContent;
        }
        field(30; Status; Enum "PAA Request Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
        }
        field(31; "Current Approver Email"; Text[250])
        {
            Caption = 'Current Approver Email';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(32; "Escalated At"; DateTime)
        {
            Caption = 'Escalated At';
            DataClassification = SystemMetadata;
        }
        field(40; "Decided By"; Text[250])
        {
            Caption = 'Decided By';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(41; "Decided At"; DateTime)
        {
            Caption = 'Decided At';
            DataClassification = SystemMetadata;
        }
        field(42; "Decision Comment"; Text[250])
        {
            Caption = 'Decision Comment';
            DataClassification = CustomerContent;
        }
        field(50; "Vendor Notified At"; DateTime)
        {
            Caption = 'Vendor Notified At';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(OrderStatus; "Order No.", Status)
        {
        }
    }

    procedure IsOpen(): Boolean
    begin
        exit(Rec.Status in [Rec.Status::Pending, Rec.Status::Escalated]);
    end;
}