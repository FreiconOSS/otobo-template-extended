# --
# Copyright (C) 2001-2019 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

### FREICON:
package Kernel::Modules::AdminTemplateExtended;
### FREICON

use strict;
use warnings;

use Kernel::Language qw(Translatable);

### FREICON: import needed Modules
use Data::Dumper;
use Kernel::System::VariableCheck qw(:all);
### FREICON

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ParamObject            = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject           = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    ### FREICON: change object to STDExtended
    #my $StandardTemplateObject = $Kernel::OM->Get('Kernel::System::StandardTemplate');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $StandardTemplateObjectExtended = $Kernel::OM->Get('Kernel::System::StandardTemplateExtended');
    ### FREICON
    my $StdAttachmentObject    = $Kernel::OM->Get('Kernel::System::StdAttachment');

    my $Notification = $ParamObject->GetParam( Param => 'Notification' ) || '';

    # ------------------------------------------------------------ #
    # change
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'Change' ) {
        my $ID   = $ParamObject->GetParam( Param => 'ID' ) || '';
        ### FREICON: use STDExtended object
        #my %Data = $StandardTemplateObject->StandardTemplateGet(
        my %Data = $StandardTemplateObjectExtended->StandardTemplateGet(
            ID => $ID,
        );
        ### FREICON

        my @SelectedAttachment;
        my %SelectedAttachmentData = $StdAttachmentObject->StdAttachmentStandardTemplateMemberList(
            StandardTemplateID => $ID,
        );
        for my $Key ( sort keys %SelectedAttachmentData ) {
            push @SelectedAttachment, $Key;
        }

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Info => Translatable('Template updated!') )
            if ( $Notification && $Notification eq 'Update' );

        $Self->_Edit(
            Action => 'Change',
            %Data,
            SelectedAttachments => \@SelectedAttachment,
        );
        ### FREICON: change template
        $Output .= $LayoutObject->Output(
            #TemplateFile => 'AdminTemplate',
            TemplateFile => 'AdminTemplateExtended',
            Data         => \%Param,
        );
        ### FREICON
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # change action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ChangeAction' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my @NewIDs = $ParamObject->GetArray( Param => 'IDs' );
        my ( %GetParam, %Errors );
        ### FREICON: added multiple parameters
        #for my $Parameter (qw(ID Name Comment ValidID TemplateType)) {
        for my $Parameter (qw(ID Name Comment ValidID TemplateType RequiredGroup TicketType Queue Service Owner SLA Subject Priority NextState Responsible ProcessEntityID)) {
            $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter ) // '';
        }
        ### FREICON

        ### FREICON: add Dynamic Field Block
        my $AllowedDynamicFields = $Kernel::OM->Get('Kernel::Config')->Get('StandardTemplateExtended::DynamicFields') || [];
        my $DynamicFieldConfigList = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
            ResultType => 'HASH',
            FieldFilter => { map { $_ => 1 } @{$AllowedDynamicFields} },
        ) || [];
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{$DynamicFieldConfigList} ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

            # extract the dynamic field value form the web request
            $GetParam{'DynamicField_'.$DynamicFieldConfig->{Name}}{ID} = $DynamicFieldConfig->{ID};

            my $Type = $DynamicFieldConfig->{FieldType};
            if ($Type eq 'Text') {
                $GetParam{'DynamicField_'.$DynamicFieldConfig->{Name}}{Value} = [{ValueText => $DynamicFieldBackendObject->EditFieldValueGet(DynamicFieldConfig => $DynamicFieldConfig,ParamObject => $ParamObject,LayoutObject => $LayoutObject,),}];
            } elsif ($Type eq 'Checkbox') {
                $GetParam{'DynamicField_'.$DynamicFieldConfig->{Name}}{Value} = [{ValueText => $DynamicFieldBackendObject->EditFieldValueGet(DynamicFieldConfig => $DynamicFieldConfig,ParamObject => $ParamObject,LayoutObject => $LayoutObject,),}];
            } elsif ($Type eq 'Dropdown') {
                $GetParam{'DynamicField_'.$DynamicFieldConfig->{Name}}{Value} = [{ValueText => $DynamicFieldBackendObject->EditFieldValueGet(DynamicFieldConfig => $DynamicFieldConfig,ParamObject => $ParamObject,LayoutObject => $LayoutObject,),}];
            } elsif ($Type eq 'Multiselect') {
                my @MultiselectData;
                for (@{$DynamicFieldBackendObject->EditFieldValueGet(DynamicFieldConfig => $DynamicFieldConfig,ParamObject => $ParamObject,LayoutObject => $LayoutObject,)}) {
                    push (@MultiselectData, {ValueText => $_});
                }
                $GetParam{'DynamicField_'.$DynamicFieldConfig->{Name}}{Value} = \@MultiselectData;
            } elsif ($Type eq 'TextArea') {
                $GetParam{'DynamicField_'.$DynamicFieldConfig->{Name}}{Value} = [{ValueText => $DynamicFieldBackendObject->EditFieldValueGet(DynamicFieldConfig => $DynamicFieldConfig,ParamObject => $ParamObject,LayoutObject => $LayoutObject,),}];
            } elsif ($Type eq 'Date') {
                $GetParam{'DynamicField_'.$DynamicFieldConfig->{Name}}{Value} = [{ValueDateTime => $DynamicFieldBackendObject->EditFieldValueGet(DynamicFieldConfig => $DynamicFieldConfig,ParamObject => $ParamObject,LayoutObject => $LayoutObject,),}];
            } elsif ($Type eq 'DateTime') {
                $GetParam{'DynamicField_'.$DynamicFieldConfig->{Name}}{Value} = [{ValueDateTime => $DynamicFieldBackendObject->EditFieldValueGet(DynamicFieldConfig => $DynamicFieldConfig,ParamObject => $ParamObject,LayoutObject => $LayoutObject,),}];
            } else {
                $GetParam{'DynamicField_'.$DynamicFieldConfig->{Name}}{Value} = [{ValueText => $DynamicFieldBackendObject->EditFieldValueGet(DynamicFieldConfig => $DynamicFieldConfig,ParamObject => $ParamObject,LayoutObject => $LayoutObject,),}];
            }
        }
        ### FREICON

        $GetParam{'Template'} = $ParamObject->GetParam(
            Param => 'Template',
            Raw   => 1
        ) || '';

        # get composed content type
        $GetParam{ContentType} = 'text/plain';
        if ( $LayoutObject->{BrowserRichText} ) {
            $GetParam{ContentType} = 'text/html';
        }

        # check needed data
        for my $Needed (qw(Name ValidID TemplateType)) {
            if ( !$GetParam{$Needed} ) {
                $Errors{ $Needed . 'Invalid' } = 'ServerError';
            }
        }
        ### FREICON:
        # check if a standard template exist with this name
        my $NameExists = $StandardTemplateObjectExtended->NameExistsCheck(
            Name => $GetParam{Name},
            ID   => $GetParam{ID}
        );
        ### FREICON

        if ($NameExists) {
            $Errors{NameExists}    = 1;
            $Errors{'NameInvalid'} = 'ServerError';
        }

        # if no errors occurred
        if ( !%Errors ) {

            # update group
            if (
                ### FREICON:
                $StandardTemplateObjectExtended->StandardTemplateUpdate(
                    %GetParam,
                    UserID => $Self->{UserID},
                )
                ### FREICON
            )
            {
                my %AttachmentsAll = $StdAttachmentObject->StdAttachmentList();

                # create hash with selected queues
                my %AttachmentsSelected = map { $_ => 1 } @NewIDs;

                # check all used attachments
                for my $AttachmentID ( sort keys %AttachmentsAll ) {
                    my $Active = $AttachmentsSelected{$AttachmentID} ? 1 : 0;

                    # set attachment to standard template relation
                    my $Success = $StdAttachmentObject->StdAttachmentStandardTemplateMemberAdd(
                        AttachmentID       => $AttachmentID,
                        StandardTemplateID => $GetParam{ID},
                        Active             => $Active,
                        UserID             => $Self->{UserID},
                    );
                }

                # if the user would like to continue editing the template, just redirect to the edit screen
                if (
                    defined $ParamObject->GetParam( Param => 'ContinueAfterSave' )
                        && ( $ParamObject->GetParam( Param => 'ContinueAfterSave' ) eq '1' )
                )
                {
                    my $ID = $ParamObject->GetParam( Param => 'ID' ) || '';
                    return $LayoutObject->Redirect(
                        OP => "Action=$Self->{Action};Subaction=Change;ID=$ID;Notification=Update"
                    );
                }
                else {

                    # otherwise return to overview
                    return $LayoutObject->Redirect( OP => "Action=$Self->{Action};Notification=Update" );
                }
            }
        }

        # something has gone wrong
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Priority => 'Error' );
        $Self->_Edit(
            Action              => 'Change',
            Errors              => \%Errors,
            SelectedAttachments => \@NewIDs,
            %GetParam,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminTemplate',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # add
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Add' ) {
        my %GetParam;
        $GetParam{Name} = $ParamObject->GetParam( Param => 'Name' );
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Self->_Edit(
            Action => 'Add',
            %GetParam,
        );
        ### FREICON:
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminTemplateExtended',
            Data         => \%Param,
        );
        ### FREICON
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # add action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'AddAction' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my @NewIDs = $ParamObject->GetArray( Param => 'IDs' );
        my ( %GetParam, %Errors );

        for my $Parameter (qw(ID Name Comment ValidID TemplateType RequiredGroup TicketType Queue Service Owner SLA Subject Priority NextState Responsible ProcessEntityID)) {
            $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter ) || '';
        }

        $GetParam{'Template'} = $ParamObject->GetParam(
            Param => 'Template',
            Raw   => 1
        ) || '';

        # get composed content type
        $GetParam{ContentType} = 'text/plain';
        if ( $LayoutObject->{BrowserRichText} ) {
            $GetParam{ContentType} = 'text/html';
        }

        # check needed data
        for my $Needed (qw(Name ValidID TemplateType)) {
            if ( !$GetParam{$Needed} ) {
                $Errors{ $Needed . 'Invalid' } = 'ServerError';
            }
        }

        # check if a standard template exists with this name
        ### FREICON:
        my $NameExists = $StandardTemplateObjectExtended->NameExistsCheck( Name => $GetParam{Name} );
        if ($NameExists) {
            $Errors{NameExists}    = 1;
            $Errors{'NameInvalid'} = 'ServerError';
        }
        ### FREICON

        # if no errors occurred
        if ( !%Errors ) {

            # add template
            ### FREICON:
            my $StandardTemplateID = $StandardTemplateObjectExtended->StandardTemplateAdd(
                %GetParam,
                UserID => $Self->{UserID},
            );
            ### FREICON
            if ($StandardTemplateID) {

                my %AttachmentsAll = $StdAttachmentObject->StdAttachmentList();

                # create hash with selected queues
                my %AttachmentsSelected = map { $_ => 1 } @NewIDs;

                # check all used attachments
                for my $AttachmentID ( sort keys %AttachmentsAll ) {
                    my $Active = $AttachmentsSelected{$AttachmentID} ? 1 : 0;

                    # set attachment to standard template relation
                    my $Success = $StdAttachmentObject->StdAttachmentStandardTemplateMemberAdd(
                        AttachmentID       => $AttachmentID,
                        StandardTemplateID => $StandardTemplateID,
                        Active             => $Active,
                        UserID             => $Self->{UserID},
                    );
                }

                $Self->_Overview();
                my $Output = $LayoutObject->Header();
                $Output .= $LayoutObject->NavigationBar();
                $Output .= $LayoutObject->Notify(
                    Info => Translatable('Template added!'),
                );
                ### FREICON:
                $Output .= $LayoutObject->Output(
                    TemplateFile => 'AdminTemplateExtended',
                    Data         => \%Param,
                );
                ### FREICON
                $Output .= $LayoutObject->Footer();
                return $Output;
            }
        }

        # something has gone wrong
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Priority => 'Error' );
        $Self->_Edit(
            Action              => 'Add',
            Errors              => \%Errors,
            SelectedAttachments => \@NewIDs,
            %GetParam,
        );
        ### FREICON:
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminTemplateExtended',
            Data         => \%Param,
        );
        ### FREICON
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # delete action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Delete' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my $ID = $ParamObject->GetParam( Param => 'ID' );
        ### FREICON:
        my $Delete = $StandardTemplateObjectExtended->StandardTemplateDelete(
            ID => $ID,
        );
        ### FREICON
        if ( !$Delete ) {
            return $LayoutObject->ErrorScreen();
        }

        return $LayoutObject->Attachment(
            ContentType => 'text/html',
            Content     => $Delete,
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    # ------------------------------------------------------------
    # overview
    # ------------------------------------------------------------
    else {
        $Self->_Overview();
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Info => Translatable('Template updated!') )
            if ( $Notification && $Notification eq 'Update' );
        ### FREICON:
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminTemplateExtended',
            Data         => \%Param,
        );
        ### FREICON
        $Output .= $LayoutObject->Footer();
        return $Output;
    }
}

sub _Edit {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    $LayoutObject->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionOverview' );

    # get valid list
    my %ValidList        = $Kernel::OM->Get('Kernel::System::Valid')->ValidList();
    my %ValidListReverse = reverse %ValidList;

    $Param{ValidOption} = $LayoutObject->BuildSelection(
        Data       => \%ValidList,
        Name       => 'ValidID',
        SelectedID => $Param{ValidID} || $ValidListReverse{valid},
        Class      => 'Modernize Validate_Required ' . ( $Param{Errors}->{'ValidIDInvalid'} || '' ),
    );

    my $TemplateTypeList = $Kernel::OM->Get('Kernel::Config')->Get('StandardTemplate::Types');

    $Param{TemplateTypeString} = $LayoutObject->BuildSelection(
        Data       => $TemplateTypeList,
        Name       => 'TemplateType',
        SelectedID => $Param{TemplateType},
        Class      => 'Modernize Validate_Required ' . ( $Param{Errors}->{'TemplateTypeInvalid'} || '' ),
    );

    my %GroupList = $Kernel::OM->Get('Kernel::System::Group')->GroupList(Valid => 1);
    $Param{RequiredGroupString} = $LayoutObject->BuildSelection(
        Data         => \%GroupList,
        PossibleNone => 1,
        Name         => 'RequiredGroup',
        SelectedID   => $Param{RequiredGroup},
        Class        => 'Modernize',
    );

    ### FREICON: add blocks for additional fields
    # get type list
    my %TypeList = $Kernel::OM->Get('Kernel::System::Type')->TypeList(
        UserID => 1,
    );

    $Param{TicketTypeString} = $LayoutObject->BuildSelection(
        Data       => {'' => '-', %TypeList},
        Name       => 'TicketType',
        SelectedID => $Param{TicketType},
        Class      => 'Modernize  ',
        Translation    => 0,
    );

    unless ( defined $Param{Queue} ) {
        $Param{Queue} = '';
    }

    $Param{QueueString} = $LayoutObject->BuildSelection(
        Data       => {'' => '-', '0' => '()', $Kernel::OM->Get('Kernel::System::Queue')->GetAllQueues(), },
        Name       => 'Queue',
        SelectedID => $Param{Queue},
        Class      => 'Modernize  ',
    );

    $Param{ServiceString} = $LayoutObject->BuildSelection(
        Data       => {'' => '-', $Kernel::OM->Get('Kernel::System::Service')->ServiceList(Valid => 1, KeepChildren => 1, UserID => 1, )},
        Name       => 'Service',
        SelectedID => $Param{Service},
        Class      => 'Modernize  ',
    );

    $Param{SLAString} = $LayoutObject->BuildSelection(
        Data       => {'' => '-', $Kernel::OM->Get('Kernel::System::SLA')->SLAList( UserID => 1, )},
        Name       => 'SLA',
        SelectedID => $Param{SLA},
        Class      => 'Modernize  ',
    );

    $Param{OwnerString} = $LayoutObject->BuildSelection(
        Data       => {'' => '-', $Kernel::OM->Get('Kernel::System::User')->UserList(Type  => 'Long', Valid => 1,)},
        Name       => 'Owner',
        SelectedID => $Param{Owner},
        Class      => 'Modernize  ',
    );

    $Param{ResponsibleString} = $LayoutObject->BuildSelection(
        Data       => {'' => '-', $Kernel::OM->Get('Kernel::System::User')->UserList(Type  => 'Long', Valid => 1,)},
        Name       => 'Responsible',
        SelectedID => $Param{Responsible},
        Class      => 'Modernize  ',
    );

    my $ProcessList = $Kernel::OM->Get('Kernel::System::ProcessManagement::Process')->ProcessList(
        ProcessState => ['Active'],           # Active, FadeAway, Inactive
        Interface    => ['AgentInterface'],   # optional, ['AgentInterface'] or ['CustomerInterface'] or ['AgentInterface', 'CustomerInterface'] or 'all'
        Silent       => 1                     # optional, 1 || 0, default 0, if set to 1 does not log errors if there are no processes configured
    ) || {};

    $Param{ProcessString} = $LayoutObject->BuildSelection(
        Data       => {'' => '-', %{$ProcessList},},
        Name       => 'ProcessEntityID',
        SelectedID => $Param{ProcessEntityID},
        Class      => 'Modernize  ',
    );

    $Param{NextStateString} = $LayoutObject->BuildSelection(
        Data       => {'' => '-', $Kernel::OM->Get('Kernel::System::State')->StateList(UserID => 1, Action => $Self->{Action},),},
        Name       => 'NextState',
        SelectedID => $Param{NextState},
        Class      => 'Modernize  ',
    );

    $Param{PriorityString} = $LayoutObject->BuildSelection(
        Data       => {'' => '-', $Kernel::OM->Get('Kernel::System::Priority')->PriorityList(UserID => 1, Action => $Self->{Action},),},
        Name       => 'Priority',
        SelectedID => $Param{Priority},
        Class      => 'Modernize  ',
    );
    ### FREICON

    my %AttachmentData = $Kernel::OM->Get('Kernel::System::StdAttachment')->StdAttachmentList( Valid => 1 );
    $Param{AttachmentOption} = $LayoutObject->BuildSelection(
        Data         => \%AttachmentData,
        Name         => 'IDs',
        Multiple     => 1,
        Size         => 6,
        Translation  => 0,
        PossibleNone => 1,
        SelectedID   => $Param{SelectedAttachments},
        Class        => 'Modernize',
    );

    my $HTMLUtilsObject = $Kernel::OM->Get('Kernel::System::HTMLUtils');

    if ( $LayoutObject->{BrowserRichText} ) {

        # reformat from plain to html
        if ( $Param{ContentType} && $Param{ContentType} =~ /text\/plain/i ) {
            $Param{Template} = $HTMLUtilsObject->ToHTML(
                String => $Param{Template},
            );
        }
    }
    else {

        # reformat from html to plain
        if ( $Param{ContentType} && $Param{ContentType} =~ /text\/html/i ) {
            $Param{Template} = $HTMLUtilsObject->ToAscii(
                String => $Param{Template},
            );
        }
    }

    $LayoutObject->Block(
        Name => 'OverviewUpdate',
        Data => {
            %Param,
            %{ $Param{Errors} },
        },
    );

    ### FREICON: add Dynamic Fields
    # get whitelisted Dynamic Fields from config
    my $WhiteDF = $Kernel::OM->Get('Kernel::Config')->Get('StandardTemplateExtended::DynamicFields');
    my @Whitelist = @{$WhiteDF};

    # create html strings for all dynamic fields
    my %DynamicFieldHTML;

    # cycle through the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(ResultType => 'HASH')} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        # don't show the dynamic field, if it isn't part of the whitelist array
        next DYNAMICFIELD if ( !grep /^$DynamicFieldConfig->{Name}$/, @Whitelist );

        my $PossibleValuesFilter;

        my $IsACLReducible = $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->HasBehavior(
            DynamicFieldConfig => $DynamicFieldConfig,
            Behavior           => 'IsACLReducible',
        );

        if ($IsACLReducible) {

            # get PossibleValues
            my $PossibleValues = $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->PossibleValuesGet(
                DynamicFieldConfig => $DynamicFieldConfig,
            );

            # check if field has PossibleValues property in its configuration
            if ( IsHashRefWithData($PossibleValues) ) {

                # convert possible values key => value to key => key for ACLs using a Hash slice
                my %AclData = %{$PossibleValues};
                @AclData{ keys %AclData } = keys %AclData;

                # set possible values filter from ACLs
                my $ACL = $Kernel::OM->Get('Kernel::System::Ticket')->TicketAcl(
                    CustomerUserID => '', #$CustomerUser || '',
                    Action         => $Self->{Action},
                    ReturnType     => 'Ticket',
                    ReturnSubType  => 'DynamicField_' . $DynamicFieldConfig->{Name},
                    Data           => \%AclData,
                    UserID         => $Self->{UserID},
                );
                if ($ACL) {
                    my %Filter = $Kernel::OM->Get('Kernel::System::Ticket')->TicketAclData();

                    # convert Filer key => key back to key => value using map
                    %{$PossibleValuesFilter}
                        = map { $_ => $PossibleValues->{$_} }
                        keys %Filter;
                }
            }
        }
        if ( $DynamicFieldConfig->{FieldType} eq 'Dropdown' ||  $DynamicFieldConfig->{FieldType} eq 'Multiselect' || exists $DynamicFieldConfig->{Config}{PossibleValues}) {
            $DynamicFieldConfig->{Config}{PossibleValues}{''} = '-';
        }
        my $ValidationResult;
        # get field html
        $DynamicFieldHTML{ $DynamicFieldConfig->{Name} }
            = $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->EditFieldRender(
            DynamicFieldConfig   => $DynamicFieldConfig,
            PossibleValuesFilter => $PossibleValuesFilter,
            ServerError          => $ValidationResult->{ServerError} || '',
            ErrorMessage         => $ValidationResult->{ErrorMessage} || '',
            LayoutObject         => $Kernel::OM->Get('Kernel::Output::HTML::Layout'),
            ParamObject          => $Kernel::OM->Get('Kernel::System::Web::Request'),
            AJAXUpdate           => 1,
            Value                => $Param{'DynamicField_'.$DynamicFieldConfig->{Name}} || '',
            UpdatableFields      => $Self->_GetFieldsToUpdate(),
            #Mandatory => $Self->{Config}->{DynamicField}->{ $DynamicFieldConfig->{Name} } == 2, #TODO
        );
    }

    $Param{DynamicFieldHTML} = \%DynamicFieldHTML;
    $Param{DynamicFieldHTML} = \%DynamicFieldHTML;

    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(ResultType => 'HASH')} ) {

        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);
        # skip fields that HTML could not be retrieved
        next DYNAMICFIELD if !IsHashRefWithData(
            $Param{DynamicFieldHTML}->{ $DynamicFieldConfig->{Name} }
        );

        # get the html strings form $Param
        my $DynamicFieldHTML = $Param{DynamicFieldHTML}->{ $DynamicFieldConfig->{Name} };

        $Kernel::OM->Get('Kernel::Output::HTML::Layout')->Block(
            Name => 'DynamicField',
            Data => {
                Name  => $DynamicFieldConfig->{Name},
                Label => $DynamicFieldHTML->{Label},
                Field => $DynamicFieldHTML->{Field},
            },
        );
    }
    ### FREICON

    # show appropriate messages for ServerError
    if ( defined $Param{Errors}->{NameExists} && $Param{Errors}->{NameExists} == 1 ) {
        $LayoutObject->Block( Name => 'ExistNameServerError' );
    }
    else {
        $LayoutObject->Block( Name => 'NameServerError' );
    }

    # add rich text editor
    if ( $LayoutObject->{BrowserRichText} ) {

        # set up rich text editor
        $LayoutObject->SetRichTextParameters(
            Data => \%Param,
        );
    }
    return 1;
}

sub _Overview {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    $LayoutObject->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionAdd' );
    $LayoutObject->Block( Name => 'Filter' );

    $LayoutObject->Block(
        Name => 'OverviewResult',
        Data => \%Param,
    );

    ### FREICON:
    my $StandardTemplateObjectExtended = $Kernel::OM->Get('Kernel::System::StandardTemplate');
    my %List                   = $StandardTemplateObjectExtended->StandardTemplateList(
        UserID => 1,
        Valid  => 0,
    );
    ### FREICON

    # if there are any results, they are shown
    if (%List) {

        my %ListGet;
        for my $ID ( sort keys %List ) {
            ### FREICON:
            %{ $ListGet{$ID} } = $StandardTemplateObjectExtended->StandardTemplateGet(
                ID => $ID,
            );
            ### FREICON
            $ListGet{$ID}->{SortName} = $ListGet{$ID}->{TemplateType} . $ListGet{$ID}->{Name};
        }

        # get valid list
        my %ValidList = $Kernel::OM->Get('Kernel::System::Valid')->ValidList();
        for my $ID ( sort { $ListGet{$a}->{SortName} cmp $ListGet{$b}->{SortName} } keys %ListGet )
        {

            my %Data = %{ $ListGet{$ID} };
            my @SelectedAttachment;
            my %SelectedAttachmentData
                = $Kernel::OM->Get('Kernel::System::StdAttachment')->StdAttachmentStandardTemplateMemberList(
                StandardTemplateID => $ID,
            );
            for my $Key ( sort keys %SelectedAttachmentData ) {
                push @SelectedAttachment, $Key;
            }
            $LayoutObject->Block(
                Name => 'OverviewResultRow',
                Data => {
                    Valid => $ValidList{ $Data{ValidID} },
                    %Data,
                    Attachments => scalar @SelectedAttachment,
                },
            );
        }
    }

    # otherwise it displays a no data found message
    else {
        $LayoutObject->Block(
            Name => 'NoDataFoundMsg',
            Data => {},
        );
    }

    return 1;
}
### FREICON:
sub _GetFieldsToUpdate {
    my @Result = [];
    return \@Result;
}
### FREICON

1;
