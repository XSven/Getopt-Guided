# Prefer numeric version for backwards compatibility
BEGIN { require 5.010_001 }; ## no critic ( RequireUseStrict, RequireUseWarnings )
use strict;
use warnings;

package Getopt::Guided;

$Getopt::Guided::VERSION = 'v1.0.0';

use Exporter       qw( import );
use File::Basename qw( basename );

@Getopt::Guided::EXPORT_OK = qw( getopts );

# https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap12.html#tag_12_02>
sub getopts ( $\% ) {
  my ( $spec, $opts ) = @_;

  my @argv_backup = @ARGV;
  my %opts_backup = %$opts;
  my @error;

  my @opts = split( //, $spec );
  # Guideline 4, Guideline 9
  while ( @ARGV and my ( $first, $rest ) = ( $ARGV[ 0 ] =~ m/\A-(.)(.*)/ ) ) {
    # Guideline 10
    shift @ARGV, last if $ARGV[ 0 ] eq '--';
    my $pos = index( $spec, $first );
    if ( $pos >= 0 ) {
      if ( defined( $opts[ $pos + 1 ] ) and ( $opts[ $pos + 1 ] eq ':' ) ) {
        shift @ARGV;
        if ( $rest eq '' ) {
          # Guideline 7
          @error = ( 'option requires an argument', $first ), last unless @ARGV;
          # Guideline 6, Guideline 8
          $opts->{ $first } = shift @ARGV
        } else {
          # Guideline 5
          @error = ( "option with argument isn't last one in group", $first );
          last;
        }
      } else {
        $opts->{ $first } = 1;
        if ( $rest eq '' ) {
          shift @ARGV
        } else {
          # Guideline 5
          $ARGV[ 0 ] = "-$rest" ## no critic ( RequireLocalizedPunctuationVars )
        }
      }
    } else {
      @error = ( 'illegal option', $first );
      last
    }
  }

  if ( @error ) {
    # Restore to avoid side effects
    @ARGV = @argv_backup; ## no critic ( RequireLocalizedPunctuationVars )
    %$opts = %opts_backup;
    # Prepare and throw error message:
    # Program name, type of error, and invalid option character
    die sprintf( "%s: %s -- %s\n", basename( $0 ), @error ); ## no critic ( RequireCarping )
  }

  undef
}

1
