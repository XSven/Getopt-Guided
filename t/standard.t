use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT is is_deeply ok plan subtest use_ok ) ], tests => 19;
use Test::Warn qw( warning_like );

my $module;

BEGIN {
  $module = 'Getopt::Guided';
  use_ok $module, qw( getopts ) or BAIL_OUT "Cannot loade module '$module'!"
}

subtest 'Usual flag' => sub {
  plan tests => 3;

  local @ARGV = qw( -b );
  ok getopts( 'b', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { b => 1 }, 'Flag has value 1';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Common option: Option and option-argument are separate' => sub {
  plan tests => 3;

  local @ARGV = qw( -a foo );
  ok getopts( 'a:', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'foo' }, 'Option has option-argument';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Common option: Option and option-argument in same argument string' => sub {
  plan tests => 3;

  local @ARGV = qw( -afoo );
  ok getopts( 'a:', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'foo' }, 'Option has option-argument';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Empty @ARGV' => sub {
  plan tests => 3;

  local @ARGV = ();
  ok getopts( 'a:b', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, {}, '%got_opts is empty';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Default for option with option-argument' => sub {
  plan tests => 3;

  local @ARGV = qw( -b );
  # Simulate default for option with option-argument
  unshift @ARGV, ( -a => 'foo' );
  ok getopts( 'a:b', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'foo', b => 1 }, 'Options properly set';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Grouping: Usual flag followed by common option' => sub {
  plan tests => 3;

  local @ARGV = qw( -ba foo );
  ok getopts( 'a:b', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'foo', b => 1 }, 'Options properly set';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Grouping: Usual flag followed by common option' => sub {
  plan tests => 3;

  local @ARGV = qw( -bafoo );
  ok getopts( 'a:b', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'foo', b => 1 }, 'Options properly set';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Grouping: Common option in the middle' => sub {
  plan tests => 3;

  local @ARGV = qw( -cab foo );
  ok getopts( 'a:bc', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'b', c => 1 }, 'Options properly set';
  is_deeply \@ARGV, [ qw( foo ) ], '@ARGV restored'
};

subtest 'End of options delimiter' => sub {
  plan tests => 3;

  local @ARGV = qw( -ba foo -c -- -d bar );
  ok getopts( 'a:bc', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'foo', b => 1, c => 1 }, 'Options properly set';
  is_deeply \@ARGV, [ qw( -d bar ) ], 'Options removed from @ARGV'
};

subtest 'End of options delimiter is an option-argument' => sub {
  plan tests => 3;

  local @ARGV = qw( -ba foo -d -- -c );
  ok getopts( 'a:bcd:', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'foo', b => 1, c => 1, d => '--' }, 'Options properly set';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Unknown option' => sub {
  plan tests => 4;

  local @ARGV = qw( -b -d bar );
  my %got_opts;
  warning_like { ok !getopts( 'a:b', %got_opts ), 'Failed' } qr/illegal option -- d/, 'Check warning';
  is_deeply \%got_opts, {}, '%got_opts is empty';
  is_deeply \@ARGV, [ qw( -b -d bar ) ], '@ARGV restored'
};

subtest 'Unknown option; default properly restored' => sub {
  plan tests => 4;

  local @ARGV = qw( -b -d bar );
  # Simulate default for option with option-argument
  unshift @ARGV, ( -a => 'foo' );
  my %got_opts;
  warning_like { ok !getopts( 'a:b', %got_opts ), 'Failed' } qr/illegal option -- d/, 'Check warning';
  is_deeply \%got_opts, {}, '%got_opts is empty';
  is_deeply \@ARGV, [ qw( -a foo -b -d bar ) ], '@ARGV restored'
};

subtest 'Missing option-argument' => sub {
  plan tests => 4;

  local @ARGV = qw( -b -a foo -c );
  my %got_opts;
  # https://github.com/Perl/perl5/issues/23906
  # Getopt::Std questionable undefined value bahaviour
  warning_like { ok !getopts( 'a:bc:', %got_opts ), 'Failed' } qr/option requires an argument -- c/, 'Check warning';
  is_deeply \%got_opts, {}, '%got_opts is empty';
  is_deeply \@ARGV, [ qw( -b -a foo -c ) ], '@ARGV restored'
};

subtest 'Undefined option-argument' => sub {
  plan tests => 4;

  local @ARGV = ( '-b', '-a', undef, '-c' );
  my %got_opts;
  warning_like { ok !getopts( 'a:bc', %got_opts ), 'Failed' } qr/option requires an argument -- a/, 'Check warning';
  is_deeply \%got_opts, {}, '%got_opts is empty';
  is_deeply \@ARGV, [ ( '-b', '-a', undef, '-c' ) ], '@ARGV restored'
};

subtest 'Non-option-argument stops option parsing' => sub {
  plan tests => 3;

  local @ARGV = qw( -b -a foo bar -c );
  ok getopts( 'a:bc', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'foo', b => 1 }, 'Options properly set';
  is_deeply \@ARGV, [ qw( bar -c ) ], 'Options removed from @ARGV'
};

subtest 'The option delimiter is a non-option-argument that stops option parsing' => sub {
  plan tests => 3;

  local @ARGV = qw( -b - a foo bar -c );
  ok getopts( 'a:bc', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { b => 1 }, 'Options properly set';
  is_deeply \@ARGV, [ qw( - a foo bar -c ) ], 'Options removed from @ARGV'
};

subtest 'Overwrite option-argument' => sub {
  plan tests => 3;

  local @ARGV = qw( -a foo -b -a bar -c );
  ok getopts( 'a:bc', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'bar', b => 1, c => 1 }, 'Options properly set';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Slurp option' => sub {
  plan tests => 3;

  local @ARGV = qw( -a -b -c );
  ok getopts( 'a:bc', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => '-b', c => 1 }, 'Options properly set';
  is @ARGV, 0, '@ARGV is empty'
}
