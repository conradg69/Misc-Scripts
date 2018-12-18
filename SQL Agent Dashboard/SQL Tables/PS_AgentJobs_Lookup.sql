USE [DBAdmin]
GO

/****** Object:  Table [dbo].[PS_AgentJobs_Lookup]    Script Date: 18/12/2018 10:41:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PS_AgentJobs_Lookup](
	[ComputerName] [nvarchar](max) NULL,
	[InstanceName] [nvarchar](max) NULL,
	[JobName] [varchar](90) NOT NULL,
	[JobID] [uniqueidentifier] NOT NULL,
	[CreateDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[JobName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

