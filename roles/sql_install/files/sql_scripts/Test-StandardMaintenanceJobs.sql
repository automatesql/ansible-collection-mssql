USE msdb
GO
if (select count(j.name) from dbo.sysjobs AS j
inner join dbo.syscategories AS c
 on j.category_id = c.category_id
where c.name IN ('Database Maintenance','Policy Based Management')) > 0
BEGIN
	PRINT 'Maintenance jobs exists.  Skipping...............'
END
ELSE
 BEGIN
	  RAISERROR('Creating the standard maintenance jobs.',16,1)
END

