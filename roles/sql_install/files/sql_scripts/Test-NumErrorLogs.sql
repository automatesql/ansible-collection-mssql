declare @Results table (Value varchar(300), Data int)
declare @data int
insert into @Results
EXEC xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'NumErrorLogs'

select @data = data from @Results
set @data = ISNULL(@data,0)

if @data <> 30
BEGIN
	RAISERROR('Number of error logs does not match the desired configuration.  Updating....',16,1)
END
ELSE
 BEGIN
	PRINT 'Number of error logs matches the desired state.  Skipping.......'
END
