USE [coredb_bank]
GO
/****** Object:  StoredProcedure [dbo].[csp_get_celebrationdays]    Script Date: 2017-02-20 11:02:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- CREATED BY: SSU 2016-12-08
-- This procedure returns all persons whos date of birth is today.
-- Excluding other DoB formats other than YYMMDD-NNNN

CREATE PROCEDURE [dbo].[csp_get_celebrationdays]
	@@activecoworker INT,
	@@enddate Nvarchar(25),
	@@xml Nvarchar(max) OUTPUT,
	@@tablename Nvarchar(50),
	@@type Nvarchar(25)
	
AS
BEGIN

	-- FLAG_EXTERNALACCESS --
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @sql NVARCHAR(MAX)
	DECLARE @xml XML


	IF ISNULL(ISDATE(@@enddate),0)=1
	BEGIN
		   SELECT CAST(@@enddate as datetime)
	END

	-- Check if user is admin, add if statement if only admin should see all customers and others should see only the customers they're responsible for. (OUTCOMMENTED CODE)
	-- the queries might need some tweeking when it comes to fieldname for the responsible coworker. 
	--DECLARE @admin INT
	--SET @admin = ISNULL((SELECT idgroup 
	--						FROM [member]
	--						WHERE idgroup = 1
	--							AND iduser = (SELECT username 
	--											FROM coworker 
	--											WHERE idcoworker = @@activecoworker)), 0)

	--IF @admin = 1
	--BEGIN
	
		IF YEAR(GETDATE()) = YEAR(@@enddate)
		BEGIN

			SELECT @sql = 'SELECT @xml = (SELECT t.id' + @@tablename + ' , t.name, CAST(CAST(DAY(t.' + @@type + ') As NVARCHAR(2)) + '' '' +
																					CAST(DATENAME(MONTH, t.' + @@type + ') As NVARCHAR(3)) As NVARCHAR(12)) As [date],
																					CAST(YEAR(GETDATE()) - YEAR(t.' + @@type + ') As NVARCHAR(3)) As [age]
											FROM ' + @@tablename + ' t
											WHERE 
											((MONTH(t.' + @@type +') = MONTH(GETDATE()) AND DAY(t.' + @@type + ') >= DAY(GETDATE()) AND MONTH(GETDATE()) < MONTH(''' + @@enddate +'''))
											OR
											(MONTH(t.' + @@type + ') = MONTH(GETDATE()) AND DAY(t.' + @@type + ') >= DAY(GETDATE()) 
												AND DAY(t.' + @@type + ') <= DAY (''' + @@enddate + ''') AND MONTH(GETDATE()) = MONTH(''' + @@enddate + '''))
											OR
											(MONTH(t.' + @@type + ') > MONTH(GETDATE()) AND MONTH(t.' + @@type + ') < MONTH(''' + @@enddate + '''))
											OR
											(MONTH(t.' + @@type + ') = MONTH(''' + @@enddate + ''') AND DAY(t.' + @@type + ') <= DAY(''' + @@enddate + ''') AND MONTH(GETDATE()) <> MONTH(''' + @@enddate + ''')))
											AND (CAST(YEAR(GETDATE()) - YEAR(t.' + @@type + ') As NVARCHAR(3)) > 0)
											ORDER BY MONTH(t.' + @@type + '), DAY(t.' + @@type + ')
											FOR XML PATH(''' + @@tablename + '''), ROOT(''' + @@tablename + 's' +'''))'

		END


		ELSE IF YEAR(GETDATE()) < YEAR(@@enddate)
		BEGIN
			SELECT @sql = 'SELECT @xml = (SELECT t.id' + @@tablename + ' , t.name, CAST(CAST(DAY(t.' + @@type + ') As NVARCHAR(2)) + '' '' +
																					CAST(DATENAME(MONTH, t.' + @@type + ') As NVARCHAR(3)) As NVARCHAR(12)) As [date],
																					CAST(YEAR(GETDATE()) - YEAR(t.' + @@type + ') As NVARCHAR(3)) As [age]
									FROM ' + @@tablename + ' t
									WHERE 
									((MONTH(t.' + @@type + ') > MONTH(GETDATE())) 
									OR 
									(MONTH(t.' + @@type + ') = MONTH(GETDATE()) AND DAY(t.' + @@type + ') >= DAY(GETDATE()))
									OR
									(MONTH(t.' +@@type +') BETWEEN MONTH(DATEADD(yy, 1, (DATEADD(yy, DATEDIFF(yy,0,GETDATE()), 0)))) AND MONTH(DATEADD(M, -1, ''' + @@enddate +''')) 
										AND MONTH(DATEADD(M, -1, ''' + @@enddate +''')) <> 12)
									OR
									(MONTH(t.' + @@type + ') = MONTH(''' + @@enddate + ''') AND DAY(t.' + @@type +') <= DAY(''' + @@enddate + ''')))
									AND (CAST(YEAR(GETDATE()) - YEAR(t.' + @@type + ') As NVARCHAR(3)) > 0)
									ORDER BY MONTH(t.' + @@type + '), DAY(t.' + @@type + ')
									FOR XML PATH(''' + @@tablename + '''), ROOT(''' + @@tablename + 's' +'''))'
		END
	--END

	--ELSE IF @admin = 0 AND @@tablename <> N'coworker' --Because users are not responsible for other coworkers (often)
	--BEGIN 
	--	IF YEAR(GETDATE()) = YEAR(@@enddate)
	--	BEGIN

	--		SELECT @sql = 'SELECT @xml = (SELECT t.id' + @@tablename + ' , t.name, CAST(CAST(DAY(t.' + @@type + ') As NVARCHAR(2)) + '' '' +
	--																				CAST(DATENAME(MONTH, t.' + @@type + ') As NVARCHAR(3)) As NVARCHAR(12)) As [date],
	--																				CAST(YEAR(GETDATE()) - YEAR(t.' + @@type + ') As NVARCHAR(3)) As [age]
	--										FROM ' + @@tablename + ' t
	--										JOIN company c ON c.idcompany = t.company AND c.coworker = ' + @@activecoworker +'
	--										WHERE 
	--										(MONTH(t.' + @@type +') = MONTH(GETDATE()) AND DAY(t.' + @@type + ') > DAY(GETDATE()) AND MONTH(GETDATE()) < MONTH(' + @@enddate +'))
	--										OR
	--										(MONTH(t.' + @@type + ') > MONTH(GETDATE()) AND MONTH(t.' + @@type + ') < MONTH(''' + @@enddate + '''))
	--										OR
	--										(MONTH(t.' + @@type + ') = MONTH(' + @@enddate + ') AND DAY(t.' + @@type + ') < DAY(''' + @@enddate + '''))
	--										ORDER BY MONTH(t.' + @@type + '), DAY(t.' + @@type + ')
	--										FOR XML PATH(''' + @@tablename + '''), ROOT(''' + @@tablename + 's' +'''))'

	--	END


	--	ELSE IF YEAR(GETDATE()) < YEAR(@@enddate)
	--	BEGIN
	--		SELECT @sql = 'SELECT @xml = (SELECT t.id' + @@tablename + ' , t.name, CAST(CAST(DAY(t.' + @@type + ') As NVARCHAR(2)) + '' '' +
	--																				CAST(DATENAME(MONTH, t.' + @@type + ') As NVARCHAR(3)) As NVARCHAR(12)) As [date],
	--																				CAST(YEAR(GETDATE()) - YEAR(t.' + @@type + ') As NVARCHAR(3)) As [age]
	--								FROM ' + @@tablename + ' t
	--								JOIN company c ON c.idcompany = t.company AND c.coworker = ' + @@activecoworker +'
	--								WHERE 
	--								(MONTH(t.' + @@type + ') > MONTH(GETDATE())) 
	--								OR 
	--								(MONTH(t.' + @@type + ') = MONTH(GETDATE()) AND DAY(t.' + @@type + ') >= DAY(GETDATE()))
	--								OR
	--								(MONTH(t.' +@@type +') BETWEEN MONTH(DATEADD(yy, 1, (DATEADD(yy, DATEDIFF(yy,0,GETDATE()), 0)))) AND MONTH(DATEADD(M, -1, ''' + @@enddate +''')) 
	--									AND MONTH(DATEADD(M, -1, ''' + @@enddate +''')) <> 12)
	--								OR
	--								(MONTH(t.' + @@type + ') = MONTH(''' + @@enddate + ''') AND DAY(t.' + @@type +') <= DAY(''' + @@enddate + '''))
	--								ORDER BY MONTH(t.' + @@type + '), DAY(t.' + @@type + ')
	--								FOR XML PATH(''' + @@tablename + '''), ROOT(''' + @@tablename + 's' +'''))'
	--	END
	--END


	EXECUTE sp_executesql @sql, N'@xml XML OUTPUT', @xml = @xml OUTPUT

				
	SET @@xml = CASE WHEN @xml IS NULL THEN '' ELSE cast(@xml as Nvarchar(max)) END


END
	



