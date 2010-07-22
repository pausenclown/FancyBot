package DBIx::Class::Storage::DBI::ODBC;
use strict;
use warnings;

use base qw/DBIx::Class::Storage::DBI/;
use mro 'c3';
use Try::Tiny;
use namespace::clean;

sub _rebless {
  my ($self) = @_;

  try {
    my $dbtype = $self->_get_dbh->get_info(17);

    # Translate the backend name into a perl identifier
    $dbtype =~ s/\W/_/gi;
    my $subclass = "DBIx::Class::Storage::DBI::ODBC::${dbtype}";

    if ($self->load_optional_class($subclass) && !$self->isa($subclass)) {
      bless $self, $subclass;
      $self->_rebless;
    }
  };
}

1;

=head1 NAME

DBIx::Class::Storage::DBI::ODBC - Base class for ODBC drivers

=head1 DESCRIPTION

This class simply provides a mechanism for discovering and loading a sub-class
for a specific ODBC backend.  It should be transparent to the user.

=head1 AUTHORS

Marc Mims C<< <marc@questright.com> >>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
