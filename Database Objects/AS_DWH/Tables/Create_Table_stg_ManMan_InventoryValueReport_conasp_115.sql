
/****** Object:  Table [reports].[f124]    Script Date: 4/20/2018 1:54:35 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE stg_ManMan_InventoryValueReport_conasp_115(
	[id] bigint NULL,
	DB varchar(6) Not null,
	SectionOfReport varchar(10) not null,
	part nvarchar(18) null,
	[desc] nvarchar(30) null,
	uom nvarchar(2) null,
	prtsc nvarchar(2) null,
	prtbc nvarchar(2) null,
	prtopc smallint null,
	curprtrev nvarchar(2) null,
	prtdwg nvarchar(18) null,
	locwar nvarchar(10) not null,
	loccode nvarchar(10) not null,
	lotno nvarchar(18) null,
	net varchar(2) not null,
	qty float null,
	locactno nvarchar(24) NOT NULL,
	prtactno nvarchar(24) null,
	std_cost float null,
	EXTvalue float null

) ON [PRIMARY]
GO


