#!/usr/bin/perl

use Modern::Perl;
use Mail::DWIM qw/mail/;

mail(
	to => $ARGV[0],
	subject => 'Attachment sent with mail_file.pl',
	attach => [$ARGV[1]],
	text => 'See attached.',
);
