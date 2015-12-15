Installationsanvisning Visma Administration-integration

1. Skapa en mapp f�r installation (t.ex. c:\VismaIntegration)
2. Skapa tv� undermappar, "bin" och "export"
3. Packa upp programfilerna till undermappen "bin"
4. Ladda hem och installera Pyton 3.4 fr�n https://www.python.org/downloads/
5. Skapa en virtuel milj� i mappen som du skapade i punkt 1. 
 * C:\VismaIntegration>c:\Python34\python.exe -m venv venv
6. Aktivera milj�n
 * C:\VismaIntegration>venv\Scripts\activate.bat
7. Installera Lime Pro API klienten fr�n PyPi
 * (venv) C:\VismaIntegration>pip install limeclient
(Mer information om installationen av Python och Import-api'et finns p� http://docs.lundalogik.com/pro/integration/import/api)
8. �ppna VismaIntegrationService.exe.config och g�r milj�inst�llningarna
 * s�kv�g till Visma Gemensamma Filer-mappen
 * s�kv�g till Visma F�retags-mappen
 * s�kv�g till exportfilen f�r fakturahuvuden
 * s�kv�g till exportfilen f�r fakturarader
 * s�kv�g till python.exe i den virtuella milj�n som du satte upp i steg 5
 * LimeApi-inst�llningar
9. Installera VismaIntegrationService.exe som Windows-tj�nst
 * start->run-> cmd.exe (h�gerklick, k�r som Admin)
 * C:\windows\microsoft.net\framework\v4.0.30319>installutil c:\VismaIntegration\bin\VismaIntegrationService.exe
10. L�gg till VismaIntegrationService.exe i Windows-brandv�gg
 * Start->control panel->windows firewall->Allow an app or feature through Windows Firewall->F�lj guiden. 
11. Starta tj�nsten
 * Start->control panel->Administrative tools->Services->h�gerklick p� VismaIntegrationService, "run".
12. Kontrollera i programmets logg-fil (C:\VismaIntegration\bin\logg) att tj�nsten startat korrekt och kunde ansluta till Vismas API. 
13. F�rdig