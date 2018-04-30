
/****** Object:  Table [reports].[f124]    Script Date: 4/20/2018 1:54:35 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE stg_ManMan_WHIPReport_374(
		[DB] varchar(6)
      ,[PartNumber] nvarchar(18)
      ,[WorkArea] nvarchar(10)
      ,[CountPointOperationSeqNum] smallint
      ,[TransactionDate] int
      ,[TransactionTime] nvarchar(8)
      ,[RP_WPVBATCH] int
      ,[DocumentRefNum] nvarchar(10)
      ,[CountPointOperationSeqWorkCenter] nvarchar(10)
      ,[QtyMoved] float
      ,[StatusFlg] smallint
      ,[ReworkOperationSeqNum] smallint
      ,[StdMaterialCst] float
      ,[StdLowerLvlMatOvhCst] float
      ,[StdThisLvlMatBurdenFactor] float
      ,[StdLowerLvlDirLabCst] float
      ,[StdLowerLvlFixOvhCst] float
      ,[StdLowerLvlVarOvhCst] float
      ,[StdLowerLvlOutProcessCst] float
      ,[StdLowerLvlOutProcessOvhCst] float
      ,[StdThisLvlDirLabCst] float
      ,[StdThisLvlFxOvhCst] float
      ,[StdThisLvlVarOvhCst] float
      ,[StdThisLvlOutProcessCst] float
      ,[StdThisLvlOutProcessBurdenFactor] float
      ,[StdPurCst] float
      ,[BatchIdNum] nvarchar(10)
      ,[QtyBackFlushed] float
      ,[QtyScrapped] float
      ,[OperationYieldFactor] float
      ,[QtyCycleCnt] float
      ,[ManBatchOrderNum] nvarchar(20)
      ,[FormulaName] nvarchar(20)
      ,[BurdendedMaterial] float
      ,[AssemblyDirectLabor] float
      ,[AssemblyFixedOverhead] float
      ,[AssemblyVariableOverhead] float
      ,[ComponentDirectLabor] float
      ,[ComponentFixedOverhead] float
      ,[ComponentVariableOverhead] float
      ,[BurdenedAssemblyOutsideProcessingCost] float
      ,[BurdenedComponentOutsideProcessingCost] float
      ,[ExtCost] float
      ,[WorkAreaDesc] nvarchar(30)
      ,[DefaultWIPLoc] nvarchar(10)

) ON [PRIMARY]
GO
