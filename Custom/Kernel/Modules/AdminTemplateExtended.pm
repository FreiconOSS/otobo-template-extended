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

        if ( $Data{RequiredGroup} ) {
            my @Array = split(',', $Data{RequiredGroup});
            $Data{RequiredGroup} = \@Array;
        }
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
        my @RequiredGroups = $ParamObject->GetArray( Param => 'RequiredGroup' );

        #for my $Parameter (qw(ID Name Comment ValidID TemplateType)) {
        for my $Parameter (qw(ID Name Comment ValidID TemplateType TicketType Queue Service Owner SLA Subject Priority NextState Responsible ProcessEntityID)) {
            $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter ) // '';
        }

        if ( @RequiredGroups ) {
            $GetParam{RequiredGroup} = join( ',', @RequiredGroups );
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
        for my $Needed (qw(Name ValidID TemplateType RequiredGroup )) {
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

    elsif ( $Self->{Subaction} eq 'AJAXUpdate' ) {
        my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
        my $FieldRestrictionsObject   = $Kernel::OM->Get('Kernel::System::Ticket::FieldRestrictions');
        my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
        my $TicketObject          = $Kernel::OM->Get('Kernel::System::Ticket');
        my $Config = $Kernel::OM->Get('Kernel::Config')->Get("Ticket::Frontend::$Self->{Action}");
        my $UploadCacheObject = $Kernel::OM->Get('Kernel::System::Web::UploadCache');


        my $ConfiguredDFs = $Kernel::OM->Get('Kernel::Config')->Get('StandardTemplateExtended::DynamicFields');

        my %FieldFilter;
        for my $Field ( @{$ConfiguredDFs} ) {
            $FieldFilter{$Field} = 1;
        }

        # get the dynamic fields for this screen
        $Self->{DynamicField} = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
            Valid       => 1,
            ObjectType => 'Ticket',
            FieldFilter => \%FieldFilter || {},
        );

        my %GetParam;
        my %DynamicFieldValues;

        my $Dest           = $ParamObject->GetParam( Param => 'Dest' ) || '';
        my $CustomerUser   = $ParamObject->GetParam( Param => 'SelectedCustomerUser' );
        my $ElementChanged = $ParamObject->GetParam( Param => 'ElementChanged' ) || '';
        my $QueueID        = '';
        if ( $Dest =~ /^(\d{1,100})\|\|.+?$/ ) {
            $QueueID = $1;
        }
        $GetParam{Dest}    = $Dest;
        $GetParam{QueueID} = $QueueID;

        # get list type
        my $TreeView = 0;
        if ( $ConfigObject->Get('Ticket::Frontend::ListType') eq 'tree' ) {
            $TreeView = 1;
        }

        my $Autoselect = $ConfigObject->Get('TicketACL::Autoselect') || undef;
        my $ACLPreselection;
        if ( $ConfigObject->Get('TicketACL::ACLPreselection') ) {

            # get cached preselection rules
            my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');
            $ACLPreselection = $CacheObject->Get(
                Type => 'TicketACL',
                Key  => 'Preselection',
            );
            if ( !$ACLPreselection ) {
                $ACLPreselection = $FieldRestrictionsObject->SetACLPreselectionCache();
            }
        }

        my %Convergence = (
            StdFields => 0,
            Fields    => 0,
        );
        my %ChangedElements        = $ElementChanged                                        ? ( $ElementChanged => 1 ) : ();
        my %ChangedElementsDFStart = $ElementChanged                                        ? ( $ElementChanged => 1 ) : ();
        my %ChangedStdFields       = $ElementChanged && $ElementChanged !~ /^DynamicField_/ ? ( $ElementChanged => 1 ) : ();

        my $LoopProtection = 100;
        my %StdFieldValues;
        my %DynFieldStates = (
            Visibility => {},
            Fields     => {},
        );

        ### FREICON: process extended template data
        my %TemplateData;
        my @TemplateAJAX;
        my @TemplateAJAXExtendend;
        my %CheckTemplate;
        if ( $ElementChanged eq 'StandardTemplateID' ) {

            ### FREICON

            if ( IsPositiveInteger( $GetParam{StandardTemplateID} ) ) {

                %TemplateData = $Self->_StandardTemplateExtendedGet( ID => $GetParam{StandardTemplateID} );
                if ( %TemplateData ) {

                    if ( IsHashRefWithData($Config->{TemplateFieldsBehavior}) ) {
                        for my $Field (keys %{$Config->{TemplateFieldsBehavior}} ) {

                            ### FREICON: previous standard template id for comparing subject
                            if ( $Field eq 'Subject' ) {
                                if ( $GetParam{$Field} eq '' ) {
                                    $GetParam{$Field} = $TemplateData{$Field};
                                    my $Hash = { Name =>$Field,  Data  => $TemplateData{$Field}};
                                    push(@TemplateAJAXExtendend, $Hash);
                                } else {
                                    ### if no pre template feature
                                    $GetParam{$Field} = $TemplateData{$Field};
                                    my $Hash = { Name =>$Field,  Data  => $TemplateData{$Field}};
                                    push(@TemplateAJAXExtendend, $Hash);
                                }
                                next;
                            }
                            ### FREICON

                            my $Modus = $Config->{TemplateFieldsBehavior}->{$Field} || '0';
                            if ( defined $TemplateData{$Field} ) {
                                $GetParam{$Field} = $TemplateData{$Field};
                                $CheckTemplate{$Field} = $Field;
                            } elsif ( $Modus eq '1' ) {
                                $TemplateData{$Field} = '';
                            } elsif ( $Modus eq '2' ) {
                                $TemplateData{$Field} = '';
                            } else {
                            }
                            next unless ( defined $TemplateData{$Field} );
                            $GetParam{$Field} = $TemplateData{$Field};
                            if ( $Field =~ m/^DynamicField_(.*)$/ ) {
                                my $Name = $1;
                                $GetParam{'DynamicField'}->{$Field} = $TemplateData{$Field};
                                my $Hash = { Name =>$Field,  Data  => $TemplateData{$Field}};
                                push(@TemplateAJAXExtendend, $Hash);
                            } elsif ( $Field eq 'Dest' ) {
                                $QueueID = $TemplateData{'QueueID'};
                                $Dest = $TemplateData{'Dest'};
                                $GetParam{Dest}    = $Dest;
                                $GetParam{QueueID} = $QueueID;
                            }

                            if ( $Field eq 'Dest' ) {
                                $CheckTemplate{$Field} = 'QueueID';
                            }
                        }
                    }
                }

            } elsif ( $Config->{TemplateResetOnDeselect} && IsHashRefWithData($Config->{TemplateFieldsBehavior}) ) {
                for my $Field (keys %{$Config->{TemplateFieldsBehavior}} ) {

                    ### FREICON: previous standard template id for comparing subject
                    if ( $Field eq 'Subject' ) {
                        if ( $GetParam{$Field} eq '' ) {
                            $GetParam{$Field} = '';
                            $CheckTemplate{$Field} = $Field;
                            my $Hash = { Name =>$Field,  Data  => $TemplateData{$Field}};
                            push(@TemplateAJAXExtendend, $Hash);
                        } else {
                            ### if no pre template feature
                            $GetParam{$Field} = '';
                            $CheckTemplate{$Field} = $Field;
                            my $Hash = { Name =>$Field,  Data  => '' };
                            push(@TemplateAJAXExtendend, $Hash);
                        }
                        next;
                    }
                    ### FREICON

                    if ( $Field eq 'NextStateID' ) {
                        $GetParam{$Field} = '';
                        $CheckTemplate{$Field} = $Field;
                        my $StateObject = $Kernel::OM->Get('Kernel::System::State');
                        if ( $Config->{StateDefault} ) {
                            my %State = $StateObject->StateGet(
                                Name  => $Config->{StateDefault},
                            );
                            if ( %State ) {
                                my $Hash = { Name =>$Field,  Data  => { $State{ID} => $State{Name} } };
                                push(@TemplateAJAXExtendend, $Hash);
                            }
                        }
                        next;
                    }

                    if ( $Field eq 'PriorityID' ) {
                        $GetParam{$Field} = '';
                        $CheckTemplate{$Field} = $Field;
                        my $PriorityObject = $Kernel::OM->Get('Kernel::System::Priority');
                        if ( $Config->{Priority} ) {
                            my $PriorityID = $PriorityObject->PriorityLookup(
                                Priority => $Config->{Priority},
                            );
                            if ( $PriorityID ) {
                                my $Hash = { Name =>$Field,  Data  => { $PriorityID => $Config->{Priority} } };
                                push(@TemplateAJAXExtendend, $Hash);
                            }
                        }
                        next;
                    }

                    if ( $Field eq 'TypeID' ) {
                        $GetParam{$Field} = '';
                        $CheckTemplate{$Field} = $Field;
                        my $DefaultTicketType = $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Type::Default');
                        if ( $DefaultTicketType ) {
                            my %Type = $Kernel::OM->Get('Kernel::System::Type')->TypeGet(
                                Name => $DefaultTicketType,
                            );
                            if ( %Type ) {
                                my $Hash = { Name =>$Field,  Data  => { $Type{ID} => $DefaultTicketType } };
                                push(@TemplateAJAXExtendend, $Hash);
                            }
                        }
                        next;
                    }

                    #my $Modus = $Config->{TemplateFieldsBehavior}->{$Field} || '0';
                    $GetParam{$Field} = '';
                    #$CheckTemplate{$Field} = $Field;
                    if ( $Field =~ m/^DynamicField_(.*)$/ ) {
                        my $Name = $1;

                        my $DynamicField = $DynamicFieldObject->DynamicFieldGet(
                            Name => $Name,
                        );

                        if ( $DynamicField ) {
                            my $EmptyValue = "";
                            if ( $DynamicField->{"FieldType"} eq 'Text' || $DynamicField->{"FieldType"} eq 'TextArea' ) {
                                $EmptyValue = "";
                            } elsif ( $DynamicField->{"FieldType"} eq 'Checkbox' ) {
                                $EmptyValue = 2;
                            }
                            $GetParam{'DynamicField'}->{$Field} = "";
                            $DynamicFieldValues{$Name} = "";
                            my $Hash = { Name => $Field,  Data  => $EmptyValue };
                            push(@TemplateAJAXExtendend, $Hash);
                            $CheckTemplate{$Field} = "";
                        }
                    }
                    if ( $Field eq 'Dest' ) {
                        $CheckTemplate{$Field} = 'QueueID';
                    }
                }
            }
        }
        ### FREICON

        until ( $Convergence{Fields} ) {

            # determine standard field input
            until ( $Convergence{StdFields} ) {

                my %NewChangedElements;

                # which standard fields to check - FieldID => GetParamValue (neccessary for Dest)
                my %Check = (
                    Dest               => 'QueueID',
                    NewUserID          => 'NewUserID',
                    NewResponsibleID   => 'NewResponsibleID',
                    NextStateID        => 'NextStateID',
                    PriorityID         => 'PriorityID',
                    ServiceID          => 'ServiceID',
                    SLAID              => 'SLAID',
                    StandardTemplateID => 'StandardTemplateID',
                    TypeID             => 'TypeID',
                );

                if ($ACLPreselection) {
                    FIELD:
                    for my $FieldID ( sort keys %Check ) {
                        if ( !$ACLPreselection->{Fields}{$FieldID} ) {
                            $Kernel::OM->Get('Kernel::System::Log')->Log(
                                Priority => 'debug',
                                Message  => "$FieldID not defined in TicketACL preselection rules!"
                            );
                            next FIELD;
                        }
                        if ( $Autoselect && $Autoselect->{$FieldID} && $ChangedElements{$FieldID} ) {
                            next FIELD;
                        }
                        for my $Element ( sort keys %ChangedElements ) {
                            if (
                                $ACLPreselection->{Rules}{Ticket}{$Element}{$FieldID}
                                    || $Self->{InternalDependancy}{$Element}{$FieldID}
                            )
                            {
                                next FIELD;
                            }
                            if ( !$ACLPreselection->{Fields}{$Element} ) {
                                $Kernel::OM->Get('Kernel::System::Log')->Log(
                                    Priority => 'debug',
                                    Message  => "$Element not defined in TicketACL preselection rules!"
                                );
                                next FIELD;
                            }
                        }

                        # delete unaffected fields
                        delete $Check{$FieldID};
                    }
                }

                ### FREICON
                %Check = (%Check, %CheckTemplate);
                ### FREICON

                # for each standard field which has to be checked, run the defined method
                METHOD:
                for my $Field ( @{ $Self->{FieldMethods} } ) {
                    next METHOD if !$Check{ $Field->{FieldID} };

                    # use $Check{ $Field->{FieldID} } for Dest=>QueueID
                    $StdFieldValues{ $Check{ $Field->{FieldID} } } = $Field->{Method}->(
                        $Self,
                        %GetParam,
                        OwnerID        => $GetParam{NewUserID},
                        CustomerUserID => $CustomerUser || '',
                        QueueID        => $GetParam{QueueID},
                        Services       => $StdFieldValues{ServiceID} || undef,    # needed for SLAID
                    );

                    # special stuff for QueueID/Dest: Dest is "QueueID||QueueName" => "QueueName";
                    if ( $Field->{FieldID} eq 'Dest' ) {
                        TOs:
                        for my $QueueID ( sort keys %{ $StdFieldValues{QueueID} } ) {
                            next TOs if ( $StdFieldValues{QueueID}{$QueueID} eq '-' );
                            $StdFieldValues{Dest}{"$QueueID||$StdFieldValues{QueueID}{ $QueueID }"} = $StdFieldValues{QueueID}{$QueueID};
                        }

                        # check current selection of QueueID (Dest will be done together with the other fields)
                        if ( $GetParam{QueueID} && !$StdFieldValues{Dest}{ $GetParam{Dest} } ) {
                            $GetParam{QueueID} = '';
                        }

                        # autoselect
                        elsif ( !$GetParam{QueueID} && $Autoselect && $Autoselect->{Dest} ) {
                            $GetParam{QueueID} = $FieldRestrictionsObject->Autoselect(
                                PossibleValues => $StdFieldValues{QueueID},
                            ) || '';
                        }
                    }

                    # check whether current selected value is still valid for the field
                    if (
                        $GetParam{ $Field->{FieldID} }
                            && !$StdFieldValues{ $Field->{FieldID} }{ $GetParam{ $Field->{FieldID} } }
                    )
                    {
                        # if not empty the field
                        $GetParam{ $Field->{FieldID} }           = '';
                        $NewChangedElements{ $Field->{FieldID} } = 1;
                        $ChangedStdFields{ $Field->{FieldID} }   = 1;
                    }

                    # autoselect
                    elsif ( !$GetParam{ $Field->{FieldID} } && $Autoselect && $Autoselect->{ $Field->{FieldID} } ) {
                        $GetParam{ $Field->{FieldID} } = $FieldRestrictionsObject->Autoselect(
                            PossibleValues => $StdFieldValues{ $Field->{FieldID} },
                        ) || '';
                        if ( $GetParam{ $Field->{FieldID} } ) {
                            $NewChangedElements{ $Field->{FieldID} } = 1;
                            $ChangedStdFields{ $Field->{FieldID} }   = 1;
                        }
                    }
                }

                if ( !%NewChangedElements ) {
                    $Convergence{StdFields} = 1;
                }
                else {
                    %ChangedElements = %NewChangedElements;
                }

                %ChangedElementsDFStart = (
                    %ChangedElementsDFStart,
                    %NewChangedElements,
                );

                if ( $LoopProtection-- < 1 ) {
                    $Kernel::OM->Get('Kernel::System::Log')->Log(
                        Priority => 'error',
                        Message  => "Ran into unresolvable loop!",
                    );
                    return;
                }

            }

            %ChangedElements        = %ChangedElementsDFStart;
            %ChangedElementsDFStart = ();

            # check dynamic fields
            my %CurFieldStates;
            if (%ChangedElements) {

                # get values and visibility of dynamic fields
                %CurFieldStates = $FieldRestrictionsObject->GetFieldStates(
                    TicketObject              => $TicketObject,
                    DynamicFields             => $Self->{DynamicField},
                    DynamicFieldBackendObject => $DynamicFieldBackendObject,
                    ChangedElements           => \%ChangedElements,            # optional to reduce ACL evaluation
                    Action                    => $Self->{Action},
                    UserID                    => $Self->{UserID},
                    TicketID                  => $Self->{TicketID},
                    FormID                    => $Self->{FormID},
                    CustomerUser              => $CustomerUser || '',
                    GetParam                  => {
                        %GetParam,
                        OwnerID => $GetParam{NewUserID},
                    },
                    Autoselect      => $Autoselect,
                    ACLPreselection => {},
                    LoopProtection  => \$LoopProtection,
                );

                    # combine FieldStates
                $DynFieldStates{Fields} = {
                    %{ $DynFieldStates{Fields} },
                    %{ $CurFieldStates{Fields} },
                };
                $DynFieldStates{Visibility} = {
                    %{ $DynFieldStates{Visibility} },
                    %{ $CurFieldStates{Visibility} },
                };

                if ( IsHashRefWithData( $CurFieldStates{NewValues} )) {
                    # store new values
                    $GetParam{DynamicField} = {
                        %{$GetParam{DynamicField}},
                        %{$CurFieldStates{NewValues}},
                    };
                }
            }

            # if dynamic fields changed, check standard fields again
            if ( %CurFieldStates && IsHashRefWithData( $CurFieldStates{NewValues} ) ) {
                $Convergence{StdFields} = 0;
                %ChangedElements = map { $_ => 1 } keys %{ $CurFieldStates{NewValues} };
            }
            else {
                $Convergence{Fields} = 1;
            }
        }

        # update Dynamic Fields Possible Values via AJAX
        my @DynamicFieldAJAX;

        # cycle through the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $Index ( sort keys %{ $DynFieldStates{Fields} } ) {
            my $DynamicFieldConfig = $Self->{DynamicField}->[$Index];

            my $DataValues = $DynFieldStates{Fields}{$Index}{NotACLReducible}
                ? $GetParam{DynamicField}{"DynamicField_$DynamicFieldConfig->{Name}"}
                :
                (
                    $DynamicFieldBackendObject->BuildSelectionDataGet(
                        DynamicFieldConfig => $DynamicFieldConfig,
                        PossibleValues     => $DynFieldStates{Fields}{$Index}{PossibleValues},
                        Value              => $GetParam{DynamicField}{"DynamicField_$DynamicFieldConfig->{Name}"},
                    )
                        || $DynFieldStates{Fields}{$Index}{PossibleValues}
                );

            # add dynamic field to the list of fields to update
            push @DynamicFieldAJAX, {
                Name        => 'DynamicField_' . $DynamicFieldConfig->{Name},
                Data        => $DataValues,
                SelectedID  => $GetParam{DynamicField}{"DynamicField_$DynamicFieldConfig->{Name}"},
                Translation => $DynamicFieldConfig->{Config}->{TranslatableValues} || 0,
                Max         => 100,
            };
        }

        # define dynamic field visibility
        my %FieldVisibility;
        if ( IsHashRefWithData( $DynFieldStates{Visibility} ) ) {
            push @DynamicFieldAJAX, {
                Name => 'Restrictions_Visibility',
                Data => $DynFieldStates{Visibility},
            };
        }

        # build AJAX return for the standard fields
        my @StdFieldAJAX;
        my %Attributes = (
            Dest => {
                Translation  => 0,
                PossibleNone => 1,
                TreeView     => $TreeView,
                Max          => 100,
            },
            NewUserID => {
                Translation  => 0,
                PossibleNone => 1,
                Max          => 100,
            },
            NewResponsibleID => {
                Translation  => 0,
                PossibleNone => 1,
                Max          => 100,
            },
            NextStateID => {
                Translation => 1,
                Max         => 100,
            },
            PriorityID => {
                Translation => 1,
                Max         => 100,
            },
            ServiceID => {
                PossibleNone => 1,
                Translation  => 0,
                TreeView     => $TreeView,
                Max          => 100,
            },
            SLAID => {
                PossibleNone => 1,
                Translation  => 0,
                Max          => 100,
            },
            StandardTemplateID => {
                PossibleNone => 1,
                Translation  => 1,
                Max          => 100,
            },
            TypeID => {
                PossibleNone => 1,
                Translation  => 0,
                Max          => 100,
            }
        );
        delete $StdFieldValues{QueueID};
        for my $Field ( sort keys %StdFieldValues ) {
            push @StdFieldAJAX, {
                Name       => $Field,
                Data       => $StdFieldValues{$Field},
                SelectedID => $GetParam{$Field},
                %{ $Attributes{$Field} },
            };
        }

        # update ticket body and attachements if needed.
        if ( $ChangedStdFields{StandardTemplateID} ) {
            my @TicketAttachments;
            my $TemplateText;

            # remove all attachments from the Upload cache
            my $RemoveSuccess = $UploadCacheObject->FormIDRemove(
                FormID => $Self->{FormID},
            );
            if ( !$RemoveSuccess ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Form attachments could not be deleted!",
                );
            }

            # get the template text and set new attachments if a template is selected
            if ( IsPositiveInteger( $GetParam{StandardTemplateID} ) ) {
                my $TemplateGenerator = $Kernel::OM->Get('Kernel::System::TemplateGenerator');

                # set template text, replace smart tags (limited as ticket is not created)
                $TemplateText = $TemplateGenerator->Template(
                    TemplateID     => $GetParam{StandardTemplateID},
                    UserID         => $Self->{UserID},
                    CustomerUserID => $CustomerUser,
                );

                # create StdAttachmentObject
                my $StdAttachmentObject = $Kernel::OM->Get('Kernel::System::StdAttachment');

                # add std. attachments to ticket
                my %AllStdAttachments = $StdAttachmentObject->StdAttachmentStandardTemplateMemberList(
                    StandardTemplateID => $GetParam{StandardTemplateID},
                );
                for ( sort keys %AllStdAttachments ) {
                    my %AttachmentsData = $StdAttachmentObject->StdAttachmentGet( ID => $_ );
                    $UploadCacheObject->FormIDAddFile(
                        FormID      => $Self->{FormID},
                        Disposition => 'attachment',
                        %AttachmentsData,
                    );
                }

                # send a list of attachments in the upload cache back to the clientside JavaScript
                # which renders then the list of currently uploaded attachments
                @TicketAttachments = $UploadCacheObject->FormIDGetAllFilesMeta(
                    FormID => $Self->{FormID},
                );

                for my $Attachment (@TicketAttachments) {
                    $Attachment->{Filesize} = $LayoutObject->HumanReadableDataSize(
                        Size => $Attachment->{Filesize},
                    );
                }
            }

            @TemplateAJAX = (
                {
                    Name => 'UseTemplateCreate',
                    Data => '0',
                },
                {
                    Name => 'RichText',
                    Data => $TemplateText || '',
                },
                {
                    Name     => 'TicketAttachments',
                    Data     => \@TicketAttachments,
                    KeepData => 1,
                },
            );
        }

        ### Freicon: merge templateajax and templateajaxextended to change dynamic fields by template
        push(@TemplateAJAX, @TemplateAJAXExtendend);
        ### FREICON

        my $JSON = $LayoutObject->BuildSelectionJSON(
            [
                @StdFieldAJAX,
                @DynamicFieldAJAX,
                @TemplateAJAX,
            ],
        );
        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );
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

        my @RequiredGroups = $ParamObject->GetArray( Param => 'RequiredGroup' );
        if ( @RequiredGroups ) {
            $GetParam{RequiredGroup} = join( ',', @RequiredGroups );
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
        for my $Needed (qw(Name ValidID TemplateType RequiredGroup)) {
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
        Multiple     => 1,
        Name         => 'RequiredGroup',
        SelectedID   => $Param{RequiredGroup},
        Class        => 'Modernize Validate_Required ',
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
                Service            => $Param{Service}
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
