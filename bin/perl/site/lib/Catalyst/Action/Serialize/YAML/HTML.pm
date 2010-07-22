package Catalyst::Action::Serialize::YAML::HTML;

use Moose;
use namespace::autoclean;

extends 'Catalyst::Action';
use YAML::Syck;
use URI::Find;

our $VERSION = '0.85';
$VERSION = eval $VERSION;

sub execute {
    my $self = shift;
    my ( $controller, $c ) = @_;

    my $stash_key = (
            $controller->{'serialize'} ?
                $controller->{'serialize'}->{'stash_key'} :
                $controller->{'stash_key'} 
        ) || 'rest';
    my $app = $c->config->{'name'} || '';
    my $output = "<html>";
    $output .= "<title>" . $app . "</title>";
    $output .= "<body><pre>";
    my $text = Dump($c->stash->{$stash_key});
    # Straight from URI::Find
    my $finder = URI::Find->new(
                              sub {
                                  my($uri, $orig_uri) = @_;
                                  my $newuri;
                                  if ($uri =~ /\?/) {
                                      $newuri = $uri . "&content-type=text/html";
                                  } else {
                                      $newuri = $uri . "?content-type=text/html";
                                  }
                                  return qq|<a href="$newuri">$orig_uri</a>|;
                              });
    $finder->find(\$text);
    $output .= $text;
    $output .= "</pre>";
    $output .= "</body>";
    $output .= "</html>";
    $c->response->output( $output );
    return 1;
}

1;
