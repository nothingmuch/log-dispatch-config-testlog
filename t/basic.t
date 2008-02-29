#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use FindBin;
use Path::Class;
use Storable qw(fd_retrieve);

my $test = dir($FindBin::Bin)->file("fake_test");

defined( my $pid = open my $fh, "$^X $test 2>&1 |" )
	or die "fork failed: $!";

() = <$fh>;
close $fh == 0 or die "$!";

my @log;

open my $log, "<", "${test}.log"
	or die "open(${test}.log): $!";

while ( my $entry = eval { fd_retrieve($log) } ) {
	push @log, $entry;
}

require_ok("Log::Dispatch::Config::TestLog");

is( @log, 10, "10 log messages" );

is_deeply(
	\@log,
	[
		{
			'level' => 'info',
			'name' => 'file',
			'message' => "Starting test $test, pid = $pid",
		},
		{
			'level' => 'info',
			'name' => 'file',
			'message' => 'TAP: ok 1 - foo'
		},
		{
			'level' => 'debug',
			'name' => 'file',
			'message' => 'moose'
		},
		{
			'level' => 'info',
			'name' => 'file',
			'message' => 'TAP: not ok 2 - blah'
		},
		{
			'level' => 'info',
			'name' => 'file',
			'message' => 'TAP: #   Failed test \'blah\''
		},
		{
			'level' => 'info',
			'name' => 'file',
			'message' => "TAP: #   at $test line 19."
		},
		{
			'level' => 'notice',
			'name' => 'file',
			'message' => 'elk'
		},
		{
			'level' => 'info',
			'name' => 'file',
			'message' => "Finishing test $test"
		},
		{
			'level' => 'info',
			'name' => 'file',
			'message' => 'TAP: 1..2'
		},
		{
			'level' => 'info',
			'name' => 'file',
			'message' => 'TAP: # Looks like you failed 1 test of 2.'
		},
	],
	"logged output",
);
