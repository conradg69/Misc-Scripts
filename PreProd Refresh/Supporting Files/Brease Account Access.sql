USE [BreaseUAT]
GO
CREATE USER [BreaseAppUAT] FOR LOGIN [BreaseAppUAT]
EXEC sp_addrolemember N'db_owner', N'BreaseAppUAT'
GO