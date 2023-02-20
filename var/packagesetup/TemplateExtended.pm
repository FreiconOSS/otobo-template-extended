# --
# PackageSetup.pm - code to excecute during package installation
# Copyright (C) 2001-2015 OTRS AG, http://otrs.com/
# Copyright (C) 2013-2019 FREICON GmbH & Co. KG, https://freicon.de/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package var::packagesetup::TemplateExtended6;

use strict;
use warnings;

use utf8;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::DB',
    'Kernel::System::Package',
    'Kernel::System::SysConfig',
    'Kernel::System::PackageSetup',
);

use Data::Dumper;

use Kernel::System::VariableCheck qw(:all);

=pod
    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $CodeModule = 'var::packagesetup::' . $Param{Structure}->{Name}->{Content};
    my $CodeObject = $Kernel::OM->Get('var::packagesetup::' . $CodeModule);
=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # always discard the config object before package code is executed,
    # to make sure that the config object will be created newly, so that it
    # will use the recently written new config from the package
    $Kernel::OM->ObjectsDiscard(
        Objects => ['Kernel::Config'],
    );

    $Self->{DatabaseTableDefinition} = [
        {
            'Table'   => 'standard_template_extended',
            'Columns' => [
                {
                    Name       => 'standard_template_id',
                    Type       => 'INTEGER',
                    NotNull    => 1,
                    References => 'standard_template (id)',
                },
                {
                    Name       => 'queue_id',
                    Type       => 'INTEGER',
                    Null       => 1,
                },
                {
                    Name       => 'ticket_type_id',
                    Type       => 'SMALLINT(6)',
                    Null       => 1,
                },
                {
                    Name       => 'service_id',
                    Type       => 'INTEGER',
                    Null       => 1,
                },
                {
                    Name       => 'sla_id',
                    Type       => 'INTEGER',
                    Null       => 1,
                },
                {
                    Name       => 'user_id',
                    Type       => 'INTEGER',
                    Null       => 1,
                },
                {
                    Name       => 'subject',
                    Type       => 'VARCHAR(255)',
                    Null       => 1,
                },
                {
                    Name       => 'ticket_state_id',
                    Type       => 'SMALLINT(6)',
                    Null       => 1,
                },
                {
                    Name       => 'ticket_priority_id',
                    Type       => 'SMALLINT(6)',
                    Null       => 1,
                },
                {
                    Name       => 'responsible_user_id',
                    Type       => 'INTEGER',
                    Null       => 1,
                },
                {
                    Name       => 'time_accounting',
                    Type       => 'DECIMAL(10,2)',
                    Null       => 1,
                },
                {
                    Name       => 'process_entity_id',
                    Type       => 'VARCHAR(255)',
                    Null       => 1,
                },
            ],
            'Indexes' => [
                {
                    Name       => '',
                    Columns    => ['standard_template_id'],
                    Primary    => 1,
                },
            ],
            'Constraints' => [
                {
                    Name            => 'FK_standard_template_extended_id',
                    Column          => 'standard_template_id',
                    ReferenceTable  => 'standard_template',
                    ReferenceColumn => 'id',
                    Delete          => 'CASCADE',
                    Foreign         => 1,
                },
            ],
        },
        {
            'Table'   => 'standard_template_extended_dynamic_fields',
            'Columns' => [
                {
                    Name       => 'id',
                    Type       => 'INTEGER',
                    NotNull    => 1,
                    AutoIncrement => 1,
                },
                {
                    Name       => 'dynamic_field_id',
                    Type       => 'INTEGER',
                    NotNull    => 1,
                    References => 'dynamic_field (id)',
                },
                {
                    Name       => 'standard_template_id',
                    Type       => 'INTEGER',
                    NotNull    => 1,
                    References => 'standard_template (id)',
                },
                {
                    Name       => 'value_text',
                    Type       => 'TEXT',
                    Null       => 1,
                },
                {
                    Name       => 'value_date',
                    Type       => 'DATETIME',
                    Null       => 1,
                },
                {
                    Name       => 'value_int',
                    Type       => 'BIGINT',
                    Null       => 1,
                },
            ],
            'Indexes' => [
                {
                    Name       => '',
                    Columns    => ['id'],
                    Primary    => 1,
                },
                {
                    Name       => 'standard_template_id',
                    Columns    => ['standard_template_id'],
                },
                {
                    Name       => 'dynamic_field_id',
                    Columns    => ['dynamic_field_id'],
                },
            ],
            'Constraints' => [
                {
                    Name            => 'FK_std_tpl_ext_df_dynamic_field_id',
                    Column          => 'dynamic_field_id',
                    ReferenceTable  => 'dynamic_field',
                    ReferenceColumn => 'id',
                    Delete          => 'CASCADE',
                    Foreign         => 1,
                },
                {
                    Name            => 'FK_std_tpl_ext_df_standard_template_id',
                    Column          => 'standard_template_id',
                    ReferenceTable  => 'standard_template',
                    ReferenceColumn => 'id',
                    Delete          => 'CASCADE',
                    Foreign         => 1,
                },
            ],
        },
    ];
    return $Self;
}



sub CodeInstall {
    my ( $Self, %Param ) = @_;
    return 1;
}

sub CodeReinstall {
    my ( $Self, %Param ) = @_;
    return 1;
}

sub CodeUpgrade {
    my ( $Self, %Param ) = @_;
    return 1;
}

sub CodeUninstall {
    my ( $Self, %Param ) = @_;
    return 1;
}



1;
