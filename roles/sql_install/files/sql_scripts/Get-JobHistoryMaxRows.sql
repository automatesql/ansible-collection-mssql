declare @Results table (Value varchar(300), Data int)
declare @data int
insert into @Results
EXEC xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\SqlServerAgent', N'JobHistoryMaxRows'

select @data = data from @Results

print isnull(@data,0)

