program autotest4delphi;

{$R 'resources\resources.res' 'resources\resources.rc'}
{$APPTYPE Console}

uses
  Classes,
  SysUtils,
  Windows,
  IniFiles,
  ActiveObjectEngine in 'ActiveObjectEngine.pas',
  DirWatcher in 'DirWatcher.pas',
  TestCommand in 'TestCommand.pas',
  GrowlNotification in 'GrowlNotification.pas',
  PrjConst in 'PrjConst.pas',
  AutoTestThread in 'AutoTestThread.pas';

{$R *.res}
var
  // MainController : IController;
  FAutoTestThread: TAutoTestThread;
  FTestProject: string;
  FDirectoryToWatch: string;
  FDCC32ExePath: string;
  FTerminate: Boolean;
  LoadResult: Byte;

const
  C_INI_NAME = 'autotest.ini';
  C_INI_SECTION = 'autotest';

function console_handler( dwCtrlType: DWORD ): BOOL; stdcall;
begin
  // Avoid terminating with Ctrl+C
  if dwCtrlType in [CTRL_C_EVENT, CTRL_CLOSE_EVENT] then
  begin
    Writeln('Closing application...');
    FAutoTestThread.Terminate;
    FTerminate := true;
    result := TRUE;
    SetConsoleCtrlHandler(@console_handler, false);
  end
  else
    result := FALSE;
end;

function LoadIni: Byte;
var
  ini: TMemInifile;
begin
  if FileExists(C_INI_NAME) then
  begin
    try
      ini := TMemIniFile.Create(C_INI_NAME);
      if ini.SectionExists(C_INI_SECTION) then
      begin
        if ini.ValueExists(C_INI_SECTION, 'TestProject') then
        begin
          FTestProject := ini.ReadString(C_INI_SECTION, 'TestProject', EmptyStr);
          if FileExists(FTestProject) then
          begin
            if ini.ValueExists(C_INI_SECTION, 'DirectoryToWatch') then
            begin
              FDirectoryToWatch := ini.ReadString(C_INI_SECTION, 'DirectoryToWatch', EmptyStr);
              if DirectoryExists(FDirectoryToWatch) then
              begin
                if ini.ValueExists(C_INI_SECTION, 'DCC32Exe') then
                begin
                  FDCC32ExePath := ini.ReadString(C_INI_SECTION, 'DCC32Exe', EmptyStr);
                  if FileExists(FDCC32ExePath) then
                  begin
                    if (LowerCase(ExtractFileName(FDCC32ExePath)) = 'dcc32.exe') then
                      Result := 0
                    else
                      Result := 9;
                  end
                  else
                    Result := 8;
                end
                else
                  Result := 7;                
              end
              else
                Result := 6;
            end
            else
              Result := 5;
          end
          else
            Result := 4;
        end
        else
          Result := 3;
      end
      else
        Result := 2;
    finally
      FreeAndNil(ini);
    end;
  end
  else
    Result := 1;
end;

begin
  LoadResult := LoadIni;

  case LoadResult of
    1: Writeln('autotest.ini not found!');
    2: Writeln('Error parsing autotest.ini: Section [autotest] not found!');
    3: Writeln('Error parsing autotest.ini: no TestProject in Section [autotest]!');
    4: Writeln(Format('TestProject "%s" not found!', [FTestProject]));
    5: Writeln('Error parsing autotest.ini: no DirectoryToWatch in Section [autotest]!');
    6: Writeln(Format('Directory "%s" not found!', [FDirectoryToWatch]));
    7: Writeln('Error parsing autotest.ini: no DCC32Exe in Section [autotest]!');
    8: Writeln(Format('DCC32.exe "%s" not found!', [FDCC32ExePath]));
    9: Writeln(Format('"%s" is not a dcc32.exe!', [FDCC32ExePath]));
  else
    SetConsoleCtrlHandler(@console_handler, true);
    FTerminate := false;

    FAutoTestThread := TAutoTestThread.Create(FDirectoryToWatch, FTestProject, FDCC32ExePath);
    FAutoTestThread.Resume;

    while not FTerminate do
      CheckSynchronize(10);
  end;
end.
