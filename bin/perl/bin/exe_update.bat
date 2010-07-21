@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S %0 %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul
goto endofperl
@rem ';
#!/usr/local/bin/perl
#line 15
# $File: //member/autrijus/Win32-Exe/script/exe_update.pl $ $Author: autrijus $
# $Revision: #1 $ $Change: 9927 $ $DateTime: 2004/02/06 19:31:24 $

use strict;
use File::Basename;
use Win32::Exe;
use Getopt::Long;

=head1 NAME

exe_update.pl - Modify windows executable files

=head1 SYNOPSIS

B<exe_update.pl> S<[ B<--gui> | B<--console> ]> S<[ B<--icon> I<iconfile> ]>
              S<[ B<--info> I<key=value;...> ]> I<exefile>

=head1 DESCRIPTION

This program rewrites PE headers in a Windows executable file.  It can
change whether the executable runs with a console window, as well as
setting the icons and version information associated with it.

=head1 OPTIONS

Options are available in a I<short> form and a I<long> form.  For
example, the three lines below are all equivalent:

    % exe_update.pl -i new.ico input.exe
    % exe_update.pl --icon new.ico input.exe
    % exe_update.pl --icon=new.ico input.exe

=over 4

=item B<-c>, B<--console>

Set the executable to always display a console window.

=item B<-g>, B<--gui>

Set the executable so it does not have a console window.

=item B<-i>, B<--icon>=I<FILE>

Specify an icon file (in F<.ico>, F<.exe> or F<.dll> format) for the
executable.

=item B<-N>, B<--info>=I<KEY=VAL>

Attach version information for the executable.  The name/value pair is
joined by C<=>.  You may specify C<-N> multiple times, or use C<;> to
link several pairs.

These special C<KEY> names are recognized:

    Comments        CompanyName     FileDescription FileVersion
    InternalName    LegalCopyright  LegalTrademarks OriginalFilename
    ProductName     ProductVersion

=back

=cut

my $Options = {};
Getopt::Long::GetOptions( $Options,
    'g|gui',            # No console window
    'c|console',        # Use console window
    'i|icon:s',         # Icon file
    'N|info:s@',        # Executable header info
);

my $exe = shift or die "Usage: " . basename($0) .
    " [--gui | --console] [--icon file.ico] [--info key=value] file.exe\n";

Win32::Exe->new($exe)->update(
    gui	    => $Options->{g},
    console => $Options->{c},
    icon    => $Options->{i},
    info    => $Options->{N},
) or die "Update of $exe failed!\n";

__END__

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>

=head1 COPYRIGHT

Copyright 2004, 2006 by Audrey Tang E<lt>cpan@audreyt.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

__END__
:endofperl
