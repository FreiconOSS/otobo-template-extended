package Kernel::Language::de_AdminTemplateExtended;

use strict;
use warnings;

sub Data {
    my $Self = shift;

    # admin module: header and description
    $Self->{Translation}->{'TemplatesExtended'} = 'Erweiterte Vorlagen';
    $Self->{Translation}->{'RequiredGroup'} = 'Erforderliche Gruppe';
    $Self->{Translation}->{'Create and manage extended templates.'} = 'Erweiterte Vorlagen erzeugen und verwalten.';

    # ???
    $Self->{Translation}->{'Add extended template'} = 'Erweiterte Ticketvorlage erstellen';
    $Self->{Translation}->{'Manage ExtendedTemplates'} = 'Erweiterte Vorlagen verwalten';

    # ticket fields
    $Self->{Translation}->{'TicketType'} = 'Tickettyp';

    # type filter widget
    $Self->{Translation}->{'TypeFilter'} = 'Filter nach Typ';

    # template types
    $Self->{Translation}->{'Wait'} = 'Warten';
    $Self->{Translation}->{'PhoneCall'} = 'Telefonanruf';

    return 1;
}

1;
