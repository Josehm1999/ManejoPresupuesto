create database ManejoPresupuesto
use ManejoPresupuesto

CREATE TABLE TiposOperaciones(
	Id int IDENTITY(1,1) NOT NULL PRIMARY KEY,
	Descripcion nvarchar(50) NOT NULL
)

Create table Usuarios(
	[Id] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[Email] [nvarchar](256) NOT NULL,
	[EmailNormalizado] [nvarchar](256) NOT NULL,
	[PasswordHash] [nvarchar](max) NOT NULL,
)

create table Categorias(
	[Id] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[Nombre] [nvarchar](50) NOT NULL,
	[TipoOperacionId] [int] NOT NULL,
	[UsuarioId] [int] NOT NULL,
)

create table TiposCuentas(
	[Id] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[Nombre] [nvarchar](50) NOT NULL,
	[UsuarioId] [int] NOT NULL,
	[Orden] [int] NOT NULL,
)

create table Cuentas(
	[Id] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[Nombre] [nvarchar](50) NOT NULL,
	[TipoCuentaId] [int] NOT NULL,
	[Balance] [decimal](18, 2) NOT NULL,
	[Descripcion] [nvarchar](1000) NULL,
)


create table Transacciones(
	[Id] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY, 
	[UsuarioId] [int] NOT NULL,
	[FechaTransaccion] [datetime] NOT NULL,
	[Monto] [decimal](18, 2) NOT NULL,
	[Nota] [nvarchar](1000) NULL,
	[CuentaId] [int] NOT NULL,
	[CategoriaId] [int] NOT NULL,
)

ALTER TABLE Cuentas  WITH CHECK ADD  CONSTRAINT [FK_Cuentas_TiposCuenta_Cascade_Delete] FOREIGN KEY(TipoCuentaId)
REFERENCES TiposCuentas(Id)
ON DELETE CASCADE;

ALTER TABLE [dbo].[Cuentas] CHECK CONSTRAINT [FK_Cuentas_TiposCuenta_Cascade_Delete];

ALTER TABLE [dbo].[Cuentas]  WITH CHECK ADD  CONSTRAINT [FK_TiposCuentas] FOREIGN KEY([TipoCuentaId])
REFERENCES [dbo].[TiposCuentas] ([Id]);

ALTER TABLE [dbo].[Cuentas] CHECK CONSTRAINT [FK_TiposCuentas];

ALTER TABLE [dbo].[TiposCuentas]  WITH CHECK ADD  CONSTRAINT [FK_TiposCuentas_Usuarios] FOREIGN KEY([UsuarioId])
REFERENCES [dbo].[Usuarios] ([Id]);

ALTER TABLE [dbo].[TiposCuentas] CHECK CONSTRAINT [FK_TiposCuentas_Usuarios];


ALTER TABLE [dbo].[Categorias]  WITH CHECK ADD  CONSTRAINT [FK_Categorias_Operacion] FOREIGN KEY([TipoOperacionId])
REFERENCES [dbo].[TiposOperaciones] ([Id]);


ALTER TABLE [dbo].[Categorias] drop CONSTRAINT [FK_Categorias_Operacion];

ALTER TABLE [dbo].[Categorias]  WITH CHECK ADD  CONSTRAINT [FK_Categorias_Usuarios] FOREIGN KEY([UsuarioId])
REFERENCES [dbo].[Usuarios] ([Id]);

ALTER TABLE [dbo].[Categorias] CHECK CONSTRAINT [FK_Categorias_Usuarios];

ALTER TABLE [dbo].[Transacciones]  WITH CHECK ADD  CONSTRAINT [FK_Transacciones_Account_Cascade_Delete] FOREIGN KEY([CuentaId])
REFERENCES [dbo].[Cuentas] ([Id])
ON DELETE CASCADE;

ALTER TABLE [dbo].[Transacciones] CHECK CONSTRAINT [FK_Transacciones_Account_Cascade_Delete];

ALTER TABLE [dbo].[Transacciones]  WITH CHECK ADD  CONSTRAINT [FK_Transacciones_Categorias_Cascade_Delete] FOREIGN KEY([CategoriaId])
REFERENCES [dbo].[Categorias] ([Id])
ON DELETE CASCADE;

ALTER TABLE [dbo].[Transacciones] CHECK CONSTRAINT [FK_Transacciones_Categorias_Cascade_Delete];

ALTER TABLE [dbo].[Transacciones]  WITH CHECK ADD  CONSTRAINT [FK_Transacciones_Usuarios] FOREIGN KEY([UsuarioId])
REFERENCES [dbo].[Usuarios] ([Id]);
ALTER TABLE [dbo].[Transacciones] CHECK CONSTRAINT [FK_Transacciones_Usuarios];


CREATE PROCEDURE [dbo].[TiposCuentas_Insertar]
	@Nombre nvarchar(50),
	@UsuarioId int
AS
BEGIN

	SET NOCOUNT ON;

    DECLARE @Orden int;
	SELECT @Orden = COALESCE(MAX(Orden),0)+1
	FROM TiposCuentas 
	WHERE UsuarioId  = @UsuarioId	

	INSERT INTO TiposCuentas (Nombre , UsuarioId, Orden)
	VALUES (@Nombre, @UsuarioId, @Orden);

	SELECT SCOPE_IDENTITY();
END
;

CREATE PROCEDURE [dbo].[Transacciones_Borrar]
	@Id int
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @Monto decimal(18,2);
	DECLARE @CuentaId int;
	DECLARE @TipoOperacionId int;

	SELECT @Monto = Monto, @CuentaId = CuentaId, @TipoOperacionId = cate.TipoOperacionId
	FROM Transacciones
	INNER JOIN Categorias cate
	ON cate.Id = Transacciones.CategoriaId
	WHERE Transacciones.Id = @Id;

	DECLARE @FactorMultiplicativo int = 1;

	IF (@TipoOperacionId = 2)
		SET @FactorMultiplicativo = -1;

	SET @Monto = @Monto * @FactorMultiplicativo;

	UPDATE Cuentas 
	SET Balance -= @Monto
	WHERE Id = @CuentaId;

	DELETE Transacciones
	WHERE Id = @Id;
END;

CREATE PROCEDURE [dbo].[Transacciones_Insertar]
	@UsuarioId int,
	@FechaTransaccion date,
	@Monto decimal(18,2),
  @CategoriaId int,
  @CuentaId int,
	@Nota nvarchar(1000) = NULL
AS
BEGIN
	SET NOCOUNT ON;

	INSERT INTO Transacciones(UsuarioId, FechaTransaccion, Monto, CategoriaId, CuentaId, Nota)
	VALUES(@UsuarioId, @FechaTransaccion, ABS(@Monto), @CategoriaId, @CuentaId, @Nota)

  UPDATE Cuentas
  SET Balance += @Monto
  WHERE Id = @CuentaId;

  SELECT SCOPE_IDENTITY();
END;

CREATE PROCEDURE [dbo].[Transacciones_Actualizar]
	@Id int,
	@FechaTransaccion datetime,
	@Monto decimal(18,2),
	@MontoAnterior decimal(18,2),
	@CuentaId int,
	@CuentaAnteriorId int,
	@CategoriaId int,
	@Nota nvarchar(1000) = NULL
AS
BEGIN
	SET NOCOUNT ON;

	-- Reverse previous transaction
	UPDATE Cuentas 
	SET Balance -= @MontoAnterior
	WHERE Id = @CuentaAnteriorId;

	-- Do a new transaction
	UPDATE Cuentas 
	SET Balance += @Monto
	WHERE Id = @CuentaId;

	UPDATE Transacciones 
	SET Monto = ABS(@Monto), FechaTransaccion = @FechaTransaccion,
	CategoriaId = @CategoriaId, CuentaId = @CuentaId, Nota = @Nota
	WHERE Id = @Id;
END;


create procedure CrearDatosUsuarioNuevo
@UsuarioId int
as BEGIN 
set NOCOUNT on;
DECLARE @Efectivo nvarchar(50) = 'Efectivo';
DECLARE @CuentasDeBanco nvarchar(50) = 'Cuentas de Banco';
DECLARE @Tarjetas  nvarchar(50) ='Tarjetas';

INSERT INTO TiposCuentas (Nombre, UsuarioId, Orden)
values (@Efectivo, @UsuarioId,1),
(@CuentasDeBanco,@UsuarioId,2),
(@Tarjetas,@UsuarioId,3)

insert into Cuentas (Nombre, Balance, TipoCuentaId)
select Nombre, 0, Id 
from TiposCuentas
where UsuarioId = @UsuarioId

insert into Categorias(Nombre, TipoOperacionId, UsuarioId)
values
('Venta',1,@UsuarioId),
('Pago empleado',2, @UsuarioId),
('Recibo de Luz',2,@UsuarioId),
('Recibo de Agua',2, @UsuarioId),
('Pago proveedor',2, @UsuarioId)
END;


