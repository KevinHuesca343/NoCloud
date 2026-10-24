' NoCloud - muestra las voces que tiene instaladas esta computadora
Set voz = CreateObject("SAPI.SpVoice")
texto = "Voces instaladas:" & vbCrLf & vbCrLf
For Each v In voz.GetVoices
    texto = texto & v.GetDescription & "   [idioma: " & v.GetAttribute("Language") & "]" & vbCrLf
Next
texto = texto & vbCrLf & "Voz por defecto: " & voz.Voice.GetDescription
MsgBox texto, 64, "NoCloud - Voces"
