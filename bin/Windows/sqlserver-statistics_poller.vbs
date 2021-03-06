'****************About Section****************
'
'  Writes desired command & calculations into output file.
'
'  Output file format:  MetricPath MetricValue EpochTimestamp
'      MetricPath:  String representing Metric.
'           "." separates sub-groupings.
'           Should include unit of measurement.
'               eg:  CPU.User-%
'      MetricValue:  Numeric value of the output.
'           "." acceptable in the value.
'               eg:  2234
'               eg:  2234.12345
'      EpochTimestamp:  Time that measurement was taken.
'               eg:  1383148462
'
'  Suggested Directory Structure
'      .../StatsPoller/output           -> Default location of output
'      .../StatsPoller/bin/Windows      -> Default location of vbscripts
'
'  When calling from the command line
'    the following parameters are accepted and are optional.
'        Output directory (Argument 1). Path only
'        Output file (Argument 2).  File name only.
'             eg.  cscript command_poller.vbs ..\output\ command.out
'
'  Scripts may have programmed delays.  Consider this when setting up run frequency.
'
'  Author:  Judah Walker
'
'**************End About Section***************

'***********Output Location Section************
Option Explicit
On Error Goto 0

Dim strSrv, strQuery
strSrv = "."
Dim objShell, objFSO, objFile, args, outputlocation, outputfile, file
Set objShell = Wscript.CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

args = WScript.Arguments.Count

outputlocation = ".\output\"
outputfile = "sqlserver_statistics.out"
If args = 1 Then
outputlocation = WScript.Arguments.Item(1)
outputfile = "sqlserver_statistics.out"
ElseIf args = 2 Then
outputlocation = WScript.Arguments.Item(1)
outputfile = WScript.Arguments.Item(2)
End If

file = outputlocation & outputfile

Set objFile = objFSO.CreateTextFile(file, True)
GetStat(StrSrv)
GetCursor(StrSrv)
GetError(StrSrv)
'**********End Output Location Section*********

'**********Epoch Time Compute Section**********
Function TimeStamp()
	Dim myDateString
	myDateString = Now()
	Dim SecsSince
	SecsSince = CLng(DateDiff("s", "01/01/1970 00:00:00", myDateString))
	TimeStamp = SecsSince + 3600 * abs(GetTimeZoneOffset()+1)
End Function

Function GetTimeZoneOffset()
    Const sComputer = "."

    Dim oWmiService : Set oWmiService = _
        GetObject("winmgmts:{impersonationLevel=impersonate}!\\" _
                  & sComputer & "\root\cimv2")

    Dim cTimeZone : Set cTimeZone = _
        oWmiService.ExecQuery("Select * from Win32_TimeZone")

    Dim oTimeZone
    For Each oTimeZone in cTimeZone
        GetTimeZoneOffset = oTimeZone.Bias / 60
        Exit For
    Next
End Function
'********End Epoch Time Compute Section********

'****************Query Section*****************
Function GetStat(StrSrv)
      Dim objWMIService, Item, Proc, Time

      strQuery = "select * from Win32_PerfFormattedData_MSSQLSERVER_SQLServerSQLStatistics"

      Set objWMIService = GetObject("winmgmts:\\" & StrSrv & "\root\cimv2")
      Set Item = objWMIService.ExecQuery(strQuery,,48)
	  Time = CStr(TimeStamp())

     For Each Proc In Item
		 objFile.WriteLine "AutoParamAttemptsPerSecond " & Proc.AutoParamAttemptsPersec & " " & Time
		 objFile.WriteLine "FailedAutoParamsPerSecond " & Proc.FailedAutoParamsPersec & " " & Time
		 objFile.WriteLine "SafeAutoParamsPerSecond " & Proc.SafeAutoParamsPersec & " " & Time
		 objFile.WriteLine "UnsafeAutoParamsPerSecond " & Proc.UnsafeAutoParamsPersec & " " & Time
		 objFile.WriteLine "BatchRequestsPerSecond " & Proc.BatchRequestsPersec & " " & Time
		 objFile.WriteLine "SqlCompilationsPerSecond " & Proc.SQLCompilationsPersec  & " " & Time
		 objFile.WriteLine "SqlReCompilationsPerSecond " & Proc.SQLReCompilationsPersec & " " & Time
		 objFile.WriteLine "SqlAttentionRate " & Proc.SQLAttentionrate & " " & Time
    Next
End Function

Function GetCursor(StrSrv)
      Dim objWMIService, Item, Proc, Time, Comp

      strQuery = "select * from Win32_PerfFormattedData_MSSQLSERVER_SQLServerCursorManagerbyType"

      Set objWMIService = GetObject("winmgmts:\\" & StrSrv & "\root\cimv2")
      Set Item = objWMIService.ExecQuery(strQuery,,48)
	  Time = CStr(TimeStamp())

     For Each Proc In Item
		 Comp = Proc.Name
		 Comp = Replace(Comp, " ", "_")
		 objFile.WriteLine Comp & "." & "ActiveCursors " & Proc.Activecursors & " " & Time
		 objFile.WriteLine Comp & "." & "CursorRequestsPerSecond " & Proc.CursorRequestsPersec & " " & Time
    Next
End Function

Function GetError(StrSrv)
      Dim objWMIService, Item, Proc, Time, Comp

      strQuery = "select * from Win32_PerfFormattedData_MSSQLSERVER_SQLServerSQLErrors"

      Set objWMIService = GetObject("winmgmts:\\" & StrSrv & "\root\cimv2")
      Set Item = objWMIService.ExecQuery(strQuery,,48)
	  Time = CStr(TimeStamp())

     For Each Proc In Item
		 Comp = Proc.Name
		 Comp = Replace(Comp, " ", "_")
		 objFile.WriteLine Comp & "." & "ErrorsPerSecond " & Proc.ErrorsPersec & " " & Time
    Next
End Function
'**************End Query Section***************
