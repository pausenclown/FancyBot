package PAR::SetupTemp;
$PAR::VERSION = '0.982';

use 5.006;
use strict;
use warnings;

use PAR::SetupProgname;

=head1 NAME

PAR::SetupTemp - Setup $ENV{PAR_TEMP}

=head1 SYNOPSIS

PAR guts, beware. Check L<PAR>

=head1 DESCRIPTION

Routines to setup the C<PAR_TEMP> environment variable.
The documentation of how the temporary directories are handled
is currently scattered across the C<PAR> manual and the
C<PAR::Environment> manual.

The C<set_par_temp_env()> subroutine sets up the C<PAR_TEMP>
environment variable.

=cut

# for PAR internal use only!
our $PARTemp;

# The C version of this code appears in myldr/mktmpdir.c
# This code also lives in PAR::Packer's par.pl as _set_par_temp!
sub set_par_temp_env {
    PAR::SetupProgname::set_progname()
      unless defined $PAR::SetupProgname::Progname;

    if (defined $ENV{PAR_TEMP} and $ENV{PAR_TEMP} =~ /(.+)/) {
        $PARTemp = $1;
        return;
    }

    my $stmpdir = _get_par_user_tempdir();
    require File::Spec;
    if (defined $stmpdir) { # it'd be quite bad if this was not the case
      if (!$ENV{PAR_CLEAN} and my $mtime = (stat($PAR::SetupProgname::Progname))[9]) {
          my $ctx = _get_digester();

          # Workaround for bug in Digest::SHA 5.38 and 5.39
          my $sha_version = eval { $Digest::SHA::VERSION } || 0;
          if ($sha_version eq '5.38' or $sha_version eq '5.39') {
              $ctx->addfile($PAR::SetupProgname::Progname, "b") if ($ctx);
          }
          else {
              if ($ctx and open(my $fh, "<$PAR::SetupProgname::Progname")) {
                  binmode($fh);
                  $ctx->addfile($fh);
                  close($fh);
              }
          }

          $stmpdir = File::Spec->catdir(
              $stmpdir,
              "cache-" . ( $ctx ? $ctx->hexdigest : $mtime )
          );
      }
      else {
          $ENV{PAR_CLEAN} = 1;
          $stmpdir = File::Spec->catdir($stmpdir, "temp-$$");
      }

      $ENV{PAR_TEMP} = $stmpdir;
      mkdir $stmpdir, 0755;
    } # end if found a temp dir

    $PARTemp = $1 if defined $ENV{PAR_TEMP} and $ENV{PAR_TEMP} =~ /(.+)/;
}

# Find any digester
# Used in PAR::Repository::Client!
sub _get_digester {
  my $ctx = eval { require Digest::SHA; Digest::SHA->new(1) }
         || eval { require Digest::SHA1; Digest::SHA1->new }
         || eval { require Digest::MD5; Digest::MD5->new };
  return $ctx;
}

# find the per-user temporary directory (eg /tmp/par-$USER)
# Used in PAR::Repository::Client!
sub _get_par_user_tempdir {
  my $username = _find_username();
  my $temp_path;
  foreach my $path (
    (map $ENV{$_}, qw( PAR_TMPDIR TMPDIR TEMPDIR TEMP TMP )),
      qw( C:\\TEMP /tmp . )
  ) {
    next unless defined $path and -d $path and -w $path;
    $temp_path = File::Spec->catdir($path, "par-$username");
    ($temp_path) = $temp_path =~ /^(.*)$/s;
    mkdir $temp_path, 0755;

    last;
  }
  return $temp_path;
}

# tries hard to find out the name of the current user
sub _find_username {
  my $username;
  my $pwuid;
  # does not work everywhere:
  eval {($pwuid) = getpwuid($>) if defined $>;};

  if ( defined(&Win32::LoginName) ) {
    $username = &Win32::LoginName;
  }
  elsif (defined $pwuid) {
    $username = $pwuid;
  }
  else {
    $username = $ENV{USERNAME} || $ENV{USER} || 'SYSTEM';
  }
  $username =~ s/\W/_/g;

  return $username;
}

1;

__END__

=head1 SEE ALSO

The PAR homepage at L<http://par.perl.org>.

L<PAR>, L<PAR::Environment>

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>,
Steffen Mueller E<lt>smueller@cpan.orgE<gt>

L<http://par.perl.org/> is the official PAR website.  You can write
to the mailing list at E<lt>par@perl.orgE<gt>, or send an empty mail to
E<lt>par-subscribe@perl.orgE<gt> to participate in the discussion.

Please submit bug reports to E<lt>bug-par@rt.cpan.orgE<gt>. If you need
support, however, joining the E<lt>par@perl.orgE<gt> mailing list is
preferred.

=head1 COPYRIGHT

Copyright 2002-2010 by Audrey Tang E<lt>cpan@audreyt.orgE<gt>.

Copyright 2006-2010 by Steffen Mueller E<lt>smueller@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

