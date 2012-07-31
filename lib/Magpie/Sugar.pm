package Magpie::Sugar 1.0;

use v5.10;
use strict;
use warnings;

use Syntax::Collector -collect => q{
use feature 0 ':5.10';
use true 0;
use utf8::all;
use Moose 2.00;
use Magpie::Constants 0;
use Method::Signatures::Simple 0;
use Try::Tiny 0;
};

sub IMPORT
{
	my ($class, %args) = @_;
	my $caller = caller(0);
	
	Method::Signatures::Simple::->install_methodhandler(
		into     => $caller,
		name     => 'handle',
		invocant => '$self = shift; my $ctxt', # HACK ALERT!
	);
	
	eval "package $caller; extends '$args{-base}'"
		if exists $args{-base};
}

1;
