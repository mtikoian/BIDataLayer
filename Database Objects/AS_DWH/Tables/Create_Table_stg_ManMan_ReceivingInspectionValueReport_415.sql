
/****** Object:  Table [reports].[f124]    Script Date: 4/20/2018 1:54:35 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE stg_ManMan_ReceivingInspectionValueReport_415(
	[loc] varchar(6)
      ,[prtno] nvarchar(18)
      ,[prtdesc] nvarchar(30)
      ,[prtrev] nvarchar(2)
      ,[prtsc] nvarchar(2)
      ,[prtbc] nvarchar(2)
      ,[prtpc] nvarchar(2)
      ,[prtcc] smallint
      ,[prtcommcod] nvarchar(8)
      ,[prtopc] smallint
      ,[prtss] int
      ,[prtpan] int
      ,[prtflt] smallint
      ,[date_last_received] int
      ,[stocking_uom] nvarchar(2)
      ,[std_cost] float
      ,[ext_std_cost] float
      ,[pohno] nvarchar(10)
      ,[pohdat] date
      ,[pohcldat] date
      ,[pohtyp] smallint
      ,[podqty] float
      ,[podrev] nvarchar(2)
      ,[podqpri] float
      ,[poddudat] date
      ,[podinsp] nvarchar(2)
      ,[podmrp] date
      ,[line] numeric(21,8)
      ,[poddudatyr] int
      ,[poddudatmnth] int
      ,[poddudatqtr] varchar(23)
      ,[qty_in_inspection] float
      ,[podsqty] float
      ,[podrtvr] float
      ,[podrtvc] date
      ,[podcldat] date
      ,[podactno] nvarchar(24)
      ,[podtyp] varchar(3)
      ,[podpo] nvarchar(10)
      ,[poddue] float
      ,[vencode] nvarchar(10)
      ,[venname] nvarchar(30)
      ,[pohendat] date
      ,[podendat] date
      ,[POItemCostHighOrLow] varchar(1)

) ON [PRIMARY]
GO
