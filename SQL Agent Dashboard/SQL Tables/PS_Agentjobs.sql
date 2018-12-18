USE [DBAdmin]
GO

/****** Object:  Table [dbo].[PS_Agentjobs]    Script Date: 18/12/2018 10:40:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PS_Agentjobs](
	[ComputerName] [nvarchar](max) NULL,
	[InstanceName] [nvarchar](max) NULL,
	[Name] [varchar](90) NOT NULL,
	[JobID] [uniqueidentifier] NULL,
	[JobType] [nvarchar](max) NULL,
	[LastRunDate] [datetime2](7) NULL,
	[NextRunDate] [datetime2](7) NULL,
	[LastRunOutcome] [nvarchar](max) NULL,
	[Enabled] [bit] NULL,
	[DateCreated] [datetime2](7) NULL,
	[DateLastModified] [datetime2](7) NULL,
	[Category] [nvarchar](max) NULL,
	[CategoryType] [tinyint] NULL,
	[Description] [nvarchar](max) NULL,
	[CurrentRunRetryAttempt] [int] NULL,
	[CurrentRunStatus] [nvarchar](max) NULL,
	[EmailLevel] [nvarchar](max) NULL,
	[OperatorToEmail] [nvarchar](max) NULL,
	[OwnerLoginName] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[PS_Agentjobs]  WITH NOCHECK ADD  CONSTRAINT [FK_AgentJobsLookups_JobName] FOREIGN KEY([Name])
REFERENCES [dbo].[PS_AgentJobs_Lookup] ([JobName])
GO

ALTER TABLE [dbo].[PS_Agentjobs] CHECK CONSTRAINT [FK_AgentJobsLookups_JobName]
GO

