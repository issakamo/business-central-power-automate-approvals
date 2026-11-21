namespace PowerAutomateApprovals.Integration.Tests;

using PowerAutomateApprovals.Integration;
using System.TestLibraries.Utilities;
using WarehouseControl.Warehouse;

codeunit 54151 "PAA Exception Notifi Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LibraryInventory: Codeunit "Library - Inventory";
        WHXExceptionMgt: Codeunit "WHX Exception Management";

    // W1 (T-09): only High and Critical exceptions are tracked.
    [Test]
    procedure OnlyHighAndCriticalExceptionsAreTracked()
    var
        Tracking: Record "PAA Exception Tracking";
        ItemNo: Code[20];
        CriticalNo: Integer;
        HighNo: Integer;
        MediumNo: Integer;
        LowNo: Integer;
    begin
        // [GIVEN] Notifications enabled
        Initialize(true);
        ItemNo := LibraryInventory.CreateItemNo();

        // [WHEN] Exceptions are created with 60%, 30%, 10% and 2% variance
        CriticalNo := WHXExceptionMgt.CreateStockException(ItemNo, '', '', 10, 4);
        HighNo := WHXExceptionMgt.CreateStockException(ItemNo, '', '', 10, 7);
        MediumNo := WHXExceptionMgt.CreateStockException(ItemNo, '', '', 10, 9);
        LowNo := WHXExceptionMgt.CreateStockException(ItemNo, '', '', 10, 9.8);

        // [THEN] Only Critical and High have a tracking row
        Assert.IsTrue(Tracking.Get(CriticalNo), 'A Critical exception should be tracked.');
        Assert.IsTrue(Tracking.Get(HighNo), 'A High exception should be tracked.');
        Assert.IsFalse(Tracking.Get(MediumNo), 'A Medium exception should not be tracked.');
        Assert.IsFalse(Tracking.Get(LowNo), 'A Low exception should not be tracked.');
    end;

    // W2: an exception raised to High after creation is tracked.
    [Test]
    procedure ExceptionRaisedToHighLaterIsTracked()
    var
        InventoryException: Record "WHX Inventory Exception";
        Tracking: Record "PAA Exception Tracking";
        EntryNo: Integer;
    begin
        // [GIVEN] A Medium exception, not tracked
        Initialize(true);
        EntryNo := WHXExceptionMgt.CreateStockException(LibraryInventory.CreateItemNo(), '', '', 10, 9);
        Assert.IsFalse(Tracking.Get(EntryNo), 'A Medium exception should not be tracked yet.');

        // [WHEN] Its priority is raised to High, as a user can on the card
        InventoryException.Get(EntryNo);
        InventoryException.Priority := InventoryException.Priority::High;
        InventoryException.Modify(true);

        // [THEN] It is tracked
        Assert.IsTrue(Tracking.Get(EntryNo), 'An exception raised to High should be tracked.');
    end;

    // W3 (T-10): closure is recorded exactly once.
    [Test]
    procedure ResolvedExceptionIsClosedOnlyOnce()
    var
        InventoryException: Record "WHX Inventory Exception";
        Tracking: Record "PAA Exception Tracking";
        EntryNo: Integer;
        ClosedAt: DateTime;
    begin
        // [GIVEN] A tracked High exception
        Initialize(true);
        EntryNo := WHXExceptionMgt.CreateStockException(LibraryInventory.CreateItemNo(), '', '', 10, 7);

        // [WHEN] It is resolved through WHX's own procedure
        InventoryException.Get(EntryNo);
        InventoryException."Resolution Notes" := 'Recounted; the difference is confirmed.';
        WHXExceptionMgt.ResolveException(InventoryException);

        // [THEN] Tracking shows it closed
        Tracking.Get(EntryNo);
        Assert.IsTrue(Tracking."Last Notified Status" = Tracking."Last Notified Status"::Resolved, 'The tracked status should be Resolved.');
        Assert.IsTrue(Tracking."Closed Notified At" <> 0DT, 'The closure should be recorded.');
        ClosedAt := Tracking."Closed Notified At";

        // [WHEN] The resolved exception is saved again
        InventoryException.Get(EntryNo);
        InventoryException."Resolution Notes" := 'Recounted twice; the difference is confirmed.';
        InventoryException.Modify(true);

        // [THEN] The closure is not recorded a second time
        Tracking.Get(EntryNo);
        Assert.AreEqual(ClosedAt, Tracking."Closed Notified At", 'The closure should be recorded only once.');
    end;

    // W4: with notifications switched off, nothing is tracked.
    [Test]
    procedure NoTrackingWhenNotificationsDisabled()
    var
        Tracking: Record "PAA Exception Tracking";
        EntryNo: Integer;
    begin
        // [GIVEN] Notifications switched off
        Initialize(false);

        // [WHEN] A High exception is created
        EntryNo := WHXExceptionMgt.CreateStockException(LibraryInventory.CreateItemNo(), '', '', 10, 7);

        // [THEN] It is not tracked
        Assert.IsFalse(Tracking.Get(EntryNo), 'Nothing should be tracked when notifications are off.');
    end;

    local procedure Initialize(NotificationsEnabled: Boolean)
    var
        Setup: Record "PAA Setup";
    begin
        Setup.InsertIfNotExists();
        Setup.Get();
        Setup."Notifications Enabled" := NotificationsEnabled;
        Setup.Modify();
    end;
}