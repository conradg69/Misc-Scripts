USE [DBAdmin]
GO

/****** Object:  Table [dbo].[PS_AgentjobsHistory]    Script Date: 18/12/2018 10:41:43 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PS_AgentjobsHistory](
	CollectionTime [datetime2](7) NULL,
	[Server] [nvarchar](max) NULL,
	[JobID] [uniqueidentifier] NULL,
	[JobName] [varchar](90) NOT NULL,
	[RunDate] [datetime2](7) NULL,
	[RunDuration] [int] NULL,
	[RunStatus] [int] NULL,
	[InstanceID] [int] NULL,
	[SqlMessageID] [int] NULL,
	[StepID] [int] NULL,
	[StepName] [nvarchar](max) NULL,
	[SqlSeverity] [int] NULL,
	[OperatorEmailed] [nvarchar](max) NULL,
	[RetriesAttempted] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[PS_AgentjobsHistory]  WITH NOCHECK ADD  CONSTRAINT [FK_AgJobLookups_JobName] FOREIGN KEY([JobName])
REFERENCES [dbo].[PS_AgentJobs_Lookup] ([JobName])
GO

ALTER TABLE [dbo].[PS_AgentjobsHistory] CHECK CONSTRAINT [FK_AgJobLookups_JobName]
GO

