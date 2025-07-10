use msdb
go
select j.name as JobName, c.name AS Categoryname
from dbo.sysjobs AS j
inner join dbo.syscategories AS c
 on j.category_id = c.category_id
where c.name IN ('Database Maintenance','Policy Based Management')

