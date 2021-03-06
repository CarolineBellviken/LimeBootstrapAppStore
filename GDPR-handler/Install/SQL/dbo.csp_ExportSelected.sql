
GO
/****** Object:  StoredProcedure [dbo].[csp_ExportSelected]    Script Date: 2017-05-10 14:45:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Rasmus Alestig Thunborg (RTH)
-- Create date: 2017-02-27
-- Description:	A procedure to allow users to export a customers or coworkers data as according to the PUL-law. 
-- =============================================
ALTER PROCEDURE [dbo].[csp_ExportSelected]
	-- Add the parameters for the stored procedure here
	@@idrecord NVARCHAR(50),
	@@activeuser INT
AS
BEGIN
	-- FLAG_EXTERNALACCESS --
	
	SET NOCOUNT ON;

		DECLARE @companydata NVARCHAR(MAX), @persondata NVARCHAR(MAX), @documentdata NVARCHAR(MAX), @helpdeskdata NVARCHAR(MAX), @historydata NVARCHAR(MAX), @xmldata NVARCHAR(MAX)

		-- Include any other fields that should be exported in the select statements below. 

		SELECT @companydata = STUFF((SELECT name, phone, postaladdress1, visitingaddress1, postalzipcode, postalcity, visitingzipcode, visitingcity, postaladdress2, visitingaddress2, customer_id, sex, personalno, mobilephone, email, email2, misc, customer_code, workphone
		FROM company
		WHERE company.idcompany = @@idrecord
		FOR xml path('')), 1, 1, '')

		SELECT @persondata = STUFF((
		SELECT p.name, p.phone, p.mobilephone, p.email
		FROM person p
		INNER JOIN company c ON c.idcompany = p.company
		WHERE c.idcompany = @@idrecord
		FOR xml path('')), 1, 1, '')
		
		SELECT @documentdata = STUFF((
		SELECT comment
		FROM document d
		INNER JOIN company c ON c.idcompany = d.company
		WHERE c.idcompany = @@idrecord
		FOR xml path('')), 1, 1, '')
	
		SELECT @helpdeskdata = STUFF((
		SELECT h.helpdeskno, h.[description]
		FROM helpdesk h
		INNER JOIN company c ON c.idcompany = h.company
		WHERE c.idcompany = @@idrecord
		FOR xml path('')), 1, 1, '')

		SELECT @historydata = STUFF((
		SELECT s.[key], h.note, 1, 100 FROM history h
		INNER JOIN company c ON c.idcompany = h.company
		INNER JOIN [string] s ON s.idstring = h.[type]
		WHERE c.idcompany = @@idrecord
		AND ( s.[key] = 'customercomment' OR s.[key] = 'fromcustomer' OR s.[key] = 'comment' OR s.[key] = 'customerservicecomment')
		FOR xml path('')), 1, 1, '')
		
		------------------------------------------------------------------			
		
		SET @xmldata = 'Registerutdrag ' 
		+ CAST(format(GETDATE(),'yyyy-mm-dd') as nvarchar(40)) + ':' + char(13) + char(13) + '<customer><' 
		+ ISNULL(@companydata, 'nocustomerdata></nocustomerdata>') + '</customer><persons><' 
		+ ISNULL(@persondata, 'nopersondata></nopersondata>')
		+ '</persons><documents><' + ISNULL(@documentdata, 'nodocumentdata></nodocumentdata>') 
		+ '</documents><helpdesk><' + ISNULL(@helpdeskdata, 'nohelpdeskdata></nohelpdeskdata>')
		+ '</helpdesk><history><' + ISNULL(@historydata, 'nohistorydata></nohistorydata>' + '</history>')
			
		INSERT INTO gdprlog ([status], createduser, [timestamp], updateduser, createdtime, [type], [datetime], responsible, company)
		VALUES(0, 1, GETDATE(), 1, GETDATE(), dbo.cfn_lc_getidstringbykey('gdprlog', 'type', 'export'), GETDATE(), @@activeuser, @@idrecord)

		INSERT INTO history([status], createduser, [timestamp], updateduser, createdtime, [type], [date], coworker, company, note)
		VALUES(0, 1, GETDATE(), 1, GETDATE(), dbo.cfn_lc_getidstringbykey('history', 'type', 'transcript'), GETDATE(), @@activeuser, @@idrecord, @xmldata)
	
END
