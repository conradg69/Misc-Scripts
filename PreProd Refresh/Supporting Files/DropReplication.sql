USE TR4_PRE_PROD
GO
EXEC sp_dropsubscription @publication = N'pubFusionILTCache', @article = N'all', @subscriber = N'all', @destination_db = N'all'
GO
EXEC sp_droppublication @publication = N'pubFusionILTCache'
GO