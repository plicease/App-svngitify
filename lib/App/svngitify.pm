package App::svngitify;

use strict;
use warnings;
use 5.010;
use Path::Class qw( file dir );
use Getopt::Long qw( GetOptions );
use Pod::Usage qw( pod2usage );
use URI;
use URI::file;
use File::chdir;
use File::Temp qw( tempdir );
use AE;
use AnyEvent::Open3::Simple;
use File::HomeDir;

# Handy doco:
# http://john.albin.net/git/convert-subversion-to-git

# ABSTRACT: Convert SVN distribution to git repository
# VERSION

=head1 DESCRIPTION

This is the module for the L<svngitify> script. See L<svngitify> for
details.

=head1 SEE ALSO

=over 4

=item L<svngitify>

=back

=cut

sub _log ($);
sub _run (@);

my $verbose;
my $editor = $ENV{EDITOR} // $ENV{VISUAL} // 'vi';

sub main
{
  local(undef, @ARGV) = @_;

  my %users;
  my $interactive;
  $verbose = 0;

  GetOptions(
    'user|u=s'            => \%users,
    'interactive|i'       => \$interactive,
    'verbose|v'           => \$verbose,
    'help|h'              => sub { pod2usage({ -verbose => 2}) },
    'version'             => sub {
      say 'svngitify version ', ($App::svngitify::VERSION // 'dev');
      exit 1;
    },
  ) || pod2usage(1);

  pod2usage(1) unless @ARGV;

  my $cwd_url = URI::file->new("$CWD/");
  $cwd_url->host('localhost');

  foreach my $src (map { URI->new_abs($_, $cwd_url) } @ARGV)
  {
    my $dest = dir( $CWD,
      Path::Class::Dir->new_foreign(
        "Unix", 
        $src->path,
      )->basename
    );
    
    if(-e $dest)
    {
      _log "$dest already exists";
      say "$dest already exists";
      exit 2;
    }

    _log "convert $src => $dest";
    say "$src => $dest";
    
    my $svn_checkout = dir( tempdir( CLEANUP => 1 ));
    _run "svn", "co", $src, $svn_checkout;

    my %users = do {
      local $CWD = $svn_checkout;
      map { $_ => $users{$_} } grep { defined } map { (split / \| /)[1] } _run "svn", "log", "-q";
    };
    
    my $usermap = file( tempdir( CLEANUP => 1 ), 'usermap.txt' );
    
    $usermap->spew(
      join "\n",
        map {
          defined $users{$_} 
          ? "$_ = $users{$_}" 
          : "$_ = "
        } keys %users
    );
    
    if(grep { !defined } values %users)
    {
      if($interactive)
      {
        system $editor, "$usermap";
      }
      else
      {
        _log "Failed: Missing user maps";
        say "Missing user maps.  Use --interactive to interactively edit the user map, or --user to specify user maps";
        exit 2;
      }
    }
    
    ## TODO: --no-metadata ?
    ## TODO: detect std lay out and use --stdlayout ?
    _run 'git', 'svn', 'clone', '--no-metadata', $src, -A => $usermap, $dest;
    
    ## TODO: convert svn:ignore to .gitignore
    ## should only do this if there ARE svn:ignore properties
    # cd dest
    # git svn show-ignore > .gitignore
    # git add .gitignore
    # git commit -m 'Convert svn:ignore properties to .gitignore'
  }
  
  0;
}

sub _run (@)
{
  my(@cmd) = map { "$_" } @_;
  
  my $done = AE::cv;
  my @out;
  my $save = defined wantarray;
  
  my $ipc = AnyEvent::Open3::Simple->new(
    on_stdout => sub {
      _log "[out]$_[1]";
      push @out, $_[1] if $save;
    },
    on_stderr => sub {
      _log "[err]$_[1]";
    },
    on_success => sub {
      _log "exit okay";
      $done->send(1);
    },
    on_error => sub {
      _log "error starting: $_[0]";
      exit 2;
    },
    on_signal => sub {
      _log "Terminted on signal: $_[1]";
      exit 2;
    },
    on_fail => sub {
      _log "Terminated on non-zero: $_[1]";
      exit 2;
    },
  );
  
  _log "[exe]% @cmd";
  $ipc->run(@cmd);
  $done->recv;
  
  $save ? @out : ();
}

sub _log ($)
{
  my($message) = @_;
  chomp $message;

  if($verbose)
  {
    say $message;
  }
  else
  {
    state $fh;
    state $filename;
  
    unless(defined $fh)
    {
      my $time = time;
      $filename = file(
        File::HomeDir->my_dist_data( "App-svngitify", { create => 1 } ),
        "detailedlog-$time-$$.log",
      );
      say "Detailed log: $filename";
      $fh = $filename->opena;
    }
  
    say $fh $message;
  }
}

1;
