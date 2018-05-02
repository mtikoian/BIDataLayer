/* copied to Production																	7/18/2013 P Parsino      */
/* Added Dim_ManMan_Commodity_Code & Oracle 											8/2/2013 P Parsino */  
/* Added  and com.Oracle_ManMan_Code is not null to avoid doubling fact rows			10/24/2013 P Parsino */ 
/* Added  Inventory Organization														5/20/2014 P Parsino */ 
/* Changed Dim_Product to Oracle Names													8/19/2014 P Parsino */ 
/* Added PPV and IPV & Release Dimension												2/06/2015 P Parsino */ 


USE [AS_DWH]
GO


-- Add Unknown member to Dim_Vendor_Pur_Group
Delete from as_dwh.dbo.Dim_Vendor_Pur_Group
Where Dim_Vendor_Group_Key = '0'

Insert Into as_dwh.dbo.Dim_Vendor_Pur_Group
Select '0', 'Unknown'


Truncate Table as_dwh.dbo.FACT_INVOICE_MERGE;

Insert into as_dwh.dbo.FACT_INVOICE_MERGE 

select *

--fact_key = IDENTITY (bigint, 1, 1) ,

--aa.* 

from 
(
		SELECT 
		f.po_quantity S_POQty,
       case when f.ad_unit_cost = 0 then 0 else f.usd_currency_amount/f.ad_unit_cost end  S_InvoiceQty,
       f.po_unit_cost S_POUnitPrice,
       f.ad_unit_cost S_InvoicePrice,
       --f.ad_unit_cost * abs(f.QUANTITY_BILLED) S_ExtInvPrice,
       f.usd_currency_amount S_ExtInvPrice,
       case when f.ad_unit_cost = 0 then 0 else f.material_cost * abs(f.usd_currency_amount/f.ad_unit_cost) end S_ExtInvoiceStdMatlCost,
       case when f.ad_unit_cost = 0 then 0 else f.material_cost * abs(f.usd_currency_amount/f.ad_unit_cost) end S_ExtInvoiceCurrentStdMatlCost,
       case when f.ad_unit_cost = 0 then 0 else f.po_unit_cost * abs(f.usd_currency_amount/f.ad_unit_cost) end S_ExtInvoicePOPrice,
       f.Dim_Production_PO_Key,
       f.dim_buyer_key DimManMan_Buyer_Code_Key,
       f.dim_product_key Dim_Receipt_PartNum_Key,
       f.dim_ap_vendor_key Dim_AP_ManManVendor_key,
       1 Dim_PUR_ORG_KEY,
       1 Dim_System_Source_Key,
       dim_ap_invoice_key Dim_APVoucherNumber_key,
       dim_po_header_key Dim_PONumber_key,
       dim_po_line_num_key dim_po_line_num_key,
       coalesce(com.Dim_ManMan_Commodity_Code_key,0)Dim_ManMan_Commodity_Code_key ,
       coalesce(ocom.Dim_Oracle_Commodity_Code_key,0)Dim_Oracle_Commodity_Code_key ,
       coalesce (cast (vlkp.[vendor group id] AS VARCHAR (7)),vlkp2.Dim_Vendor_Group_Key)
          AS Vendor_Group_ID,
       coalesce (vlkp.[vendor group id description], f.vendor_name)
         AS Vendor_Group_ID_Desc,
      dim_inv_gl_date_key dim_VoucherDate_key,
      Dim_INVENTORY_ORGANIZATION_KEY Dim_INVENTORY_ORGANIZATION_KEY,
      abs(f.material_cost) material_cost,
      abs(f.material_cost) - abs(f.po_unit_cost) ppv,
      abs(f.material_cost) - abs(f.ad_unit_cost) ipv,
      (abs(f.material_cost) - abs(f.po_unit_cost)) * f.po_quantity eppv,
      (abs(f.material_cost) - abs(f.ad_unit_cost)) * f.po_quantity eipv,
      dim_po_release_key,
      dim_po_type_key,
	  dim_operating_unit_key,
	  f.inv_functional_amount S_ExtInvPriceLC
  FROM    as_dwh.dbo.Fact_AP_INVOICE_DISTRIBUTIONS_ALL f
       LEFT OUTER JOIN AS_DWH.dbo.Dim_Oracle_Commodity_Code ocom
          ON (ocom.comm_code) = (f.comm_code) 

       LEFT OUTER JOIN AS_DWH.dbo.Dim_ManMan_Commodity_Code com
          ON coalesce(f.comm_Code,'Unknown') LIKE
                         '%'
                       + coalesce(com.Oracle_ManMan_Code,'Unknown')
                       + '%' 
       LEFT OUTER JOIN AS_STAGE.dbo.VendorMasterLookup vlkp
       ON vlkp.sitecode = 'L' + '-' + f.vendor_num
	   Left Outer Join as_dwh.dbo.Dim_Vendor_pur_Group vlkp2
	   ON vlkp2.Dim_Vendor_Group_Key = 'L' + '-' + f.vendor_num
 WHERE f.org_id = 151
 --  and com.Oracle_ManMan_Code is not null
UNION ALL
SELECT im.S_POQty,
       im.S_InvoiceQty,
       im.S_POUnitPrice,
       im.S_InvoicePrice,
       im.S_ExtInvPrice,
       im.S_ExtInvoiceStdMatlCost,
       im.S_ExtInvoiceCurrentStdMatlCost,
       im.S_ExtInvoicePOPrice,
       im.Dim_Production_PO_Key,
       isnull (im.DimManMan_Buyer_Code_Key, 0) DimManMan_Buyer_Code_Key,
       im.Dim_PRODUCT_KEY,
       im.Dim_AP_ManManVendor_key,
       -- im.Dim_MFG_ManManVendor_key,
       im.dim_pur_org_key,
       im.Dim_System_Source_key,
       im.Dim_APVoucherNumber_key,
       im.Dim_PONumber_key,
       im.dim_po_line_num_key, 
       im.Dim_ManMan_Commodity_code_key,
       im.Dim_Oracle_Commodity_code_key,
      rap.VendorGroupId ap_group_id_key,
      rmfg.VendorGroupId mfg_group_id_key,
      im.dim_VoucherDate_key,
      0 Dim_INVENTORY_ORGANIZATION_KEY,
      abs(im.S_ReceiptStdMatlCost) material_cost,
      abs(im.S_ReceiptStdMatlCost)  - abs(im.S_POUnitPrice) ppv,
      abs(im.S_ReceiptStdMatlCost)  - abs(im.S_InvoicePrice) ipv, 
      (abs(im.S_ReceiptStdMatlCost) - abs(im.S_POUnitPrice)) *  im.S_POQty eppv,
      (abs(im.S_ReceiptStdMatlCost) - abs(im.S_InvoicePrice)) * im.S_POQty eipv,
      0 dim_po_release_key,
      Case
		When S_POType = '0' Then -21
		When S_POType = '1' Then -1
		When S_POType = '2' Then -2
		When S_POType = '3' Then -3
		When S_POType = '10' Then -10
		When S_POType = '11' Then -11
		When S_POType = '12' Then -12
		When S_POType = '13' Then 1
		When S_POType = '20' Then -20
		Else 0
	  End dim_po_type_key
	  , 0 dim_operating_unit_key
	  , im.S_ExtInvPrice	S_ExtInvPriceLC -- Use same values for USD and LC
  --   ,COUNT(*)
  FROM AS_STAGE.dbo.stage_INVOICE_ManMan im
       LEFT JOIN AS_DWH.dbo.AP_GROUP_ManManVendors rap
          ON rap.site_code = im.APVendorCode
       LEFT JOIN AS_DWH.dbo.MFG_GROUP_ManManVendors rmfg
          ON rmfg.site_code = im.MFGVendorCode) aa