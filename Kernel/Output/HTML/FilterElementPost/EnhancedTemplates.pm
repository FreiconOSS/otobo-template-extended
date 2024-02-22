# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2019 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2022 Rother OSS GmbH, https://otobo.de/
# --
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
# --

package Kernel::Output::HTML::FilterElementPost::EnhancedTemplates;

use strict;
use warnings;
use Data::Dumper;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # Get template name.
    my $TemplateName = $Param{TemplateFile} || '';
    return 1 if !$TemplateName;

    # Get valid modules.
    my $ValidTemplates = $Kernel::OM->Get('Kernel::Config')->Get('Frontend::Output::FilterElementPost')->{'EnhancedTemplates'}->{Templates};

    # Apply only if template is valid in config.
    return 1 if !$ValidTemplates->{$TemplateName};

    # Get config object.
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # Get queue create permissions for the user.
    my %UserGroups = $Kernel::OM->Get('Kernel::System::Group')->PermissionUserGet(
        UserID => $Self->{UserID},
        Type   => 'create',
    );

    my $StandardTemplateObjectExtended = $Kernel::OM->Get('Kernel::System::StandardTemplateExtended');
    my %StandardTemplates = $StandardTemplateObjectExtended->StandardTemplateList(
        Valid => 1,
        Type  => 'Create',
    );

    my %FilterStandardTemplates;
    for my $Template ( keys %StandardTemplates ) {
        my %StandardTemplate = $StandardTemplateObjectExtended->StandardTemplateGet(
            ID => $Template,
        );
        my $Found;
        for my $Group ( keys %UserGroups ) {
            next if ( $Found );
            if ( $StandardTemplate{RequiredGroup} =~ /$Group/ ) {
                $Found = 1;
            }
        }

        if ( $Found ) {
            $FilterStandardTemplates{$Template} = $StandardTemplates{$Template};
        }
    }


    my $StandardTemplateStrg = $LayoutObject->BuildSelection(
        Data         => \%FilterStandardTemplates || {},
        Name         => 'EnhancedTemplateID',
        SelectedID   =>  '',
        Class        => 'Modernize',
        PossibleNone => 1,
        Sort         => 'AlphanumericValue',
        Translation  => 1,
        Max          => 200,
    );

    # Add a hidden input containing DynamicField names.
    my $Search  = '(\s+<fieldset class="TableLike">)';
    my $Replace = << "END";
\n<!--Start YK -->
    <fieldset class="TableLike">
    <label class="" for="EnhancedTemplate">Template: </label>
    <div class="Field">$StandardTemplateStrg</div>
    <div class="Clear"></div>
<!--End YK-->
END

    # Update the source.
    ${ $Param{Data} } =~ s{$Search}{$Replace $1};

    return ;
}

1;
