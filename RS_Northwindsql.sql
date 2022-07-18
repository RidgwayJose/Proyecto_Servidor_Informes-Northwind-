USE Northwind

IF OBJECT_ID('vw_ListarEmpleados') IS NOT NULL
BEGIN
    DROP VIEW vw_ListarEmpleados
END
GO

--Vista
CREATE VIEW vw_ListarEmpleados
AS
	select FirstName + ' '+LastName as Nombres_Apellidos from Employees

go


/*
select * from vw_ListarEmpleados
go
*/



IF OBJECT_ID('proc_Ordenes_por_Empleado') IS NOT NULL
BEGIN
    DROP PROC proc_Ordenes_por_Empleado
END
GO

--Procedimiento
CREATE PROCEDURE proc_Ordenes_por_Empleado
	@Employees_Nombres_Apellidos varchar(60)
AS
BEGIN
	Select  emp.FirstName + ' '+emp.LastName  as Nombres_Apellidos,ord.OrderID,ord.OrderDate,prod.ProductID,prod.ProductName,ctg.CategoryName,sup.CompanyName
	from Employees emp
	INNER JOIN Orders ord ON emp.EmployeeID = ord.EmployeeID
	INNER JOIN [Order Details] ord_d ON ord.OrderID = ord_d.OrderID
	INNER JOIN Products prod ON ord_d.ProductID = prod.ProductID
	INNER JOIN Categories ctg ON prod.CategoryID = ctg.CategoryID
	INNER JOIN Suppliers sup ON prod.SupplierID = sup.SupplierID
	Where  emp.FirstName + ' '+emp.LastName  = @Employees_Nombres_Apellidos
	ORDER BY ord.OrderID,ord.OrderDate,prod.ProductID,prod.ProductName,ctg.CategoryName,sup.CompanyName
END
GO

/*
exec proc_Ordenes_por_Empleado 'Margaret Peacock'
go
*/

----------------------------------------
----------------------------------------

IF OBJECT_ID('vw_Years') IS NOT NULL
BEGIN
    DROP VIEW vw_Years
END
GO

--Vista
CREATE VIEW vw_Years
AS
	select top 99.9 PERCENT YEAR(orderdate) as YEAR from orders
	group by YEAR(orderdate)
	ORDER BY YEAR DESC
GO

/*
select * from vw_Years
go
*/


IF OBJECT_ID('proc_Prod_por_Ctg') IS NOT NULL
BEGIN
    DROP PROC proc_Prod_por_Ctg
END
GO
--Proc
CREATE PROCEDURE proc_Prod_por_Ctg
	@Year varchar(20)
AS
Begin
	Select CategoryName, COUNT(CategoryName)AS Cuenta
	from Products prod 
	INNER JOIN Categories ctg ON prod.CategoryID = ctg.CategoryID
	INNER JOIN [Order Details] ord_d ON prod.ProductID = ord_d.ProductID
	INNER JOIN Orders ord ON ord_d.OrderID = ord.OrderID
	WHERE year(OrderDate) = @Year
	group by CategoryName 
end
go

/*
exec proc_Prod_por_Ctg 1998
go
*/
--------------------------------------------------------------
--------------------------------------------------------------
IF OBJECT_ID('proc_IngresoPorEmpleado') IS NOT NULL
BEGIN
    DROP PROC proc_IngresoPorEmpleado
END
GO

CREATE PROCEDURE proc_IngresoPorEmpleado
	@Year varchar(20)
AS
BEGIN
	select emp.FirstName + ' '+emp.LastName  as Nombres_Apellidos, Sum(UnitPrice) as Monto_Total
	from Employees emp
	INNER JOIN Orders ord ON emp.EmployeeID = ord.EmployeeID
	INNER JOIN [Order Details] ord_d ON ord.OrderID = ord_d.OrderID
	WHERE year(OrderDate) = @Year
	Group by emp.FirstName + ' '+emp.LastName
END
GO
/*
exec proc_IngresoPorEmpleado 1996
go
*/

-----------------------------------------------------------------
-----------------------------------------------------------------


--Proc
IF OBJECT_ID('proc_Monto_por_Clientes') IS NOT NULL
BEGIN
    DROP PROC proc_Monto_por_Clientes
END
GO

CREATE PROCEDURE proc_Monto_por_Clientes
	@Years varchar(20)
AS
BEGIN
	Select cust.CompanyName,MONTH(ord.OrderDate) as N_Mes,DATENAME(MONTH,ord.OrderDate) as Nombre_Mes, COUNT(prod.ProductID)AS Cant_Prod
	from Customers cust
	INNER JOIN Orders ord on cust.CustomerID = ord.CustomerID
	INNER JOIN [Order Details] ord_d ON ord.OrderID = ord_d.OrderID
	INNER JOIN Products prod ON ord_d.ProductID = prod.ProductID
	WHERE Discontinued = 0 and Year(OrderDate) = @Years
	GROUP BY MONTH(ord.OrderDate),cust.CompanyName,DATENAME(MONTH,ord.OrderDate)
END
GO

exec proc_Monto_por_Clientes 1996
/*
select * from Customers
go
*/


----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------
IF OBJECT_ID('proc_Monto_por_Empleado') IS NOT NULL
BEGIN
    DROP PROC proc_Monto_por_Empleado
END
GO

CREATE PROCEDURE proc_Monto_por_Empleado
    @Employees_Nombres_Apellidos varchar(60)
AS
BEGIN
        SELECT CONCAT(FirstName , ' ' , LastName)Nombres_Apellidos, YEAR(orderdate) as Year,MONTH(ord.OrderDate) as N_Mes, DATENAME(MONTH, OrderDate) as Month, SUM(unitprice) as Monto_Total
        FROM Employees emp
        INNER JOIN Orders ord on emp.EmployeeID = ord.EmployeeID
        INNER JOIN [Order Details] ord_d ON ord.OrderID = ord_d.OrderID
        WHERE CONCAT(FirstName , ' ' , LastName) = @Employees_Nombres_Apellidos
        group by CONCAT(FirstName , ' ' , LastName), YEAR(orderdate),MONTH(OrderDate),DATENAME(MONTH, OrderDate)
END
GO

IF OBJECT_ID('vw_IngresoMes') IS NOT NULL
BEGIN
    DROP PROC vw_IngresoMes
END
GO

CREATE VIEW vw_IngresoMes
AS
	select top 100 percent MONTH(OrderDate) as Month,year(ord.OrderDate) as YEAR, Sum(UnitPrice) as Monto_Total, 
	Lag(Sum(UnitPrice), 1,0) OVER (ORDER BY YEAR(orderdate) asc ,Month(orderdate) asc) as MontoAnterior,
	CASE
		WHEN  Lag(Sum(UnitPrice), 1,0) OVER (ORDER BY YEAR(orderdate) asc ,Month(orderdate) asc) = 0 THEN 1
		WHEN  Sum(UnitPrice)/Lag(Sum(UnitPrice), 1,0) OVER (ORDER BY YEAR(orderdate) asc ,Month(orderdate) asc)>= 1 THEN 1
		WHEN  Sum(UnitPrice)/Lag(Sum(UnitPrice), 1,0) OVER (ORDER BY YEAR(orderdate) asc ,Month(orderdate) asc)<= 0.9 THEN -1
		Else 0
	END as Estado
	from Employees emp
	INNER JOIN Orders ord ON emp.EmployeeID = ord.EmployeeID
	INNER JOIN [Order Details] ord_d ON ord.OrderID = ord_d.OrderID
	Group by MONTH(OrderDate),year(ord.OrderDate)
	order by YEAR asc ,Month asc
GO

select * from vw_IngresoMes