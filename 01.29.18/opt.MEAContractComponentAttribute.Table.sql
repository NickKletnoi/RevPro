USE [RevPro]
GO
/****** Object:  Table [opt].[MEAContractComponentAttribute]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [opt].[MEAContractComponentAttribute](
	[MEAContractComponentAttributeID] [int] NOT NULL,
	[MEAContractComponentID] [int] NOT NULL,
	[AttributeType] [varchar](50) NOT NULL,
	[AttributeValue] [decimal](15, 2) NOT NULL,
	[AttributeTextValue] [varchar](100) NULL,
	[AttributeExplanationText] [varchar](100) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
