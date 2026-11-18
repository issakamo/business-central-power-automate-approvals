namespace PowerAutomateApprovals.Integration;

page 54103 "PAA Decision Dialog"
{
    ApplicationArea = All;
    Caption = 'Decision Comment';
    PageType = StandardDialog;

    layout
    {
        area(Content)
        {
            field(DecisionCommentField; DecisionComment)
            {
                Caption = 'Comment';
                ToolTip = 'Specifies the reason for the decision. A comment is required to reject a request.';
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction <> Action::OK then
            exit(true);
        if CommentRequired and (DelChr(DecisionComment, '<>', ' ') = '') then begin
            Message(CommentRequiredMsg);
            exit(false);
        end;
        exit(true);
    end;

    var
        DecisionComment: Text[250];
        CommentRequired: Boolean;
        CommentRequiredMsg: Label 'Enter a comment before you choose OK.';

    procedure SetCommentRequired(NewCommentRequired: Boolean)
    begin
        CommentRequired := NewCommentRequired;
    end;

    procedure GetComment(): Text
    begin
        exit(DecisionComment);
    end;
}