# --
# Copyright (C) 2001-2017 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::StandardTemplateExtended;

use strict;
use warnings;

### FREICON: import dev module
#test
use Data::Dumper;
use Kernel::System::VariableCheck qw(:all);
### FREICON

our @ObjectDependencies = (
    'Kernel::System::Cache',
    'Kernel::System::DB',
    'Kernel::System::Log',
    'Kernel::System::Valid',
);

=head1 NAME

Kernel::System::StandardTemplate - standard template lib

=head1 SYNOPSIS

All standard template functions. E. g. to add standard template or other functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $StandardTemplateObject = $Kernel::OM->Get('Kernel::System::StandardTemplate');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item StandardTemplateAdd()

add new standard template

    my $ID = $StandardTemplateObject->StandardTemplateAdd(
        Name         => 'New Standard Template',
        Template     => 'Thank you for your email.',
        ContentType  => 'text/plain; charset=utf-8',
        TemplateType => 'Answer',                     # or 'Forward' or 'Create'
        ValidID      => 1,
        UserID       => 123,
    );

=cut

sub StandardTemplateAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(Name ValidID Template ContentType UserID TemplateType)) {
        if ( !defined( $Param{$_} ) ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!"
            );
            return;
        }
    }

    #    print STDERR Dumper \%Param;

    # check if a standard template with this name already exists
    if ( $Kernel::OM->Get('Kernel::System::StandardTemplate')->NameExistsCheck( Name => $Param{Name} ) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "A standard template with name '$Param{Name}' already exists!"
        );
        return;
    }

    my $ID = $Kernel::OM->Get('Kernel::System::StandardTemplate')->StandardTemplateAdd(%Param);

    # check the result
    return if (!$ID);

    for my $Key (qw(TicketType Queue Service Owner SLA Priority NextState Responsible ProcessEntityID)) {
        if ( $Param{$Key} =~ /^Process/ ) {

        } elsif ( $Param{$Key}  !~ m/^\d+$/ ) {
            $Param{$Key} = undef;
        }
    }

    if ( IsArrayRefWithData($Param{RequiredGroup}) ) {
        $Param{RequiredGroup} = join( ',', @{$Param{RequiredGroup}} );
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Do(
        SQL => '
            INSERT INTO standard_template_extended (standard_template_id, queue_id, ticket_type_id, service_id, sla_id,
                user_id, subject, ticket_state_id, ticket_priority_id, process_entity_id, required_group, responsible_user_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        Bind => [
            \$ID,        \$Param{Queue}, \$Param{TicketType}, \$Param{Service},
            \$Param{SLA}, \$Param{Owner},  \$Param{Subject},  \$Param{NextState},
            \$Param{Priority}, \$Param{ProcessEntityID}, \$Param{RequiredGroup}, \$Param{Responsible}
        ],
    );

    return if !$DBObject->Prepare(
        SQL  => 'SELECT id FROM standard_template WHERE name = ? AND change_by = ?',
        Bind => [ \$Param{Name}, \$Param{UserID}, ],
    );

    for (keys %Param) {
        next if (!/^DynamicField_.*/);
        next if (!$Param{$_}->{Value});
        $Self->_ValueSet(
            DynamicFieldID => $Param{$_}->{ID},
            TemplateID => $ID,
            Value => $Param{$_}->{Value},
        );
    }

    # clear queue cache, due to Queue <-> Template relations
    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => 'Queue',
    );

    return $ID;
}

=item StandardTemplateGet()

get standard template attributes

    my %StandardTemplate = $StandardTemplateObject->StandardTemplateGet(
        ID => 123,
    );

Returns:

    %StandardTemplate = (
        ID                  => '123',
        Name                => 'Simple remplate',
        Comment             => 'Some comment',
        Template            => 'Template content',
        ContentType         => 'text/plain',
        TemplateType        => 'Answer',
        ValidID             => '1',
        CreateTime          => '2010-04-07 15:41:15',
        CreateBy            => '321',
        ChangeTime          => '2010-04-07 15:59:45',
        ChangeBy            => '223',
    );

=cut

sub StandardTemplateGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ID!'
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Prepare(
        SQL => '
            SELECT name, valid_id, comments, text, content_type, create_time, create_by,
                change_time, change_by, template_type,
                subject, ticket_type_id, sla_id, queue_id, service_id, user_id, ticket_priority_id, ticket_state_id, process_entity_id,
                required_group, responsible_user_id
            FROM standard_template
            LEFT JOIN standard_template_extended
                ON standard_template.id = standard_template_extended.standard_template_id
            WHERE id = ?',
        Bind => [ \$Param{ID} ],
    );

    my %Data;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        %Data = (
            ID              => $Param{ID},
            Name            => $Data[0],
            Comment         => $Data[2],
            Template        => $Data[3],
            ContentType     => $Data[4] || 'text/plain',
            ValidID         => $Data[1],
            CreateTime      => $Data[5],
            CreateBy        => $Data[6],
            ChangeTime      => $Data[7],
            ChangeBy        => $Data[8],
            TemplateType    => $Data[9],

            Subject         => $Data[10],
            TicketType      => $Data[11],
            SLA             => $Data[12],
            Queue           => $Data[13],
            Service         => $Data[14],
            Owner           => $Data[15],
            Priority        => $Data[16],
            NextState       => $Data[17],
            ProcessEntityID => $Data[18],

            RequiredGroup   => $Data[19],
            Responsible     => $Data[20],
        );
    }

    #return %Data;
    return (%Data, $Self->_ValueGetAll(TemplateID => $Param{ID}));
}

=item StandardTemplateDelete()

delete a standard template

    $StandardTemplateObject->StandardTemplateDelete(
        ID => 123,
    );

=cut

sub StandardTemplateDelete {
    my ( $Self, %Param ) = @_;

    return $Kernel::OM->Get('Kernel::System::StandardTemplate')->StandardTemplateDelete(%Param);
}

=item StandardTemplateUpdate()

update standard template attributes

    $StandardTemplateObject->StandardTemplateUpdate(
        ID           => 123,
        Name         => 'New Standard Template',
        Template     => 'Thank you for your email.',
        ContentType  => 'text/plain; charset=utf-8',
        TemplateType => 'Answer',
        ValidID      => 1,
        UserID       => 123,
    );

=cut

sub StandardTemplateUpdate {
    my ( $Self, %Param ) = @_;

    return if !$Kernel::OM->Get('Kernel::System::StandardTemplate')->StandardTemplateUpdate(%Param);

    for my $Key (qw(TicketType Queue Service Owner SLA Priority NextState Responsible ProcessEntityID)) {
        if ( $Param{$Key} =~ /^Process/ ) {

        } elsif ( $Param{$Key}  !~ m/^\d+$/ ) {
            $Param{$Key} = undef;
        }
    }

    # sql
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => '
            DELETE FROM standard_template_extended WHERE standard_template_id = ?',
        Bind => [
            \$Param{ID}
        ],
    );
    # sql
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => '
            INSERT INTO standard_template_extended (standard_template_id, queue_id, ticket_type_id, service_id, sla_id,
                user_id, subject, ticket_state_id, ticket_priority_id, process_entity_id, required_group, responsible_user_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        Bind => [
            \$Param{ID},        \$Param{Queue}, \$Param{TicketType}, \$Param{Service},
            \$Param{SLA}, \$Param{Owner},  \$Param{Subject},  \$Param{NextState},
            \$Param{Priority}, \$Param{ProcessEntityID}, \$Param{RequiredGroup}, \$Param{Responsible}
        ],
    );

    for (keys %Param) {
        next if (!/^DynamicField_.*/);
        next if (!$Param{$_}->{Value});
        $Self->_ValueSet(
            DynamicFieldID => $Param{$_}->{ID},
            TemplateID => $Param{ID},
            Value => $Param{$_}->{Value},
        );
    }

    # clear queue cache, due to Queue <-> Template relations
    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => 'Queue',
    );

    return 1;
}

=item StandardTemplateLookup()

return the name or the standard template id

    my $StandardTemplateName = $StandardTemplateObject->StandardTemplateLookup(
        StandardTemplateID => 123,
    );

    or

    my $StandardTemplateID = $StandardTemplateObject->StandardTemplateLookup(
        StandardTemplate => 'Std Template Name',
    );

=cut

sub StandardTemplateLookup {
    my ( $Self, %Param ) = @_;

    return $Kernel::OM->Get('Kernel::System::StandardTemplate')->StandardTemplateLookup(%Param);
}

=item StandardTemplateList()

get all valid standard templates

    my %StandardTemplates = $StandardTemplatesObject->StandardTemplateList();

Returns:
    %StandardTemplates = (
        1 => 'Some Name',
        2 => 'Some Name2',
        3 => 'Some Name3',
    );

get all standard templates

    my %StandardTemplates = $StandardTemplateObject->StandardTemplateList(
        Valid => 0,
    );

Returns:
    %StandardTemplates = (
        1 => 'Some Name',
        2 => 'Some Name2',
    );

get standard templates from a certain type
    my %StandardTemplates = $StandardTemplateObject->StandardTemplateList(
        Valid => 0,
        Type  => 'Answer',
    );

Returns:
    %StandardTemplates = (
        1 => 'Answer - Some Name',
    );

=cut

sub StandardTemplateList {
    my ( $Self, %Param ) = @_;

    return $Kernel::OM->Get('Kernel::System::StandardTemplate')->StandardTemplateList(%Param);
}

=item NameExistsCheck()

    return 1 if another standard template with this name already exists

        $Exist = $StandardTemplateObject->NameExistsCheck(
            Name => 'Some::Template',
            ID => 1, # optional
        );

=cut

sub NameExistsCheck {
    my ( $Self, %Param ) = @_;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL  => 'SELECT id FROM standard_template WHERE name = ?',
        Bind => [ \$Param{Name} ],
    );

    # fetch the result
    my $Flag;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        if ( !$Param{ID} || $Param{ID} ne $Row[0] ) {
            $Flag = 1;
        }
    }
    if ($Flag) {
        return 1;
    }
    return 0;
}

=item ValueSet()

sets a dynamic field value. This is represented by one or more rows in the dynamic_field_value
table, each storing one text, date and int field. Please see how they will be returned by
L</ValueGet()>.

    my $Success = $DynamicFieldValueObject->ValueSet(
        FieldID  => $FieldID,                 # ID of the dynamic field
        ObjectID => $ObjectID,                # ID of the current object that the field
                                              #   must be linked to, e. g. TicketID
        Value    => [
            {
                ValueText          => 'some text',            # optional, one of these fields must be provided
                ValueDateTime      => '1977-12-12 12:00:00',  # optional
                ValueInt           => 123,                    # optional
            },
            ...
        ],
        UserID   => $UserID,
    );

=cut

sub _ValueSet {
    my ( $Self, %Param ) = @_;
    for my $Needed (qw(DynamicFieldID TemplateID Value)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }
    if ( ref $Param{Value} ne 'ARRAY' || !$Param{Value}->[0] ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need Param{Value}! $Param{DynamicFieldID}"
        );
        return;
    }
    my @Values;

    for (my $i = 0; 1; $i++) {
        if ( ref $Param{Value}->[$i] ne 'HASH' ) {
            last;
        }

        if (
            !defined $Param{Value}->[$i]->{ValueText}
                && !defined $Param{Value}->[$i]->{ValueInt}
                && !defined $Param{Value}->[$i]->{ValueDateTime}
        )
        {
            last;
        }

        my %Value = (
            ValueText     => scalar $Param{Value}->[$i]->{ValueText},
            ValueInt      => scalar $Param{Value}->[$i]->{ValueInt},
            ValueDateTime => scalar $Param{Value}->[$i]->{ValueDateTime},
        );

        # data validation
        my $Success = $Self->_ValueValidate( Value => \%Value );

        return if !$Success;

        # data conversions

        # set ValueDateTime column to NULL
        if ( exists $Value{ValueDateTime} && !$Value{ValueDateTime} ) {
            $Value{ValueDateTime} = undef;
        }

        # set Int Zero
        if ( defined $Value{ValueInt} && !$Value{ValueInt} ) {
            $Value{ValueInt} = '0';
        }

        push @Values, \%Value;
    }

    # delete existing value
    $Self->_ValueDelete(
        DynamicFieldID  => $Param{DynamicFieldID},
        TemplateID => $Param{TemplateID},
    );
    for my $Value (@Values) {

        # create a new value entry #sql
        return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
            SQL =>
                'INSERT INTO standard_template_extended_dynamic_fields (dynamic_field_id, standard_template_id, value_text, value_date, value_int)'
                    . ' VALUES (?, ?, ?, ?, ?)',
            Bind => [
                \$Param{DynamicFieldID}, \$Param{TemplateID},
                \$Value->{ValueText}, \$Value->{ValueDateTime}, \$Value->{ValueInt},
            ],
        );
    }
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(SQL =>'DELETE FROM standard_template_extended_dynamic_fields WHERE (value_text IS NULL AND value_text = "") AND value_int IS NULL AND value_date IS NULL');


    # delete cache
    #$Self->_DeleteFromCache(%Param);

    return 1;
}

=item ValueGet()

get a dynamic field value. For each table row there will be one entry in the
result list.

    my $Value = $DynamicFieldValueObject->ValueGet(
        FieldID            => $FieldID,                 # ID of the dynamic field
        ObjectID           => $ObjectID,                # ID of the current object that the field
                                                        #   is linked to, e. g. TicketID
    );

    Returns [
        {
            ID                 => 437,
            ValueText          => 'some text',
            ValueDateTime      => '1977-12-12 12:00:00',
            ValueInt           => 123,
        },
    ];

=cut

sub _ValueGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(DynamicFieldID TemplateID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # We'll populate cache with all object's dynamic fields to reduce
    # number of db accesses (only one db query for all dynamic fields till
    # cache expiration); return only specified one dynamic field
    return if !$Kernel::OM->Get('Kernel::System::DB')->Prepare(
        SQL =>
            'SELECT id, value_text, value_date, value_int, dynamic_field_id
        FROM standard_template_extended_dynamic_fields
        WHERE standard_template_id  = ?
        ORDER BY id',
        Bind => [ \$Param{TemplateID} ],
    );

    while ( my @Data = $Kernel::OM->Get('Kernel::System::DB')->FetchrowArray() ) {

        # cleanup time stamps (some databases are using e. g. 2008-02-25 22:03:00.000000
        # and 0000-00-00 00:00:00 time stamps)
        if ( $Data[2] ) {
            if ( $Data[2] eq '0000-00-00 00:00:00' ) {
                $Data[2] = undef;
            }
            $Data[2] =~ s/^(\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2})\..+?$/$1/;
        }
    }

    return [];
}


sub _ValueGetAll {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TemplateID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    return if !$Kernel::OM->Get('Kernel::System::DB')->Prepare(
        SQL =>
            'SELECT DISTINCT dynamic_field_id
         FROM standard_template_extended_dynamic_fields
         WHERE standard_template_id = ?',
        Bind => [ \$Param{TemplateID} ],
    );

    my %Result;

    my @DynamicFieldIDs;
    while ( my @DynamicFieldID = $Kernel::OM->Get('Kernel::System::DB')->FetchrowArray() ) {
        push(@DynamicFieldIDs, $DynamicFieldID[0]);
    }
    for (@DynamicFieldIDs) {
        return if !$Kernel::OM->Get('Kernel::System::DB')->Prepare(
            SQL =>
                'SELECT field_type, value_text , value_date , value_int, name
             FROM standard_template_extended_dynamic_fields
             INNER JOIN dynamic_field ON dynamic_field_id = dynamic_field.id
             WHERE dynamic_field_id = ?
             AND standard_template_id = ?',
            Bind => [ \$_, \$Param{TemplateID} ],
        );
        while ( my @DynamicFieldData = $Kernel::OM->Get('Kernel::System::DB')->FetchrowArray() ) {
            if ($DynamicFieldData[0] eq 'Text') {
                $Result{'DynamicField_'.$DynamicFieldData[4]} = $DynamicFieldData[1];
            } elsif ($DynamicFieldData[0] eq 'Checkbox') {
                $Result{'DynamicField_'.$DynamicFieldData[4]} = $DynamicFieldData[1];
            } elsif ($DynamicFieldData[0] eq 'Dropdown') {
                $Result{'DynamicField_'.$DynamicFieldData[4]} = $DynamicFieldData[1];
            } elsif ($DynamicFieldData[0] eq 'Multiselect') {
                push @{$Result{'DynamicField_'.$DynamicFieldData[4]}}, $DynamicFieldData[1];
            } elsif ($DynamicFieldData[0] eq 'Date') {
                $Result{'DynamicField_'.$DynamicFieldData[4]} = $DynamicFieldData[2];
            } elsif ($DynamicFieldData[0] eq 'DateTime') {
                $Result{'DynamicField_'.$DynamicFieldData[4]} = $DynamicFieldData[2];
            } elsif ($DynamicFieldData[0] eq 'TextArea') {
                $Result{'DynamicField_'.$DynamicFieldData[4]}{ValueDateTime} = $DynamicFieldData[1];
            } else {
                $Result{'DynamicField_'.$DynamicFieldData[4]} = $DynamicFieldData[1];
            }
        }
    }
    return %Result;
}

=item ValueDelete()

delete a Dynamic field value entry. All associated rows will be deleted.

    my $Success = $DynamicFieldValueObject->ValueDelete(
        FieldID            => $FieldID,                 # ID of the dynamic field
        ObjectID           => $ObjectID,                # ID of the current object that the field
                                                        #   is linked to, e. g. TicketID
        UserID  => 123,
    );

    Returns 1.

=cut

sub _ValueDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(DynamicFieldID TemplateID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # delete dynamic field value
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'DELETE FROM standard_template_extended_dynamic_fields WHERE dynamic_field_id = ? AND standard_template_id = ?',
        Bind => [ \$Param{DynamicFieldID}, \$Param{TemplateID} ],
    );

    # delete cache
    $Self->_DeleteFromCache(%Param);

    return 1;
}

=item AllValuesDelete()

delete all entries of a dynamic field .

    my $Success = $DynamicFieldValueObject->AllValuesDelete(
        FieldID            => $FieldID,                 # ID of the dynamic field
        UserID  => 123,
    );

    Returns 1.

=cut

sub _AllValuesDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(FieldID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # delete dynamic field value
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL  => 'DELETE FROM dynamic_field_value WHERE field_id = ?',
        Bind => [ \$Param{FieldID} ],
    );

    # clear queue cache, due to Queue <-> Template relations
    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => 'Queue',
    );

    return 1;
}

=head2 ValueValidate()

checks if the given value is valid for the value type.

    my $IsValid = $DynamicFieldValueObject->ValueValidate(
    Value  =>  {
        ValueText          => 'some text',            # optional, one of these fields must be provided
        ValueDateTime      => '1977-12-12 12:00:00',  # optional
        ValueInt           => 123,                    # optional
    },
    UserID => $UserID,
);

=cut

sub _ValueValidate {
    my ( $Self, %Param ) = @_;

    return unless IsHashRefWithData( $Param{Value} );

    my %Value = $Param{Value}->%*;

    # validate date
    if ( $Value{ValueDateTime} ) {

        # get time object
        my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');

        # convert the DateTime value to system time to check errors
        my $SystemTime = $DateTimeObject->Set(
            String => $Value{ValueDateTime},
        );

        return unless defined $SystemTime;

        # convert back to time stamp to check errors
        my $TimeStamp = $DateTimeObject->ToString;

        return unless $TimeStamp;

        # compare if the date is the same
        return unless $Value{ValueDateTime} eq $TimeStamp;
    }

    # validate integer
    if ( $Value{ValueInt} ) {

        if ( $Value{ValueInt} !~ m{\A  -? \d+ \z}smx ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Invalid Integer '$Value{ValueInt}'!"
            );

            return;
        }
    }

    # no validation for ValueText

    # report as valid when no check found a reason to complain
    return 1;
}



sub _DeleteFromCache {
    return 1;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
