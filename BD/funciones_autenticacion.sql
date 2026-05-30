CREATE OR REPLACE FUNCTION public.fn_crear_usuario(
    p_user_name varchar,
    p_user_password varchar,
    p_u_pnombre varchar,
    p_u_papellido varchar,
    p_role_id integer DEFAULT 1,
    p_u_snombre varchar DEFAULT NULL,
    p_u_sapellido varchar DEFAULT NULL,
    p_u_fechanacimiento date DEFAULT NULL,
    p_gender_id integer DEFAULT NULL,
    p_u_correo varchar DEFAULT NULL,
    p_u_telefono varchar DEFAULT NULL,
    p_u_estudianteutp boolean DEFAULT TRUE
)
RETURNS TABLE (
    user_id integer,
    user_name varchar,
    u_pnombre varchar,
    u_snombre varchar,
    u_papellido varchar,
    u_sapellido varchar,
    u_fechanacimiento date,
    u_edad integer,
    gender_id integer,
    u_correo varchar,
    u_telefono varchar,
    u_estudianteutp boolean,
    role_id integer
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id integer;
    v_edad integer;
BEGIN
    IF NULLIF(BTRIM(p_user_name), '') IS NULL THEN
        RAISE EXCEPTION 'El nombre de usuario es obligatorio.';
    END IF;

    IF NULLIF(BTRIM(p_user_password), '') IS NULL THEN
        RAISE EXCEPTION 'La contrasena es obligatoria.';
    END IF;

    IF NULLIF(BTRIM(p_u_pnombre), '') IS NULL THEN
        RAISE EXCEPTION 'El primer nombre es obligatorio.';
    END IF;

    IF NULLIF(BTRIM(p_u_papellido), '') IS NULL THEN
        RAISE EXCEPTION 'El primer apellido es obligatorio.';
    END IF;

    IF LENGTH(BTRIM(p_user_name)) > 20 THEN
        RAISE EXCEPTION 'El nombre de usuario no puede superar 20 caracteres.';
    END IF;

    IF p_u_correo IS NOT NULL AND LENGTH(BTRIM(p_u_correo)) > 100 THEN
        RAISE EXCEPTION 'El correo no puede superar 100 caracteres.';
    END IF;

    IF p_u_telefono IS NOT NULL AND LENGTH(BTRIM(p_u_telefono)) > 15 THEN
        RAISE EXCEPTION 'El telefono no puede superar 15 caracteres.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.usuarios u
        WHERE LOWER(u.user_name) = LOWER(BTRIM(p_user_name))
    ) THEN
        RAISE EXCEPTION 'El nombre de usuario ya existe.';
    END IF;

    IF p_u_correo IS NOT NULL AND EXISTS (
        SELECT 1
        FROM public.usuarios u
        WHERE LOWER(u.u_correo) = LOWER(BTRIM(p_u_correo))
    ) THEN
        RAISE EXCEPTION 'El correo ya esta registrado.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.roles r WHERE r.role_id = p_role_id) THEN
        RAISE EXCEPTION 'El rol indicado no existe.';
    END IF;

    IF p_gender_id IS NOT NULL
        AND NOT EXISTS (SELECT 1 FROM public.gender g WHERE g.gender_id = p_gender_id) THEN
        RAISE EXCEPTION 'El genero indicado no existe.';
    END IF;

    IF p_u_fechanacimiento IS NOT NULL THEN
        v_edad := DATE_PART('year', AGE(CURRENT_DATE, p_u_fechanacimiento))::integer;
    END IF;

    INSERT INTO public.usuarios (
        user_name,
        user_password,
        u_pnombre,
        u_snombre,
        u_papellido,
        u_sapellido,
        u_fechanacimiento,
        u_edad,
        gender_id,
        u_correo,
        u_telefono,
        u_estudianteutp,
        role_id
    )
    VALUES (
        BTRIM(p_user_name),
        p_user_password,
        BTRIM(p_u_pnombre),
        NULLIF(BTRIM(p_u_snombre), ''),
        BTRIM(p_u_papellido),
        NULLIF(BTRIM(p_u_sapellido), ''),
        p_u_fechanacimiento,
        v_edad,
        p_gender_id,
        NULLIF(BTRIM(p_u_correo), ''),
        NULLIF(BTRIM(p_u_telefono), ''),
        COALESCE(p_u_estudianteutp, TRUE),
        p_role_id
    )
    RETURNING usuarios.user_id INTO v_user_id;

    RETURN QUERY
    SELECT
        u.user_id,
        u.user_name,
        u.u_pnombre,
        u.u_snombre,
        u.u_papellido,
        u.u_sapellido,
        u.u_fechanacimiento,
        u.u_edad,
        u.gender_id,
        u.u_correo,
        u.u_telefono,
        u.u_estudianteutp,
        u.role_id
    FROM public.usuarios u
    WHERE u.user_id = v_user_id;
END;
$$;
