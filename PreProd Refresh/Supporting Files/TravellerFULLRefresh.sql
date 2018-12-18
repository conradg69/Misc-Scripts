--Alter database TR4_PRE_PROD set single_user with rollback immediate
--Go
--Alter database TR4_PRE_PROD set multi_user with rollback immediate
--Go
RESTORE DATABASE TR4_PRE_PROD FROM  DISK = '\\WERCOVRUATSQLD1\DBBackups4\TR4_LIVE\FULL\TR4_LIVE.FULLCOMP.20180914200000.BAK'
WITH  
MOVE N'Tr@veller_Data' TO N'H:\SQLData\TR4_PRE_PROD.mdf',  
MOVE N'Traveller_Data2' TO N'H:\SQLData\TR4_PRE_PROD_1.ndf',
MOVE 'Traveller_AddData' TO 'H:\SQLData\TR4_PRE_PROD_2.ndf',  
MOVE 'Tr@veller_Log' TO 'K:\SQLTLog\TR4_PRE_PROD_3.LDF',
MOVE 'Tr@veller_Log2' TO 'K:\SQLTLog\TR4_PRE_PROD_4.LDF',
REPLACE, NORECOVERY,  STATS = 5;