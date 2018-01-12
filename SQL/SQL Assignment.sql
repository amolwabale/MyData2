-----------------------------------------------------------------------
-- DATABASE REFERRED : NORTHWND
-- Description       : Open source SQL database available for practice
-- Download Link     : https://northwinddatabase.codeplex.com/
-- Assignment By	 : Amol Wabale
-----------------------------------------------------------------------
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- Problem statement 1
-- Show available category wise 
-- For single category
-- For all Category (Pass 0 as parameter)
-----------------------------------------------------------------------
-----------------------------------------------------------------------

create procedure AsnGetProductByCategory
@CatId int = NULL
as
begin
	select b.ProductName, b.UnitPrice, a.CategoryName, a.Description
	from Categories a
	inner join Products b on a.CategoryID = b.CategoryID
	where (@CatId = 0 OR @CatId IS NULL)
	OR @CatId != 0 AND a.CategoryID = @CatId
end

-----------------------------------------------------------------------
-- Problem statement 2
-- List all ordered elements of customers (Pass customer ID as parameter)
-----------------------------------------------------------------------
-----------------------------------------------------------------------

create procedure AsnGetOrderDetailsOfCustomer
@CustomerId varchar(100)
as
begin
	select a.ContactName, a.Address, d.ProductName, c.UnitPrice, c.Quantity, 
					c.Discount, b.OrderDate, b.ShipVia, b.ShipName
	from Customers a
	inner join Orders b on a.CustomerID = b.CustomerID
	inner join [Order Details] c on c.OrderID = b.OrderID
	inner join Products d on d.ProductID = c.ProductID
	where a.CustomerID = @CustomerId
end

-----------------------------------------------------------------------
-- Problem statement 3
-- List product supplier category wise (Pass Category ID as parameter)
-----------------------------------------------------------------------
-----------------------------------------------------------------------
 
create procedure AsnGetProdSuppliersByCategory
@CategoryId int = null
as
begin
	select c.CategoryName, a.CompanyName, a.ContactName, a.ContactTitle, a.Address
	from Suppliers a
	inner join Products b on a.SupplierID = b.SupplierID
	inner join Categories c on b.CategoryID = c.CategoryID
	where (@CategoryId = 0 or @CategoryId is null)
	or (@CategoryId != 0 and b.CategoryID = @CategoryId)
end

-----------------------------------------------------------------------
-- Problem statement 4
-- List number of product supplied by supplier category wise (Pass Category ID as parameter)
-----------------------------------------------------------------------
-----------------------------------------------------------------------

create procedure AsnGetProductCountByCategory
@CategoryId int = null
as
begin
	select c.CategoryName, count(a.ProductID) as [Product Count]
	from [Order Details] a
	inner join Products b on a.ProductID = b.ProductID
	inner join Categories c on b.CategoryID = c.CategoryID
	where (@CategoryId = 0 or @CategoryId is null)
	or (@CategoryId != 0 and b.CategoryID = @CategoryId)
	group by c.CategoryName
end

create procedure AsnGetSupplierProductCountByCategory
@CategoryId int = null
as
begin
	select c.CategoryName, d.ContactName as [Supplier Name], count(a.ProductID) as [Product Count]
	from [Order Details] a
	inner join Products b on a.ProductID = b.ProductID
	inner join Categories c on b.CategoryID = c.CategoryID
	inner join Suppliers d on b.SupplierID = d.SupplierID 
	where (@CategoryId = 0 or @CategoryId is null)
	or (@CategoryId != 0 and b.CategoryID = @CategoryId)
	group by c.CategoryName, d.ContactName
end

-----------------------------------------------------------------------
-- Problem statement 5
-- List down the employee to their reporting manager
-----------------------------------------------------------------------
-----------------------------------------------------------------------

create procedure AsnGetEmployeeReporting
as
begin
	select dbo.GetFullName(b.FirstName,b.LastName) as [Employee Name], dbo.GetAge(b.BirthDate) as[Employee DOB],
	dbo.GetFullName(a.FirstName,a.LastName) as [Reporting Manager], dbo.GetAge(a.BirthDate) as[Manager DOB]
	from Employees a
	inner join Employees b on b.ReportsTo = a.EmployeeID
end

create function GetAge(@Dob Date)
returns int
as
begin
 declare @age int
 set @age = datediff(year,@Dob,getdate())
 return @age
end

create function [dbo].[GetFullName](@FirstName varchar(max), @LastName varchar(max))
returns varchar(max)
as
begin
return @FirstName + ' ' + @LastName
end

---------------------------------------------------------------------------------------------------------------
-- UPDATE OPERATION
---------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------
-- Problem statement 6
-- Update Products table by passing ProductId, Column Name to update and value
-----------------------------------------------------------------------
-----------------------------------------------------------------------

create procedure AsnUpdateProducts
@ProductId varchar(100),
@ColumnName varchar(100),
@ColumnValue varchar(100)
as
begin try
	SET XACT_ABORT ON;
	begin transaction
		declare @sql nvarchar(max)
		set @sql = 'update Products set ' +@ColumnName + ' = ''' + @ColumnValue + ''' where ProductID = '+  @ProductId
		exec sp_executesql @sql
	commit transaction
end try
begin catch
	SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage;

	IF (XACT_STATE()) = -1  
    BEGIN  
        PRINT  
            N'The transaction is in an uncommittable state.' +  
            'Rolling back transaction.'  
        ROLLBACK TRANSACTION;  
    END; 

	IF (XACT_STATE()) = 1  
    BEGIN  
        PRINT  
            N'The transaction is committable.' +  
            'Committing transaction.'  
        COMMIT TRANSACTION;     
    END;

end catch

-----------------------------------------------------------------------
-- Problem statement 7
-- Bulk insert into Categories table using csv
-----------------------------------------------------------------------
-----------------------------------------------------------------------

create procedure AsnBulkInsertCategoryCsv
@Path nvarchar(max)
as
begin
	declare @sql nvarchar(max) = '
	begin try
		SET XACT_ABORT ON;
		begin transaction
			bulk insert Categories
			from  ''' + @Path + '''
			with
			(
				rowterminator = ''\n'',
				fieldterminator = '',''
			)
		commit transaction
	end try
	begin catch

	SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage;

		IF (XACT_STATE()) = -1  
		BEGIN  
			PRINT  
				N''The transaction is in an uncommittable state.'' +  
				''Rolling back transaction.''  
			ROLLBACK TRANSACTION;  
		END; 

		IF (XACT_STATE()) = 1  
		BEGIN  
			PRINT  
				N''The transaction is committable.'' +  
				''Committing transaction.''  
			COMMIT TRANSACTION;     
		END;

	end catch'
	exec(@sql)
end

-----------------------------------------------------------------------
-- Problem statement 8
-- Bulk insert into Categories table using temporary table
-----------------------------------------------------------------------
-----------------------------------------------------------------------

-- Create temporary table for inserting data
create table #tempTable
(
Id int,
CategoryName nvarchar(max),
Description nvarchar(max),
Picture image
)

insert into #tempTable values( 0,'cat1','desc1',null)
insert into #tempTable values( 0,'cat2','desc2',null)
insert into #tempTable values( 0,'cat3','desc3',null)
insert into #tempTable values( 0,'cat4','desc4',null)
insert into #tempTable values( 0,'cat5','desc5',null)

-- Create table type
CREATE TYPE UDT_Category AS TABLE
(
	Id int,
	CategoryName nvarchar(max),
	Description nvarchar(max),
	Picture image
)

-- Store procedure
create procedure AsnBulkInsertCategoryTempTable
@tb UDT_Category readonly
as
begin try
	SET XACT_ABORT ON;
	begin transaction
		insert into Categories([CategoryName],[Description],[Picture])
		select [CategoryName],[Description],[Picture] from @tb
	commit transaction
end try
begin catch

	SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage;

		IF (XACT_STATE()) = -1  
		BEGIN  
			PRINT  
				N'The transaction is in an uncommittable state.' +  
				'Rolling back transaction.'  
			ROLLBACK TRANSACTION;  
		END; 

		IF (XACT_STATE()) = 1  
		BEGIN  
			PRINT  
				N'The transaction is committable.' +  
				'Committing transaction.'  
			COMMIT TRANSACTION;     
		END;

	end catch

-- Executing store procedure
declare @tb UDT_Category
insert into @tb 
select * from #tempTable
exec AsnBulkInsertCategoryTempTable @tb

-----------------------------------------------------------------------
-- Problem statement 9
-- Bulk update Categories table using temporary table
-----------------------------------------------------------------------
-----------------------------------------------------------------------

create table #tempTable2
(
Id int,
CategoryName nvarchar(max),
Description nvarchar(max),
Picture image
)

insert into #tempTable2 values( 1,'cat1','desc1',null)
insert into #tempTable2 values( 2,'cat2','desc2',null)
insert into #tempTable2 values( 3,'cat3','desc3',null)
insert into #tempTable2 values( 4,'cat4','desc4',null)
insert into #tempTable2 values( 8,'cat5','desc5',null)

-- Create table type
CREATE TYPE UDT_Category AS TABLE
(
	Id int,
	CategoryName nvarchar(max),
	Description nvarchar(max),
	Picture image
)

-- Store Procedure
create procedure AsnBulkUpdateCategoryTempTable
@tb UDT_Category readonly
as
begin try
	SET XACT_ABORT ON;
	begin transaction
		update b
		set
		b.CategoryName = a.CategoryName,
		b.Description = a.Description,
		b.Picture = a.Picture
		from @tb a
		join Categories b on a.Id = b.CategoryID
	commit transaction
end try
begin catch

	SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage;

		IF (XACT_STATE()) = -1  
		BEGIN  
			PRINT  
				N'The transaction is in an uncommittable state.' +  
				'Rolling back transaction.'  
			ROLLBACK TRANSACTION;  
		END; 

		IF (XACT_STATE()) = 1  
		BEGIN  
			PRINT  
				N'The transaction is committable.' +  
				'Committing transaction.'  
			COMMIT TRANSACTION;     
		END;

	end catch

-- Executing store procedure
declare @tb UDT_Category
insert into @tb 
select * from #tempTable2
exec AsnBulkUpdateCategoryTempTable @tb

