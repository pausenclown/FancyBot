package FancyBot::WebShell::Controller::Login;
use Moose;
use XML::Simple;
use LWP::Simple;
use Win32::Guidgen;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

FancyBot::WebShell::Controller::Login - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut
use Data::Dumper;

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
	
	if ( $c->request->param('submit') )
	{
		my ( $login, $error ) = $self->admin_login( $c->request->param('name'), $c->request->param('password') );
		
		if ( $login )
		{
			$c->session->{player_name}    = $c->request->param('name');
			$c->response->redirect('/login/cookie');
			return;
		}
		else
		{
			$c->stash->{error} = $error;
			$c->stash->{name}  = $c->request->param('name');
		}
	}
	
	$c->stash->{template} = 'login.tt';
}

sub cookie :Local
{
    my ( $self, $c ) = @_;
	my $cookie = Win32::Guidgen::create(); $cookie =~ s/[^0-9A-Z]//g;
	
	$c->stash->{name}     = $c->session->{player_name};
	$c->stash->{cookie}   = "-admin $cookie";
	$c->stash->{template} = 'cookie.tt';
	
	$c->stash->{error} = 'Could not write cookie' unless
		$self->write_cookie( $c->stash->{name}, $cookie );
		
	$c->session->{current_cookie} = $cookie;
}


sub console :Local
{
    my ( $self, $c ) = @_;
	$c->stash->{template} = 'console.tt';
	$c->stash->{ip}       = get( 'http://www.whatismyip.com/automation/n09230945.asp' );
}

sub write_cookie
{
	my ($self, $player_name, $cookie) = @_;
	
	open my $out, '>', "login/$cookie" or return;
	print $out time, ':', $player_name, "\n";
	close $out;
	return 1;
}

sub admin_login
{
	my ($self, $player_name, $password) = @_;
	
	my $security = XMLin('conf/security.xml');
	my $error    = '';

	$error .= 'Please enter a Playername.<br/>' unless $player_name;
	$error .= 'Please enter a Password.<br/>'   unless $password;
	
	my @admins = 
		grep { $_->{content} eq $player_name } 
		map { ref $_ ? $_ : { password => $security->{AdminPassword}, content => $_ } }
		@{ $security->{Admins}->{Admin} };
	
	$error .= 'You are not an Admin.<br/>'
		unless @admins;
		
	$error .= 'Incorrect Password.<br/>'
		if $admins[0]->{password} ne $password;
		
	return (1) unless $error;
	return (0, $error);
}
	

=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
