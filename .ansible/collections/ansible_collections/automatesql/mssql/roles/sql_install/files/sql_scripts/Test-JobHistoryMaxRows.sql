declare @Results table (Value varchar(300), Data int)
declare @data int
insert into @Results
EXEC xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\SqlServerAgent', N'JobHistoryMaxRows'

select @data = data from @Results
set @data = ISNULL(@data,0)

if @data <> -1
BEGIN
	RAISERROR('SQL Server Agent job history max rows does not match the desired configuration.  Updating....',16,1)
END
ELSE
 BEGIN
	PRINT 'SQL Server Agent job history max rows matches the desired state.  Skipping.......'
END

