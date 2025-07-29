if (select count(name) from sys.databases where name = 'DBA') = 0
BEGIN
	--RAISERROR ('Did not find database [DBA]', 16, 1)
	PRINT 'Did not find database [DBA].  Skipping...............'
END
ELSE
BEGIN
if (select count(*) from DBA.sys.objects where is_ms_shipped = 0) > 0
	BEGIN
	 PRINT 'Found database [DBA].  However, it contains user objects.  Skipping..'
	END
	ELSE
	BEGIN
	  RAISERROR('Found database [DBA].  Deploying objects........',16,1)
	END

END