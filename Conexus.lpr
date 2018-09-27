program Conexus;

{$mode objfpc}{$H+}
{$MACRO ON}

{____________________________________________________________
|  _______________________________________________________  |
| |                                                       | |
| |       Remote for Frontier Silicon based devices       | |
| | (c) 2018 Alexander Feuster (alexander.feuster@web.de) | |
| |             http://www.github.com/feuster             | |
| |_______________________________________________________| |
|___________________________________________________________}

//define program basics
{$DEFINE PROGVERSION:='2.4'}
//{$DEFINE PROG_DEBUG}
{___________________________________________________________}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, CustApp
  { you can add units after this },
  StrUtils, FrontierSiliconAPI;

type

  { TApp }

  TApp = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
    procedure HelpHint; virtual;
    procedure WaitPrint; virtual;
    procedure WaitClear; virtual;
  end;


const
  //program title
  STR_Title:    String = ' __________________________________________________ '+#13#10+
                         '|  ______________________________________________  |'+#13#10+
                         '| |                                              | |'+#13#10+
                         '| |**********************************************| |'+#13#10+
                         '| |  Remote for Frontier Silicon based devices   | |'+#13#10+
                         '| |          (c) 2018 Alexander Feuster          | |'+#13#10+
                         '| |        http://www.github.com/feuster         | |'+#13#10+
                         '| |______________________________________________| |'+#13#10+
                         '|__________________________________________________|'+#13#10;

  //program version
  STR_Version:    String = PROGVERSION;

  //CPU architecture
  STR_CPU:      String = {$I %FPCTARGETCPU%};

  //Build info
  STR_Build:    String = {$I %FPCTARGETOS%}+' '+{$I %FPCTARGETCPU%}+' '+{$I %DATE%}+' '+{$I %TIME%};
  {$WARNINGS OFF}
  STR_User:     String = {$I %USER%};
  {$WARNINGS ON}
  STR_Date:     String = {$I %DATE%};

  //Message strings
  STR_Info:         String = 'Info:    ';
  STR_Error:        String = 'Error:   ';
  STR_Space:        String = '         ';
  STR_Warning:      String = 'Warning: ';
  STR_WaitingMsg:   String = 'Please wait...';
  {$IFDEF PROG_DEBUG}
  STR_Debug:        String = 'Debug:   ';
  {$ENDIF}

  //Timeout
  INT_Timeout:  Integer = 1500;

var
  STR_Title_Banner: String;


{ Conexus }

procedure TApp.DoRun;
var
  ErrorMsg:   String;
  URL:        String;
  PIN:        String;
  Command:    String;
  Value:      String;
  Buffer:     String;
  Buffer2:    Byte;
  Buffer3:    TStringList;
  Buffer4:    TStringList;
  Buffer5:    Integer;

begin
  //add CPU architecture info to title
  if STR_CPU='x86_64' then
    {$IFDEF PROG_DEBUG}
    STR_Title_Banner:=StringReplace(STR_Title,'**********************************************','          Conexus V'+STR_Version+' Debug (64Bit)          ',[])
    {$ELSE}
    STR_Title_Banner:=StringReplace(STR_Title,'**********************************************','             Conexus V'+STR_Version+' (64Bit)             ',[])
    {$ENDIF}
  else if STR_CPU='i386' then
    {$IFDEF PROG_DEBUG}
    STR_Title_Banner:=StringReplace(STR_Title,'**********************************************','          Conexus V'+STR_Version+' Debug (32Bit)          ',[])
    {$ELSE}
    STR_Title_Banner:=StringReplace(STR_Title,'**********************************************','             Conexus V'+STR_Version+' (32Bit)             ',[])
    {$ENDIF}
  else
    {$IFDEF PROG_DEBUG}
    STR_Title_Banner:=StringReplace(STR_Title,'**********************************************','             Conexus V'+STR_Version+' Debug               ',[]);
    {$ELSE}
    STR_Title_Banner:=StringReplace(STR_Title,'**********************************************','                 Conexus V'+STR_Version+'                 ',[]);
    {$ENDIF}

  // quick check parameters
  ErrorMsg:=CheckOptions('hbadlnsu:p:r:w:f:c:', 'help build api devicelist license nobanner showbanner url: pin: read: write: fullraw: command: icondownload: coverdownload:');
  if ErrorMsg<>'' then begin
    //write title banner
    WriteLn(STR_Title_Banner);
    WriteLn(STR_Error+ErrorMsg);
    HelpHint;
    Terminate;
    Exit;
  end;

  // parse parameters

  //show banner if not surpressed
  if (HasOption('n', 'nobanner')=false) or (HasOption('s', 'showbanner')=true) then
    WriteLn(STR_Title_Banner);

  //exit if showbanner is called
  if HasOption('s', 'showbanner')=true then
    begin
      Terminate;
      Exit;
    end;

  //show help
  if HasOption('h', 'help') then
    begin
      WriteHelp;
      Terminate;
      Exit;
    end;

  //show build info
  if HasOption('b', 'build') then
    begin
      if STR_User<>'' then
        {$IFDEF PROG_DEBUG}
        WriteLn(STR_Info,'Build "V'+STR_Version+' '+STR_Build+'" (DEBUG) compiled by "'+STR_User+'"')
        {$ELSE}
        WriteLn(STR_Info,'Build "V'+STR_Version+' '+STR_Build+'" compiled by "'+STR_User+'"')
        {$ENDIF}
      else
        {$IFDEF PROG_DEBUG}
        WriteLn(STR_Info,'Build "V'+STR_Version+' (DEBUG) '+STR_Build+'"');
        {$ELSE}
        WriteLn(STR_Info,'Build "V'+STR_Version+' '+STR_Build+'"');
        {$ENDIF}
      Terminate;
      Exit;
    end;

  //show API info
  if HasOption('a', 'api') then
    begin
      if FSAPI_DEBUG then
        WriteLn(STR_Info,'Frontier Silicon API V'+API_Version+' (Debug)')
      else
        WriteLn(STR_Info,'Frontier Silicon API V'+API_Version);
      Terminate;
      Exit;
    end;

  //show license info
  if HasOption('l', 'license') then
    begin
      //show Conexus license
      WriteLn('Conexus V'+STR_Version+' (c) '+STR_Date[1..4]+' Alexander Feuster (alexander.feuster@web.de)'+#13#10+
              'http://www.github.com/feuster'+#13#10+
              'This program is provided "as-is" without any warranties for any data loss,'+#13#10+
              'device defects etc. Use at own risk!'+#13#10+
              'Free for personal use. Commercial use is prohibited without permission.'+#13#10);
      //show API license
      Write(API_License);
      Terminate;
      Exit;
    end;

  //list in network available Frontier Silicon devices
  if HasOption('d', 'devicelist') then
    begin
      WriteLn(STR_Info,'UPnP network scan for available Frontier Silicon devices');
      WaitPrint;
      Buffer3:=TStringList.Create;
      Buffer3:=fsapi_Info_DeviceList(INT_Timeout,true);
      WaitClear;
      if Buffer3.Count=0 then
        begin
          WriteLn(STR_Info,'First try did not found any available devices. Starting second try.');
          Buffer3:=fsapi_Info_DeviceList(INT_Timeout,true);
          WaitClear;
          if Buffer3.Count=0 then
            begin
              WriteLn(STR_Info,'No devices available!')
            end
          else
            begin
              if Buffer3.Count>0 then
                begin
                  Buffer4:=TStringList.Create;
                  Buffer4.StrictDelimiter:=true;
                  Buffer4.Delimiter:='|';
                  WriteLn('');
                  WriteLn('       IP      |                Name                |                UUID');
                  WriteLn('---------------|------------------------------------|------------------------------------');
                  for Buffer2:=0 to Buffer3.Count-1 do
                    begin
                      Buffer4.DelimitedText:=Buffer3.Strings[Buffer2];
                      WriteLn(Format('%0:-15s',[Buffer4.Strings[0]]):15,'|',Format('%0:-36s',[Buffer4.Strings[1]]):36,'|',Format('%0:-36s',[Buffer4.Strings[2]]):36);
                    end;
                  WriteLn('');
                  WriteLn('       IP      |                                 Icon URL');
                  WriteLn('---------------|-------------------------------------------------------------------------');
                  for Buffer2:=0 to Buffer3.Count-1 do
                    begin
                      Buffer4.DelimitedText:=Buffer3.Strings[Buffer2];
                      WriteLn(Format('%0:-15s',[Buffer4.Strings[0]]):15,'|',Format('%0:-73s',[Buffer4.Strings[3]]):73);
                    end;
                end;
            end;
        end
      else
        begin
          if Buffer3.Count>0 then
            begin
              Buffer4:=TStringList.Create;
              Buffer4.StrictDelimiter:=true;
              Buffer4.Delimiter:='|';
              WriteLn('');
              WriteLn('       IP      |                Name                |                UUID');
              WriteLn('---------------|------------------------------------|------------------------------------');
              for Buffer2:=0 to Buffer3.Count-1 do
                begin
                  Buffer4.DelimitedText:=Buffer3.Strings[Buffer2];
                  WriteLn(Format('%0:-15s',[Buffer4.Strings[0]]):15,'|',Format('%0:-36s',[Buffer4.Strings[1]]):36,'|',Format('%0:-36s',[Buffer4.Strings[2]]):36);
                end;
              WriteLn('');
              WriteLn('       IP      |                                 Icon URL');
              WriteLn('---------------|-------------------------------------------------------------------------');
              for Buffer2:=0 to Buffer3.Count-1 do
                begin
                  Buffer4.DelimitedText:=Buffer3.Strings[Buffer2];
                  WriteLn(Format('%0:-15s',[Buffer4.Strings[0]]):15,'|',Format('%0:-73s',[Buffer4.Strings[3]]):73);
                end;
            end;
        end;
      Terminate;
      Exit;
    end;

  { add your program here }

  //check URL
  if HasOption('u', 'url') then
    begin
      URL:=(GetOptionValue('u', 'url'));
      if AnsiPos(LowerCase('http://'),URL)<>1 then
        URL:='http://'+URL;
    end
  else
    begin
      WriteLn(STR_Error+'No URL specified');
      HelpHint;
      Terminate;
      Exit;
    end;

  //start icon download (since no PIN is needed function is started before PIN check)
  if HasOption('icondownload') then
    begin
      Buffer:=(GetOptionValue('icondownload'));
      if DirectoryExists(ExtractFilePath(Buffer))=true then
        begin
          if fsapi_Info_DeviceFileDownload(URL,Buffer)=true then
            WriteLn(STR_Info+'Icon saved to "'+Buffer+'"')
          else
            WriteLn(STR_Error+'Icon not saved');
        end
      else
        WriteLn(STR_Error+'Folder "'+ExtractFilePath(Buffer)+'" does not exist');
      Terminate;
      Exit;
    end;

  //PIN check
  if HasOption('p', 'pin') then
    begin
      PIN:=(GetOptionValue('p', 'pin'));
    end
  else
    begin
      for Buffer5:=0 to ParamCount do
        begin
          Buffer:=Buffer+ParamStr(Buffer5);
        end;
      //additional PIN check for fullraw command
      if Pos('pin=',LowerCase(Buffer))=0 then
        begin
          WriteLn(STR_Error+'No PIN specified');
          WriteLn(STR_Warning+'Trying default PIN "1234"');
          PIN:='1234';
        end;
      Buffer:='';
      Buffer5:=0;
    end;

  //start cover download
  if HasOption('coverdownload') then
    begin
      Buffer:=(GetOptionValue('coverdownload'));
      if DirectoryExists(ExtractFilePath(Buffer))=true then
        begin
          URL:=fsapi_Info_graphicUri(URL,PIN);
          if (RightStr(Buffer,1)='\') or (RightStr(Buffer,1)='/') then
            Buffer:=Buffer+ExtractFileName(URL)
          else
            Buffer:=Buffer+'/'+ExtractFileName(URL);
          if (URL<>'') and (Buffer<>'') then
            begin
              if fsapi_Info_DeviceFileDownload(URL,Buffer)=true then
                WriteLn(STR_Info+'Cover saved to "'+Buffer+'"')
              else
                WriteLn(STR_Error+'Cover not saved');
            end
          else
            WriteLn(STR_Error+'Cover not saved');
        end
      else
        WriteLn(STR_Error+'Folder "'+ExtractFilePath(Buffer)+'" does not exist');
      Terminate;
      Exit;
    end;

  //check for read command
  if HasOption('r', 'read') then
    begin
      Command:=GetOptionValue('r', 'read');
      WriteLn(STR_Info+'read by raw sending GET command '+#13#10+STR_Space+'"'+Command+'"');
      Buffer:=fsapi_RAW(URL,PIN,COMMAND);
      if Buffer<>'' then
        begin
          WriteLn(STR_Info+'XML output:');
          WriteLn('--------------------------------------------------------------------------------');
          Write(Buffer);
          WriteLn('--------------------------------------------------------------------------------');
        end
      else
        WriteLn(STR_Error+'read command "'+Command+'" failed');
      Terminate;
      Exit;
    end;

  //check for write command
  if HasOption('w', 'write') then
    begin
      Command:=GetOptionValue('w', 'write');
      Value:=MidStr(Command,AnsiPos(':',Command)+1,Length(Command)-AnsiPos(':',Command));
      Command:=StringReplace(Command,':'+Value,'',[rfReplaceAll,rfIgnoreCase]);
      WriteLn(STR_Info+'write by raw sending SET command '+#13#10+STR_Space+'"'+Command+'" with value "'+value+'"');
      Buffer:=fsapi_RAW(URL,PIN,COMMAND,true,Value);
      if Buffer<>'' then
        begin
          WriteLn(STR_Info+'XML output:');
          WriteLn('--------------------------------------------------------------------------------');
          Write(Buffer);
          WriteLn('--------------------------------------------------------------------------------');
        end
      else
        WriteLn(STR_Error+'write command "'+Command+'" failed');
      Terminate;
      Exit;
    end;

  //check for fullraw command
  if HasOption('f', 'fullraw') then
    begin
      Command:=GetOptionValue('f', 'fullraw');
      Value:=MidStr(Command,AnsiPos(':',Command)+1,Length(Command)-AnsiPos(':',Command));
      Command:=StringReplace(Command,':'+Value,'',[rfReplaceAll,rfIgnoreCase]);
      //adding PIN and SID only when no fsapi "?" arguments are given
      if Pos('?',Command)=0 then
        Command:=Command+'?pin='+PIN
      else
        begin
          if Pos('pin=',LowerCase(Command))=0 then
            Command:=Command+'&pin='+PIN;
        end;
      if Pos('&sid=',LowerCase(Command))=0 then
        begin
          Buffer:=fsapi_CreateSession(URL,PIN);
          if Buffer<>'' then
            Command:=Command+'&sid='+Buffer;
        end;
      WriteLn(STR_Info+'sending full raw HTTP command '+#13#10+STR_Space+'"'+URL+Command+'"');
      Buffer:=fsapi_RAW_URL(URL+Command);
      if Buffer<>'' then
        begin
          WriteLn(STR_Info+'XML output:');
          WriteLn('--------------------------------------------------------------------------------');
          Write(Buffer);
          WriteLn('--------------------------------------------------------------------------------');
        end
      else
        WriteLn(STR_Error+'sending full raw HTTP command '+#13#10+STR_Space+'"'+URL+Command+'" failed');
      Terminate;
      Exit;
    end;

  //check for existing command
  if HasOption('c', 'command') then
    begin
      Command:=UpperCase((GetOptionValue('c', 'command')));
    end
  else
    begin
      WriteLn(STR_Error+'No command specified');
      HelpHint;
      Terminate;
      Exit;
    end;

  //check and execute command

  //Standby on
  if Command='ON' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Standby_On(URL,PIN)=true then
        WriteLn(STR_Info+'command "'+Command+'" successful')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Standy off
  else if Command='OFF' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Standby_Off(URL,PIN)=true then
        WriteLn(STR_Info+'command "'+Command+'" successful')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Standy on/off
  else if Command='STANDBY' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Standby(URL,PIN)=true then
        WriteLn(STR_Info+'command "'+Command+'" successful')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Standy state
  else if Command='STANDBYSTATE' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Standby_State(URL,PIN)=true then
        WriteLn(STR_Info+'device active')
      else
        WriteLn(STR_Info+'device in Standby or disconnected');
    end
  //Image version
  else if Command='VERSION' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer:=fsapi_Info_ImageVersion(URL,PIN);
      if Buffer<>'' then
        WriteLn(STR_Info+'image version "'+Buffer+'"')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Get notifies
  else if Command='GETNOTIFIES' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer3:=fsapi_Info_GetNotifies(URL,PIN);
      if Buffer3.Count>0 then
        begin
          WriteLn(STR_Info+'command "'+Command+'" successful');
          WriteLn('');
          WriteLn('                      Notify                      |       Value      ');
          WriteLn('--------------------------------------------------|------------------');
          for Buffer2:=0 to Buffer3.Count-1 do
            begin
              Buffer4:=TStringList.Create;
              Buffer4.StrictDelimiter:=true;
              Buffer4.Delimiter:='|';
              Buffer4.DelimitedText:=Buffer3.Strings[Buffer2];
              WriteLn(Format('%0:-50s',[Buffer4.Strings[0]]):50,'|',Format('%0:-18s',[Buffer4.Strings[1]]):18);
            end;
        end
      else
        WriteLn(STR_Error+'command "'+Command+'" failed or no notifies available');
    end
  //Friendly name
  else if (Command='FRIENDLYNAME') or (Command='NAME') or (Command='DEVICENAME') then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer:=fsapi_Info_FriendlyName(URL,PIN);
      if Buffer<>'' then
        WriteLn(STR_Info+'friendly name "'+Buffer+'"')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //ID
  else if (Command='ID') or (Command='RADIOID') then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer:=fsapi_Info_RadioID(URL,PIN);
      if Buffer<>'' then
        WriteLn(STR_Info+'ID "'+Buffer+'"')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Mute on
  else if Command='MUTEON' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Mute_On(URL,PIN)=true then
        WriteLn(STR_Info+'command "'+Command+'" successful')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Mute off
  else if Command='MUTEOFF' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Mute_Off(URL,PIN)=true then
        WriteLn(STR_Info+'command "'+Command+'" successful')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Mute on/off
  else if Command='MUTE' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Mute(URL,PIN)=true then
        WriteLn(STR_Info+'command "'+Command+'" successful')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Mute state
  else if Command='MUTESTATE' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Mute_State(URL,PIN)=true then
        WriteLn(STR_Info+'device muted')
      else
        WriteLn(STR_Info+'device not muted or disconnected');
    end
  //PLAYPAUSE
  else if Command='PLAYPAUSE' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_PlayControl_PlayPause(URL,PIN)=true then
        WriteLn(STR_Info+'command "'+Command+'" successful')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //PLAY
  else if Command='PLAY' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_PlayControl_Play(URL,PIN)=true then
        WriteLn(STR_Info+'command "'+Command+'" successful')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //PAUSE
  else if Command='PAUSE' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_PlayControl_Pause(URL,PIN)=true then
        WriteLn(STR_Info+'command "'+Command+'" successful')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //NEXT
  else if Command='NEXT' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_PlayControl_Next(URL,PIN)=true then
        WriteLn(STR_Info+'command "'+Command+'" successful')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //PREVIOUS
  else if Command='PREVIOUS' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_PlayControl_Previous(URL,PIN)=true then
        WriteLn(STR_Info+'command "'+Command+'" successful')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Repeat on
  else if Command='REPEATON' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Repeat_On(URL,PIN)=true then
        WriteLn(STR_Info+'command "'+Command+'" successful')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Repeat off
  else if Command='REPEATOFF' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Repeat_Off(URL,PIN)=true then
        WriteLn(STR_Info+'command "'+Command+'" successful')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Repeat on/off
  else if Command='REPEAT' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Repeat(URL,PIN)=true then
        WriteLn(STR_Info+'command "'+Command+'" successful')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Repeat state
  else if Command='REPEATSTATE' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Repeat_State(URL,PIN)=true then
        WriteLn(STR_Info+'repeat mode active')
      else
        WriteLn(STR_Info+'repeat mode not active or device disconnected');
    end
  //Shuffle on
  else if Command='SHUFFLEON' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Shuffle_On(URL,PIN)=true then
        WriteLn(STR_Info+'command "'+Command+'" successful')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Shuffle off
  else if Command='SHUFFLEOFF' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Shuffle_Off(URL,PIN)=true then
        WriteLn(STR_Info+'command "'+Command+'" successful')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Shuffle on/off
  else if Command='SHUFFLE' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Shuffle(URL,PIN)=true then
        WriteLn(STR_Info+'command "'+Command+'" successful')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Shuffle state
  else if Command='SHUFFLESTATE' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Shuffle_State(URL,PIN)=true then
        WriteLn(STR_Info+'shuffle mode active')
      else
        WriteLn(STR_Info+'shuffle mode not active or device disconnected');
    end
  //Scrobble on
  else if Command='SCROBBLEON' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Scrobble_On(URL,PIN)=true then
        WriteLn(STR_Info+'command "'+Command+'" successful')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Scrobble off
  else if Command='SCROBBLEOFF' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Scrobble_Off(URL,PIN)=true then
        WriteLn(STR_Info+'command "'+Command+'" successful')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Scrobble on/off
  else if Command='SCROBBLE' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Scrobble(URL,PIN)=true then
        WriteLn(STR_Info+'command "'+Command+'" successful')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Scrobble state
  else if Command='SCROBBLESTATE' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Shuffle_State(URL,PIN)=true then
        WriteLn(STR_Info+'scrobble mode active')
      else
        WriteLn(STR_Info+'scrobble mode not active or device disconnected');
    end
  //Set new position in ms
  else if LeftStr(Command,14)='SETPOSITIONMS:' then
    begin
      try
      Buffer5:=StrToInt(StringReplace(Command,'SETPOSITIONMS:','',[rfReplaceAll,rfIgnoreCase]));
      except
        WriteLn(STR_Error+'command "'+Command+'" incorrect volume value') ;
        Terminate;
        Exit;
      end;
      WriteLn(STR_Info+'sending command "SETPOSITIONMS:'+IntToStr(Buffer5)+'"');
      if fsapi_PlayControl_SetPositionMS(URL,PIN,Buffer5)=true then
        WriteLn(STR_Info+'command "SETPOSITIONMS:'+IntToStr(Buffer5)+'" successful')
      else
        WriteLn(STR_Error+'command "SETPOSITIONMS:'+IntToStr(Buffer5)+'" failed');
    end
  //Set new position in time format hh:mm:ss
  else if LeftStr(Command,12)='SETPOSITION:' then
    begin
      try
      Buffer:=StringReplace(Command,'SETPOSITION:','',[rfReplaceAll,rfIgnoreCase]);
      if not ((MidStr(Buffer,3,1)=':') and (MidStr(Buffer,6,1)=':') and (Length(Buffer)=8)) then
        begin
          WriteLn(STR_Error+'command "'+Command+'" incorrect time format') ;
          Terminate;
          Exit;
        end;
      WriteLn(STR_Info+'sending command "SETPOSITION:'+Buffer+'"');
      if fsapi_PlayControl_SetPosition(URL,PIN,Buffer)=true then
        WriteLn(STR_Info+'command "SETPOSITION:'+Buffer+'" successful')
      else
        WriteLn(STR_Error+'command "SETPOSITION:'+Buffer+'" failed');
      except
        WriteLn(STR_Error+'command "SETPOSITION:'+Buffer+'" failed');
      end;
    end
  //Artist
  else if Command='GETARTIST' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer:=fsapi_Info_Artist(URL,PIN);
      if Buffer<>'' then
        WriteLn(STR_Info+'artist "'+Buffer+'"')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Name
  else if Command='GETNAME' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer:=fsapi_Info_Name(URL,PIN);
      if Buffer<>'' then
        WriteLn(STR_Info+'name "'+Buffer+'"')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Text
  else if Command='GETTEXT' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer:=fsapi_Info_Text(URL,PIN);
      if Buffer<>'' then
        WriteLn(STR_Info+'text "'+Buffer+'"')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Graphic URI
  else if Command='GETGRAPHICURI' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer:=fsapi_Info_graphicUri(URL,PIN);
      if Buffer<>'' then
        WriteLn(STR_Info+'graphic URI "'+Buffer+'"')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Get duration
  else if Command='GETDURATION' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer5:=fsapi_Info_Duration(URL,PIN);
      if Buffer5<>0 then
        WriteLn(STR_Info+'duration '+TimeToStr(Buffer5/MSecsPerDay))
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Get position
  else if Command='GETPOSITION' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer5:=fsapi_Info_Position(URL,PIN);
      if Buffer5<>0 then
        WriteLn(STR_Info+'position '+TimeToStr(Buffer5/MSecsPerDay))
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Play info
  else if Command='GETPLAYINFO' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer:=fsapi_Info_PlayInfo(URL,PIN);
      if Buffer<>'' then
        WriteLn(STR_Info+'actually playing "'+Buffer+'"')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Play status
  else if Command='GETPLAYSTATUS' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer2:=fsapi_Info_PlayStatus(URL,PIN);
      if Buffer2=1 then
        WriteLn(STR_Info+'play status "buffering/loading"')
      else if Buffer2=2 then
        WriteLn(STR_Info+'play status "playing"')
      else if Buffer2=3 then
        WriteLn(STR_Info+'play status "paused"')
      else if Buffer2=255 then
        WriteLn(STR_Error+'command "'+Command+'" failed')
      else
        WriteLn(STR_Info+'play status unknown') ;
    end
  //Play error
  else if Command='GETPLAYERROR' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer:=fsapi_Info_PlayError(URL,PIN);
      if Buffer<>'' then
        WriteLn(STR_Info+'play error "'+Buffer+'"')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed or no play error available');
    end
  //Time
  else if Command='TIME' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer:=fsapi_Info_Time(URL,PIN);
      if Buffer<>'' then
        WriteLn(STR_Info+'time "'+Buffer+'"')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Date
  else if Command='DATE' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer:=fsapi_Info_Date(URL,PIN);
      if Buffer<>'' then
        WriteLn(STR_Info+'date "'+Buffer+'"')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Date & Time
  else if Command='DATETIME' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer:=fsapi_Info_DateTime(URL,PIN);
      if Buffer<>'' then
        WriteLn(STR_Info+'date&time "'+Buffer+'"')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //LAN MAC address
  else if Command='LANMAC' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer:=fsapi_Info_LAN_MAC(URL,PIN);
      if Buffer<>'' then
        WriteLn(STR_Info+'LAN MAC address "'+Buffer+'"')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //WLAN MAC address
  else if Command='WLANMAC' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer:=fsapi_Info_WLAN_MAC(URL,PIN);
      if Buffer<>'' then
        WriteLn(STR_Info+'WLAN MAC address "'+Buffer+'"')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //WLAN RSSI value
  else if Command='WLANRSSI' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer:=fsapi_Info_WLAN_RSSI(URL,PIN);
      if Buffer<>'' then
        WriteLn(STR_Info+'WLAN RSSI value "'+Buffer+'"')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed or zero RSSI signal strength');
    end
  //WLAN Connected SSID
  else if Command='WLANSSID' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer:=fsapi_Info_WLAN_ConnectedSSID(URL,PIN);
      if Buffer<>'' then
        WriteLn(STR_Info+'WLAN connected AP SSID "'+Buffer+'"')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed or no connected WLAN AP SSID available');
    end
  //Volume value
  else if Command='GETVOLVALUE' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer2:=fsapi_Volume_Get(URL,PIN);
      if Buffer2=255 then
        WriteLn(STR_Error+'command "'+Command+'" failed')
      else
        WriteLn(STR_Info+'volume is set to "'+IntToStr(Buffer2)+'"');
    end
  //Get maximum supported volume steps value
  else if Command='GETVOLSTEPS' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer2:=fsapi_Volume_GetSteps(URL,PIN);
      if Buffer2=255 then
        WriteLn(STR_Error+'command "'+Command+'" failed')
      else
        WriteLn(STR_Info+'maximum supported volume is "'+IntToStr(Buffer2)+'"');
    end
  //Volume set new value
  else if LeftStr(Command,4)='VOL:' then
    begin
      if (Length(Command)>6) or (Length(Command)<5)then
        begin
          WriteLn(STR_Error+'command "'+Command+'" incorrect') ;
          Terminate;
          Exit;
        end;
      try
      Buffer2:=StrToInt(StringReplace(Command,'VOL:','',[rfReplaceAll,rfIgnoreCase]));
      except
        WriteLn(STR_Error+'command "'+Command+'" incorrect volume value') ;
        Terminate;
        Exit;
      end;
      WriteLn(STR_Info+'sending command "VOL:'+IntToStr(Buffer2)+'"');
      if fsapi_Volume_Set(URL,PIN,Buffer2)=true then
        WriteLn(STR_Info+'command "VOL:'+IntToStr(Buffer2)+'" successful')
      else
        WriteLn(STR_Error+'command "VOL:'+IntToStr(Buffer2)+'" failed');
    end
  //Volume up
  else if ((Command='VOLUP') or (Command='VOL+'))then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Volume_Up(URL,PIN)=true then
        WriteLn(STR_Info+'command "'+Command+'" successful')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Volume down
  else if ((Command='VOLDOWN') or (Command='VOL-'))then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Volume_Down(URL,PIN)=true then
        WriteLn(STR_Info+'command "'+Command+'" successful')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Mode list
  else if ((Command='MODELIST') or (Command='MODES'))then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer3:=TStringList.Create;
      Buffer3:=fsapi_Modes_Get(URL,PIN);
      if Buffer3.Count>0 then
        begin
          WriteLn(STR_Info+'command "'+Command+'" successful');
          WriteLn('');
          WriteLn(' Mode |       Label      |        ID        ');
          WriteLn('------|------------------|------------------');
          for Buffer2:=0 to Buffer3.Count-1 do
            begin
              Buffer4:=TStringList.Create;
              Buffer4.StrictDelimiter:=true;
              Buffer4.Delimiter:='|';
              Buffer4.DelimitedText:=Buffer3.Strings[Buffer2];
              WriteLn(Format('%0:-6s',[Buffer4.Strings[0]]):6,'|',Format('%0:-18s',[Buffer4.Strings[1]]):18,'|',Format('%0:-18s',[Buffer4.Strings[2]]):18);
            end;
        end
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Modes: set new active mode
  else if LeftStr(Command,5)='MODE:' then
    begin
      try //mode as numeric value
      Buffer2:=StrToInt(StringReplace(Command,'MODE:','',[rfReplaceAll,rfIgnoreCase]));
      WriteLn(STR_Info+'sending command "MODE:'+IntToStr(Buffer2)+'"');
      if fsapi_Modes_Set(URL,PIN,Buffer2)=true then
        WriteLn(STR_Info+'command "'+Command+'" successful')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
      except //mode as text value
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Modes_SetModeByAlias(URL,PIN,StringReplace(Command,'MODE:','',[rfReplaceAll,rfIgnoreCase]))=true then
        WriteLn(STR_Info+'command "'+Command+'" successful')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
      end;
    end
  //Modes: get mode value by label or ID
  else if LeftStr(Command,8)='GETMODE:' then
    begin
      Buffer2:=fsapi_Modes_GetModeByIdLabel(URL,PIN,StringReplace(Command,'GETMODE:','',[rfReplaceAll,rfIgnoreCase]));
      if Buffer2<255 then
        WriteLn(STR_Info+'command "'+Command+'" successful returned value "'+IntToStr(Buffer2)+'"')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Get active mode
  else if Command='ACTIVEMODE' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer:=fsapi_Modes_ActiveModeLabel(URL,PIN);
      if Buffer<>'' then
        WriteLn(STR_Info+'active mode "'+Buffer+'"')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Get active mode ID
  else if Command='ACTIVEMODEID' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer5:=fsapi_Modes_ActiveMode(URL,PIN);
      if Buffer5>-1 then
        WriteLn(STR_Info+'active mode "'+IntToStr(Buffer5)+'"')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //switch to next available mode
  else if Command='NEXTMODE' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Modes_NextMode(URL,PIN)=true then
        WriteLn(STR_Info+'switched to next mode')
      else
        WriteLn(STR_Info+'could not switch to next mode');
    end
  //switch to previous available mode
  else if Command='PREVIOUSMODE' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Modes_PreviousMode(URL,PIN)=true then
        WriteLn(STR_Info+'switched to previous mode')
      else
        WriteLn(STR_Info+'could not switch to previous mode');
    end
  //DAB scan
  else if Command='DABSCAN' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_DAB_Scan(URL,PIN)=true then
        WriteLn(STR_Info+'command "'+Command+'" successful')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //DAB prune
  else if Command='DABPRUNE' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_DAB_Prune(URL,PIN)=true then
        WriteLn(STR_Info+'command "'+Command+'" successful')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //DAB frequency list
  else if (Command='DABFREQ') or (Command='DABFREQUENCIES') then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer3:=TStringList.Create;
      Buffer3:=fsapi_DAB_FrequencyList(URL,PIN);
      if Buffer3.Count>0 then
        begin
          WriteLn(STR_Info+'command "'+Command+'" successful');
          WriteLn('');
          WriteLn(' ID | Frequency | Label ');
          WriteLn('----|-----------|-------');
          for Buffer2:=0 to Buffer3.Count-1 do
            begin
              Buffer4:=TStringList.Create;
              Buffer4.StrictDelimiter:=true;
              Buffer4.Delimiter:='|';
              Buffer4.DelimitedText:=Buffer3.Strings[Buffer2];
              WriteLn(Format('%0:-4s',[Buffer4.Strings[0]]):4,'|',Format('%0:-11s',[Buffer4.Strings[1]]):11,'|',Format('%0:-7s',[Buffer4.Strings[2]]):7);
            end;
        end
      else
        WriteLn(STR_Error+'command "'+Command+'" failed or no preset list available');
    end
  //Preset list
  else if (Command='PRESETLIST') or (Command='PRESETS') then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer3:=TStringList.Create;
      Buffer3:=fsapi_Presets_List(URL,PIN);
      if Buffer3.Count>0 then
        begin
          WriteLn(STR_Info+'command "'+Command+'" successful');
          WriteLn('');
          WriteLn(' ID |                Name');
          WriteLn('----|------------------------------------');
          for Buffer2:=0 to Buffer3.Count-1 do
            begin
              Buffer4:=TStringList.Create;
              Buffer4.StrictDelimiter:=true;
              Buffer4.Delimiter:='|';
              Buffer4.DelimitedText:=Buffer3.Strings[Buffer2];
              WriteLn(Format('%0:-4s',[Buffer4.Strings[0]]):4,'|',Format('%0:-36s',[Buffer4.Strings[1]]):36);
            end;
        end
      else
        WriteLn(STR_Error+'command "'+Command+'" failed or no preset list available');
    end
  //select Preset
  else if (LeftStr(Command,13)='PRESETSELECT:') or (LeftStr(Command,7)='PRESET:') then
    begin
      try
      Command:=StringReplace(Command,'PRESETSELECT:','',[rfReplaceAll,rfIgnoreCase]);
      Command:=StringReplace(Command,'PRESET:','',[rfReplaceAll,rfIgnoreCase]);
      Buffer2:=StrToInt(Command);
      except
        WriteLn(STR_Error+'command "'+Command+'" incorrect preset value') ;
        Terminate;
        Exit;
      end;
      WriteLn(STR_Info+'sending command "PRESETSELECT:'+IntToStr(Buffer2)+'"');
      if fsapi_Presets_Set(URL,PIN,Buffer2)=true then
        WriteLn(STR_Info+'command "PRESETSELECT:'+IntToStr(Buffer2)+'" successful')
      else
        WriteLn(STR_Error+'command "PRESETSELECT:'+IntToStr(Buffer2)+'" failed');
    end
  //add Preset
  else if LeftStr(Command,10)='PRESETADD:' then
    begin
      try
      Command:=StringReplace(Command,'PRESETADD:','',[rfReplaceAll,rfIgnoreCase]);
      Buffer2:=StrToInt(Command);
      except
        WriteLn(STR_Error+'command "'+Command+'" incorrect preset value') ;
        Terminate;
        Exit;
      end;
      WriteLn(STR_Info+'sending command "PRESETADD:'+IntToStr(Buffer2)+'"');
      if fsapi_Presets_Add(URL,PIN,Buffer2)=true then
        WriteLn(STR_Info+'command "PRESETADD:'+IntToStr(Buffer2)+'" successful')
      else
        WriteLn(STR_Error+'command "PRESETADD:'+IntToStr(Buffer2)+'" failed');
    end
  //switch to next available Preset
  else if Command='NEXTPRESET' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Presets_NextPreset(URL,PIN)=true then
        WriteLn(STR_Info+'switched to next preset')
      else
        WriteLn(STR_Info+'could not switch to next preset');
    end
  //switch to previous available Preset
  else if Command='PREVIOUSPRESET' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Presets_PreviousPreset(URL,PIN)=true then
        WriteLn(STR_Info+'switched to previous preset')
      else
        WriteLn(STR_Info+'could not switch to previous Preset');
    end
  //Update info
  else if Command='UPDATEINFO' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer:=fsapi_Info_DeviceUpdateInfo(URL,PIN);
      if Buffer<>'' then
        begin
          WriteLn(STR_Info+'command "'+Command+'" successful');
          WriteLn(STR_Info+'XML output:');
          WriteLn('--------------------------------------------------------------------------------');
          Write(Buffer);
          WriteLn('--------------------------------------------------------------------------------');
        end
      else
        WriteLn(STR_Info+'No update available or command "'+Command+'" failed');
    end
  //LAN interface enabled info
  else if Command='LANSTATUS' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Info_LAN_Enabled(URL,PIN)=true then
        WriteLn(STR_Info+'LAN interface enabled')
      else
        WriteLn(STR_Info+'LAN interface not enabled or command failed');
    end
  //WLAN interface enabled info
  else if Command='WLANSTATUS' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Info_WLAN_Enabled(URL,PIN)=true then
        WriteLn(STR_Info+'WLAN interface enabled')
      else
        WriteLn(STR_Info+'WLAN interface not enabled or command failed');
    end
  //Update info
  else if Command='INTERFACES' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer:=fsapi_Info_Network_Interfaces(URL,PIN);
      if Buffer<>'' then
        WriteLn(STR_Info+'enabled network interfaces: "'+Buffer+'"')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Factory reset
  else if Command='FACTORYRESET' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_FACTORY_RESET(URL,PIN)=true then
        begin
          WriteLn(STR_Info+'Factory reset activated. Your device should be in Setup mode now.');
          WriteLn(STR_Info+'Use your default app to setup your device again.')
        end
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Device ID
  else if Command='DEVICEID' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer:=fsapi_Info_DeviceID(URL,PIN);
      if Buffer<>'' then
        WriteLn(STR_Info+'device ID "'+Buffer+'"')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Navigation list
  else if Command='NAVLIST' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer3:=TStringList.Create;
      Buffer3:=fsapi_Nav_List(URL,PIN);
      if Buffer3.Count>0 then
        begin
          WriteLn(STR_Info+'command "'+Command+'" successful');
          WriteLn('');
          WriteLn(' ID |                Name                |  Type   | Subtype ');
          WriteLn('----|------------------------------------|---------|---------');
          for Buffer2:=0 to Buffer3.Count-1 do
            begin
              Buffer4:=TStringList.Create;
              Buffer4.StrictDelimiter:=true;
              Buffer4.Delimiter:='|';
              Buffer4.DelimitedText:=Buffer3.Strings[Buffer2];
              WriteLn(Format('%0:-4s',[Buffer4.Strings[0]]):4,'|',Format('%0:-36s',[Buffer4.Strings[1]]):36,'|',Format('%0:-9s',[Buffer4.Strings[2]]):9,'|',Format('%0:-9s',[Buffer4.Strings[3]]):9);
            end;
        end
      else
        WriteLn(STR_Error+'command "'+Command+'" failed or no list available');
    end
  //select navigation item (must be type = 0)
  else if LeftStr(Command,16)='NAVITEMNAVIGATE:' then
    begin
      try
      Buffer2:=StrToInt(StringReplace(Command,'NAVITEMNAVIGATE:','',[rfReplaceAll,rfIgnoreCase]));
      except
        WriteLn(STR_Error+'command "'+Command+'" incorrect navigation item value') ;
        Terminate;
        Exit;
      end;
      WriteLn(STR_Info+'sending command "NAVITEMNAVIGATE:'+IntToStr(Buffer2)+'"');
      if fsapi_Nav_Navigate(URL,PIN,Buffer2)=true then
        WriteLn(STR_Info+'command "NAVITEMNAVIGATE:'+IntToStr(Buffer2)+'" successful')
      else
        WriteLn(STR_Error+'command "NAVITEMNAVIGATE:'+IntToStr(Buffer2)+'" failed');
    end
  //select navigation item (must be type > 0)
  else if LeftStr(Command,14)='NAVITEMSELECT:' then
    begin
      try
      Buffer2:=StrToInt(StringReplace(Command,'NAVITEMSELECT:','',[rfReplaceAll,rfIgnoreCase]));
      except
        WriteLn(STR_Error+'command "'+Command+'" incorrect navigation item value') ;
        Terminate;
        Exit;
      end;
      WriteLn(STR_Info+'sending command "NAVITEMSELECT:'+IntToStr(Buffer2)+'"');
      if fsapi_Nav_SelectItem(URL,PIN,Buffer2)=true then
        WriteLn(STR_Info+'command "NAVITEMSELECT:'+IntToStr(Buffer2)+'" successful')
      else
        WriteLn(STR_Error+'command "NAVITEMSELECT:'+IntToStr(Buffer2)+'" failed');
    end
  //Get navigation caps
  else if Command='NAVCAPS' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer5:=fsapi_Nav_Caps(URL,PIN);
      if Buffer5>-1 then
        WriteLn(STR_Info+'caps "'+IntToStr(Buffer5)+'"')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed or no caps available');
    end
  //Get navigation item count
  else if Command='NAVNUMITEMS' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer5:=fsapi_Nav_NumItems(URL,PIN);
      if Buffer5>-1 then
        WriteLn(STR_Info+'number of navigation items "'+IntToStr(Buffer5)+'"')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed or no items available');
    end
  //Navigation status
  else if Command='NAVSTATUS' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer5:=fsapi_Nav_Status(URL,PIN);
      if Buffer5>-1 then
        WriteLn(STR_Info+'navigation status "'+IntToStr(Buffer5)+'"')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed or navigation status not available');
    end
  //Get FM highest allowed frequency
  else if Command='FMUPPERCAP' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer5:=fsapi_FM_FreqRange_UpperCap(URL,PIN);
      if Buffer5>-1 then
        WriteLn(STR_Info+'highest allowed FM frequency "'+IntToStr(Buffer5)+'" kHz')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed or no items available');
    end
  //Get FM lowest allowed frequency
  else if Command='FMLOWERCAP' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer5:=fsapi_FM_FreqRange_LowerCap(URL,PIN);
      if Buffer5>-1 then
        WriteLn(STR_Info+'lowest allowed FM frequency "'+IntToStr(Buffer5)+'" kHz')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed or no items available');
    end
  //Get FM allowed frequency steps
  else if Command='FMSTEPS' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer5:=fsapi_FM_FreqRange_Steps(URL,PIN);
      if Buffer5>-1 then
        WriteLn(STR_Info+'allowed FM frequency step size "'+IntToStr(Buffer5)+'" kHz')
      else
        WriteLn(STR_Error+'command "'+Command+'" failed or no items available');
    end
  //System state
  else if Command='SYSSTATE' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer5:=fsapi_Sys_State(URL,PIN);
      if Buffer5>-1 then
        WriteLn(STR_Info+'system state "'+IntToStr(Buffer5)+'"')
      else
        WriteLn(STR_Info+'command "'+Command+'" failed or system state not available');
    end
  //set new frequency
  else if LeftStr(Command,10)='FMSETFREQ:' then
    begin
      try
      Buffer5:=StrToInt(StringReplace(Command,'FMSETFREQ:','',[rfReplaceAll,rfIgnoreCase]));
      except
        WriteLn(STR_Error+'command "'+Command+'" incorrect navigation item value') ;
        Terminate;
        Exit;
      end;
      WriteLn(STR_Info+'sending command "FMSETFREQ:'+IntToStr(Buffer5)+'"');
      if fsapi_FM_SetFrequency(URL,PIN,Buffer5)=true then
        WriteLn(STR_Info+'command "FMSETFREQ:'+IntToStr(Buffer5)+'" successful')
      else
        WriteLn(STR_Error+'command "FMSETFREQ:'+IntToStr(Buffer5)+'" failed');
    end
  //get frequency
  else if Command='FMGETFREQ' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer5:=fsapi_FM_GetFrequency(URL,PIN);
      if Buffer5>-1 then
        WriteLn(STR_Info+'actual FM frequency "'+IntToStr(Buffer5)+'"')
      else
        WriteLn(STR_Info+'command "'+Command+'" failed or actual FM frequency not available');
    end
  //set new sleeptimer
  else if LeftStr(Command,14)='SETSLEEPTIMER:' then
    begin
      try
      Buffer5:=StrToInt(StringReplace(Command,'SETSLEEPTIMER:','',[rfReplaceAll,rfIgnoreCase]));
      except
        WriteLn(STR_Error+'command "'+Command+'" incorrect seconds value') ;
        Terminate;
        Exit;
      end;
      WriteLn(STR_Info+'sending command "SETSLEEPTIMER:'+IntToStr(Buffer5)+'"');
      if fsapi_Sys_SetSleepTimer(URL,PIN,Buffer5)=true then
        WriteLn(STR_Info+'command "SETSLEEPTIMER:'+IntToStr(Buffer5)+'" successful')
      else
        WriteLn(STR_Error+'command "SETSLEEPTIMER:'+IntToStr(Buffer5)+'" failed');
    end
  //get sleeptimer time
  else if Command='GETSLEEPTIMER' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer5:=fsapi_Sys_GetSleepTimer(URL,PIN);
      if Buffer5>-1 then
        begin
          if Buffer5>0 then
            WriteLn(STR_Info+'sleeptimer in "'+IntToStr(Buffer5)+'" seconds')
          else
            WriteLn(STR_Info+'sleeptimer is "off"')
        end
      else
        WriteLn(STR_Error+'command "'+Command+'" failed');
    end
  //Equalizer preset list
  else if (Command='EQPRESETLIST') or (Command='EQPRESETS') then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer3:=TStringList.Create;
      Buffer3:=fsapi_Equalizer_Presets_List(URL,PIN);
      if Buffer3.Count>0 then
        begin
          WriteLn(STR_Info+'command "'+Command+'" successful');
          WriteLn('');
          WriteLn(' ID |        Equalizer Preset Name');
          WriteLn('----|------------------------------------');
          for Buffer2:=0 to Buffer3.Count-1 do
            begin
              Buffer4:=TStringList.Create;
              Buffer4.StrictDelimiter:=true;
              Buffer4.Delimiter:='|';
              Buffer4.DelimitedText:=Buffer3.Strings[Buffer2];
              WriteLn(Format('%0:-4s',[Buffer4.Strings[0]]):4,'|',Format('%0:-36s',[Buffer4.Strings[1]]):36);
            end;
        end
      else
        WriteLn(STR_Error+'command "'+Command+'" failed or no equalizer preset list available');
    end
  //Equalizer bands list
  else if (Command='EQBANDSLIST') or (Command='EQBANDS') then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer3:=TStringList.Create;
      Buffer3:=fsapi_Equalizer_Bands_List(URL,PIN);
      if Buffer3.Count>0 then
        begin
          WriteLn(STR_Info+'command "'+Command+'" successful');
          WriteLn('');
          WriteLn(' ID |        Equalizer Preset Name       | Min | Max ');
          WriteLn('----|------------------------------------|-----|-----');
          for Buffer2:=0 to Buffer3.Count-1 do
            begin
              Buffer4:=TStringList.Create;
              Buffer4.StrictDelimiter:=true;
              Buffer4.Delimiter:='|';
              Buffer4.DelimitedText:=Buffer3.Strings[Buffer2];
              WriteLn(Format('%0:-4s',[Buffer4.Strings[0]]):4,'|',Format('%0:-36s',[Buffer4.Strings[1]]):36,'|',Format('%0:-5s',[Buffer4.Strings[2]]):5,'|',Format('%0:-5s',[Buffer4.Strings[3]]):5);
            end;
        end
      else
        WriteLn(STR_Error+'command "'+Command+'" failed or no equalizer preset list available');
    end
  //get active equalizer ID
  else if Command='GETEQUALIZER' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer2:=fsapi_Equalizer_Get(URL,PIN);
      if Buffer2<255 then
        begin
          WriteLn(STR_Info+'active equalizer "'+IntToStr(Buffer2)+'"')
        end
      else
        WriteLn(STR_Error+'command "'+Command+'" failed or no equalizer value available');
    end
  //set new equalizer mode
  else if LeftStr(Command,13)='SETEQUALIZER:' then
    begin
      try
      Buffer5:=StrToInt(StringReplace(Command,'SETEQUALIZER:','',[rfReplaceAll,rfIgnoreCase]));
      except
        WriteLn(STR_Error+'command "'+Command+'" incorrect ID value') ;
        Terminate;
        Exit;
      end;
      WriteLn(STR_Info+'sending command "SETEQUALIZER:'+IntToStr(Buffer5)+'"');
      if fsapi_Equalizer_Set(URL,PIN,Buffer5)=true then
        WriteLn(STR_Info+'command "SETEQUALIZER:'+IntToStr(Buffer5)+'" successful')
      else
        WriteLn(STR_Error+'command "SETEQUALIZER:'+IntToStr(Buffer5)+'" failed');
    end
  //get custom equalizer 0 value
  else if Command='GETCUSTOMEQ0' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer5:=fsapi_Equalizer_CustomParam0_Get(URL,PIN);
      if Buffer5<255 then
        begin
          WriteLn(STR_Info+'custom equalizer 0 value "'+IntToStr(Buffer5)+'"')
        end
      else
        WriteLn(STR_Error+'command "'+Command+'" failed or no custom equalizer 0 value available');
    end
  //set custom equalizer 0 value
  else if LeftStr(Command,13)='SETCUSTOMEQ0:' then
    begin
      try
      Buffer5:=StrToInt(StringReplace(Command,'SETCUSTOMEQ0:','',[rfReplaceAll,rfIgnoreCase]));
      except
        WriteLn(STR_Error+'command "'+Command+'" incorrect value') ;
        Terminate;
        Exit;
      end;
      WriteLn(STR_Info+'sending command "SETCUSTOMEQ0:'+IntToStr(Buffer5)+'"');
      if fsapi_Equalizer_CustomParam0_Set(URL,PIN,Buffer5)=true then
        WriteLn(STR_Info+'command "SETCUSTOMEQ0:'+IntToStr(Buffer5)+'" successful')
      else
        WriteLn(STR_Error+'command "SETCUSTOMEQ0:'+IntToStr(Buffer5)+'" failed');
    end
  //get custom equalizer 1 value
  else if Command='GETCUSTOMEQ1' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      Buffer5:=fsapi_Equalizer_CustomParam1_Get(URL,PIN);
      if Buffer5<255 then
        begin
          WriteLn(STR_Info+'custom equalizer 1 value "'+IntToStr(Buffer5)+'"')
        end
      else
        WriteLn(STR_Error+'command "'+Command+'" failed or no custom equalizer 1 value available');
    end
  //set custom equalizer 1 value
  else if LeftStr(Command,13)='SETCUSTOMEQ1:' then
    begin
      try
      Buffer5:=StrToInt(StringReplace(Command,'SETCUSTOMEQ1:','',[rfReplaceAll,rfIgnoreCase]));
      except
        WriteLn(STR_Error+'command "'+Command+'" incorrect value') ;
        Terminate;
        Exit;
      end;
      WriteLn(STR_Info+'sending command "SETCUSTOMEQ1:'+IntToStr(Buffer5)+'"');
      if fsapi_Equalizer_CustomParam1_Set(URL,PIN,Buffer5)=true then
        WriteLn(STR_Info+'command "SETCUSTOMEQ1:'+IntToStr(Buffer5)+'" successful')
      else
        WriteLn(STR_Error+'command "SETCUSTOMEQ1:'+IntToStr(Buffer5)+'" failed');
    end

  //Enable navigation
  else if Command='NAVENABLE' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Nav_State(URL,PIN,true)=true then
        WriteLn(STR_Info+'navigation enabled')
      else
        WriteLn(STR_Info+'command "'+Command+'" failed or navigation not enabled');
    end
  //Disable navigation
  else if Command='NAVDISABLE' then
    begin
      WriteLn(STR_Info+'sending command "'+Command+'"');
      if fsapi_Nav_State(URL,PIN,false)=true then
        WriteLn(STR_Info+'navigation disabled')
      else
        WriteLn(STR_Info+'command "'+Command+'" failed or navigation not disabled');
    end

  //unknown command
  else
    begin
      WriteLn(STR_Error+'Unknown command "'+Command+'" set');
      HelpHint;
    end;
  //clean up
  {$IFDEF PROG_DEBUG}
  if fsapi_SessionID<>'' then
    begin
      Write(STR_Debug+'Deletion of session ID "'+fsapi_SessionID+'"');
      if fsapi_DeleteSession(URL,PIN)=true then
        WriteLn(' succeeded')
      else
        WriteLn(' failed');
    end;
  {$ELSE}
  if fsapi_SessionID<>'' then
    fsapi_DeleteSession(URL,PIN);
  {$ENDIF}
  Terminate;
end;

constructor TApp.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
end;

destructor TApp.Destroy;
begin
  inherited Destroy;
end;

procedure TApp.WriteHelp;
begin
  { add your help code here }
  WriteLn('General usage:          ', ExtractFileName(ExeName), ' --url=[IP or LOCAL DOMAIN] --pin=[DEVICE PIN] --command=[COMMAND]');
  WriteLn('                        or');
  WriteLn('                        ', ExtractFileName(ExeName), ' -u [IP or LOCAL DOMAIN] -p [DEVICE PIN] -c [COMMAND]');
  WriteLn('');
  WriteLn('General usage examples: ', ExtractFileName(ExeName), ' --url=192.168.0.34 --pin=1234 --command=on');
  WriteLn('                        ', ExtractFileName(ExeName), ' -u AudioMaster.fritz.box -p 9999 -c off');
  WriteLn('                        ', ExtractFileName(ExeName), ' --url=192.168.0.34 -p 1234 -c mode:1');
  WriteLn('');
  WriteLn('Usage hints:            Some commands need additional values. These values are added with ":" after the command.');
  WriteLn('                        If a value contains one or more spaces the value must be quoted with ".');
  WriteLn('                        Examples:');
  WriteLn('                        --command="COMMAND:VALUE"');
  WriteLn('                        -w "netRemote.sys.info.friendlyName:DigitRadio 360 CD"');
  WriteLn('');
  WriteLn('List of commands:');
  WriteLn('ON                      switch device on');
  WriteLn('OFF                     switch device off');
  WriteLn('STANDBY                 toggle device state from on to off and vice versa');
  WriteLn('STANDBYSTATE            show device power state');
  WriteLn('VERSION                 show the version of the installed image');
  WriteLn('GETNOTIFIES             list device notifies if available');
  WriteLn('FRIENDLYNAME            show the device friendly name (alternative commands: NAME, DEVICENAME)');
  WriteLn('ID                      show the device (alternative command: RADIOID)');
  WriteLn('TIME                    show device time');
  WriteLn('DATE                    show device date');
  WriteLn('DATETIME                show device date&time');
  WriteLn('LANMAC                  show device LAN MAC address');
  WriteLn('LANSTATUS               show status if LAN interface is enabled or not');
  WriteLn('WLANMAC                 show device WLAN MAC address');
  WriteLn('WLANSTATUS              show status if WLAN interface is enabled or not');
  WriteLn('WLANRSSI                show device WLAN Received Signal Strength Indicator (RSSI)');
  WriteLn('WLANSSID                show the SSID (Service Set Identifier) of the connected Wireless Access Point');
  WriteLn('INTERFACES              shows which network interface is enabled ("LAN", "WLAN" or "NONE").');
  WriteLn('MUTEON                  activate mute function');
  WriteLn('MUTEOFF                 deactivate mute function');
  WriteLn('MUTE                    toggle muting state from on to off and vice versa');
  WriteLn('MUTESTATE               show device muting state');
  WriteLn('PLAY                    start playback');
  WriteLn('PAUSE                   pause playback');
  WriteLn('PLAYPAUSE               toggle playback state from play to pause and vice versa');
  WriteLn('NEXT                    play next item or track');
  WriteLn('PREVIOUS                play previous item or track');
  WriteLn('REPEATON                activate repeat function');
  WriteLn('REPEATOFF               deactivate repeat function');
  WriteLn('REPEAT                  toggle repeat function state from on to off and vice versa');
  WriteLn('REPEATSTATE             show device repeat state');
  WriteLn('SHUFFLEON               activate shuffle function');
  WriteLn('SHUFFLEOFF              deactivate shuffle function');
  WriteLn('SHUFFLE                 toggle shuffle function state from on to off and vice versa');
  WriteLn('SHUFFLESTATE            show shuffle function state');
  WriteLn('SCROBBLEON              activate scrobble function');
  WriteLn('SCROBBLEOFF             deactivate scrobble function');
  WriteLn('SCROBBLE                toggle scrobble function state from on to off and vice versa');
  WriteLn('SCROBBLESTATE           show scrobble function state');
  WriteLn('SETPOSITIONMS           set new play position in milliseconds');
  WriteLn('SETPOSITION             set new play position in time format hh:mm:ss');
  WriteLn('GETARTIST               show artist');
  WriteLn('GETNAME                 show name(title)');
  WriteLn('GETTEXT                 show text');
  WriteLn('GETGRAPHICURI           show URI for graphic (the actual cover or logo)');
  WriteLn('GETDURATION             show duration');
  WriteLn('GETPOSITION             show actual play position');
  WriteLn('GETPLAYINFO             show artist/name(title)/position/duration');
  WriteLn('GETPLAYSTATUS           show actual play status');
  WriteLn('GETPLAYERROR            show play error if available');
  WriteLn('GETVOLVALUE             show the actual set volume value');
  WriteLn('GETVOLSTEPS             show the volume step count. The maximum supported volume value should be "steps - 1".');
  WriteLn('VOL:[VALUE]             set volume to [VALUE] (allowed value range: 0-max / for max see GETMAXVOLVALUE)');
  WriteLn('VOLUP                   increase volume value (alternative command: VOL+)');
  WriteLn('VOLDOWN                 decrease volume value (alternative command: VOL-)');
  WriteLn('MODELIST                show the available device modes and their aliases (alternative command: MODES)');
  WriteLn('MODE:[VALUE]            set mode to [VALUE] (allowed values: mode number, ID or label)');
  WriteLn('NEXTMODE                switch to the next available mode');
  WriteLn('PREVIOUSMODE            switch to the previous available mode');
  WriteLn('ACTIVEMODE              get mode label for active mode');
  WriteLn('ACTIVEMODEID            get mode ID number for active mode');
  WriteLn('GETMODE:[VALUE]         get mode number for [VALUE] (allowed values: ID or label)');
  WriteLn('PRESETLIST              list stored presets (alternative command: PRESETS)');
  WriteLn('PRESETSELECT:[VALUE]    select stored preset [VALUE] (alternative command: PRESET))');
  WriteLn('PRESETADD:[VALUE]       store actual running service as preset [VALUE]');
  WriteLn('NEXTPRESET              switch to the next available preset');
  WriteLn('PREVIOUSPRESET          switch to the previous available preset');
  WriteLn('NAVENABLE               enable navigation (this must be called before navigation related commands)');
  WriteLn('NAVDISABLE              disable/end navigation (this must be called to end the actual navigation session)');
  WriteLn('NAVSTATUS               show navigation status');
  WriteLn('NAVLIST                 list available navigation items');
  WriteLn('NAVITEMNAVIGATE:[VALUE] select [VALUE] navigation item (must be type = 0 see NAVLIST)');
  WriteLn('NAVITEMSELECT:[VALUE]   select [VALUE] navigation item (must be type > 0 see NAVLIST)');
  WriteLn('NAVCAPS                 show navigation caps');
  WriteLn('NAVNUMITEMS             show navigation item count');
  WriteLn('UPDATEINFO              check if an update is available for the device and print XML output');
  WriteLn('DEVICEID                show device id (unique)');
  WriteLn('FACTORYRESET            CAUTION: this does activate the factory reset! Use your default app to setup the device again');
  WriteLn('DABSCAN                 start DAB scan');
  WriteLn('DABPRUNE                start DAB prune');
  WriteLn('DABFREQ                 show available DAB frequencies/channels (alternative command: DABFREQUENCIES)');
  WriteLn('FMUPPERCAP              show highest allowed FM frequency in kHz');
  WriteLn('FMLOWERCAP              show lowest allowed FM frequency in kHz');
  WriteLn('FMSTEPS                 show allowed FM step size in kHz');
  WriteLn('FMSETFREQ               set new FM frequency');
  WriteLn('FMGETFREQ               show actual FM frequency');
  WriteLn('SYSSTATE                show system state');
  WriteLn('GETSLEEPTIMER           show time until sleep starts (0 = sleeptimer off)');
  WriteLn('SETSLEEPTIMER:[VALUE]   show time until sleep starts ([VALUE] in seconds)');
  WriteLn('EQPRESETLIST            list stored equalizer presets (alternative command: EQPRESETS)');
  WriteLn('EQBANDSLIST             list stored custom equalizer settings (alternative command: EQBANDS)');
  WriteLn('GETEQUALIZER            show the actual active equalizer');
  WriteLn('SETEQUALIZER:[VALUE]    set an equalizer mode ([VALUE] equalizer preset ID)');
  WriteLn('GETCUSTOMEQ0            show the value for the custom equalizer 0 (in most cases this is BASS see EQBANDSLIST)');
  WriteLn('SETCUSTOMEQ0:[VALUE]    set new custom equalizer 0 [VALUE]');
  WriteLn('GETCUSTOMEQ1            show the value for the custom equalizer 1 (in most cases this is TREBLE see EQBANDSLIST)');
  WriteLn('SETCUSTOMEQ1:[VALUE]    set new custom equalizer 1 [VALUE]');
  WriteLn('');
  WriteLn('Commands hint:          not all commands are supported by all modes');
  WriteLn('');
  WriteLn('Mode aliases:');
  WriteLn('Additional to the original mode label/IDs it is possible to use optional aliases for the same mode');
  WriteLn('Example for music mode: ', ExtractFileName(ExeName), ' --url=192.168.0.34 --pin=1234 --command=mode:MUSIC');
  WriteLn('                        ', ExtractFileName(ExeName), ' --url=192.168.0.34 --pin=1234 --command=mode:MP3');
  WriteLn('                        ', ExtractFileName(ExeName), ' --url=192.168.0.34 --pin=1234 --command=mode:MP');
  WriteLn('');
  WriteLn('List of supported mode aliases:');
  WriteLn('BLUETOOTH               BLUETOOTH, BLUE, BT');
  WriteLn('AUXIN                   "AUX EINGANG", AUXIN, AUX');
  WriteLn('FM                      FM, UKW, UKWRADIO');
  WriteLn('DAB                     DAB, RADIO, DABRADIO, DIGITALRADIO');
  WriteLn('MP                      "MUSIK ABSPIELEN", MUSIK, MUSIC, MP3, MP');
  WriteLn('IR                      "INTERNET RADIO", INTERNETRADIO, INTERNET, "WEB RADIO", WEBRADIO, WEB, IR');
  WriteLn('SPOTIFY                 SPOTIFY, "SPOTIFY CONNECT", SPOT');
  WriteLn('CD                      CD, CDROM, CD-ROM, DISC, COMPACTDISC');
  WriteLn('                        for a list of default modes see command "MODELIST"');
  WriteLn('');
  WriteLn('Additional program functions:');
  WriteLn('Help:              ', ExtractFileName(ExeName), ' -h (--help)');
  WriteLn('                   Show this help text.'+#13#10);
  WriteLn('Build info:        ', ExtractFileName(ExeName), ' -b (--build)');
  WriteLn('                   Show the program build info.'+#13#10);
  WriteLn('API info:          ', ExtractFileName(ExeName), ' -a (--api)');
  WriteLn('                   Show the Frontier Silicon API info.'+#13#10);
  WriteLn('Banner:            ', ExtractFileName(ExeName), ' -n (--nobanner)');
  WriteLn('                   Hide the banner.'+#13#10);
  WriteLn('                   ', ExtractFileName(ExeName), ' -s (--showbanner)');
  WriteLn('                   Just show the banner (overrides -n --nobanner).'+#13#10);
  WriteLn('License info:      ', ExtractFileName(ExeName), ' -l (--license)');
  WriteLn('                   Show license info.'+#13#10);
  WriteLn('Device list:       ', ExtractFileName(ExeName), ' -d (--devicelist)');
  WriteLn('                   UPnP network scan of supported active devices with icon URL if available.');
  WriteLn('                   This scan may take up around to 5 seconds.'+#13#10);
  WriteLn('Read command:      ', ExtractFileName(ExeName), ' -u [IP] (--url=[IP]) -p [PIN] (--pin=[PIN]) -r [COMMAND] (--read=[COMMAND])');
  WriteLn('                   Read by sending a RAW fsapi GET command and the resulting XML output will be printed.');
  WriteLn('                   For example: ');
  WriteLn('                   ', ExtractFileName(ExeName), ' --url=192.168.0.34 --pin=1234 --read=netRemote.sys.info.friendlyName'+#13#10);
  WriteLn('Write command:     ', ExtractFileName(ExeName), ' -u [IP] (--url=[IP]) -p [PIN] (--pin=[PIN]) -w [COMMAND:VALUE] (--write=[COMMAND:VALUE])');
  WriteLn('                   Write a value by sending a RAW fsapi SET command and the resulting XML output will be printed.');
  WriteLn('                   For example: ');
  WriteLn('                   ', ExtractFileName(ExeName), ' -u 192.168.0.34 -p 1234 -w "netRemote.sys.info.friendlyName:DigitRadio 360 CD"');
  WriteLn('                   ', ExtractFileName(ExeName), ' --url=192.168.0.34 --pin=1234 --write=netRemote.sys.audio.volume:10'+#13#10);
  WriteLn('FullRAW command:   ', ExtractFileName(ExeName), ' -u [IP] (--url=[IP]) -p [PIN] (--pin=[PIN]) -f [COMMAND:VALUE] (--fullraw=[COMMAND])');
  WriteLn('                   Sends a RAW HTTP command and the resulting XML output will be printed.');
  WriteLn('                   For example: ');
  WriteLn('                   ', ExtractFileName(ExeName), ' -u 192.168.0.34 -p 1234 -f /fsapi/GET/netRemote.sys.info.version');
  WriteLn('                   Normally the PIN will be automatically added to the RAW command but the PIN can');
  WriteLn('                   also be added manually.');
  WriteLn('                   For example: ');
  WriteLn('                   ', ExtractFileName(ExeName), ' -u 192.168.0.34 -f /fsapi/GET/netRemote.sys.info.version?pin=1234');
  WriteLn('                   In most cases the session ID will also be automatically created and added to the RAW command.');
  WriteLn('                   In case the session ID should be manually added to a RAW command create a session ID first.');
  WriteLn('                   For example: ');
  WriteLn('                   ', ExtractFileName(ExeName), ' -u 192.168.0.34 -f /fsapi/CREATE_SESSION');
  WriteLn('                   Now extract the session ID from the XML output and add it manually.');
  WriteLn('                   For example: ');
  WriteLn('                   ', ExtractFileName(ExeName), ' -u 192.168.0.34 -f "/fsapi/GET/netRemote.sys.power?pin=1234&sid=1970732077"');
  WriteLn('                   In case the RAW commandline is not accepted by your terminal quote the RAW command');
  WriteLn('                   as shown above with ".');
  WriteLn('Icon download:     ', ExtractFileName(ExeName), ' -u [ICONURL] (--url=[ICONURL]) --icondownload=[LocalFilePath]');
  WriteLn('                   Download the device icon. In this case the URL must be the Icon URL and NOT only the device IP!');
  WriteLn('                   The Icon URL can be found by using -d (--devicelist) (see "Device list").'+#13#10);
  WriteLn('                   For example: ');
  WriteLn('                   ', ExtractFileName(ExeName), ' -u 192.168.0.13:8080/icon2.jpg --icondownload="C:/Icon Folder/Icon2.jpg"');
  WriteLn('Cover download:    ', ExtractFileName(ExeName), ' -u [URL] (--url=[URL]) --coverdownload=[LocalFolderPath]');
  WriteLn('                   Download an actual cover or logo graphic (see "GETGRAPHICURI").');
  WriteLn('                   In this case the URL must be only the device IP!'+#13#10);
  WriteLn('                   For example: ');
  WriteLn('                   ', ExtractFileName(ExeName), ' -u 192.168.0.13 -p 1234 --coverdownload="C:/Cover Folder/"');
end;

procedure TApp.HelpHint;
//show a hint for the help function
begin
  WriteLn(STR_Info+'Try "', ExtractFileName(ExeName), ' -h" or "', ExtractFileName(ExeName), ' --help" for a detailed help.');
  WriteLn(STR_Info+'Try "', ExtractFileName(ExeName), ' -l" or "', ExtractFileName(ExeName), ' --license" for the license.');
end;


procedure TApp.WaitPrint;
//show waiting hint
begin
  Write(STR_Info+STR_WaitingMsg);
end;

procedure TApp.WaitClear;
//clear waiting hint
begin
  Write(StringOfChar(#8, Length(STR_Info)+Length(STR_WaitingMsg))+StringOfChar(' ', Length(STR_Info)+Length(STR_WaitingMsg)));
end;

var
  Application: TApp;

begin
  Application:=TApp.Create(nil);
  Application.Run;
  Application.Free;
end.

