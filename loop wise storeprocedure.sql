USE [NML_SPD_20]
GO
/****** Object:  StoredProcedure [dbo].[sp_UpdatePipeLine]    Script Date: 1/30/2020 4:13:45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_UpdatePipeLine]
AS
BEGIN
	SELECT * 
INTO #temp
FROM (
    SELECT distinct ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as id, IB.PartsNo as ItemCode,SUM(ISNULL(IB.OrderQty,0))OrderQty,
	SUM(ISNULL(IB.InvoiceQty,0))InvoiceQty,SUM(ISNULL(IB.QtyIntransit,0))QtyIntransit,SUM(ISNULL(IB.PackedQty,0))PackedQty,SUM(ISNULL(IB.UnderPacking,0))UnderPacking,
	SUM(ISNULL(IB.BlockedQty,0))BlockedQty,SUM(ISNULL(IB.TMLBlockedQty,0))TMLBlockedQty,SUM(ISNULL(IB.PendingQty,0))PendingQty,SUM(ISNULL(rec.ReciveQty,0)) ReceiveQty,  
    0 AS ExcessQty,0 as PipeLine    
    FROM (      (SELECT OrderDate,TMLSAPNO,PartsNo,SUM(ISNULL(OrderQty,0))OrderQty,SUM(ISNULL(InvoiceQty,0))InvoiceQty,SUM(ISNULL(QtyIntransit,0))QtyIntransit,
	SUM(ISNULL(PackedQty,0))PackedQty,SUM(ISNULL(UnderPacking,0))UnderPacking,SUM(ISNULL(BlockedQty,0))BlockedQty,SUM(ISNULL(TMLBlockedQty,0))TMLBlockedQty,
	SUM(ISNULL(PendingQty,0))PendingQty From tblNMLOrderDetail       Group BY TMLSAPNO,PartsNo,Description,OrderDate )  IB     Left OUTER JOIN    (SELECT ItemCode,SAPNO,
	SUM(Qty) ReciveQty FROM tblReceipt GROUP BY tblReceipt.ItemCode,tblReceipt.SAPNO    ) rec    ON IB.PartsNo=rec.ItemCode AND IB.TMLSAPNO=rec.SAPNO    )  
    WHERE OrderDate >= CONVERT(datetime,'2019-03-31 00:00:00.000')  
    GROUP BY IB.PartsNo
	HAVING  (SUM(ISNULL(IB.OrderQty, 0)) - SUM(ISNULL(IB.BlockedQty, 0)) - SUM(ISNULL(rec.ReciveQty, 0)) > 0)
) AS x
 
Update ItemInfo set PipeLine=0
Declare @Id int;
set @Id=1;
declare @count int;
set @count =1;
While (Select Count(*) From #Temp) >= @count
Begin
  declare  @TotalPipeLine real;
  set @TotalPipeLine=0;
  declare  @Total real;
  set @Total=0;
  declare  @OrderQty real;
  set @OrderQty=0;
  declare  @BlockedQty real;
  set @BlockedQty=0;
  declare  @ReceiveQty real;
  set @ReceiveQty=0;
  declare @Itemcode varchar(50);
  set @Itemcode=null;
  set @OrderQty= (select #temp.OrderQty from #temp where #temp.id=@Id)
  set @BlockedQty= (select #temp.BlockedQty from #temp where #temp.id=@Id)
  set @ReceiveQty= (select #temp.ReceiveQty from #temp where #temp.id=@Id)
  set @Itemcode= (select #temp.ItemCode from #temp where #temp.id=@Id)

   set @Total =(@OrderQty) - (@BlockedQty) - (@ReceiveQty);
   if (@Total > 0)
   Begin
     set  @TotalPipeLine = (@OrderQty) - (@BlockedQty) - (@ReceiveQty);
   End
   else
   Begin
    set   @TotalPipeLine = 0;
   End
   
   Update ItemInfo set PipeLine=@TotalPipeLine Where ItemCode=@Itemcode
   
   set @Id=@id+1;
   set @count=@count+1;

End
END
