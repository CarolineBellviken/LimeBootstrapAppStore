Public Function Initialize() As String

    
    'ropa p� sql procedur och skicka med namnet p� statusf�lt och v�rde f�ltet och f� tillbaka en xml som liknar nedan
    Dim businessXML As String

    Dim procGetBusinessvalue As LDE.Procedure
    Set procGetBusinessvalue = Application.Database.Procedures.Lookup("csp_getBusinessValue", lkLookupProcedureByName)

    procGetBusinessvalue.Parameters("@@lang").InputValue = Database.Locale
    Call procGetBusinessvalue.Execute(False)

    businessXML = procGetBusinessvalue.Result
    
    Initialize = businessXML

End Function