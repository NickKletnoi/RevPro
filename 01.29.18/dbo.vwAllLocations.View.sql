USE [RevPro]
GO
/****** Object:  View [dbo].[vwAllLocations]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vwAllLocations]
AS


SELECT DISTINCT L.LocationID, L.LocationName
FROM Staging.dbo.Location L
	JOIN Staging.dbo.[Contract] C
		ON L.LocationID = C.BillingLocationID
	JOIN RevPro.dbo.Active_SOFile SO
		ON C.ContractID = SO.ContractID 
UNION
SELECT DISTINCT L.LocationID, L.LocationName
FROM Staging.dbo.Location L
	JOIN Staging.dbo.LineItem LI
		ON L.LocationID = LI.SiteLocationID
	JOIN RevPro.dbo.Active_SOFile SO
		ON LI.ContractID = SO.ContractID










GO
