# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2021 Rother OSS GmbH, https://otobo.de/
# --
# $origin: otobo - 866ca7d0103f52a61cedf7c5b10cac6b9cb56991 - Kernel/Modules/AdminService.pm
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

package Kernel::Modules::EnhancedTemplates;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;
use Kernel::System::VariableCheck qw(:all);
use Data::Dumper;

sub new {
    my ($Type, %Param) = @_;

    # allocate new hash for object
    my $Self = { %Param };
    bless($Self, $Type);

    return $Self;
}

sub Run {
    my ($Self, %Param) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $UploadCacheObject = $Kernel::OM->Get('Kernel::System::Web::UploadCache');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $StandardTemplateObject = $Kernel::OM->Get('Kernel::System::StandardTemplateExtended');
    my $TemplateGenerator = $Kernel::OM->Get('Kernel::System::TemplateGenerator');

    if ($Self->{Subaction} eq 'AJAXUpdate') {

        my $EnhancedTemplateID = $ParamObject->GetParam(Param => 'EnhancedTemplateID') || '';
        my $CustomerUser = $ParamObject->GetParam(Param => 'SelectedCustomerUser') || "";
        my $FormID = $ParamObject->GetParam(Param => 'FormID') || "";
        my $OrigAction = $ParamObject->GetParam(Param => 'OrigAction') || "";
        my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
        
        if (!defined($EnhancedTemplateID) || $EnhancedTemplateID eq '') {
            return ReturnEmptyResponse();
        }

        my %StandardTemplate = $StandardTemplateObject->StandardTemplateGet(
            ID => $EnhancedTemplateID,
        );

        my @TemplateAJAX;
        my $FieldRestrictionsObject = $Kernel::OM->Get('Kernel::System::Ticket::FieldRestrictions');
        my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
        my $Config = $Kernel::OM->Get('Kernel::Config')->Get("Ticket::Frontend::$OrigAction");
        my %GetParam;
        my $LoopProtection = 100;

        # get the dynamic fields for this screen
        $Self->{DynamicField} = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
            Valid       => 1,
            ObjectType  => [ 'Ticket' ],
            FieldFilter => $Config->{DynamicField} || {},
        );

        # update ticket body and attachements if needed.
        my @TicketAttachments;
        my $TemplateText;

        # remove all attachments from the Upload cache
        my $RemoveSuccess = $UploadCacheObject->FormIDRemove(
            FormID => $FormID,
        );

        if (!$RemoveSuccess) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Form attachments could not be deleted!",
            );
        }

        # get the template text and set new attachments if a template is selected
        if (IsPositiveInteger($EnhancedTemplateID)) {
            my $TemplateGenerator = $Kernel::OM->Get('Kernel::System::TemplateGenerator');

            # set template text, replace smart tags (limited as ticket is not created)
            $TemplateText = $TemplateGenerator->Template(
                TemplateID     => $EnhancedTemplateID,
                UserID         => $Self->{UserID},
                CustomerUserID => $CustomerUser,
            );

            # Replace tags for subject
            my %Ticket;
            $Ticket{CustomerUserID} = $CustomerUser;
            my $Language //= $Kernel::OM->Get('Kernel::Config')->Get('DefaultLanguage') || 'en';
            $StandardTemplate{Subject} = $TemplateGenerator->_Replace(
                RichText   => 0,
                Text       => $StandardTemplate{Subject} || '',
                TicketData => \%Ticket,
                Data       => $Param{Data} || {},
                UserID     => $Self->{UserID},
                Language   => $Language,
                Template   => $StandardTemplate{TemplateType},
            );

            # create StdAttachmentObject
            my $StdAttachmentObject = $Kernel::OM->Get('Kernel::System::StdAttachment');

            # add std. attachments to ticket
            my %AllStdAttachments = $StdAttachmentObject->StdAttachmentStandardTemplateMemberList(
                StandardTemplateID => $EnhancedTemplateID,
            );
            for (sort keys %AllStdAttachments) {
                my %AttachmentsData = $StdAttachmentObject->StdAttachmentGet(ID => $_);
                $UploadCacheObject->FormIDAddFile(
                    FormID      => $FormID,
                    Disposition => 'attachment',
                    %AttachmentsData,
                );
            }

            # send a list of attachments in the upload cache back to the clientside JavaScript
            # which renders then the list of currently uploaded attachments
            @TicketAttachments = $UploadCacheObject->FormIDGetAllFilesMeta(
                FormID => $FormID,
            );

            for my $Attachment (@TicketAttachments) {
                $Attachment->{Filesize} = $LayoutObject->HumanReadableDataSize(
                    Size => $Attachment->{Filesize},
                );
            }
        }

        # get list type
        my $TreeView = 0;

        # my $TreeConfig = $ConfigObject->Get('Ticket::Frontend::ListType');

        if ($ConfigObject->Get('Ticket::Frontend::ListType') eq 'tree') {
            $TreeView = 1;
        }

        my %Attributes = (
            Dest      => {
                Translation  => 0,
                PossibleNone => 1,
                TreeView     => $TreeView,
                Max          => 100, },
            ServiceID => {
                PossibleNone => 1,
                Translation  => 0,
                TreeView     => $TreeView,
                Max          => 100, },
            TypeID    => {
                PossibleNone => 1,
                Translation  => 0,
                Max          => 100, }
        );

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
                Name => "Subject",
                Data => $StandardTemplate{Subject},
            },
            {
                Name     => 'TicketAttachments',
                Data     => \@TicketAttachments,
                KeepData => 1,
            },
        );

        if ($StandardTemplate{Service}) {
            my $Services = $Self->_GetServices(
                CustomerUserID => '',
                QueueID        => $StandardTemplate{Queue},
            );

            push @TemplateAJAX, {
                'Data'       => $Services,
                'SelectedID' => $StandardTemplate{Service},
                'Name'       => 'ServiceID',
                'Translation'  => 0,
                'PossibleNone' => 1,
                'TreeView'     => 1,
                'Max'          => 100,
            };

            if ($StandardTemplate{SLA}) {
                my $SLAs = $Self->_GetSLAs(
                    Services  => $Services,
                    ServiceID => $StandardTemplate{Service}
                );

                push @TemplateAJAX, {
                    'Data'       => $SLAs,
                    'SelectedID' => $StandardTemplate{SLA},
                    'Name'       => 'SLAID',
                    'Translation'  => 0,
                    'PossibleNone' => 1,
                    'TreeView'     => 0,
                    'Max'          => 100,
                }
            }
        }

        if ($StandardTemplate{TicketType}) {
            my $TicketTypes = $Self->_GetTypes(
                CustomerUserID => '',
                QueueID        => $StandardTemplate{Queue},
            );

            push @TemplateAJAX, {
                'Data'         => $TicketTypes,
                'SelectedID'   => $StandardTemplate{TicketType},
                'Name'         => 'TypeID',
                'TreeView'     => 1,
                'PossibleNone' => 1
            };
        }

        if ($StandardTemplate{Queue}) {
            my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');
            #my %Queues = $QueueObject->QueueList( Valid => 1 );
            my $Queues = $Self->_GetTos();
            my %QueueHash = %{$Queues};
            my %NewQueueHash;
            for my $QueueItem (keys %QueueHash) {
                $NewQueueHash{"$QueueItem||$QueueHash{$QueueItem}"} = $QueueHash{$QueueItem};
            }

            push @TemplateAJAX, {
                'Data'       => \%NewQueueHash,
                'SelectedID' => "$StandardTemplate{Queue}||$QueueHash{$StandardTemplate{Queue}}",
                'Name'       => 'Dest',
                'Translation'  => 0,
                'PossibleNone' => 1,
                'TreeView'     => 1,
                'Max'          => 100,
            };
            push @TemplateAJAX, {
                'Data'       => \%NewQueueHash,
                'SelectedID' => "$StandardTemplate{Queue}||$QueueHash{$StandardTemplate{Queue}}",
                'Name'       => 'QueueID',
                'Translation'  => 0,
                'PossibleNone' => 1,
                'TreeView'     => 1,
                'Max'          => 100,
            };
        }

        if ($StandardTemplate{Owner}) {
            my $NewUsers = $Self->_GetUsers(
                QueueID  => $StandardTemplate{Queue},
                OwnerAll => 1
            );

            push @TemplateAJAX, {
                'Data'       => $NewUsers,
                'SelectedID' => $StandardTemplate{Owner},
                'Name'       => 'NewUserID',
            };
        }

        if ($StandardTemplate{Responsible}) {
            my $NewUsers = $Self->_GetUsers(
                QueueID  => $StandardTemplate{Queue},
                OwnerAll => 1
            );

            push @TemplateAJAX, {
                'Data'       => $NewUsers,
                'SelectedID' => $StandardTemplate{Responsible},
                'Name'       => 'NewResponsibleID',
            };
        }

        if ($StandardTemplate{Priority}) {
            my $Priorities = $Self->_GetPriorities(
                QueueID => $StandardTemplate{Queue},
            );

            push @TemplateAJAX, {
                'Data'       => $Priorities,
                'SelectedID' => $StandardTemplate{Priority},
                'Name'       => 'PriorityID',
            };
        }

        if ($StandardTemplate{NextState}) {
            my $NextStates = $Self->_GetNextStates();

            push @TemplateAJAX, {
                'Data'       => $NextStates,
                'SelectedID' => $StandardTemplate{NextState},
                'Name'       => 'NextStateID',
            };
        }


        for my $DynamicField (@{$Self->{DynamicField}}) {
            
            next if ($DynamicField->{FieldType} eq "Database");
            my $PossibleValues = $DynamicField->{Config}->{PossibleValues};

            if ($DynamicField->{Config}->{PossibleNone} && $DynamicField->{Config}->{PossibleNone} == 1) {
                $PossibleValues->{''} = '-';
            }
            
            if ($DynamicField->{FieldType} eq "FreiconWebServiceSingle") {
                $PossibleValues = $DynamicFieldBackendObject->PossibleValuesGet(
                    DynamicFieldConfig   => $DynamicField,
                    OverridePossibleNone => 0,
                    Service              => $StandardTemplate{Service}
                );
                next if ($PossibleValues->{"FieldLabel_1"});
            }

            next unless $PossibleValues;

            push @TemplateAJAX, {
                'Data'       => $PossibleValues,
                'SelectedID' => $StandardTemplate{"DynamicField_$DynamicField->{Name}"},
                'Name'       => "DynamicField_" . $DynamicField->{Name},
            };
        }

        my $JSON = $LayoutObject->BuildSelectionJSON(
            [
                @TemplateAJAX,
            ],
        );

        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );

    } else {
        my $JSON = $LayoutObject->JSONEncode(
            Data => {},
        );
        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );
    }

}

sub ReturnEmptyResponse {
    my ($Self, %Param) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my $JSON = $LayoutObject->JSONEncode(
        Data => {},
    );

    return $LayoutObject->Attachment(
        ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
        Content     => $JSON,
        Type        => 'inline',
        NoCache     => 1,
    );
}

sub _GetNextStates {
    my ($Self, %Param) = @_;

    # use default Queue if none is provided
    $Param{QueueID} = $Param{QueueID} || 1;

    my %NextStates = ();
    if ($Param{QueueID} || $Param{TicketID}) {
        %NextStates = $Kernel::OM->Get('Kernel::System::Ticket')->TicketStateList(
            %Param,
            Action => "AgentTicketPhone",
            UserID => $Self->{UserID},
        );
    }
    return \%NextStates;
}

sub _GetUsers {
    my ($Self, %Param) = @_;

    # get users
    my %ShownUsers;
    my %AllGroupsMembers = $Kernel::OM->Get('Kernel::System::User')->UserList(
        Type  => 'Long',
        Valid => 1,
    );

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # just show only users with selected custom queue
    if ($Param{QueueID} && !$Param{OwnerAll}) {
        my @UserIDs = $TicketObject->GetSubscribedUserIDsByQueueID(%Param);
        for my $KeyGroupMember (sort keys %AllGroupsMembers) {
            my $Hit = 0;
            for my $UID (@UserIDs) {
                if ($UID eq $KeyGroupMember) {
                    $Hit = 1;
                }
            }
            if (!$Hit) {
                delete $AllGroupsMembers{$KeyGroupMember};
            }
        }
    }

    # show all system users
    if ($Kernel::OM->Get('Kernel::Config')->Get('Ticket::ChangeOwnerToEveryone')) {
        %ShownUsers = %AllGroupsMembers;
    }

    # show all users who are owner or rw in the queue group
    elsif ($Param{QueueID}) {
        my $GID = $Kernel::OM->Get('Kernel::System::Queue')->GetQueueGroupID(QueueID => $Param{QueueID});
        my %MemberList = $Kernel::OM->Get('Kernel::System::Group')->PermissionGroupGet(
            GroupID => $GID,
            Type    => 'owner',
        );
        for my $KeyMember (sort keys %MemberList) {
            if ($AllGroupsMembers{$KeyMember}) {
                $ShownUsers{$KeyMember} = $AllGroupsMembers{$KeyMember};
            }
        }
    }

    # workflow
    my $ACL = $TicketObject->TicketAcl(
        %Param,
        Action        => $Self->{Action},
        ReturnType    => 'Ticket',
        ReturnSubType => 'Owner',
        Data          => \%ShownUsers,
        UserID        => $Self->{UserID},
    );

    return { $TicketObject->TicketAclData() } if $ACL;

    return \%ShownUsers;
}

sub _GetResponsibles {
    my ($Self, %Param) = @_;

    # get users
    my %ShownUsers;
    my %AllGroupsMembers = $Kernel::OM->Get('Kernel::System::User')->UserList(
        Type  => 'Long',
        Valid => 1,
    );

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # just show only users with selected custom queue
    if ($Param{QueueID} && !$Param{ResponsibleAll}) {
        my @UserIDs = $TicketObject->GetSubscribedUserIDsByQueueID(%Param);
        for my $KeyGroupMember (sort keys %AllGroupsMembers) {
            my $Hit = 0;
            for my $UID (@UserIDs) {
                if ($UID eq $KeyGroupMember) {
                    $Hit = 1;
                }
            }
            if (!$Hit) {
                delete $AllGroupsMembers{$KeyGroupMember};
            }
        }
    }

    # show all system users
    if ($Kernel::OM->Get('Kernel::Config')->Get('Ticket::ChangeOwnerToEveryone')) {
        %ShownUsers = %AllGroupsMembers;
    }

    # show all users who are responsible or rw in the queue group
    elsif ($Param{QueueID}) {
        my $GID = $Kernel::OM->Get('Kernel::System::Queue')->GetQueueGroupID(QueueID => $Param{QueueID});
        my %MemberList = $Kernel::OM->Get('Kernel::System::Group')->PermissionGroupGet(
            GroupID => $GID,
            Type    => 'responsible',
        );
        for my $KeyMember (sort keys %MemberList) {
            if ($AllGroupsMembers{$KeyMember}) {
                $ShownUsers{$KeyMember} = $AllGroupsMembers{$KeyMember};
            }
        }
    }

    # workflow
    my $ACL = $TicketObject->TicketAcl(
        %Param,
        Action        => $Self->{Action},
        ReturnType    => 'Ticket',
        ReturnSubType => 'Responsible',
        Data          => \%ShownUsers,
        UserID        => $Self->{UserID},
    );

    return { $TicketObject->TicketAclData() } if $ACL;

    return \%ShownUsers;
}

sub _GetPriorities {
    my ($Self, %Param) = @_;

    # use default Queue if none is provided
    $Param{QueueID} = $Param{QueueID} || 1;

    # get priority
    my %Priorities;
    if ($Param{QueueID} || $Param{TicketID}) {
        %Priorities = $Kernel::OM->Get('Kernel::System::Ticket')->TicketPriorityList(
            %Param,
            Action => $Self->{Action},
            UserID => $Self->{UserID},
        );
    }
    return \%Priorities;
}

sub _GetTypes {
    my ($Self, %Param) = @_;

    # use default Queue if none is provided
    $Param{QueueID} = $Param{QueueID} || 1;

    # get type
    my %Type;
    if ($Param{QueueID} || $Param{TicketID}) {
        %Type = $Kernel::OM->Get('Kernel::System::Ticket')->TicketTypeList(
            %Param,
            Action => $Self->{Action},
            UserID => $Self->{UserID},
        );
    }
    return \%Type;
}

sub _GetServices {
    my ($Self, %Param) = @_;

    # get service
    my %Service;

    my $ServiceObject = $Kernel::OM->Get('Kernel::System::Service');

    # use default Queue if none is provided
    $Param{QueueID} = $Param{QueueID} || '';

    # get options for default services for unknown customers
    my $DefaultServiceUnknownCustomer = $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Service::Default::UnknownCustomer');

    # check if no CustomerUserID is selected
    # if $DefaultServiceUnknownCustomer = 0 leave CustomerUserID empty, it will not get any services
    # if $DefaultServiceUnknownCustomer = 1 set CustomerUserID to get default services
    if (!$Param{CustomerUserID} && $DefaultServiceUnknownCustomer) {
        $Param{CustomerUserID} = '<DEFAULT>';
    }

    # get service list
    # if ($Param{CustomerUserID} && $Param{QueueID}) {
    #     %Service = $Kernel::OM->Get('Kernel::System::Ticket')->TicketServiceList(
    #         %Param,
    #         Action => $Self->{Action},
    #         UserID => $Self->{UserID},
    #     );
    # } else {
    # Return all Services, filtering by KeepChildren config .
    %Service = $ServiceObject->ServiceList(
        UserID       => $Self->{UserID},
        KeepChildren => $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Service::KeepChildren'),
    );
    # }
    return \%Service;
}

sub _GetSLAs {
    my ($Self, %Param) = @_;

    # use default Queue if none is provided
    $Param{QueueID} = $Param{QueueID} || 1;

    # get services if they were not determined in an AJAX call
    if (!defined $Param{Services}) {
        $Param{Services} = $Self->_GetServices(%Param);
    }

    # get sla
    my %SLA;
    if ($Param{ServiceID} && $Param{Services} && %{$Param{Services}}) {
        if ($Param{Services}->{ $Param{ServiceID} }) {
            %SLA = $Kernel::OM->Get('Kernel::System::Ticket')->TicketSLAList(
                %Param,
                Action => $Self->{Action},
                UserID => $Self->{UserID},
            );
        }
    }
    return \%SLA;
}

sub _GetTos {
    my ($Self, %Param) = @_;

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # check own selection
    my %NewTos;
    if ($ConfigObject->Get('Ticket::Frontend::NewQueueOwnSelection')) {
        %NewTos = %{$ConfigObject->Get('Ticket::Frontend::NewQueueOwnSelection')};
    } else {

        # SelectionType Queue or SystemAddress?
        my %Tos;
        if ($ConfigObject->Get('Ticket::Frontend::NewQueueSelectionType') eq 'Queue') {
            %Tos = $Kernel::OM->Get('Kernel::System::Ticket')->MoveList(
                %Param,
                Type    => 'create',
                Action  => $Self->{Action},
                QueueID => $Self->{QueueID},
                UserID  => $Self->{UserID},
            );
        } else {
            %Tos = $Kernel::OM->Get('Kernel::System::SystemAddress')->SystemAddressQueueList();
        }

        # get create permission queues
        my %UserGroups = $Kernel::OM->Get('Kernel::System::Group')->PermissionUserGet(
            UserID => $Self->{UserID},
            Type   => 'create',
        );

        my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');
        my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');

        # build selection string
        QUEUEID:
        for my $QueueID (sort keys %Tos) {

            my %QueueData = $QueueObject->QueueGet(ID => $QueueID);

            # permission check, can we create new tickets in queue
            next QUEUEID if !$UserGroups{ $QueueData{GroupID} };

            my $String = $ConfigObject->Get('Ticket::Frontend::NewQueueSelectionString')
                || '<Realname> <<Email>> - Queue: <Queue>';
            $String =~ s/<Queue>/$QueueData{Name}/g;
            $String =~ s/<QueueComment>/$QueueData{Comment}/g;

            # remove trailing spaces
            if (!$QueueData{Comment}) {
                $String =~ s{\s+\z}{};
            }

            if ($ConfigObject->Get('Ticket::Frontend::NewQueueSelectionType') ne 'Queue') {
                my %SystemAddressData = $SystemAddressObject->SystemAddressGet(
                    ID => $Tos{$QueueID},
                );
                $String =~ s/<Realname>/$SystemAddressData{Realname}/g;
                $String =~ s/<Email>/$SystemAddressData{Name}/g;
            }
            $NewTos{$QueueID} = $String;
        }
    }

    # add empty selection
    $NewTos{''} = '-';

    return \%NewTos;
}

sub _GetTimeUnits {
    my ($Self, %Param) = @_;

    my $AccountedTime = '';

    # Get accounted time if AccountTime config item is enabled.
    if ($Kernel::OM->Get('Kernel::Config')->Get('Ticket::Frontend::AccountTime') && defined $Param{ArticleID}) {
        $AccountedTime = $Kernel::OM->Get('Kernel::System::Ticket::Article')->ArticleAccountedTimeGet(
            ArticleID => $Param{ArticleID},
        );
    }

    return $AccountedTime ? $AccountedTime : '';
}

1;
