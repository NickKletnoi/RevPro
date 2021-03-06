USE [RevPro]
GO
/****** Object:  Table [lookups].[Calendar]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [lookups].[Calendar](
	[DateKey] [date] NOT NULL,
	[CalendarDate] [datetime] NULL,
	[DaysInMonth] [int] NULL,
	[DaysRemain] [int] NULL,
	[YearNumber] [int] NULL,
	[MonthNumber] [int] NULL,
	[DayNumber] [int] NULL
) ON [PRIMARY]

GO
