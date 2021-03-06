USE `terminal_automotriz`;
DROP procedure IF EXISTS `cargar_pedido2`;

DELIMITER $$
USE `terminal_automotriz`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `cargar_pedido2`(IN _id_pedido int,out _mensaje varchar(60))
BEGIN

DECLARE idPedidoParametro INTEGER DEFAULT 0;
DECLARE idChasis INTEGER DEFAULT 0;
DECLARE dFechaIngreso DATETIME;
DECLARE finished INT DEFAULT 0; 

-- variables cursor pedido
DECLARE _modelo_id_modelo INTEGER;
DECLARE nCantidadDetalle INT;
DECLARE conteo INT DEFAULT 0;

-- variables cursor chasis
DECLARE n_chasis int;
DECLARE existe INT DEFAULT 0;


-- Cursor para recorrer los detalles pero solo del pedido indicado en el parametro
DECLARE curDetallePedido CURSOR FOR
SELECT modelo_id_modelo, cantidad FROM pedido_del_modelo WHERE pedido_id_pedido = _id_pedido;

-- Cursor para recorrer la tabla de vehiculos completa
DECLARE curChasis CURSOR FOR SELECT id_chasis FROM vehiculo;

-- Manejador de ambos cursores
DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1; -- inicializado en true

-- INICIO chequeo si pedido esta cargado --
set @auto_repetido =0; 
select count(*) into @auto_repetido from vehiculo where pedido_id_pedido = _id_pedido;
 if @auto_repetido > 0 then
	SET _mensaje= 'El auto ya está pedido';
else
    SET _mensaje= 'El auto se proceso con exito';
end if;

-- FIN chequeo si pedido esta cargado --

   -- Aca comienzo el loop recorriendo el cursor de pedido.
OPEN curDetallePedido;
getDetalle: LOOP
	FETCH curDetallePedido INTO _modelo_id_modelo, nCantidadDetalle;
	IF finished = 1 THEN
		CLOSE curDetallePedido;
		LEAVE getDetalle;
	END IF;
	SET conteo = 0;		-- control de cantidad de vehiculos cargados por linea
	
	WHILE 	conteo < nCantidadDetalle and @auto_repetido =0 DO -- Aca loopeo para hacer N inserts.
		validaChasis: LOOP
			SET idChasis= FLOOR(RAND() * 100); -- genera id aleatorio entre 0 y 100.000
			--  genero un loop nuevo con un cursor y recorro todo el listado de chasis existentes para asegurar que no exista el que acabo de generar
                    OPEN curChasis;
					getChasis: LOOP
						FETCH curChasis INTO n_chasis;
						IF finished = 1 THEN
							SET finished = 0; -- regreso manejador a falso para no salir del cursor de pedido
                            CLOSE curChasis;  -- cierro cursor
							LEAVE validaChasis;
						END IF;
                        IF n_chasis=idChasis THEN
                            CLOSE curChasis;
                            ITERATE validaChasis;
						END IF;
					END LOOP getChasis;

        insert into vehiculo values (idChasis,_modelo_id_modelo, _id_pedido);
	END LOOP validaChasis;
		
	-- insert into vehiculo values (idChasis,_modelo_id_modelo, _id_pedido);
	

	SET conteo = conteo  +1;

	END WHILE;

    END LOOP getDetalle;
-- 
-- Elimino el cursor de memoria

    CLOSE curDetallePedido;

END$$

DELIMITER ;

call abm_pedido (9,127,'2020-02-09','2020-07-20','alta',@_respuesta);
select @_respuesta;
Insert into pedido_del_modelo values (9,2,35);

call cargar_pedido2(9,@_mensaje);
Select @_mensaje; 

Select * from vehiculo where pedido_id_pedido= 9 ;
Select count(*) pedido_id_pedido from vehiculo where pedido_id_pedido = 9 ;
