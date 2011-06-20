#!/usr/bin/perl

# monitor_lso.pl - Monitor directory for new Flash LSOs
# Darian Anthony Patrick <darian@criticode.com>
#
# Uses inotify to monitor a directory for the
# creation/modification of new Flash LSO files
# and directories

use Modern::Perl;
use threads;
use Thread::Queue;
#use App::Daemon qw(daemonize);
use Sys::Syslog qw(:standard :macros);
use Linux::Inotify2;
use IO::All;

my $directory = '/home/'. getlogin() . '/.macromedia';

sub inspect_file {
	my $file_path = shift;

	my $message = "$file_path written.";

	syslog(LOG_ALERT, $message);

	return;
}

sub main {
	# Check that a directory was set
	unless ( defined $directory && -d $directory ) {
		say STDERR 'Error: $directory invalid.';
		exit 1;
	}

	# Open syslog
	openlog('monitor_lso', '', LOG_USER);

	# Daemonize process
	#daemonize();
	syslog(LOG_INFO, "Daemon started; watching $directory");

	# Create queue for processing new files
	my $file_queue = Thread::Queue->new();

	# Create thread handling file inspection
	my $inspect_thread
		= threads->create(sub {
			while ( my $file_path = $file_queue->dequeue() ) {
				inspect_file($file_path);
			}
		})->detach();

	my $inotify = Linux::Inotify2->new()
		or die "Could not create new inotify object: $!";

	# Define filesystem events which require inspection
	opendir(my $dh, $directory);
	while (my $dir = readdir $dh) {
		next if $dir =~ m/^\.{1,2}$/;
		$dir = $directory . '/' . $dir;
		next unless -d $dir;
		say $dir;
		$inotify->watch( $dir, IN_CREATE | IN_MODIFY | IN_MOVED_TO, sub {
			say "called";
			my $e = shift;
			$file_queue->enqueue($e->fullname);
		});
	}
	close $dh;

	# Start manual event loop, waiting for events in supplied directory
	1 while $inotify->poll;
}

main() if $0 eq __FILE__;
