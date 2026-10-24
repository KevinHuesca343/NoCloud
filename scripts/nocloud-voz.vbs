' NoCloud - habla con Piper (voz propia guardada en la USB).
' Guarda cada frase ya generada en voz\cache para que la siguiente vez suene casi al instante.
' Si Piper no funciona, usa una voz en espanol de Windows como respaldo.
On Error Resume Next

Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")
q = Chr(34)

carpeta = fso.GetParentFolderName(WScript.ScriptFullName)
voz = carpeta & "\voz"

' Usa el primer archivo .onnx que haya en la carpeta voz
modelo = ""
If fso.FolderExists(voz) Then
    For Each archivo In fso.GetFolder(voz).Files
        If LCase(fso.GetExtensionName(archivo.Name)) = "onnx" Then
            modelo = archivo.Path
            Exit For
        End If
    Next
End If

texto = ""
If WScript.Arguments.Count > 0 Then texto = WScript.Arguments(0)
If texto = "" Then WScript.Quit

Function Limpiar(t)
    For Each c In Array("&", "|", "<", ">", "^", "%", Chr(34))
        t = Replace(t, c, "")
    Next
    Limpiar = t
End Function

Function NombreSeguro(t)
    r = ""
    For i = 1 To Len(t)
        ch = Mid(t, i, 1)
        If (ch >= "a" And ch <= "z") Or (ch >= "A" And ch <= "Z") Or (ch >= "0" And ch <= "9") Then
            r = r & ch
        Else
            r = r & "_"
        End If
    Next
    NombreSeguro = Left(r, 60)
End Function

Sub Registrar(m)
    Set f = fso.OpenTextFile(carpeta & "\nocloud-voz.log", 2, True)
    f.WriteLine Now & " - " & m
    f.Close
End Sub

' Reproduce un .wav sin abrir ventanas. Devuelve True si logro reproducirlo.
Function Reproducir(wav)
    Reproducir = False
    sono = False

    Err.Clear
    Set p = CreateObject("WMPlayer.OCX")
    If Err.Number = 0 Then
        p.settings.volume = 100
        p.URL = wav
        p.controls.play
        t = 0
        Do
            WScript.Sleep 100
            t = t + 1
            estado = p.playState
            If estado = 3 Or estado = 8 Then sono = True
        Loop While (t < 5 Or estado = 3 Or estado = 9 Or estado = 6 Or estado = 0) And t < 200
        p.Close
        If sono Then
            Reproducir = True
            Exit Function
        End If
    End If

    ' Plan B: PowerShell (mas lento al arrancar)
    Err.Clear
    ps = "powershell -NoProfile -Command " & q & "(New-Object Media.SoundPlayer '" & wav & "').PlaySync()" & q
    sh.Run ps, 0, True
    If Err.Number = 0 Then Reproducir = True
End Function

' --- Buscar piper.exe en las ubicaciones posibles ---
piperExe = ""
candidatas = Array(voz & "\piper_windows_amd64\piper\piper.exe", voz & "\piper_windows_amd64\piper.exe", voz & "\piper\piper.exe", voz & "\piper.exe")
For Each c In candidatas
    If fso.FileExists(c) Then
        piperExe = c
        Exit For
    End If
Next

hablado = False

' --- Intento 1: Piper (con cache) ---
If piperExe <> "" And modelo <> "" Then
    carpetaCache = voz & "\cache"
    If Not fso.FolderExists(carpetaCache) Then fso.CreateFolder carpetaCache

    usaCache = fso.FolderExists(carpetaCache)
    If usaCache Then
        wav = carpetaCache & "\" & NombreSeguro(Limpiar(texto)) & "_" & fso.GetBaseName(modelo) & ".wav"
    Else
        wav = fso.GetSpecialFolder(2) & "\nocloud_voz.wav"
    End If

    desdeCache = fso.FileExists(wav)

    If Not desdeCache Then
        sh.CurrentDirectory = fso.GetParentFolderName(piperExe)
        cmd = "cmd /c echo " & Limpiar(texto) & " | " & q & piperExe & q & " --model " & q & modelo & q & " --output_file " & q & wav & q
        sh.Run cmd, 0, True
    End If

    If fso.FileExists(wav) Then
        If fso.GetFile(wav).Size > 1000 Then
            If Reproducir(wav) Then hablado = True
        Else
            fso.DeleteFile wav, True
        End If
        If hablado And Not usaCache Then fso.DeleteFile wav, True
    End If
End If

If hablado Then
    If desdeCache Then
        Registrar "Piper OK (desde cache)"
    Else
        Registrar "Piper OK (audio generado y guardado)"
    End If
    WScript.Quit
End If

Registrar "Piper no funciono. piper.exe=[" & piperExe & "] modelo=[" & modelo & "]. Usando voz de Windows."

' --- Intento 2: voz de Windows en espanol ---
Set voces = CreateObject("SAPI.SpVoice")
elegida = False
Set candidatasVoz = voces.GetVoices("Language=80A")
If candidatasVoz.Count > 0 Then
    Set voces.Voice = candidatasVoz.Item(0)
    elegida = True
End If
If Not elegida Then
    For Each v In voces.GetVoices
        If InStr(v.GetDescription, "Spanish") > 0 Then
            Set voces.Voice = v
            Exit For
        End If
    Next
End If
voces.Speak texto
