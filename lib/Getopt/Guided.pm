# Prefer numeric version for backwards compatibility
BEGIN { require 5.010_001 }; ## no critic ( RequireUseStrict, RequireUseWarnings )
use strict;
use warnings;

package Getopt::Guided;

$Getopt::Guided::VERSION = 'v2.0.0';

use Carp           qw( croak );
use File::Basename qw( basename );

# Flag Indicator Character Class
sub FICC () { '[!+]' }
# Option-Argument Indicator Character Class
sub OAICC () { '[,:]' }

@Getopt::Guided::EXPORT_OK = qw( getopts getopts3 );

sub import {
  my $module = shift;

  our @EXPORT_OK;
  my $target = caller;
  for my $func ( @_ ) {
    croak "$module: '$func' is not exported, stopped"
      unless grep { $func eq $_ } @EXPORT_OK;
    no strict 'refs'; ## no critic ( ProhibitNoStrict )
    *{ "$target\::$func" } = $module->can( $func )
  }
}

# Implementation is based on m//gc with \G
sub _prepare_name_to_ind ( $ ) {
  my $spec = shift;

  my $name_to_ind;
  while ( $spec =~ m/\G ( [[:alnum:]] ) ( ${ \( FICC ) } | ${ \( OAICC ) } | )/gcx ) {
    my ( $name, $ind ) = ( $1, $2 );
    croak "getopts: \$spec parameter contains option '$name' multiple times, stopped"
      if exists $name_to_ind->{ $name };
    $name_to_ind->{ $name } = $ind;
  }
  my $offset = pos $spec;
  croak "getopts: \$spec parameter isn't a string of alphanumeric characters, stopped"
    unless defined $offset and $offset == length $spec;

  $name_to_ind
}

# https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap12.html#tag_12_02>
sub getopts3 ( \@$\% ) {
  my ( $argv, $spec, $opts ) = @_;

  my $name_to_ind = _prepare_name_to_ind $spec;
  croak "getopts: \$opts parameter hash isn't empty, stopped"
    if %$opts;

  my @argv_backup = @$argv;
  my @error;
  # Guideline 4, Guideline 9
  while ( @$argv and my ( $first, $rest ) = ( $argv->[ 0 ] =~ m/\A-(.)(.*)/ ) ) {
    # Guideline 10
    shift @$argv, last if $argv->[ 0 ] eq '--';
    my $pos = index( $spec, $first );
    if ( $pos >= 0 ) {
      my $ind = $name_to_ind->{ $first };
      if ( $ind =~ m/\A ${ \( OAICC ) } \z/x ) {
        shift @$argv;
        if ( $rest eq '' ) {
          # Guideline 7
          @error = ( 'option requires an argument', $first ), last
            unless @$argv;
          # Guideline 6, Guideline 8
          @error = ( 'option requires an argument', $first ), last
            unless defined( my $val = shift @$argv );
          if ( $ind eq ':' ) {
            # Standard behaviour: Overwrite option-argument
            $opts->{ $first } = $val
          } else {
            # Create and fill list of option-arguments ( $ind eq ',' )
            $opts->{ $first } = [] unless exists $opts->{ $first };
            push @{ $opts->{ $first } }, $val
          }
        } else {
          # Guideline 5
          @error = ( "option with argument isn't last one in group", $first );
          last
        }
      } else {
        if ( $ind eq '' ) {
          # Standard behaviour: Assign perl boolean true value
          $opts->{ $first } = !!1
        } elsif ( $ind eq '!' ) {
          # Negate logically
          $opts->{ $first } = !!!$opts->{ $first }
        } else {
          # Increment ( $ind eq '+' )
          ++$opts->{ $first }
        }
        if ( $rest eq '' ) {
          shift @$argv
        } else {
          # Guideline 5
          $argv->[ 0 ] = "-$rest" ## no critic ( RequireLocalizedPunctuationVars )
        }
      }
    } else {
      @error = ( 'illegal option', $first ), last
    }
  }

  if ( @error ) {
    # Restore to avoid side effects
    @$argv = @argv_backup; ## no critic ( RequireLocalizedPunctuationVars )
    %$opts = ();
    # Prepare and print warning message:
    # Program name, type of error, and invalid option character
    warn sprintf( "%s: %s -- %s\n", basename( $0 ), @error ); ## no critic ( RequireCarping )
  }

  @error == 0
}

sub getopts ( $\% ) {
  my ( $spec, $opts ) = @_;

  getopts3 @ARGV, $spec, %$opts
}

1
