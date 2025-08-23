; === Cool Trivia Maze – Offline installer ===
#define MyAppName "Cool Trivia Maze"
#define MyAppVersion "1.0"
#define MyExeName "cool_trivia_maze_windows.exe"
#define MySrcDir SourcePath   ; folder where this .iss file lives

[Setup]
AppId={{E206A3A7-49D0-40CC-9C2B-CNT-123456789ABC}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
DefaultDirName={autopf}\{#MyAppName}   ; Program Files\Cool Trivia Maze
DefaultGroupName={#MyAppName}
OutputDir=installer
OutputBaseFilename=CoolTriviaMaze_Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=admin               ; users get UAC prompt (typical for Program Files)

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; Game + required DLL(s) – make sure these exist in .\dist\
Source: "{#MySrcDir}\dist\{#MyExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MySrcDir}\dist\libgdsqlite.windows.template_release.x86_64.dll"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: postinstall skipifsilent