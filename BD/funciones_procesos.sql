CREATE OR REPLACE FUNCTION public.fn_usuario_es_admin(p_user_id integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
    v_admin boolean;
BEGIN
    SELECT COALESCE(r.admin, FALSE)
    INTO v_admin
    FROM public.usuarios u
    JOIN public.roles r ON r.role_id = u.role_id
    WHERE u.user_id = p_user_id;

    IF v_admin IS NULL THEN
        RAISE EXCEPTION 'No existe el usuario %', p_user_id;
    END IF;

    RETURN v_admin;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_validar_admin(p_user_id integer)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    IF public.fn_usuario_es_admin(p_user_id) = FALSE THEN
        RAISE EXCEPTION 'El usuario % no tiene permisos de administrador.', p_user_id;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_stock_delta_pedido(p_product_id integer, p_delta numeric)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_stock_id integer;
    v_pedido_actual numeric(12,2);
    v_pedido_nuevo numeric(12,2);
BEGIN
    SELECT s.stock_id, COALESCE(s.pedido, 0)
    INTO v_stock_id, v_pedido_actual
    FROM public.stock s
    WHERE s.product_id = p_product_id
    FOR UPDATE;

    IF v_stock_id IS NULL THEN
        RAISE EXCEPTION 'No existe registro en stock para el producto %', p_product_id;
    END IF;

    v_pedido_nuevo := v_pedido_actual + p_delta;

    IF v_pedido_nuevo < 0 THEN
        RAISE EXCEPTION
            'El pedido del producto % no puede quedar negativo. Actual: %, Movimiento: %',
            p_product_id, v_pedido_actual, p_delta;
    END IF;

    UPDATE public.stock
    SET pedido = v_pedido_nuevo
    WHERE stock_id = v_stock_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.aprobar_reserva_comprometer_stock()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    item record;
    v_disponible numeric(12,2);
BEGIN
    IF OLD.status <> 'A' AND NEW.status = 'A' THEN
        FOR item IN
            SELECT product_id, SUM(quantity) AS quantity
            FROM public.reservas_d
            WHERE reserv_id = NEW.reserv_id
            GROUP BY product_id
        LOOP
            SELECT COALESCE(disponible, 0)
            INTO v_disponible
            FROM public.stock
            WHERE product_id = item.product_id
            FOR UPDATE;

            IF v_disponible IS NULL THEN
                RAISE EXCEPTION 'El producto % no tiene registro de stock.', item.product_id;
            END IF;

            IF item.quantity > v_disponible THEN
                RAISE EXCEPTION
                    'No se puede aprobar la reserva. Producto % sin disponible suficiente. Disponible: %, solicitado: %',
                    item.product_id, v_disponible, item.quantity;
            END IF;

            PERFORM public.fn_stock_delta_comprometido(item.product_id, item.quantity);
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.cancelar_reserva_liberar_stock()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    item record;
BEGIN
    IF OLD.status = 'A' AND NEW.status = 'D' THEN
        FOR item IN
            SELECT product_id, SUM(quantity) AS quantity
            FROM public.reservas_d
            WHERE reserv_id = NEW.reserv_id
            GROUP BY product_id
        LOOP
            PERFORM public.fn_stock_delta_comprometido(item.product_id, -item.quantity);
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.trg_reservas_c_status_comprometido()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    item record;
BEGIN
    IF OLD.status = NEW.status THEN
        RETURN NEW;
    END IF;

    IF OLD.status = 'A' AND NEW.status = 'C' THEN
        FOR item IN
            SELECT product_id, SUM(quantity) AS quantity
            FROM public.reservas_d
            WHERE reserv_id = NEW.reserv_id
            GROUP BY product_id
        LOOP
            PERFORM public.fn_stock_delta_comprometido(item.product_id, -item.quantity);
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.trg_reservas_d_comprometido()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_status character(1);
    v_new_status character(1);
BEGIN
    IF TG_OP = 'INSERT' THEN
        SELECT status INTO v_new_status
        FROM public.reservas_c
        WHERE reserv_id = NEW.reserv_id;

        IF v_new_status = 'A' THEN
            PERFORM public.fn_stock_delta_comprometido(NEW.product_id, NEW.quantity);
        END IF;

        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN
        SELECT status INTO v_old_status
        FROM public.reservas_c
        WHERE reserv_id = OLD.reserv_id;

        SELECT status INTO v_new_status
        FROM public.reservas_c
        WHERE reserv_id = NEW.reserv_id;

        IF v_old_status = 'A' THEN
            PERFORM public.fn_stock_delta_comprometido(OLD.product_id, -OLD.quantity);
        END IF;

        IF v_new_status = 'A' THEN
            PERFORM public.fn_stock_delta_comprometido(NEW.product_id, NEW.quantity);
        END IF;

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        SELECT status INTO v_old_status
        FROM public.reservas_c
        WHERE reserv_id = OLD.reserv_id;

        IF v_old_status = 'A' THEN
            PERFORM public.fn_stock_delta_comprometido(OLD.product_id, -OLD.quantity);
        END IF;

        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION public.trg_orden_reposicion_c_status()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    item record;
BEGIN
    IF OLD.status = NEW.status THEN
        RETURN NEW;
    END IF;

    IF OLD.status = 'A' AND NEW.status <> 'A' THEN
        FOR item IN
            SELECT product_id, SUM(quantity) AS quantity
            FROM public.orden_reposicion_d
            WHERE reposicion_id = NEW.reposicion_id
            GROUP BY product_id
        LOOP
            PERFORM public.fn_stock_delta_pedido(item.product_id, -item.quantity);
        END LOOP;
    END IF;

    IF OLD.status <> 'A' AND NEW.status = 'A' THEN
        FOR item IN
            SELECT product_id, SUM(quantity) AS quantity
            FROM public.orden_reposicion_d
            WHERE reposicion_id = NEW.reposicion_id
            GROUP BY product_id
        LOOP
            PERFORM public.fn_stock_delta_pedido(item.product_id, item.quantity);
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.trg_orden_reposicion_d_pedido()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_status character(1);
BEGIN
    IF TG_OP = 'INSERT' THEN
        SELECT status INTO v_status
        FROM public.orden_reposicion_c
        WHERE reposicion_id = NEW.reposicion_id;

        IF v_status = 'A' THEN
            PERFORM public.fn_stock_delta_pedido(NEW.product_id, NEW.quantity);
        END IF;

        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN
        SELECT status INTO v_status
        FROM public.orden_reposicion_c
        WHERE reposicion_id = NEW.reposicion_id;

        IF v_status = 'A' THEN
            PERFORM public.fn_stock_delta_pedido(OLD.product_id, -OLD.quantity);
            PERFORM public.fn_stock_delta_pedido(NEW.product_id, NEW.quantity);
        END IF;

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        SELECT status INTO v_status
        FROM public.orden_reposicion_c
        WHERE reposicion_id = OLD.reposicion_id;

        IF v_status = 'A' THEN
            PERFORM public.fn_stock_delta_pedido(OLD.product_id, -OLD.quantity);
        END IF;

        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION public.registrar_entrada_stock()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_stock_actual numeric(12,2);
    v_costo_actual numeric(12,2);
    v_nuevo_costo numeric(12,2);
BEGIN
    SELECT stock, cost
    INTO v_stock_actual, v_costo_actual
    FROM public.stock
    WHERE product_id = NEW.product_id
    FOR UPDATE;

    IF v_stock_actual IS NULL THEN
        INSERT INTO public.stock (
            product_id,
            stock,
            price,
            cost,
            pedido,
            comprometido,
            stock_min,
            stock_max
        )
        VALUES (
            NEW.product_id,
            NEW.quantity,
            0,
            NEW.cost,
            0,
            0,
            0,
            0
        );
    ELSE
        IF (v_stock_actual + NEW.quantity) > 0 THEN
            v_nuevo_costo :=
                ((v_stock_actual * COALESCE(v_costo_actual, 0)) + (NEW.quantity * NEW.cost))
                / (v_stock_actual + NEW.quantity);
        ELSE
            v_nuevo_costo := NEW.cost;
        END IF;

        UPDATE public.stock
        SET stock = COALESCE(stock, 0) + NEW.quantity,
            cost = ROUND(v_nuevo_costo, 2)
        WHERE product_id = NEW.product_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_stock_recalcular_disponible(p_product_id integer)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.stock WHERE product_id = p_product_id) THEN
        RAISE EXCEPTION 'No existe registro en stock para el producto %', p_product_id;
    END IF;

    -- stock.disponible es una columna generada: (stock + pedido) - comprometido.
    RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION public.validar_disponibilidad_reserva()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_disponible numeric(12,2);
    v_total_reservado numeric(12,2);
BEGIN
    SELECT COALESCE(disponible, 0)
    INTO v_disponible
    FROM public.stock
    WHERE product_id = NEW.product_id;

    IF v_disponible IS NULL THEN
        RAISE EXCEPTION 'El producto % no tiene registro de stock.', NEW.product_id;
    END IF;

    IF TG_OP = 'INSERT' THEN
        SELECT COALESCE(SUM(quantity), 0)
        INTO v_total_reservado
        FROM public.reservas_d
        WHERE reserv_id = NEW.reserv_id
          AND product_id = NEW.product_id;
    ELSE
        SELECT COALESCE(SUM(quantity), 0)
        INTO v_total_reservado
        FROM public.reservas_d
        WHERE reserv_id = NEW.reserv_id
          AND product_id = NEW.product_id
          AND reserve_detail_id <> OLD.reserve_detail_id;
    END IF;

    IF (v_total_reservado + NEW.quantity) > v_disponible THEN
        RAISE EXCEPTION
            'Stock disponible insuficiente para el producto %. Disponible: %, solicitado: %',
            NEW.product_id, v_disponible, v_total_reservado + NEW.quantity;
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.sp_crear_reserva(
    p_user_id integer,
    p_planning_date date,
    p_detalles jsonb
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_reserv_id integer;
    item record;
    v_disponible numeric(12,2);
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.usuarios WHERE user_id = p_user_id) THEN
        RAISE EXCEPTION 'No existe el usuario %', p_user_id;
    END IF;

    IF p_planning_date IS NULL THEN
        RAISE EXCEPTION 'La fecha planificada es obligatoria.';
    END IF;

    IF p_detalles IS NULL OR jsonb_typeof(p_detalles) <> 'array' OR jsonb_array_length(p_detalles) = 0 THEN
        RAISE EXCEPTION 'La reserva debe tener al menos un producto.';
    END IF;

    FOR item IN
        SELECT product_id, SUM(quantity) AS quantity
        FROM (
            SELECT
                (detalle->>'product_id')::integer AS product_id,
                (detalle->>'quantity')::numeric AS quantity
            FROM jsonb_array_elements(p_detalles) AS detalle
        ) x
        GROUP BY product_id
    LOOP
        IF item.product_id IS NULL OR item.quantity IS NULL OR item.quantity <= 0 THEN
            RAISE EXCEPTION 'Cada detalle debe tener product_id y quantity mayor a cero.';
        END IF;

        SELECT COALESCE(disponible, 0)
        INTO v_disponible
        FROM public.stock
        WHERE product_id = item.product_id;

        IF v_disponible IS NULL THEN
            RAISE EXCEPTION 'El producto % no tiene registro de stock.', item.product_id;
        END IF;

        IF item.quantity > v_disponible THEN
            RAISE EXCEPTION
                'Stock disponible insuficiente para el producto %. Disponible: %, solicitado: %',
                item.product_id, v_disponible, item.quantity;
        END IF;
    END LOOP;

    INSERT INTO public.reservas_c (user_id, system_date, planning_date, status)
    VALUES (p_user_id, CURRENT_TIMESTAMP, p_planning_date, 'O')
    RETURNING reserv_id INTO v_reserv_id;

    INSERT INTO public.reservas_d (reserv_id, line_id, product_id, quantity)
    SELECT
        v_reserv_id,
        ROW_NUMBER() OVER (ORDER BY ordinality),
        (detalle->>'product_id')::integer,
        (detalle->>'quantity')::numeric
    FROM jsonb_array_elements(p_detalles) WITH ORDINALITY AS t(detalle, ordinality);

    RETURN v_reserv_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.sp_aprobar_reserva(
    p_admin_user_id integer,
    p_reserv_id integer
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_status character(1);
    v_total_detalles integer;
BEGIN
    PERFORM public.fn_validar_admin(p_admin_user_id);

    SELECT status INTO v_status
    FROM public.reservas_c
    WHERE reserv_id = p_reserv_id
    FOR UPDATE;

    IF v_status IS NULL THEN
        RAISE EXCEPTION 'No existe la reserva %', p_reserv_id;
    END IF;

    IF v_status <> 'O' THEN
        RAISE EXCEPTION 'Solo se pueden aprobar reservas abiertas. Reserva %, estado actual: %', p_reserv_id, v_status;
    END IF;

    SELECT COUNT(*) INTO v_total_detalles
    FROM public.reservas_d
    WHERE reserv_id = p_reserv_id;

    IF v_total_detalles = 0 THEN
        RAISE EXCEPTION 'La reserva % no tiene articulos en el detalle.', p_reserv_id;
    END IF;

    UPDATE public.reservas_c
    SET status = 'A'
    WHERE reserv_id = p_reserv_id;

    RETURN p_reserv_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.sp_cancelar_reserva(
    p_admin_user_id integer,
    p_reserv_id integer
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_status character(1);
BEGIN
    PERFORM public.fn_validar_admin(p_admin_user_id);

    SELECT status INTO v_status
    FROM public.reservas_c
    WHERE reserv_id = p_reserv_id
    FOR UPDATE;

    IF v_status IS NULL THEN
        RAISE EXCEPTION 'No existe la reserva %', p_reserv_id;
    END IF;

    IF v_status NOT IN ('O', 'A') THEN
        RAISE EXCEPTION 'Solo se pueden cancelar reservas abiertas o aprobadas. Reserva %, estado actual: %', p_reserv_id, v_status;
    END IF;

    UPDATE public.reservas_c
    SET status = 'D'
    WHERE reserv_id = p_reserv_id;

    RETURN p_reserv_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.sp_crear_entrega_desde_reserva(
    p_user_id integer,
    p_reserv_id integer,
    p_delivery_date date DEFAULT CURRENT_DATE
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_delivery_id integer;
    v_status character(1);
    v_total_detalles integer;
    item record;
    v_stock_actual numeric(12,2);
BEGIN
    PERFORM public.fn_validar_admin(p_user_id);

    SELECT status INTO v_status
    FROM public.reservas_c
    WHERE reserv_id = p_reserv_id
    FOR UPDATE;

    IF v_status IS NULL THEN
        RAISE EXCEPTION 'No existe la reserva %', p_reserv_id;
    END IF;

    IF v_status <> 'A' THEN
        RAISE EXCEPTION 'Solo se pueden entregar reservas aprobadas. Reserva %, estado actual: %', p_reserv_id, v_status;
    END IF;

    SELECT COUNT(*) INTO v_total_detalles
    FROM public.reservas_d
    WHERE reserv_id = p_reserv_id;

    IF v_total_detalles = 0 THEN
        RAISE EXCEPTION 'La reserva % no tiene articulos en el detalle.', p_reserv_id;
    END IF;

    FOR item IN
        SELECT product_id, SUM(quantity) AS quantity
        FROM public.reservas_d
        WHERE reserv_id = p_reserv_id
        GROUP BY product_id
    LOOP
        SELECT COALESCE(stock, 0)
        INTO v_stock_actual
        FROM public.stock
        WHERE product_id = item.product_id
        FOR UPDATE;

        IF v_stock_actual IS NULL THEN
            RAISE EXCEPTION 'No existe stock para el producto %', item.product_id;
        END IF;

        IF v_stock_actual < item.quantity THEN
            RAISE EXCEPTION
                'Stock insuficiente para el producto %. Stock actual: %, Cantidad requerida: %',
                item.product_id, v_stock_actual, item.quantity;
        END IF;
    END LOOP;

    INSERT INTO public.entregas_c (user_id, system_date, delivery_date, reserv_id)
    VALUES (p_user_id, CURRENT_TIMESTAMP, COALESCE(p_delivery_date, CURRENT_DATE), p_reserv_id)
    RETURNING delivery_id INTO v_delivery_id;

    INSERT INTO public.entregas_d (delivery_id, line_id, product_id, quantity)
    SELECT v_delivery_id, line_id, product_id, quantity
    FROM public.reservas_d
    WHERE reserv_id = p_reserv_id
    ORDER BY line_id;

    RETURN v_delivery_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.sp_crear_orden_reposicion(
    p_user_id integer,
    p_needed_date date,
    p_tipo_ingreso varchar,
    p_comment varchar,
    p_detalles jsonb
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_reposicion_id integer;
    item record;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.usuarios WHERE user_id = p_user_id) THEN
        RAISE EXCEPTION 'No existe el usuario %', p_user_id;
    END IF;

    IF p_detalles IS NULL OR jsonb_typeof(p_detalles) <> 'array' OR jsonb_array_length(p_detalles) = 0 THEN
        RAISE EXCEPTION 'La orden de reposicion debe tener al menos un producto.';
    END IF;

    FOR item IN
        SELECT
            (detalle->>'product_id')::integer AS product_id,
            (detalle->>'quantity')::numeric AS quantity,
            COALESCE((detalle->>'price')::numeric, 0) AS price
        FROM jsonb_array_elements(p_detalles) AS detalle
    LOOP
        IF item.product_id IS NULL OR item.quantity IS NULL OR item.quantity <= 0 THEN
            RAISE EXCEPTION 'Cada detalle debe tener product_id y quantity mayor a cero.';
        END IF;

        IF item.price < 0 THEN
            RAISE EXCEPTION 'El precio de reposicion no puede ser negativo.';
        END IF;

        IF NOT EXISTS (SELECT 1 FROM public.productos WHERE product_id = item.product_id) THEN
            RAISE EXCEPTION 'No existe el producto %', item.product_id;
        END IF;
    END LOOP;

    INSERT INTO public.orden_reposicion_c (
        user_id,
        status,
        tipo_ingreso,
        needed_date,
        system_date,
        comment
    )
    VALUES (
        p_user_id,
        'O',
        COALESCE(NULLIF(BTRIM(p_tipo_ingreso), ''), 'COMPRA'),
        p_needed_date,
        CURRENT_TIMESTAMP,
        NULLIF(BTRIM(p_comment), '')
    )
    RETURNING reposicion_id INTO v_reposicion_id;

    INSERT INTO public.orden_reposicion_d (
        reposicion_id,
        line_id,
        product_id,
        quantity,
        price,
        comment
    )
    SELECT
        v_reposicion_id,
        ROW_NUMBER() OVER (ORDER BY ordinality),
        (detalle->>'product_id')::integer,
        (detalle->>'quantity')::numeric,
        COALESCE((detalle->>'price')::numeric, 0),
        NULLIF(BTRIM(detalle->>'comment'), '')
    FROM jsonb_array_elements(p_detalles) WITH ORDINALITY AS t(detalle, ordinality);

    RETURN v_reposicion_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.sp_aprobar_orden_reposicion(
    p_admin_user_id integer,
    p_reposicion_id integer
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_status character(1);
    v_total_detalles integer;
BEGIN
    PERFORM public.fn_validar_admin(p_admin_user_id);

    SELECT status INTO v_status
    FROM public.orden_reposicion_c
    WHERE reposicion_id = p_reposicion_id
    FOR UPDATE;

    IF v_status IS NULL THEN
        RAISE EXCEPTION 'No existe la orden de reposicion %', p_reposicion_id;
    END IF;

    IF v_status <> 'O' THEN
        RAISE EXCEPTION 'Solo se pueden aprobar ordenes abiertas. Orden %, estado actual: %', p_reposicion_id, v_status;
    END IF;

    SELECT COUNT(*) INTO v_total_detalles
    FROM public.orden_reposicion_d
    WHERE reposicion_id = p_reposicion_id;

    IF v_total_detalles = 0 THEN
        RAISE EXCEPTION 'La orden de reposicion % no tiene articulos en el detalle.', p_reposicion_id;
    END IF;

    UPDATE public.orden_reposicion_c
    SET status = 'A'
    WHERE reposicion_id = p_reposicion_id;

    RETURN p_reposicion_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.sp_cancelar_orden_reposicion(
    p_admin_user_id integer,
    p_reposicion_id integer
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_status character(1);
BEGIN
    PERFORM public.fn_validar_admin(p_admin_user_id);

    SELECT status INTO v_status
    FROM public.orden_reposicion_c
    WHERE reposicion_id = p_reposicion_id
    FOR UPDATE;

    IF v_status IS NULL THEN
        RAISE EXCEPTION 'No existe la orden de reposicion %', p_reposicion_id;
    END IF;

    IF v_status NOT IN ('O', 'A') THEN
        RAISE EXCEPTION 'Solo se pueden cancelar ordenes abiertas o aprobadas. Orden %, estado actual: %', p_reposicion_id, v_status;
    END IF;

    UPDATE public.orden_reposicion_c
    SET status = 'D'
    WHERE reposicion_id = p_reposicion_id;

    RETURN p_reposicion_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.sp_crear_entrada_desde_reposicion(
    p_user_id integer,
    p_reposicion_id integer
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_income_id integer;
    v_tipo_ingreso varchar(20);
    v_status character(1);
    v_total_detalles integer;
BEGIN
    PERFORM public.fn_validar_admin(p_user_id);

    SELECT tipo_ingreso, status
    INTO v_tipo_ingreso, v_status
    FROM public.orden_reposicion_c
    WHERE reposicion_id = p_reposicion_id
    FOR UPDATE;

    IF v_status IS NULL THEN
        RAISE EXCEPTION 'No existe la orden de reposicion %', p_reposicion_id;
    END IF;

    IF v_status <> 'A' THEN
        RAISE EXCEPTION 'Solo se puede generar entrada desde ordenes aprobadas. Orden %, estado actual: %', p_reposicion_id, v_status;
    END IF;

    SELECT COUNT(*) INTO v_total_detalles
    FROM public.orden_reposicion_d
    WHERE reposicion_id = p_reposicion_id;

    IF v_total_detalles = 0 THEN
        RAISE EXCEPTION 'La orden de reposicion % no tiene articulos en el detalle.', p_reposicion_id;
    END IF;

    INSERT INTO public.entrada_c (user_id, system_date, reposicion_id, tipo_ingreso)
    VALUES (p_user_id, CURRENT_TIMESTAMP, p_reposicion_id, v_tipo_ingreso)
    RETURNING income_id INTO v_income_id;

    INSERT INTO public.entrada_d (income_id, line_id, product_id, quantity, cost)
    SELECT v_income_id, line_id, product_id, quantity, price
    FROM public.orden_reposicion_d
    WHERE reposicion_id = p_reposicion_id
    ORDER BY line_id;

    RETURN v_income_id;
END;
$$;
