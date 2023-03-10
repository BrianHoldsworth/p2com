program p2c;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}
{$IFDEF MSWINDOWS}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, Crt, CustApp, IniFiles, LazLogger, GlobalUnit, DependencyHandler;

type

  { TApplication }

  TApplication = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  Application: TApplication;
  Tests: TIniFile;
  CurrentFilename: string;
  TopFilename: string;

  TopDir: string;
  CurrentDir: string;

  // Forward declare
  procedure WriteHelp(err: string=''); forward;
  procedure CompileProgram(doVerify: boolean); forward;
  procedure Compile; forward;
  procedure CompileRecursively(Filename: string; Level: integer); forward;
  procedure CompilerError(ErrorMsg: string; Loc: integer = 0); forward;
  procedure LoadCompilerFile(Filename: string); forward;
  procedure LoadFile(const Filename: string); forward;
  procedure SaveTextFile(Filename: string; Start: PByteArray; Bytes: integer); forward;
  procedure SaveFile(Filename: string; Start: Pointer; Bytes: integer); forward;
  procedure LoadObj(Filename: string); forward;

  // Color Debug output
  procedure DebugLn(const s: string; c: Byte=LightGray); overload;
  begin
    TextColor(c);
    DebugLogger.DebugLn(s);
    TextColor(LightGray);
  end;

  procedure DebugLn(const S: String; Args: array of const; c: Byte=LightGray); overload;
  begin
    TextColor(c);
    DebugLogger.DebugLn(S, Args);
    TextColor(LightGray);
  end;

{ TApplication }

// Main entry point
procedure TApplication.DoRun;
var
  ParseErr, ShortOpts: string;
  LongOpts, NonOpts: TStringArray;
  Verify: boolean;
begin
  ShortOpts:='v';
  LongOpts:=['verify'];

  // Read .ini file settings
  Tests := TIniFile.Create('.p2c_verify');

  // For managing dependency files
  Dependency := TDependencyHandler.Create;

  // Basic command parsing
  ParseErr := Application.CheckOptions(ShortOpts, LongOpts);
  if Length(ParseErr) > 1 then
  begin
    WriteHelp(ParseErr);
    Exit;
  end
  else if Length(ParseErr) = 1 then
    Verify := true;

  Nonopts := Application.GetNonOptions(ShortOpts, LongOpts);
  if Length(NonOpts) > 1 then
  begin
    WriteHelp('Too many arguments');
    Exit;
  end
  else if Length(Nonopts) = 0 then
  begin
    WriteHelp('Too few arguments');
    Exit;
  end;

  // Set Topfile
  TopFilename := Nonopts[0];
  if Topfilename='' then
  begin
    WriteHelp('No topfile for source code specified');
    Exit;
  end;
  // And verify Topfilename exists
  if not Dependency.Always(TopFilename) then
  begin
    if not TopFilename.EndsWith('.spin2') then TopFilename := TopFilename + '.spin2';
    if not Dependency.Always(TopFilename) then
    begin
      DebugLn('Top file not found: "%s"', [TopFilename], LightRed);
      Exit;
    end;
  end;

  // init p2com interface
  P2 := P2InitStruct;
  P2.List := @ListBuffer;
  P2.ListLimit := ListLimit;
  P2.Doc := @DocBuffer;
  P2.DocLimit := DocLimit;
  P2.DebugMode := false;

  CompileProgram(Verify);
  Exit;
end;

constructor TApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
end;

destructor TApplication.Destroy;
begin
  inherited Destroy;
end;

procedure WriteHelp(err: string='');
begin
  if Length(err) > 0 then WriteLn(err);
  Writeln('Usage: p2c [-v/--verify] spin2file');
  Writeln('where --verify is optional for automated compiler tests.');
end;

procedure SetFilename(const NewFilename: string);
begin
  CurrentFilename := NewFilename;
end;

procedure WriteErrorFile(s: string);
var
  f: TextFile;
begin
  AssignFile(f, 'Error.txt');
  ReWrite(f);
  WriteLn(f, s);
  CloseFile(f);
end;

/////////////////////
//  Tool Routines  //
/////////////////////

procedure SetDirectories;
begin
  if TopFilename = '' then
    TopDir := '<none>'
  else
    TopDir := IncludeTrailingPathDelimiter(ExtractFileDir(TopFilename));
  CurrentDir := IncludeTrailingPathDelimiter(GetCurrentDir());
end;

procedure CompileProgram;
var
  s: integer;
begin
  P2.DebugMode := False;
  Compile; // aborts if error
  // Compose .bin, insert interpreter?
  if not P2.PasmMode then
  begin
    P2InsertInterpreter;
    if P2.Error then CompilerError(P2.ErrorMsg);  //aborts if error
  end;
  // check to make sure program fits into hub
  s := P2.SizeObj;
  if not P2.PasmMode then s := s + P2.SizeInterpreter + P2.SizeVar + $400;
  if s > HubLimit then
    CompilerError('Program requirement exceeds ' + IntToStr(HubLimit div 1024)
      + 'KB hub RAM by ' + IntToStr(s - HubLimit) + ' bytes');  //aborts if error
  // save .bin file
  SaveFile(ExtFilename(CurrentFilename, 'bin'), @(P2.Obj), P2.ObjLength);
  DebugLn('Build successful', Green);
end;

procedure Compile;
var
  Level, i: integer;
begin
  // perform nested compilation
  SetDirectories;
  if TopFilename = '' then Level := 2 else Level := 1;
  if Level = 1 then TopFile := TopFilename else TopFile := CurrentFilename;
  P2.DownloadBaud := 2000000;
  PWordArray(@P2.DebugData)[0] := $200;         // reset debug data
  for i := 1 to 255 do PWordArray(@P2.DebugData)[i] := 0;
  P2.ObjStackPtr := 0;
  CompileRecursively(TopFile, Level);           // aborts if error
end;

procedure CompileRecursively(Filename: string; Level: integer);
var
  i, p, s: integer;

  Params: integer;
  ParamNames: array[0..ParamLimit*32-1] of byte;
  ParamTypes: array[0..ParamLimit-1] of byte;
  ParamValues: array[0..ParamLimit-1] of integer;

  ObjFiles, DatFiles: integer;
  ObjFilename, DatFilename: string;
  ObjFilenames: array[0..FileLimit-1] of string[32];
  ObjFilenamesStart: array[0..FileLimit-1] of integer;
  ObjFilenamesFinish: array[0..FileLimit-1] of integer;

  ObjParams: array[0..FileLimit-1] of integer;
  ObjParamNames: array[0..FileLimit*ParamLimit*32-1] of byte;
  ObjParamTypes: array[0..FileLimit*ParamLimit-1] of byte;
  ObjParamValues: array[0..FileLimit*ParamLimit-1] of integer;

  ObjTitle: PChar;
  f: file;
begin
  // update progress form
  DebugLn('Compiling '+ExtractFilename(Filename));
  // increment stack pointer and check for overflow (possible circular reference)
  Inc(P2.ObjStackPtr);
  if P2.ObjStackPtr > ObjStackLimit then
    CompilerError('Object nesting exceeds ' + IntToStr(ObjStackLimit) + ' levels - illegal circular reference may exist');
  // load source file and perform first pass of compilation
  LoadCompilerFile(Filename);
  P2Compile1;
  if P2.Error then begin
    CompilerError(P2.ErrorMsg, P2.SourceStart);
    Exit;
  end;
  if P2.PasmMode and (P2.ObjStackPtr > 1) then CompilerError(Filename + ' is a PASM file and cannot be used as a Spin2 object'); // aborts if error
  ObjFiles := P2.ObjFiles;
  DatFiles := P2.DatFiles;
  // ensure presence of any sub-objects' .obj files
  if ObjFiles > 0 then
  begin
    // save current parameters
    Params := P2.Params;
    Move(P2.ParamNames, ParamNames, SizeOf(ParamNames));
    Move(P2.ParamTypes, ParamTypes, SizeOf(ParamTypes));
    Move(P2.ParamValues, ParamValues, SizeOf(ParamValues));
    // save sub-objects' parameters
    Move(P2.ObjParams, ObjParams, SizeOf(ObjParams));
    Move(P2.ObjParamNames, ObjParamNames, SizeOf(ObjParamNames));
    Move(P2.ObjParamTypes, ObjParamTypes, SizeOf(ObjParamTypes));
    Move(P2.ObjParamValues, ObjParamValues, SizeOf(ObjParamValues));
    // get sub-objects' filenames
    for i := 0 to ObjFiles-1 do
    begin
      ObjFilenames[i] := PChar(@P2.ObjFilenames[i shl 8]);
      ObjFilenamesStart[i] := P2.ObjFilenamesStart[i];
      ObjFilenamesFinish[i] := P2.ObjFilenamesFinish[i];
    end;
    // compile sub-objects' .spin2 files or verify existence of .obj files
    for i := 0 to ObjFiles-1 do
    begin
      // set sub-object's parameters
      P2.Params := ObjParams[i];
      Move(ObjParamNames[i*ParamLimit*32], P2.ParamNames, ParamLimit*32);
      Move(ObjParamTypes[i*ParamLimit], P2.ParamTypes, ParamLimit);
      Move(ObjParamValues[i*ParamLimit], P2.ParamValues, ParamLimit*4);
      // compile sub-object
      if (Level = 1) and Dependency.Exists(TopDir + ObjFilenames[i] + '.spin2') then CompileRecursively(TopDir + ObjFilenames[i] + '.spin2', 1)
      else if not ((Level = 1) and FileExists(TopDir + ObjFilenames[i] + '.obj')) then
        if (Level <> 3) and Dependency.Exists(CurrentDir + ObjFilenames[i] + '.spin2') then CompileRecursively(CurrentDir + ObjFilenames[i] + '.spin2', 2)
        else if not ((Level <> 3) and FileExists(CurrentDir + ObjFilenames[i] + '.obj')) then
          // error, neither .spin2 nor .obj file found
          begin
            LoadCompilerFile(Filename);
            P2.SourceStart := ObjFilenamesStart[i];
            P2.SourceFinish := ObjFilenamesFinish[i];
            CompilerError('Cannot find .spin2 or .obj file for ' + ObjFilenames[i]);
          end;
    end;
    // restore current parameters
    P2.Params := Params;
    Move(ParamNames, P2.ParamNames, SizeOf(ParamNames));
    Move(ParamTypes, P2.ParamTypes, SizeOf(ParamTypes));
    Move(ParamValues, P2.ParamValues, SizeOf(ParamValues));
  end;
  // reload source file and reperform first pass of compilation
  LoadCompilerFile(Filename);
  P2Compile1;
  if P2.Error then begin
    CompilerError(P2.ErrorMsg, P2.SourceStart); //aborts if error
    Exit;
  end;
  // load sub-objects' .obj files
  p := 0;
  if ObjFiles > 0 then
    for i := 0 to ObjFiles-1 do
    begin
      ObjFilename := ObjFilenames[i] + '.obj';
      if (Level = 1) and FileExists(TopDir + ObjFilename) then ObjFilename := TopDir + ObjFilename
      else if (Level <> 3) and FileExists(CurrentDir + ObjFilename) then ObjFilename := CurrentDir + ObjFilename;
      AssignFile(f, ObjFilename);
      try
        try
          Reset(f, 1);
          s := FileSize(f);
          if p + s > ObjLimit then CompilerError('OBJ files exceed ' + IntToStr(ObjLimit div 1024) + 'k limit');
          BlockRead(f, P2.ObjData[p], s);
          P2.ObjOffsets[i] := p;
          P2.ObjLengths[i] := s;
          p := p + s;
        except
          CompilerError('Failure reading file ' + ObjFilename); //aborts if error
        end;
      finally
        CloseFile(f);
      end;
    end;
  // load any data files
  p := 0;
  if DatFiles > 0 then
    for i := 0 to DatFiles-1 do
    begin
      DatFilename := PChar(@P2.DatFilenames[i shl 8]);
      if (Level = 1) and Dependency.Always(TopDir + DatFilename) then DatFilename := TopDir + DatFilename
      else if (Level <> 3) and Dependency.Always(CurrentDir + DatFilename) then DatFilename := CurrentDir + DatFilename;
      AssignFile(f, DatFilename);
      DebugLn('Load DAT file ' + DatFilename);
      try
        try
          Reset(f, 1);
          s := FileSize(f);
          if p + s > ObjLimit then CompilerError('DAT files exceed ' + IntToStr(ObjLimit div 1024) + 'k limit');
          BlockRead(f, P2.DatData[p], s);
          P2.DatOffsets[i] := p;
          P2.DatLengths[i] := s;
          p := p + s;
        except
          CompilerError('Failure reading file ' + DatFilename); //aborts if error
        end;
      finally
        CloseFile(f);
      end;
    end;
  // perform second pass of compilation
  ObjTitle := @(P2.ObjTitle);
  StrCopy(ObjTitle, PChar(ExtractFilename(Filename)));
  P2Compile2;
  if P2.Error then begin
    CompilerError(P2.ErrorMsg, P2.SourceStart); //aborts if error
    Exit;
  end;
  // save obj file
  SaveFile(ExtFilename(CurrentFilename, 'obj'), @(P2.Obj), P2.ObjLength);
  // decrement stack pointer
  Dec(P2.ObjStackPtr);
end;

procedure CompilerError(ErrorMsg: string; Loc: integer);
var
  LineNum, Col: integer;
begin
  LineNum := 0;
  Col := 0;
  while Loc > 0 do
  begin
    Inc(LineNum);
    Col := Loc + 1;
    while (Loc>0) and (SourceBuffer[Loc]<>13) do
      Dec(Loc);
    Dec(Loc);
  end;
  if LineNum > 0 then
     ErrorMsg := CurrentFilename+': '+ErrorMsg+
     ' ['+IntToStr(LineNum)+','+IntToStr(Col)+']';
  DebugLn(ErrorMsg, LightRed);
end;

procedure LoadCompilerFile(Filename: string);
begin
  LoadFile(Filename);
  P2.Source := @SourceBuffer;
end;

procedure LoadFile(const Filename: string);
var
  f: TStringList;
begin
  f := TStringList.Create;
  f.DefaultEncoding := TEncoding.ANSI;
  f.LoadFromFile(Filename, TEncoding.UTF8);
  if f.Encoding=TEncoding.UTF8 then
  begin
       f.Text := Utf8ToAnsi(f.Text);
  end;
  f.TextLineBreakStyle := tlbsCR;
  StrPCopy(@SourceBuffer, f.Text);
  SetFilename(Filename);
  f.Free;
end;

procedure SaveTextFile(Filename: string; Start: PByteArray; Bytes: integer);
var
  t: TStringList;
  i: integer;
  s: string;
begin
  t := TStringList.Create;
  t.DefaultEncoding := TEncoding.ANSI;
  s := '';
  for i:=0 to Bytes-1 do
  begin
    if Start[i]=13 then
    begin
      t.Add(s);
      s := '';
      Continue;
    end;
    s := s + AnsiChar(Start[i]);
  end;
  t.Add(s);
  t.Text := AnsiToUtf8(t.Text);
  t.SaveToFile(Filename, TEncoding.UTF8);
end;

procedure SaveFile(Filename: string; Start: Pointer; Bytes: integer);
var
  f: file;
begin
  AssignFile(f, Filename);
  try
    Rewrite(f, 1);
    BlockWrite(f, Start^, Bytes);
  finally
    CloseFile(f);
  end;
end;

procedure LoadObj(Filename: string);
var
  f: file;
  Size, i: Integer;
begin
  AssignFile(f, Filename);
  try
    Reset(f, 1);
    Size := Smaller(FileSize(f), ObjLimit);
    BlockRead(f, P2.Obj, Size);
    if Size < ObjLimit then for i := Size to ObjLimit-1 do P2.Obj[i] := 0;
  finally
    CloseFile(f);
  end;
end;

begin
  Application:=TApplication.Create(nil);
  Application.DoRun;
  Application.Free;
end.

