USE [DBAdmin]
GO

/****** Object:  Table [dbo].[PS_AgentJobCategories]    Script Date: 18/12/2018 10:42:37 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PS_AgentJobCategories](
	[ComputerName] [nvarchar](max) NULL,
	[InstanceName] [nvarchar](max) NULL,
	[SqlInstance] [nvarchar](max) NULL,
	[JobCount] [int] NULL,
	[Parent] [nvarchar](max) NULL,
	[CategoryType] [nvarchar](max) NULL,
	[ID] [int] NULL,
	[Name] [nvarchar](max) NULL,
	[ParentCollection] [nvarchar](max) NULL,
	[Urn] [nvarchar](max) NULL,
	[Properties] [nvarchar](max) NULL,
	[ServerVersion] [nvarchar](max) NULL,
	[DatabaseEngineType] [nvarchar](max) NULL,
	[DatabaseEngineEdition] [nvarchar](max) NULL,
	[ExecutionManager] [nvarchar](max) NULL,
	[UserData] [nvarchar](max) NULL,
	[State] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

