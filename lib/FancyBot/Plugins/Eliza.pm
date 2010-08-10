=head1 FancyBot::Plugins::Eliza

FancyBot ChatBot Plugin 

=head1 SYNOPSIS
 
=head1 DESCRIPTION

This plugin acts as a chatbot in the ingame chat. It is called Eliza.

Those are the inner workings:

=head2 QUESTIONS

As soon as Eliza sees a question (means a question mark) and the word immedeatly before it
matches a question in the configuration, Eliza will answer that question. For example, if your 
Eliza configuration looks like

	<Eliza>
		<Questions>
			<Question>
				<Subject>poptart</Subject>
				<Answers>
					<Answer>Someone who cowardly hides behind a hill or structure, comes out, fires and disappears. Not to be mixed with jumpsnipers.</Answer>
					<Answer>Someone who cleverly uses radar and terrain to his fortune, minimzing own damage. Not to be mixed with jumpsnipers.</Answer>
				</Answers>
			</Question>
		</Questions>
	</Eliza>

the bot will react to a chat like

	WTF, Poptart? 
	
randomly with one of the two configured answers.

=head2 OPINIONS

As soon as Eliza sees a recognized subject (means a word) she has an opinion about, she will state her opinion. 
For example, if your Eliza configuration looks like

	<Eliza>
		<Opinions>
			<Opinion>
				<Subject>poptart</Subject>
				<Statements>
					<Statement>Stop arguing about poptarts. They have their uses. Sometimes.</Statement>
					<Statement>Oh no, not that discussion.</Statement>
				</Statements>
			</Opinion>
		<Opinions>
	</Eliza>

the bot will react to a chat like

	Oh noes, a Poptart!
	
randomly with one of the two configured opinions.

=head2  OTHER TALK

As soon as Eliza sees her name mentioned (means the BotName as configure), Eliza will try her best to parse
the input and make a sensible comment. Example:

	Someplayer :> Fuck you ServerBot
	ServerBot :> Does it make you feel strong to use such language?
  
The values of the C<<Subject>> tags are interpreted as Regular Expressions to make Eliza more flexible.

For Example

	<Opinion>
		<Subject>(jump ?)?sniper</Subject>
		<Statements>
			<Statement>You have to get along with snipers, though you don't have to like them.</Statement>
			<Statement>A good jump sniper is worth his weight in Teflon.</Statement>
		</Statements>
	</Opinion>

creates and opinion which reacts to

	jumpsniper
	Jump Sniper
	sniper
	SNIPER
	
etc.

=cut

package FancyBot::Plugins::Eliza;

use Moose;
use Chatbot::Eliza

# Declare the events we listen to, here: chatter
has events =>
	isa     => 'HashRef',
	is      => 'ro',
	default => sub {{
		# Player has joined# %player #
		'player_connect' => sub 
		{
			my $args  = shift;
			
			# Make sure we got a bot reference
			my $bot       = $args->{bot}         || die "No bot reference";
			my $player    = $args->{player_name} || die "No player reference";

			my @greetings = ref $bot->config->{Eliza}->{Greetings}->{Greeting} eq "ARRAY" ? 
			                @{ $bot->config->{Eliza}->{Greetings}->{Greeting} } :
							( bot->config->{Eliza}->{Greetings}->{Greeting} );
							
			for my $greeting ( @greetings )
			{
				# See if the question matches the configured subject
				my $re = $greeting->{Match}; if ( $player =~ /${re}/ )
				{
					# Depending on the XML we sometimes get a string or an array
					my $messages = ref $greeting->{Message} ? 
								   $greeting->{Message}     : 
								   [ $greeting->{Message} ] ;
					
					# Choose a random answer
					my $msg = $messages->[ int( rand( scalar @$messages ) ) ];
					$msg =~ s/%player/$player/g;
																	
					# Say Hi
					sleep(5);
					$bot->screen->send_chatter( $msg ); 
					
					return 1;
				}
			}

			return 1;			
		},

		# React to all chat
		'chatter' => sub 
		{
			# Fetch args from @_
			my $args  = shift;
			
			# Make sure we got a bot reference
			my $bot   = $args->{bot}      || die "No bot reference";
			
			# Make sure we got a message to parse
			my $txt   = $args->{message}  || die "No message";
			
			# Fetch info about the user- and botname
			my $user  = $args->{user};
			my $botn  = $bot->config->{'Server'}->{'BotName'} || 'Fancy';
			
			# no user chat, most likely from MOTD.TXT
			return 1  unless $user;
			
			# ignore non intentional self chatter
			return 1 if $user eq $botn && $txt !~ /^!!!/;

			# Someone asks Eliza a question
			if ( $txt =~ s/\?$// )
			{
				# Look for answer in config
				for my $question ( @{ $bot->config->{Eliza}->{Questions}->{Question} }  )
				{
					# See if the question matches the configured subject
					my $re = $question->{Subject}; if ( $txt =~ /^!!!?${re}$/i )
					{
						# Depending on the XML we sometimes get a string or an array
						my $answers = ref $question->{Answers}->{Answer} ? 
						              $question->{Answers}->{Answer}     : 
									  [ $question->{Answers}->{Answer} ] ;
						
						# Choose a random answer
						my $answer = int( rand( scalar @$answers ) );
																		
						# Enlighting
						$bot->screen->send_chatter( $answers->[ $answer ] ); 
						
						return 1;
					}
				}
			}
			
			# Eliza states her opinion
			for my $opinion ( @{ $bot->config->{Eliza}->{Opinions}->{Opinion} }  )
			{
				# See if we find something we got an opinion on
				my $re = $opinion->{Subject}; if ( $txt =~ /\b${re}\b/i )
				{
					# Depending on the XML we sometimes get a string or an array
					my $statements = ref $opinion->{Statements}->{Statement} ? 
								  $opinion->{Statements}->{Statement}     : 
								  [ $opinion->{Statements}->{Statement} ] ;
					
					# Choose a random statement
					my $statement = int( rand( scalar @$statements ) );
																	
					# Enlighting
					$bot->screen->send_chatter( $statements->[ $statement ] ); 
					
					return 1;
				}
			}
		
			# Someone mentions Elizas name
			if ( $txt =~ s/$botn//i )
			{
				$bot->plugin_stash->{eliza} ||= Chatbot::Eliza->new( $botn );
				$bot->screen->send_chatter( $bot->plugin_stash->{eliza}->transform( $txt ) );
			}
			
			return 1;
		},
	}};

1;