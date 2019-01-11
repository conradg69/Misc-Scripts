USE [DBAdmin]
GO

/****** Object:  Table [dbo].[PS_AgentJobSteps]    Script Date: 18/12/2018 10:42:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PS_AgentJobSteps](
	CollectTime [datetime2](7) NULL,
	[ComputerName] [nvarchar](max) NULL,
	[InstanceName] [nvarchar](max) NULL,
	[AgentJob] [varchar](90) NOT NULL,
	[Name] [nvarchar](max) NULL,
	[LastRunDate] [datetime2](7) NULL,
	[LastRunOutcome] [nvarchar](max) NULL,
	[LastRunDurationAsTimeSpan] [bigint] NULL,
	[LastRunRetries] [int] NULL,
	[Command] [nvarchar](max) NULL,
	[CommandExecutionSuccessCode] [int] NULL,
	[DatabaseName] [nvarchar](max) NULL,
	[DatabaseUserName] [nvarchar](max) NULL,
	[ID] [int] NULL,
	[JobStepFlags] [nvarchar](max) NULL,
	[OnFailAction] [nvarchar](max) NULL,
	[OnSuccessAction] [nvarchar](max) NULL,
	[RetryAttempts] [int] NULL,
	[Server] [nvarchar](max) NULL,
	[SubSystem] [nvarchar](max) NULL,
	[UserData] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[PS_AgentJobSteps]  WITH NOCHECK ADD  CONSTRAINT [FK_AgJobLookup_JobName] FOREIGN KEY([AgentJob])
REFERENCES [dbo].[PS_AgentJobs_Lookup] ([JobName])
GO

ALTER TABLE [dbo].[PS_AgentJobSteps] CHECK CONSTRAINT [FK_AgJobLookup_JobName]
GO

