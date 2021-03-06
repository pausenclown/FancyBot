; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{06E6212D-1EDC-4CB1-9FD6-7173FB3148AE}
AppName=FancyBot
AppVersion=0.01
;AppVerName=FancyBot 1.5
AppPublisher=DSA Development Studios
AppPublisherURL=http://dark-star-alliance.clangroups.com
AppSupportURL=http://github.com/pausenclown/FancyBot
AppUpdatesURL=http://github.com/pausenclown/FancyBot
DefaultDirName=\Mercs\FancyBot
DefaultGroupName=FancyBot
OutputBaseFilename=setup
Compression=lzma
SolidCompression=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "basque"; MessagesFile: "compiler:Languages\Basque.isl"
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"
Name: "catalan"; MessagesFile: "compiler:Languages\Catalan.isl"
Name: "czech"; MessagesFile: "compiler:Languages\Czech.isl"
Name: "danish"; MessagesFile: "compiler:Languages\Danish.isl"
Name: "dutch"; MessagesFile: "compiler:Languages\Dutch.isl"
Name: "finnish"; MessagesFile: "compiler:Languages\Finnish.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "german"; MessagesFile: "compiler:Languages\German.isl"
Name: "hebrew"; MessagesFile: "compiler:Languages\Hebrew.isl"
Name: "hungarian"; MessagesFile: "compiler:Languages\Hungarian.isl"
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"
Name: "japanese"; MessagesFile: "compiler:Languages\Japanese.isl"
Name: "norwegian"; MessagesFile: "compiler:Languages\Norwegian.isl"
Name: "polish"; MessagesFile: "compiler:Languages\Polish.isl"
Name: "portuguese"; MessagesFile: "compiler:Languages\Portuguese.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "slovak"; MessagesFile: "compiler:Languages\Slovak.isl"
Name: "slovenian"; MessagesFile: "compiler:Languages\Slovenian.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "\Mercs\FancyBot\FancyBot.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "\Mercs\FancyBot\WebShell.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "\Mercs\FancyBot\bin\*"; DestDir: "{app}\bin"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "\Mercs\FancyBot\lib\*"; DestDir: "{app}\lib"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "\Mercs\FancyBot\conf\*.xml"; DestDir: "{app}\conf"; Flags: ignoreversion
Source: "\Mercs\FancyBot\root\*"; DestDir: "{app}\root"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "\Mercs\FancyBot\tmp\.exists"; DestDir: "{app}\tmp"; Flags: ignoreversion recursesubdirs createallsubdirs

; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{group}\FancyBot"; Filename: "{app}\FancyBot.exe"
Name: "{commondesktop}\FancyBot"; Filename: "{app}\FancyBot.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\FancyBot.exe"; Description: "{cm:LaunchProgram,FancyBot}"; Flags: nowait postinstall skipifsilent


