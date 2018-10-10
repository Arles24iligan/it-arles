USE master
GO
IF OBJECT_ID ('sp_hexadecimal') IS NOT NULL
DROP PROCEDURE sp_hexadecimal
GO
CREATE PROCEDURE sp_hexadecimal
@binvalue varbinary(256),
@hexvalue varchar(256) OUTPUT
AS
DECLARE @charvalue varchar(256)
DECLARE @i int
DECLARE @length int
DECLARE @hexstring char(16)
SELECT @charvalue = '0x'
SELECT @i = 1
SELECT @length = DATALENGTH (@binvalue)
SELECT @hexstring = '0123456789ABCDEF'
WHILE (@i <= @length)
BEGIN
DECLARE @tempint int
DECLARE @firstint int
DECLARE @secondint int
SELECT @tempint = CONVERT(int, SUBSTRING(@binvalue,@i,1))
SELECT @firstint = FLOOR(@tempint/16)
SELECT @secondint = @tempint - (@firstint*16)
SELECT @charvalue = @charvalue +
SUBSTRING(@hexstring, @firstint+1, 1) +
SUBSTRING(@hexstring, @secondint+1, 1)
SELECT @i = @i + 1
END
SELECT @hexvalue = @charvalue
GO

IF OBJECT_ID ('sp_help_revlogin_2000_to_2005') IS NOT NULL
DROP PROCEDURE sp_help_revlogin_2000_to_2005
GO
CREATE PROCEDURE sp_help_revlogin_2000_to_2005

@login_name sysname = NULL,
@include_db bit = 0,
@include_role bit = 0

AS
DECLARE @name sysname
DECLARE @xstatus int
DECLARE @binpwd varbinary (256)
DECLARE @dfltdb varchar (256)
DECLARE @txtpwd sysname
DECLARE @tmpstr varchar (256)
DECLARE @SID_varbinary varbinary(85)
DECLARE @SID_string varchar(256)

IF (@login_name IS NULL)
DECLARE login_curs CURSOR STATIC FOR
SELECT sid, [name], xstatus, password, isnull(db_name(dbid), 'master')
FROM master.dbo.sysxlogins
WHERE srvid IS NULL AND
[name] <> 'sa'
ELSE
DECLARE login_curs CURSOR FOR
SELECT sid, [name], xstatus, password, isnull(db_name(dbid), 'master')
FROM master.dbo.sysxlogins
WHERE srvid IS NULL AND
[name] = @login_name

OPEN login_curs

FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @xstatus, @binpwd, @dfltdb

IF (@@fetch_status = -1)
BEGIN
PRINT 'No login(s) found.'
CLOSE login_curs
DEALLOCATE login_curs
RETURN -1
END

SET @tmpstr = '/* sp_help_revlogin script '
PRINT @tmpstr
SET @tmpstr = '** Generated '
+ CONVERT (varchar, GETDATE()) + ' on ' + @@SERVERNAME + ' */'
PRINT @tmpstr
PRINT ''
PRINT ''
PRINT ''
PRINT '/***** CREATE LOGINS *****/'

WHILE @@fetch_status = 0
BEGIN
PRINT ''
SET @tmpstr = '-- Login: ' + @name
PRINT @tmpstr

IF (@xstatus & 4) = 4
BEGIN -- NT authenticated account/group
IF (@xstatus & 1) = 1
BEGIN -- NT login is denied access
SET @tmpstr = '' --'EXEC master..sp_denylogin ''' + @name + ''''
PRINT @tmpstr
END
ELSE
BEGIN -- NT login has access
SET @tmpstr = 'IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE [name] = ''' + @name + ''')'
PRINT @tmpstr
SET @tmpstr = CHAR(9) + 'CREATE LOGIN [' + @name + '] FROM WINDOWS'
PRINT @tmpstr
END
END
ELSE
BEGIN -- SQL Server authentication
EXEC sp_hexadecimal @SID_varbinary, @SID_string OUT

IF (@binpwd IS NOT NULL)
BEGIN -- Non-null password
EXEC sp_hexadecimal @binpwd, @txtpwd OUT
SET @tmpstr = 'CREATE LOGIN [' + @name + '] WITH PASSWORD=' + @txtpwd + ' HASHED'
END
ELSE
BEGIN -- Null password
SET @tmpstr = 'CREATE LOGIN [' + @name + '] WITH PASSWORD='''''
END

SET @tmpstr = @tmpstr + ', CHECK_POLICY=OFF, SID=' + @SID_string
PRINT @tmpstr
END

FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @xstatus, @binpwd, @dfltdb
END

IF @include_db = 1
BEGIN
PRINT ''
PRINT ''
PRINT ''
PRINT '/***** SET DEFAULT DATABASES *****/'

FETCH FIRST FROM login_curs INTO @SID_varbinary, @name, @xstatus, @binpwd, @dfltdb

WHILE @@fetch_status = 0
BEGIN
PRINT ''
SET @tmpstr = '-- Login: ' + @name
PRINT @tmpstr

SET @tmpstr = 'ALTER LOGIN [' + @name + '] WITH DEFAULT_DATABASE=[' + @dfltdb + ']'
PRINT @tmpstr

FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @xstatus, @binpwd, @dfltdb
END
END

IF @include_role = 1
BEGIN
PRINT ''
PRINT ''
PRINT ''
PRINT '/***** SET SERVER ROLES *****/'

FETCH FIRST FROM login_curs INTO @SID_varbinary, @name, @xstatus, @binpwd, @dfltdb

WHILE @@fetch_status = 0
BEGIN
PRINT ''
SET @tmpstr = '-- Login: ' + @name
PRINT @tmpstr

IF @xstatus &16 = 16 -- sysadmin
BEGIN
SET @tmpstr = 'exec master.dbo.sp_addsrvrolemember @loginame=''' + @name + ''', @rolename=''sysadmin'''
PRINT @tmpstr
END

IF @xstatus &32 = 32 -- securityadmin
BEGIN
SET @tmpstr = 'exec master.dbo.sp_addsrvrolemember @loginame=''' + @name + ''', @rolename=''securityadmin'''
PRINT @tmpstr
END

IF @xstatus &64 = 64 -- serveradmin
BEGIN
SET @tmpstr = 'exec master.dbo.sp_addsrvrolemember @loginame=''' + @name + ''', @rolename=''serveradmin'''
PRINT @tmpstr
END

IF @xstatus &128 = 128 -- setupadmin
BEGIN
SET @tmpstr = 'exec master.dbo.sp_addsrvrolemember @loginame=''' + @name + ''', @rolename=''setupadmin'''
PRINT @tmpstr
END

IF @xstatus &256 = 256 --processadmin
BEGIN
SET @tmpstr = 'exec master.dbo.sp_addsrvrolemember @loginame=''' + @name + ''', @rolename=''processadmin'''
PRINT @tmpstr
END

IF @xstatus &512 = 512 -- diskadmin
BEGIN
SET @tmpstr = 'exec master.dbo.sp_addsrvrolemember @loginame=''' + @name + ''', @rolename=''diskadmin'''
PRINT @tmpstr
END

IF @xstatus &1024 = 1024 -- dbcreator
BEGIN
SET @tmpstr = 'exec master.dbo.sp_addsrvrolemember @loginame=''' + @name + ''', @rolename=''dbcreator'''
PRINT @tmpstr
END

IF @xstatus &4096 = 4096 -- bulkadmin
BEGIN
SET @tmpstr = 'exec master.dbo.sp_addsrvrolemember @loginame=''' + @name + ''', @rolename=''bulkadmin'''
PRINT @tmpstr
END

FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @xstatus, @binpwd, @dfltdb
END
END

CLOSE login_curs
DEALLOCATE login_curs
RETURN 0
GO

-- exec sp_help_revlogin_2000_to_2005 @login_name=NULL, @include_db=1, @include_role=1

IF OBJECT_ID ('sp_help_revlogin_2005') IS NOT NULL
DROP PROCEDURE sp_help_revlogin_2005
GO
CREATE PROCEDURE sp_help_revlogin_2005

@login_name sysname = NULL,
@include_db bit = 0,
@include_role bit = 0

AS
DECLARE @name sysname
DECLARE @type char(1)
DECLARE @binpwd varbinary (256)
DECLARE @dfltdb varchar (256)
DECLARE @isdisabled int
DECLARE @login_id int
DECLARE @txtpwd sysname
DECLARE @tmpstr varchar (256)
DECLARE @SID_varbinary varbinary(85)
DECLARE @SID_string varchar(256)

IF (@login_name IS NULL)
DECLARE login_curs CURSOR STATIC FOR
SELECT l.SID, l.[name], l.[type], s.password_hash, isnull(l.default_database_name, 'master'), l.is_disabled, l.principal_id
FROM sys.server_principals l
LEFT OUTER JOIN sys.sql_logins s
ON l.SID = s.SID
WHERE l.[type] IN ('S', 'U', 'G') AND -- S = SQL login, U = Windows login, G = Windows group
l.[name] NOT LIKE '%User$%$MSSQLSERVER' AND
( (@login_name IS NULL and l.[name] <> 'sa') OR
(@login_name IS NOT NULL and l.[name] = @login_name))

OPEN login_curs

FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @binpwd, @dfltdb, @isdisabled, @login_id

IF (@@fetch_status = -1)
BEGIN
PRINT 'No login(s) found.'
CLOSE login_curs
DEALLOCATE login_curs
RETURN -1
END

SET @tmpstr = '/* sp_help_revlogin script '
PRINT @tmpstr
SET @tmpstr = '** Generated '
+ CONVERT (varchar, GETDATE()) + ' on ' + @@SERVERNAME + ' */'
PRINT @tmpstr
PRINT ''
PRINT ''
PRINT '/***** CREATE LOGINS *****/'

WHILE @@fetch_status = 0
BEGIN
PRINT ''
SET @tmpstr = '-- Login: ' + @name
PRINT @tmpstr

IF @type <> 'S'
BEGIN -- NT authenticated account/group
SET @tmpstr = 'IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE [name] = ''' + @name + ''')'
PRINT @tmpstr
SET @tmpstr = CHAR(9) + 'CREATE LOGIN [' + @name + '] FROM WINDOWS'
PRINT @tmpstr
END
ELSE
BEGIN -- SQL Server authentication
EXEC sp_hexadecimal @SID_varbinary, @SID_string OUT

IF (@binpwd IS NOT NULL)
BEGIN -- Non-null password
EXEC sp_hexadecimal @binpwd, @txtpwd OUT
SET @tmpstr = 'CREATE LOGIN [' + @name + '] WITH PASSWORD=' + @txtpwd + ' HASHED'
END
ELSE
BEGIN -- Null password
SET @tmpstr = 'CREATE LOGIN [' + @name + '] WITH PASSWORD='''''
END

SET @tmpstr = @tmpstr + ', CHECK_POLICY=OFF, SID=' + @SID_string
PRINT @tmpstr
END

IF @isdisabled = 1
BEGIN
SET @tmpstr = 'ALTER LOGIN [' + @name + '] DISABLE'
PRINT @tmpstr
END

FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @binpwd, @dfltdb, @isdisabled, @login_id
END

IF @include_db = 1
BEGIN
PRINT ''
PRINT ''
PRINT '/***** SET DEFAULT DATABASES *****/'

FETCH FIRST FROM login_curs INTO @SID_varbinary, @name, @type, @binpwd, @dfltdb, @isdisabled, @login_id

WHILE @@fetch_status = 0
BEGIN
PRINT ''
SET @tmpstr = '-- Login: ' + @name
PRINT @tmpstr

SET @tmpstr = 'ALTER LOGIN [' + @name + '] WITH DEFAULT_DATABASE=[' + @dfltdb + ']'
PRINT @tmpstr

FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @binpwd, @dfltdb, @isdisabled, @login_id
END
END

IF @include_role = 1
BEGIN
PRINT ''
PRINT ''
PRINT ''
PRINT '/***** SET SERVER ROLES *****/'

FETCH FIRST FROM login_curs INTO @SID_varbinary, @name, @type, @binpwd, @dfltdb, @isdisabled, @login_id

DECLARE @role_name sysname

WHILE @@fetch_status = 0
BEGIN
PRINT ''
SET @tmpstr = '-- Login: ' + @name
PRINT @tmpstr

DECLARE role_curs CURSOR FOR
SELECT r.[name] as role_name
FROM sys.server_principals l,
sys.server_role_members m,
sys.server_principals r
WHERE l.[name] = @name AND
l.[type] IN ('S', 'U', 'G') AND -- S = SQL login, U = Windows login, G = Windows group
l.principal_id = m.member_principal_id and
m.role_principal_id = r.principal_id and
r.[type] = 'R'

OPEN role_curs

FETCH NEXT FROM role_curs INTO @role_name

WHILE @@FETCH_STATUS = 0
BEGIN
SET @tmpstr = 'exec master.dbo.sp_addsrvrolemember @loginame=''' + @name + ''', @rolename=''' + @role_name + ''''
PRINT @tmpstr

FETCH NEXT FROM role_curs INTO @role_name
END

CLOSE role_curs
DEALLOCATE role_curs

FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @binpwd, @dfltdb, @isdisabled, @login_id
END
END

CLOSE login_curs
DEALLOCATE login_curs
RETURN 0
GO

-- exec sp_help_revlogin_2005 @login_name=NULL, @include_db=1, @include_role=1
