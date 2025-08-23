; ---- CoolTriviaMaze_OfflineInstaller.iss ----
#define MyAppName    "Cool Trivia Maze"
#define MyAppVersion "1.0.0"
#define MyCompany    "Your Team"
#define DistDir      SourcePath + "\dist"

[Setup]
AppId={{E206A73F-79DD-40CC-92B2-C13A54E96789}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyCompany}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputBaseFilename=CoolTriviaMaze_Setup
OutputDir=installer\artifacts
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64

; Show the “Choose Install Location” page
DisableDirPage=no

; If you want per-user install (no UAC), uncomment the next line.
; If your compiler still complains, leave it commented (default is admin).
;PrivilegesRequired=lowest

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &Desktop shortcut"; Flags: unchecked

[Files]
; Core game files (EXE and PCK names must match!)
Source: "{#DistDir}\cool_trivia_maze_windows.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#DistDir}\cool_trivia_maze_windows.pck";  DestDir: "{app}"; Flags: ignoreversion
Source: "{#DistDir}\libgdsqlite.windows.template_release.x86_64.dll"; DestDir: "{app}"; Flags: ignoreversion

; Create assets directory and place SQLite DB there
Source: "{#DistDir}\TriviaQuestions.db"; DestDir: "{app}\assets"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}";       Filename: "{app}\cool_trivia_maze_windows.exe"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\cool_trivia_maze_windows.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\cool_trivia_maze_windows.exe"; Description: "Launch {#MyAppName}"; Flags: postinstall skipifsilent
