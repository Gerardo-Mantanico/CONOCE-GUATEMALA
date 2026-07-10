CREATE SCHEMA IF NOT EXISTS meta;

-- ============================================================
-- 1. Versionamiento del proyecto
-- ============================================================

CREATE TABLE IF NOT EXISTS meta.version_proyecto (
    id_version INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    numero_version VARCHAR(20) NOT NULL UNIQUE,
    nombre_version VARCHAR(120),
    fecha_version DATE NOT NULL,
    descripcion TEXT NOT NULL,
    cambios_principales TEXT NOT NULL,
    responsable VARCHAR(150),
    estado VARCHAR(30) NOT NULL DEFAULT 'ACTIVA',
    observaciones TEXT,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT ck_version_proyecto_estado
        CHECK (estado IN ('ACTIVA', 'BORRADOR', 'CERRADA', 'OBSOLETA'))
);

COMMENT ON TABLE meta.version_proyecto IS
'Registra las versiones del proyecto, lo que incluye cada versión y los cambios principales.';

COMMENT ON COLUMN meta.version_proyecto.numero_version IS
'Número o etiqueta de la versión, por ejemplo 1.0, 1.1 o 2.0.';

COMMENT ON COLUMN meta.version_proyecto.cambios_principales IS
'Resumen de esquemas, tablas, fuentes o cambios agregados en esta versión.';


-- ============================================================
-- 2. Catálogo de esquemas
-- ============================================================

CREATE TABLE IF NOT EXISTS meta.esquema_datos (
    id_esquema INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_esquema VARCHAR(80) NOT NULL UNIQUE,
    titulo VARCHAR(150) NOT NULL,
    descripcion TEXT NOT NULL,
    objetivo TEXT NOT NULL,
    alcance TEXT NOT NULL,
    fuera_de_alcance TEXT,
    responsable VARCHAR(150),
    id_version_desde INT REFERENCES meta.version_proyecto(id_version),
    estado VARCHAR(30) NOT NULL DEFAULT 'ACTIVO',
    observaciones TEXT,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT ck_esquema_datos_estado
        CHECK (estado IN ('ACTIVO', 'BORRADOR', 'DEPRECATED', 'INACTIVO'))
);

COMMENT ON TABLE meta.esquema_datos IS
'Describe los esquemas disponibles en la base de datos, su objetivo, alcance y límites.';

COMMENT ON COLUMN meta.esquema_datos.fuera_de_alcance IS
'Describe qué tipo de información no debe almacenarse dentro de este esquema.';


-- ============================================================
-- 3. Catálogo de tablas
-- ============================================================

CREATE TABLE IF NOT EXISTS meta.tabla_datos (
    id_tabla INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_esquema INT NOT NULL REFERENCES meta.esquema_datos(id_esquema),
    nombre_tabla VARCHAR(120) NOT NULL,
    titulo VARCHAR(180) NOT NULL,
    descripcion TEXT NOT NULL,
    tipo_tabla VARCHAR(50) NOT NULL,
    granularidad TEXT,
    criterio_inclusion TEXT,
    criterio_exclusion TEXT,
    ejemplo_uso TEXT,
    id_version_desde INT REFERENCES meta.version_proyecto(id_version),
    estado VARCHAR(30) NOT NULL DEFAULT 'ACTIVA',
    observaciones TEXT,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_tabla_datos UNIQUE (id_esquema, nombre_tabla),

    CONSTRAINT ck_tabla_datos_tipo
        CHECK (tipo_tabla IN (
            'CATALOGO',
            'OPERATIVA',
            'RELACIONAL',
            'PUENTE',
            'METADATA',
            'FUENTE',
            'HISTORICA',
            'TRANSACCIONAL',
            'OTRA'
        )),

    CONSTRAINT ck_tabla_datos_estado
        CHECK (estado IN ('ACTIVA', 'BORRADOR', 'DEPRECATED', 'INACTIVA'))
);

COMMENT ON TABLE meta.tabla_datos IS
'Describe cada tabla del proyecto, su uso, granularidad y criterios para decidir si un dato pertenece o no a ella.';

COMMENT ON COLUMN meta.tabla_datos.criterio_inclusion IS
'Reglas o criterios para determinar qué datos sí deben registrarse en esta tabla.';

COMMENT ON COLUMN meta.tabla_datos.criterio_exclusion IS
'Reglas o criterios para determinar qué datos no deben registrarse en esta tabla.';


-- ============================================================
-- 4. Diccionario de columnas
-- ============================================================

CREATE TABLE IF NOT EXISTS meta.columna_datos (
    id_columna INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tabla INT NOT NULL REFERENCES meta.tabla_datos(id_tabla),
    nombre_columna VARCHAR(120) NOT NULL,
    tipo_dato VARCHAR(80) NOT NULL,
    descripcion TEXT NOT NULL,
    obligatorio BOOLEAN NOT NULL DEFAULT FALSE,
    es_llave_primaria BOOLEAN NOT NULL DEFAULT FALSE,
    es_llave_foranea BOOLEAN NOT NULL DEFAULT FALSE,
    tabla_referenciada VARCHAR(200),
    columna_referenciada VARCHAR(120),
    valores_permitidos TEXT,
    ejemplo_valor TEXT,
    regla_validacion TEXT,
    id_version_desde INT REFERENCES meta.version_proyecto(id_version),
    observaciones TEXT,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_columna_datos UNIQUE (id_tabla, nombre_columna)
);

COMMENT ON TABLE meta.columna_datos IS
'Diccionario de columnas consultable desde la base de datos.';

COMMENT ON COLUMN meta.columna_datos.valores_permitidos IS
'Lista o descripción de valores aceptados para la columna cuando aplique.';

COMMENT ON COLUMN meta.columna_datos.ejemplo_valor IS
'Ejemplo de valor válido para facilitar la comprensión del campo.';


-- ============================================================
-- 5. Catálogo de temas
-- ============================================================

CREATE TABLE IF NOT EXISTS meta.tema_datos (
    id_tema INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_tema VARCHAR(120) NOT NULL UNIQUE,
    descripcion TEXT NOT NULL,
    palabras_clave TEXT,
    tema_padre_id INT REFERENCES meta.tema_datos(id_tema),
    estado VARCHAR(30) NOT NULL DEFAULT 'ACTIVO',
    observaciones TEXT,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT ck_tema_datos_estado
        CHECK (estado IN ('ACTIVO', 'BORRADOR', 'INACTIVO'))
);

COMMENT ON TABLE meta.tema_datos IS
'Catálogo de temas o dominios de búsqueda, por ejemplo turismo, deportes, cultura, geografía o patrimonio.';

COMMENT ON COLUMN meta.tema_datos.palabras_clave IS
'Palabras clave asociadas al tema para facilitar búsquedas dentro del catálogo de datos.';


-- ============================================================
-- 6. Relación entre temas y objetos de base de datos
-- ============================================================

CREATE TABLE IF NOT EXISTS meta.objeto_tema (
    id_objeto_tema INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tema INT NOT NULL REFERENCES meta.tema_datos(id_tema),
    nivel_objeto VARCHAR(30) NOT NULL,
    id_esquema INT REFERENCES meta.esquema_datos(id_esquema),
    id_tabla INT REFERENCES meta.tabla_datos(id_tabla),
    id_columna INT REFERENCES meta.columna_datos(id_columna),
    relevancia VARCHAR(30) NOT NULL DEFAULT 'MEDIA',
    justificacion TEXT,
    ejemplo_relacion TEXT,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT ck_objeto_tema_nivel
        CHECK (nivel_objeto IN ('ESQUEMA', 'TABLA', 'COLUMNA')),

    CONSTRAINT ck_objeto_tema_relevancia
        CHECK (relevancia IN ('ALTA', 'MEDIA', 'BAJA')),

    CONSTRAINT ck_objeto_tema_objeto
        CHECK (
            (nivel_objeto = 'ESQUEMA' AND id_esquema IS NOT NULL AND id_tabla IS NULL AND id_columna IS NULL)
            OR
            (nivel_objeto = 'TABLA' AND id_tabla IS NOT NULL AND id_columna IS NULL)
            OR
            (nivel_objeto = 'COLUMNA' AND id_columna IS NOT NULL)
        )
);

COMMENT ON TABLE meta.objeto_tema IS
'Relaciona temas con esquemas, tablas o columnas para permitir búsquedas temáticas dentro de la base.';

COMMENT ON COLUMN meta.objeto_tema.justificacion IS
'Explica por qué el objeto se relaciona con el tema indicado.';


-- ============================================================
-- 7. Catálogo general de fuentes
-- ============================================================

CREATE TABLE IF NOT EXISTS meta.fuente_datos (
    id_fuente INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo_fuente VARCHAR(120) NOT NULL UNIQUE,
    nombre_fuente VARCHAR(250) NOT NULL,
    institucion VARCHAR(250),
    tipo_fuente VARCHAR(80) NOT NULL,
    url TEXT,
    fecha_consulta DATE,
    descripcion TEXT,
    confiabilidad VARCHAR(30) NOT NULL DEFAULT 'MEDIA',
    cobertura_geografica VARCHAR(150),
    licencia_uso TEXT,
    observaciones TEXT,
    estado VARCHAR(30) NOT NULL DEFAULT 'ACTIVA',
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT ck_fuente_datos_tipo
        CHECK (tipo_fuente IN (
            'OFICIAL',
            'INSTITUCIONAL',
            'INTERNACIONAL',
            'MUNICIPAL',
            'ACADEMICA',
            'ABIERTA',
            'MANUAL',
            'OTRA'
        )),

    CONSTRAINT ck_fuente_datos_confiabilidad
        CHECK (confiabilidad IN ('ALTA', 'MEDIA', 'BAJA')),

    CONSTRAINT ck_fuente_datos_estado
        CHECK (estado IN ('ACTIVA', 'BORRADOR', 'INACTIVA'))
);

COMMENT ON TABLE meta.fuente_datos IS
'Registra las fuentes utilizadas en el proyecto, su institución, URL, tipo y nivel de confiabilidad.';

COMMENT ON COLUMN meta.fuente_datos.codigo_fuente IS
'Código corto único para identificar la fuente dentro del proyecto.';


-- ============================================================
-- 8. Relación entre fuentes y tablas/columnas
-- ============================================================

CREATE TABLE IF NOT EXISTS meta.tabla_fuente (
    id_tabla_fuente INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_fuente INT NOT NULL REFERENCES meta.fuente_datos(id_fuente),
    nivel_respaldo VARCHAR(30) NOT NULL DEFAULT 'TABLA',
    id_esquema INT REFERENCES meta.esquema_datos(id_esquema),
    id_tabla INT REFERENCES meta.tabla_datos(id_tabla),
    id_columna INT REFERENCES meta.columna_datos(id_columna),
    uso_fuente TEXT NOT NULL,
    campos_respalda TEXT,
    observaciones TEXT,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT ck_tabla_fuente_nivel
        CHECK (nivel_respaldo IN ('ESQUEMA', 'TABLA', 'COLUMNA', 'REGISTRO')),

    CONSTRAINT ck_tabla_fuente_objeto
        CHECK (
            (nivel_respaldo = 'ESQUEMA' AND id_esquema IS NOT NULL AND id_tabla IS NULL AND id_columna IS NULL)
            OR
            (nivel_respaldo = 'TABLA' AND id_tabla IS NOT NULL AND id_columna IS NULL)
            OR
            (nivel_respaldo = 'COLUMNA' AND id_columna IS NOT NULL)
            OR
            (nivel_respaldo = 'REGISTRO' AND id_tabla IS NOT NULL)
        )
);

COMMENT ON TABLE meta.tabla_fuente IS
'Relaciona fuentes con esquemas, tablas, columnas o registros que son respaldados por dichas fuentes.';

COMMENT ON COLUMN meta.tabla_fuente.campos_respalda IS
'Campos o atributos específicos que la fuente respalda.';


-- ============================================================
-- 9. Reglas de calidad de datos
-- ============================================================

CREATE TABLE IF NOT EXISTS meta.regla_calidad (
    id_regla INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tabla INT NOT NULL REFERENCES meta.tabla_datos(id_tabla),
    id_columna INT REFERENCES meta.columna_datos(id_columna),
    nombre_regla VARCHAR(180) NOT NULL,
    descripcion TEXT NOT NULL,
    tipo_regla VARCHAR(50) NOT NULL,
    severidad VARCHAR(30) NOT NULL DEFAULT 'MEDIA',
    expresion_validacion TEXT,
    accion_si_falla TEXT,
    estado VARCHAR(30) NOT NULL DEFAULT 'ACTIVA',
    id_version_desde INT REFERENCES meta.version_proyecto(id_version),
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT ck_regla_calidad_tipo
        CHECK (tipo_regla IN (
            'OBLIGATORIEDAD',
            'UNICIDAD',
            'REFERENCIAL',
            'FORMATO',
            'RANGO',
            'CATALOGO',
            'FUENTE',
            'COHERENCIA',
            'REVISION_PARES',
            'OTRA'
        )),

    CONSTRAINT ck_regla_calidad_severidad
        CHECK (severidad IN ('ALTA', 'MEDIA', 'BAJA')),

    CONSTRAINT ck_regla_calidad_estado
        CHECK (estado IN ('ACTIVA', 'BORRADOR', 'INACTIVA'))
);

COMMENT ON TABLE meta.regla_calidad IS
'Define reglas de calidad que deben cumplir los datos registrados en las tablas del proyecto.';

COMMENT ON COLUMN meta.regla_calidad.expresion_validacion IS
'Expresión SQL, pseudocódigo o descripción de cómo validar la regla.';


-- ============================================================
-- 10. Revisión por pares
-- ============================================================

CREATE TABLE IF NOT EXISTS meta.revision_pares (
    id_revision INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nivel_revision VARCHAR(30) NOT NULL,
    id_esquema INT REFERENCES meta.esquema_datos(id_esquema),
    id_tabla INT REFERENCES meta.tabla_datos(id_tabla),
    id_columna INT REFERENCES meta.columna_datos(id_columna),
    id_regla INT REFERENCES meta.regla_calidad(id_regla),
    tipo_revision VARCHAR(50) NOT NULL,
    descripcion_revision TEXT,
    revisor_1 VARCHAR(150) NOT NULL,
    estado_revisor_1 VARCHAR(30) NOT NULL,
    fecha_revisor_1 DATE,
    comentario_revisor_1 TEXT,
    revisor_2 VARCHAR(150) NOT NULL,
    estado_revisor_2 VARCHAR(30) NOT NULL,
    fecha_revisor_2 DATE,
    comentario_revisor_2 TEXT,
    estado_final VARCHAR(30) NOT NULL DEFAULT 'PENDIENTE',
    observaciones TEXT,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT ck_revision_pares_nivel
        CHECK (nivel_revision IN ('ESQUEMA', 'TABLA', 'COLUMNA', 'REGLA', 'FUENTE', 'DATOS')),

    CONSTRAINT ck_revision_pares_tipo
        CHECK (tipo_revision IN ('MODELO', 'DATOS', 'FUENTE', 'CALIDAD', 'DOCUMENTACION', 'OTRA')),

    CONSTRAINT ck_revision_pares_estado_1
        CHECK (estado_revisor_1 IN ('PENDIENTE', 'APROBADO', 'RECHAZADO', 'OBSERVADO')),

    CONSTRAINT ck_revision_pares_estado_2
        CHECK (estado_revisor_2 IN ('PENDIENTE', 'APROBADO', 'RECHAZADO', 'OBSERVADO')),

    CONSTRAINT ck_revision_pares_estado_final
        CHECK (estado_final IN ('PENDIENTE', 'APROBADO', 'RECHAZADO', 'OBSERVADO')),

    CONSTRAINT ck_revision_pares_objeto
        CHECK (
            (nivel_revision = 'ESQUEMA' AND id_esquema IS NOT NULL)
            OR
            (nivel_revision = 'TABLA' AND id_tabla IS NOT NULL)
            OR
            (nivel_revision = 'COLUMNA' AND id_columna IS NOT NULL)
            OR
            (nivel_revision = 'REGLA' AND id_regla IS NOT NULL)
            OR
            (nivel_revision IN ('FUENTE', 'DATOS'))
        )
);

COMMENT ON TABLE meta.revision_pares IS
'Registra la revisión o aprobación por pares de esquemas, tablas, columnas, reglas, fuentes o datos.';

COMMENT ON COLUMN meta.revision_pares.estado_final IS
'Resultado final de la revisión después de considerar a los dos revisores.';


-- ============================================================
-- 11. Decisiones de modelado
-- ============================================================

CREATE TABLE IF NOT EXISTS meta.decision_modelado (
    id_decision INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tema INT REFERENCES meta.tema_datos(id_tema),
    tema VARCHAR(150) NOT NULL,
    pregunta TEXT NOT NULL,
    decision TEXT NOT NULL,
    justificacion TEXT NOT NULL,
    ejemplo TEXT,
    id_esquema_recomendado INT REFERENCES meta.esquema_datos(id_esquema),
    id_tabla_recomendada INT REFERENCES meta.tabla_datos(id_tabla),
    alternativa TEXT,
    responsable VARCHAR(150),
    fecha_decision DATE NOT NULL DEFAULT CURRENT_DATE,
    id_version_desde INT REFERENCES meta.version_proyecto(id_version),
    estado VARCHAR(30) NOT NULL DEFAULT 'VIGENTE',
    observaciones TEXT,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT ck_decision_modelado_estado
        CHECK (estado IN ('VIGENTE', 'BORRADOR', 'OBSOLETA'))
);

COMMENT ON TABLE meta.decision_modelado IS
'Documenta decisiones importantes sobre dónde debe almacenarse un tipo de dato y por qué.';

COMMENT ON COLUMN meta.decision_modelado.pregunta IS
'Pregunta de modelado que se desea resolver, por ejemplo si festividades pertenecen a turismo o cultura.';

COMMENT ON COLUMN meta.decision_modelado.decision IS
'Respuesta o criterio aprobado para modelar el dato.';

COMMENT ON COLUMN meta.decision_modelado.alternativa IS
'Otra opción posible de modelado, si existe.';


-- ============================================================
-- 12. Índices de apoyo para búsquedas
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_esquema_datos_nombre
    ON meta.esquema_datos(nombre_esquema);

CREATE INDEX IF NOT EXISTS idx_tabla_datos_esquema
    ON meta.tabla_datos(id_esquema);

CREATE INDEX IF NOT EXISTS idx_tabla_datos_nombre
    ON meta.tabla_datos(nombre_tabla);

CREATE INDEX IF NOT EXISTS idx_columna_datos_tabla
    ON meta.columna_datos(id_tabla);

CREATE INDEX IF NOT EXISTS idx_columna_datos_nombre
    ON meta.columna_datos(nombre_columna);

CREATE INDEX IF NOT EXISTS idx_tema_datos_nombre
    ON meta.tema_datos(nombre_tema);

CREATE INDEX IF NOT EXISTS idx_objeto_tema_tema
    ON meta.objeto_tema(id_tema);

CREATE INDEX IF NOT EXISTS idx_objeto_tema_esquema
    ON meta.objeto_tema(id_esquema);

CREATE INDEX IF NOT EXISTS idx_objeto_tema_tabla
    ON meta.objeto_tema(id_tabla);

CREATE INDEX IF NOT EXISTS idx_fuente_datos_codigo
    ON meta.fuente_datos(codigo_fuente);

CREATE INDEX IF NOT EXISTS idx_tabla_fuente_fuente
    ON meta.tabla_fuente(id_fuente);

CREATE INDEX IF NOT EXISTS idx_regla_calidad_tabla
    ON meta.regla_calidad(id_tabla);

CREATE INDEX IF NOT EXISTS idx_revision_pares_tabla
    ON meta.revision_pares(id_tabla);

CREATE INDEX IF NOT EXISTS idx_decision_modelado_tema
    ON meta.decision_modelado(tema);


-- ============================================================
-- 13. Vistas útiles para consulta rápida del catálogo
-- ============================================================

CREATE OR REPLACE VIEW meta.vw_catalogo_tablas AS
SELECT
    e.nombre_esquema,
    e.titulo AS titulo_esquema,
    t.nombre_tabla,
    t.titulo AS titulo_tabla,
    t.descripcion,
    t.tipo_tabla,
    t.granularidad,
    t.criterio_inclusion,
    t.criterio_exclusion,
    v.numero_version AS version_desde,
    t.estado
FROM meta.tabla_datos t
JOIN meta.esquema_datos e
    ON e.id_esquema = t.id_esquema
LEFT JOIN meta.version_proyecto v
    ON v.id_version = t.id_version_desde;

COMMENT ON VIEW meta.vw_catalogo_tablas IS
'Vista rápida para consultar los esquemas y tablas documentadas en el catálogo de metadatos.';


CREATE OR REPLACE VIEW meta.vw_diccionario_columnas AS
SELECT
    e.nombre_esquema,
    t.nombre_tabla,
    c.nombre_columna,
    c.tipo_dato,
    c.descripcion,
    c.obligatorio,
    c.es_llave_primaria,
    c.es_llave_foranea,
    c.tabla_referenciada,
    c.columna_referenciada,
    c.valores_permitidos,
    c.ejemplo_valor,
    c.regla_validacion
FROM meta.columna_datos c
JOIN meta.tabla_datos t
    ON t.id_tabla = c.id_tabla
JOIN meta.esquema_datos e
    ON e.id_esquema = t.id_esquema;

COMMENT ON VIEW meta.vw_diccionario_columnas IS
'Vista de diccionario de datos con columnas, tipos, descripciones y reglas básicas.';


CREATE OR REPLACE VIEW meta.vw_busqueda_temas AS
SELECT
    tema.nombre_tema,
    tema.palabras_clave,
    ot.nivel_objeto,
    e.nombre_esquema,
    td.nombre_tabla,
    cd.nombre_columna,
    ot.relevancia,
    ot.justificacion,
    ot.ejemplo_relacion
FROM meta.objeto_tema ot
JOIN meta.tema_datos tema
    ON tema.id_tema = ot.id_tema
LEFT JOIN meta.esquema_datos e
    ON e.id_esquema = ot.id_esquema
LEFT JOIN meta.tabla_datos td
    ON td.id_tabla = ot.id_tabla
LEFT JOIN meta.columna_datos cd
    ON cd.id_columna = ot.id_columna;

COMMENT ON VIEW meta.vw_busqueda_temas IS
'Vista para buscar qué esquemas, tablas o columnas están relacionados con un tema específico.';


CREATE OR REPLACE VIEW meta.vw_fuentes_por_tabla AS
SELECT
    f.codigo_fuente,
    f.nombre_fuente,
    f.institucion,
    f.tipo_fuente,
    f.url,
    f.confiabilidad,
    tf.nivel_respaldo,
    e.nombre_esquema,
    t.nombre_tabla,
    c.nombre_columna,
    tf.uso_fuente,
    tf.campos_respalda
FROM meta.tabla_fuente tf
JOIN meta.fuente_datos f
    ON f.id_fuente = tf.id_fuente
LEFT JOIN meta.esquema_datos e
    ON e.id_esquema = tf.id_esquema
LEFT JOIN meta.tabla_datos t
    ON t.id_tabla = tf.id_tabla
LEFT JOIN meta.columna_datos c
    ON c.id_columna = tf.id_columna;

COMMENT ON VIEW meta.vw_fuentes_por_tabla IS
'Vista para consultar qué fuentes respaldan cada esquema, tabla o columna.';






-- **********************************************************************
-- **********************************************************************
-- Schema: auditoria
-- Auditoría genérica y centralizada de la base.
-- **********************************************************************
-- **********************************************************************

-- Tabla de registro y función trigger genérica para cualquier tabla
CREATE SCHEMA IF NOT EXISTS auditoria;
COMMENT ON SCHEMA auditoria IS 'Auditoría genérica y centralizada de la base de datos. Registra automáticamente cambios estructurales y de datos sin requerir código específico por tabla.';

-- Bitácora de registros
-- Guarda el antes/después como JSONB, así no depende de la estructura de las tablas auditadas.
CREATE TABLE auditoria.registro (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    esquema TEXT NOT NULL,
    tabla TEXT NOT NULL,
    operacion TEXT NOT NULL,          -- INSERT | UPDATE | DELETE
    pk TEXT,                          -- valor de la columna 'id' si existe
    datos_old JSONB,                  -- fila previa (UPDATE/DELETE)
    datos_new JSONB,                  -- fila nueva (INSERT/UPDATE)
    usuario_bd TEXT NOT NULL DEFAULT current_user,   -- rol de PostgreSQL
    app_usuario TEXT,                 -- colaborador/ETL (GUC 'audit.app_usuario')
    fecha TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE auditoria.registro IS 'Bitácora central de auditoría. Guarda el estado previo y posterior de las filas modificadas en formato JSONB para independizarse de la estructura de cada tabla.';
COMMENT ON COLUMN auditoria.registro.id IS 'Identificador único autogenerado del registro de auditoría.';
COMMENT ON COLUMN auditoria.registro.esquema IS 'Nombre del esquema de la base de datos donde ocurrió la modificación.';
COMMENT ON COLUMN auditoria.registro.tabla IS 'Nombre de la tabla donde ocurrió la modificación.';
COMMENT ON COLUMN auditoria.registro.operacion IS 'Tipo de operación DML realizada (INSERT, UPDATE o DELETE).';
COMMENT ON COLUMN auditoria.registro.pk IS 'Valor de la columna "id" de la fila afectada (si la tabla auditada cuenta con una).';
COMMENT ON COLUMN auditoria.registro.datos_old IS 'Estado previo de la fila en formato JSONB (se llena en operaciones UPDATE y DELETE).';
COMMENT ON COLUMN auditoria.registro.datos_new IS 'Nuevo estado de la fila en formato JSONB (se llena en operaciones INSERT y UPDATE).';
COMMENT ON COLUMN auditoria.registro.usuario_bd IS 'Rol o usuario nativo de PostgreSQL que ejecutó la operación en la base de datos.';
COMMENT ON COLUMN auditoria.registro.app_usuario IS 'Usuario de la aplicación, colaborador o proceso ETL responsable del cambio (obtenido de la variable GUC "audit.app_usuario").';
COMMENT ON COLUMN auditoria.registro.fecha IS 'Fecha y hora exactas en la que se registró la operación.';

CREATE INDEX ON auditoria.registro (esquema, tabla);
CREATE INDEX ON auditoria.registro (fecha);

-- Función trigger genérica. Usa las variables TG_* para saber qué tabla lo disparó
CREATE OR REPLACE FUNCTION auditoria.fn_auditar()
    RETURNS trigger
    LANGUAGE plpgsql
AS $$
DECLARE
    v_old JSONB := NULL;
    v_new JSONB := NULL;
BEGIN
    IF (TG_OP = 'DELETE') THEN
        v_old := to_jsonb(OLD);
    ELSIF (TG_OP = 'UPDATE') THEN
        v_old := to_jsonb(OLD);
        v_new := to_jsonb(NEW);
    ELSE  -- INSERT
        v_new := to_jsonb(NEW);
    END IF;

    INSERT INTO auditoria.registro
    (esquema, tabla, operacion, pk, datos_old, datos_new, app_usuario)
    VALUES (
               TG_TABLE_SCHEMA,
               TG_TABLE_NAME,
               TG_OP,
               COALESCE(v_new ->> 'id', v_old ->> 'id'),   -- NULL si la tabla no tiene 'id'
               v_old,
               v_new,
               current_setting('audit.app_usuario', true)  -- NULL si no se indica
           );
    RETURN NULL;  -- trigger AFTER: el valor de retorno se ignora
END;
$$;
COMMENT ON FUNCTION auditoria.fn_auditar() IS 'Función trigger genérica. Determina el tipo de operación (TG_OP), extrae los registros OLD/NEW según corresponda, los convierte a JSONB e inserta el evento en auditoria.registro.';


-- Engancha el trigger de auditoría a todas las tablas de los schemas indicados que aún no lo tengan.
-- Audita todos los schemas de dominio, excluyendo los de sistema, 'auditoria' (su propio esquema) y 'meta' (trazabilidad de cargas)
-- Para auditar meta u otro subconjunto: SELECT auditoria.aplicar_auditoria(ARRAY['meta']);
CREATE OR REPLACE FUNCTION auditoria.aplicar_auditoria(p_schemas TEXT[] DEFAULT NULL)
    RETURNS void
    LANGUAGE plpgsql
AS $$
DECLARE
    v_schemas TEXT[];
    r RECORD;
BEGIN
    IF p_schemas IS NULL THEN
        SELECT array_agg(nspname) INTO v_schemas
        FROM pg_namespace
        WHERE nspname NOT IN ('auditoria', 'meta',
                              'pg_catalog', 'information_schema', 'pg_toast')
          AND nspname NOT LIKE 'pg_temp%'
          AND nspname NOT LIKE 'pg_toast_temp%';
    ELSE
        v_schemas := p_schemas;
    END IF;

    IF v_schemas IS NULL THEN
        RETURN;  -- no hay schemas que auditar todavía
    END IF;

    FOR r IN
        SELECT n.nspname AS esquema, c.relname AS tabla
        FROM pg_class c
                 JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relkind = 'r'                       -- solo tablas ordinarias
          AND n.nspname = ANY(v_schemas)
          AND NOT EXISTS (
            SELECT 1 FROM pg_trigger t
            WHERE t.tgrelid = c.oid
              AND t.tgname  = 'trg_auditoria'
              AND NOT t.tgisinternal
        )
        LOOP
            EXECUTE format(
                    'CREATE TRIGGER trg_auditoria
                       AFTER INSERT OR UPDATE OR DELETE ON %I.%I
                       FOR EACH ROW EXECUTE FUNCTION auditoria.fn_auditar()',
                    r.esquema, r.tabla
                    );
            RAISE NOTICE 'Auditoría aplicada a %.%', r.esquema, r.tabla;
        END LOOP;
END;
$$;
COMMENT ON FUNCTION auditoria.aplicar_auditoria(TEXT[]) IS 'Función utilitaria que asocia automáticamente el trigger "trg_auditoria" a todas las tablas ordinarias de los esquemas indicados. Si no se especifican esquemas, audita todos los esquemas de dominio excluyendo los de sistema, "meta" y "auditoria".';

-- **********************************************************************
-- Fin schema auditoria
-- **********************************************************************






-- **********************************************************************
-- **********************************************************************
-- Schema: geografía
-- Información geográfica, divisiones territoriales, etc.
-- **********************************************************************
-- **********************************************************************


CREATE SCHEMA geografia;
COMMENT ON SCHEMA geografia IS 'Entidades geográficas: países, regiones, departamentos, municipios.';

CREATE TABLE geografia.pais (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    pcode VARCHAR(12) UNIQUE,
    iso2 CHAR(2),
    iso3 CHAR(3),
    area_km2 NUMERIC(14, 4),
    centro_lat NUMERIC(11, 8),
    centro_lon NUMERIC(11, 8)
);
COMMENT ON TABLE geografia.pais IS 'Catálogo de países utilizados por el sistema como nivel geográfico principal.';
COMMENT ON COLUMN geografia.pais.id IS 'Identificador único del país.';
COMMENT ON COLUMN geografia.pais.nombre IS 'Nombre oficial del país.';
COMMENT ON COLUMN geografia.pais.pcode IS 'Código geográfico estandarizado (P-Code OCHA/HDX) del país, p.ej. GT';
COMMENT ON COLUMN geografia.pais.iso2 IS 'Código ISO 3166-1 alfa-2 del país.';
COMMENT ON COLUMN geografia.pais.iso3 IS 'Código ISO 3166-1 alfa-3 del país.';
COMMENT ON COLUMN geografia.pais.area_km2 IS 'Superficie territorial del país expresada en kilómetros cuadrados.';
COMMENT ON COLUMN geografia.pais.centro_lat IS 'Latitud del centroide geográfico del país.';
COMMENT ON COLUMN geografia.pais.centro_lon IS 'Longitud del centroide geográfico del país.';

CREATE TRIGGER trg_auditoria AFTER INSERT OR DELETE OR UPDATE ON geografia.pais FOR EACH ROW EXECUTE FUNCTION auditoria.fn_auditar();

CREATE TABLE geografia.departamento (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    pais_id INT NOT NULL REFERENCES geografia.pais(id),
    pcode VARCHAR(12) UNIQUE,
    area_km2 NUMERIC(14, 4),
    centro_lat NUMERIC(11, 8),
    centro_lon NUMERIC(11, 8)
);
COMMENT ON TABLE geografia.departamento IS 'Catálogo de departamentos o divisiones administrativas de primer nivel.';
COMMENT ON COLUMN geografia.departamento.id IS 'Identificador único del departamento.';
COMMENT ON COLUMN geografia.departamento.nombre IS 'Nombre oficial del departamento.';
COMMENT ON COLUMN geografia.departamento.pcode IS 'Código geográfico estandarizado (P-Code OCHA/HDX) del departamento, p.ej. GT04.';
COMMENT ON COLUMN geografia.departamento.area_km2 IS 'Superficie territorial del departamento expresada en kilómetros cuadrados.';
COMMENT ON COLUMN geografia.departamento.centro_lat IS 'Latitud del centroide geográfico del departamento.';
COMMENT ON COLUMN geografia.departamento.centro_lon IS 'Longitud del centroide geográfico del departamento.';

CREATE TRIGGER trg_auditoria AFTER INSERT OR DELETE OR UPDATE ON geografia.departamento FOR EACH ROW EXECUTE FUNCTION auditoria.fn_auditar();


CREATE TABLE geografia.municipio (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    departamento_id INT NOT NULL REFERENCES geografia.departamento(id),
    nombre VARCHAR(100) NOT NULL,
    pcode VARCHAR(12) UNIQUE,
    area_km2 NUMERIC(14, 4),
    centro_lat NUMERIC(11, 8),
    centro_lon NUMERIC(11, 8)
);
COMMENT ON TABLE geografia.municipio IS 'Catálogo de municipios asociados a un departamento.';
COMMENT ON COLUMN geografia.municipio.id IS 'Identificador único del municipio.';
COMMENT ON COLUMN geografia.municipio.departamento_id IS 'Departamento al que pertenece el municipio.';
COMMENT ON COLUMN geografia.municipio.nombre IS 'Nombre oficial del municipio.';
COMMENT ON COLUMN geografia.municipio.pcode IS 'Código geográfico estandarizado (P-Code OCHA/HDX) del municipio, p.ej. GT0411';
COMMENT ON COLUMN geografia.municipio.area_km2 IS 'Superficie territorial del municipio expresada en kilómetros cuadrados.';
COMMENT ON COLUMN geografia.municipio.centro_lat IS'Latitud del centroide geográfico del municipio.';
COMMENT ON COLUMN geografia.municipio.centro_lon IS 'Longitud del centroide geográfico del municipio.';

CREATE TRIGGER trg_auditoria AFTER INSERT OR DELETE OR UPDATE ON geografia.municipio FOR EACH ROW EXECUTE FUNCTION auditoria.fn_auditar();

-- **********************************************************************
-- Fin schema geografia
-- **********************************************************************






-- **********************************************************************
-- **********************************************************************
-- Schema: clima
-- Climatología registrada por estaciones meteorológicas.
-- **********************************************************************
-- **********************************************************************

CREATE SCHEMA IF NOT EXISTS clima;
COMMENT ON SCHEMA clima IS 'Registros climáticos históricos y en tiempo real por municipio.';

-- Estación meteorológica
CREATE TABLE clima.estacion (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(200) NOT NULL,
    ubicacion TEXT,
    municipio INT REFERENCES geografia.municipio,
    latitud NUMERIC(10, 7),
    longitud NUMERIC(10, 7)
);

COMMENT ON TABLE  clima.estacion IS 'Estaciones meteorologicas que reportan datos climaticos.';
COMMENT ON COLUMN clima.estacion.codigo IS 'Codigo de la estacion segun la fuente. Clave natural.';
COMMENT ON COLUMN clima.estacion.nombre IS 'Nombre de la estacion.';
COMMENT ON COLUMN clima.estacion.ubicacion IS 'Ubicacion o descripcion del sitio de la estacion.';
COMMENT ON COLUMN clima.estacion.latitud IS 'Latitud de la estacion en grados decimales.';
COMMENT ON COLUMN clima.estacion.longitud IS 'Longitud de la estacion en grados decimales.';

-- Registro climatico diario
-- Una fila por estacion y fecha. Cada medición es opcional
CREATE TABLE clima.registro_climatico (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    estacion_id INT  NOT NULL REFERENCES clima.estacion(id),
    fecha DATE NOT NULL,
    lluvia NUMERIC,
    temperatura_maxima NUMERIC,
    temperatura_minima NUMERIC,
    temperatura_media NUMERIC,
    evaporacion_tanque NUMERIC,
    humedad_relativa NUMERIC,
    brillo_solar NUMERIC,
    nubosidad NUMERIC,
    velocidad_viento NUMERIC,
    direccion_viento NUMERIC,
    presion_atmosferica NUMERIC,
    temperatura_suelo_50cm NUMERIC,
    temperatura_suelo_100cm NUMERIC,
    radiacion NUMERIC,
    CONSTRAINT uq_registro_estacion_fecha UNIQUE (estacion_id, fecha)
);

COMMENT ON TABLE  clima.registro_climatico IS 'Mediciones climáticas diarias por estación. Una fila por estación y fecha.';
COMMENT ON COLUMN clima.registro_climatico.estacion_id IS 'Estación que produjo el registro.';
COMMENT ON COLUMN clima.registro_climatico.fecha IS 'Fecha del registro (dia).';
COMMENT ON COLUMN clima.registro_climatico.lluvia IS 'Precipitación (lluvia) del dia, en mm.';
COMMENT ON COLUMN clima.registro_climatico.temperatura_maxima IS 'Temperatura maxima del dia, en grados Celsius.';
COMMENT ON COLUMN clima.registro_climatico.temperatura_minima IS 'Temperatura minima del dia, en grados Celsius.';
COMMENT ON COLUMN clima.registro_climatico.temperatura_media IS 'Temperatura media del dia, en grados Celsius.';
COMMENT ON COLUMN clima.registro_climatico.evaporacion_tanque IS 'Evaporación medida en tanque, en mm.';
COMMENT ON COLUMN clima.registro_climatico.humedad_relativa IS 'Humedad relativa, en porcentaje.';
COMMENT ON COLUMN clima.registro_climatico.brillo_solar IS 'Brillo solar (horas de sol).';
COMMENT ON COLUMN clima.registro_climatico.nubosidad IS 'Nubosidad reportada por la estación.';
COMMENT ON COLUMN clima.registro_climatico.velocidad_viento IS 'Velocidad del viento según la fuente.';
COMMENT ON COLUMN clima.registro_climatico.direccion_viento IS 'Dirección del viento, en grados.';
COMMENT ON COLUMN clima.registro_climatico.presion_atmosferica IS 'Presión atmosférica, en hPa.';
COMMENT ON COLUMN clima.registro_climatico.temperatura_suelo_50cm IS 'Temperatura del suelo a 50 cm, en grados Celsius.';
COMMENT ON COLUMN clima.registro_climatico.temperatura_suelo_100cm IS 'Temperatura del suelo a 100 cm, en grados Celsius.';
COMMENT ON COLUMN clima.registro_climatico.radiacion IS 'Radiación solar según la fuente.';

CREATE INDEX ON clima.registro_climatico (fecha);

-- **********************************************************************
-- Fin schema clima
-- **********************************************************************


-- **********************************************************************
-- Inicio schema TURISMO
-- **********************************************************************
CREATE SCHEMA IF NOT EXISTS turismo;

COMMENT ON SCHEMA turismo IS 'Esquema del area Turismo para el proyecto CONOSE Occidente / Conocer Guatemala. Consume la geografia oficial desde el esquema geografia.';

-- ============================================================
-- Tipos de datos propios del dominio turismo
-- ============================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'turismo' AND t.typname = 'tipo_destino'
    ) THEN
        CREATE TYPE turismo.tipo_destino AS ENUM (
            'NATURAL',
            'CULTURAL',
            'ARQUEOLOGICO',
            'URBANO',
            'RELIGIOSO',
            'RECREATIVO',
            'MIXTO'
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'turismo' AND t.typname = 'dificultad_destino'
    ) THEN
        CREATE TYPE turismo.dificultad_destino AS ENUM (
            'BAJA',
            'MEDIA',
            'ALTA',
            'VARIABLE'
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'turismo' AND t.typname = 'tipo_patrimonio'
    ) THEN
        CREATE TYPE turismo.tipo_patrimonio AS ENUM (
            'UNESCO_CULTURAL',
            'UNESCO_NATURAL',
            'UNESCO_MIXTO',
            'UNESCO_INTANGIBLE',
            'NACIONAL'
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'turismo' AND t.typname = 'tipo_recomendacion'
    ) THEN
        CREATE TYPE turismo.tipo_recomendacion AS ENUM (
            'SEGURIDAD',
            'AMBIENTAL',
            'CULTURAL',
            'LOGISTICA',
            'TEMPORADA'
        );
    END IF;
END $$;

COMMENT ON TYPE turismo.tipo_destino IS 'Clasificacion general del destino turistico: natural, cultural, arqueologico, urbano, religioso, recreativo o mixto.';
COMMENT ON TYPE turismo.dificultad_destino IS 'Nivel de dificultad esperado para visitar el destino turistico.';
COMMENT ON TYPE turismo.tipo_patrimonio IS 'Tipo de reconocimiento patrimonial asociado al destino o expresion cultural.';
COMMENT ON TYPE turismo.tipo_recomendacion IS 'Tipo de recomendacion asociada a un destino turistico.';

-- ============================================================
-- Funciones helper para resolver llaves de geografia por nombre
-- Evitan guardar departamentos/municipios duplicados en turismo.
-- ============================================================
CREATE OR REPLACE FUNCTION turismo.fn_normalizar_texto(p_texto TEXT)
RETURNS TEXT
LANGUAGE SQL
IMMUTABLE
AS $$
    SELECT lower(
        translate(
            coalesce(p_texto, ''),
            'ÁÉÍÓÚÜÑáéíóúüñ',
            'AEIOUUNaeiouun'
        )
    );
$$;

COMMENT ON FUNCTION turismo.fn_normalizar_texto(TEXT) IS 'Normaliza texto a minusculas y sin tildes para comparar nombres de geografia y turismo sin depender de extensiones externas.';

CREATE OR REPLACE FUNCTION turismo.fn_departamento_id(p_nombre_departamento TEXT)
RETURNS INT
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_id INT;
BEGIN
    SELECT d.id
      INTO v_id
      FROM geografia.departamento d
     WHERE turismo.fn_normalizar_texto(d.nombre) = turismo.fn_normalizar_texto(p_nombre_departamento)
     LIMIT 1;

    IF v_id IS NULL THEN
        RAISE EXCEPTION 'No se encontro el departamento % en geografia.departamento', p_nombre_departamento;
    END IF;

    RETURN v_id;
END;
$$;

COMMENT ON FUNCTION turismo.fn_departamento_id(TEXT) IS 'Devuelve el identificador de geografia.departamento a partir del nombre del departamento.';

CREATE OR REPLACE FUNCTION turismo.fn_municipio_id(
    p_nombre_departamento TEXT,
    p_nombre_municipio TEXT,
    p_obligatorio BOOLEAN DEFAULT FALSE
)
RETURNS INT
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_id INT;
BEGIN
    IF p_nombre_municipio IS NULL OR btrim(p_nombre_municipio) = '' THEN
        RETURN NULL;
    END IF;

    SELECT m.id
      INTO v_id
      FROM geografia.municipio m
      JOIN geografia.departamento d ON d.id = m.departamento_id
     WHERE turismo.fn_normalizar_texto(d.nombre) = turismo.fn_normalizar_texto(p_nombre_departamento)
       AND turismo.fn_normalizar_texto(m.nombre) = turismo.fn_normalizar_texto(p_nombre_municipio)
     LIMIT 1;

    IF v_id IS NULL AND p_obligatorio THEN
        RAISE EXCEPTION 'No se encontro el municipio % en el departamento % dentro de geografia.municipio', p_nombre_municipio, p_nombre_departamento;
    END IF;

    RETURN v_id;
END;
$$;

COMMENT ON FUNCTION turismo.fn_municipio_id(TEXT, TEXT, BOOLEAN) IS 'Devuelve el identificador de geografia.municipio a partir del departamento y municipio; opcionalmente falla si no existe.';

-- ============================================================
-- Fuentes documentales del dominio turismo
-- ============================================================
CREATE TABLE IF NOT EXISTS turismo.fuente_turistica (
    id_fuente        INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    codigo           VARCHAR(80)  NOT NULL UNIQUE,
    nombre           VARCHAR(220) NOT NULL,
    institucion      VARCHAR(180),
    tipo             VARCHAR(80)  NOT NULL,
    url              VARCHAR(700) NOT NULL,
    fecha_consulta   DATE NOT NULL,
    descripcion      TEXT
);

COMMENT ON TABLE turismo.fuente_turistica IS 'Fuentes documentales utilizadas para sustentar los datos reales del area de turismo.';
COMMENT ON COLUMN turismo.fuente_turistica.id_fuente IS 'Identificador unico de la fuente turistica dentro del esquema turismo.';
COMMENT ON COLUMN turismo.fuente_turistica.codigo IS 'Codigo estable de la fuente para usar en migraciones, ETL y trazabilidad.';
COMMENT ON COLUMN turismo.fuente_turistica.nombre IS 'Nombre oficial o descriptivo de la fuente consultada.';
COMMENT ON COLUMN turismo.fuente_turistica.institucion IS 'Institucion, organismo o portal responsable de la fuente.';
COMMENT ON COLUMN turismo.fuente_turistica.tipo IS 'Tipo de fuente: oficial, internacional, cultural, conservacion, turismo u otro.';
COMMENT ON COLUMN turismo.fuente_turistica.url IS 'URL principal consultada.';
COMMENT ON COLUMN turismo.fuente_turistica.fecha_consulta IS 'Fecha de consulta de la fuente.';
COMMENT ON COLUMN turismo.fuente_turistica.descripcion IS 'Descripcion del uso de la fuente dentro del modelo turismo.';
-- ============================================================
-- Regiones turisticas y su relacion con geografia.departamento
-- ============================================================
CREATE TABLE IF NOT EXISTS turismo.region_turistica (
    id_region      INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    codigo         VARCHAR(50)  NOT NULL UNIQUE,
    nombre         VARCHAR(150) NOT NULL UNIQUE,
    descripcion    TEXT,
    fuente_id      INT REFERENCES turismo.fuente_turistica(id_fuente)
);

COMMENT ON TABLE turismo.region_turistica IS 'Regiones turisticas de Guatemala utilizadas para agrupar atractivos y destinos.';
COMMENT ON COLUMN turismo.region_turistica.id_region IS 'Identificador unico de la region turistica.';
COMMENT ON COLUMN turismo.region_turistica.codigo IS 'Codigo estable de la region turistica.';
COMMENT ON COLUMN turismo.region_turistica.nombre IS 'Nombre de la region turistica.';
COMMENT ON COLUMN turismo.region_turistica.descripcion IS 'Descripcion general de la region turistica.';
COMMENT ON COLUMN turismo.region_turistica.fuente_id IS 'Fuente documental principal que respalda la definicion de la region.';
CREATE TABLE IF NOT EXISTS turismo.departamento_region_turistica (
    id_departamento_region INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    region_turistica_id    INT NOT NULL REFERENCES turismo.region_turistica(id_region),
    departamento_id        INT NOT NULL REFERENCES geografia.departamento(id),
    observacion            VARCHAR(400),
    CONSTRAINT uq_turismo_departamento_region UNIQUE (region_turistica_id, departamento_id)
);

COMMENT ON TABLE turismo.departamento_region_turistica IS 'Tabla puente entre regiones turisticas del esquema turismo y departamentos oficiales del esquema geografia.';
COMMENT ON COLUMN turismo.departamento_region_turistica.id_departamento_region IS 'Identificador unico de la relacion departamento-region turistica.';
COMMENT ON COLUMN turismo.departamento_region_turistica.region_turistica_id IS 'Region turistica a la que se asocia el departamento.';
COMMENT ON COLUMN turismo.departamento_region_turistica.departamento_id IS 'Departamento oficial registrado en geografia.departamento.';
COMMENT ON COLUMN turismo.departamento_region_turistica.observacion IS 'Nota para casos donde un departamento participa parcialmente en mas de una region turistica.';
CREATE INDEX IF NOT EXISTS ix_depto_region_region ON turismo.departamento_region_turistica(region_turistica_id);
CREATE INDEX IF NOT EXISTS ix_depto_region_depto ON turismo.departamento_region_turistica(departamento_id);

-- ============================================================
-- Catalogos de clasificacion turistica
-- ============================================================
CREATE TABLE IF NOT EXISTS turismo.categoria_destino (
    id_categoria INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    codigo       VARCHAR(60)  NOT NULL UNIQUE,
    nombre       VARCHAR(120) NOT NULL UNIQUE,
    descripcion  TEXT
);

COMMENT ON TABLE turismo.categoria_destino IS 'Categorias tematicas utilizadas para clasificar destinos turisticos.';
COMMENT ON COLUMN turismo.categoria_destino.id_categoria IS 'Identificador unico de la categoria turistica.';
COMMENT ON COLUMN turismo.categoria_destino.codigo IS 'Codigo estable de la categoria.';
COMMENT ON COLUMN turismo.categoria_destino.nombre IS 'Nombre de la categoria.';
COMMENT ON COLUMN turismo.categoria_destino.descripcion IS 'Descripcion de la categoria y criterio de uso.';
CREATE TABLE IF NOT EXISTS turismo.actividad_turistica (
    id_actividad INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    codigo       VARCHAR(60)  NOT NULL UNIQUE,
    nombre       VARCHAR(140) NOT NULL UNIQUE,
    descripcion  TEXT
);

COMMENT ON TABLE turismo.actividad_turistica IS 'Actividades turisticas que pueden realizarse o recomendarse en los destinos.';
COMMENT ON COLUMN turismo.actividad_turistica.id_actividad IS 'Identificador unico de la actividad turistica.';
COMMENT ON COLUMN turismo.actividad_turistica.codigo IS 'Codigo estable de la actividad.';
COMMENT ON COLUMN turismo.actividad_turistica.nombre IS 'Nombre de la actividad turistica.';
COMMENT ON COLUMN turismo.actividad_turistica.descripcion IS 'Descripcion de la actividad y su uso analitico.';
CREATE TABLE IF NOT EXISTS turismo.temporada_turistica (
    id_temporada INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    codigo       VARCHAR(60)  NOT NULL UNIQUE,
    nombre       VARCHAR(120) NOT NULL UNIQUE,
    meses        VARCHAR(120) NOT NULL,
    descripcion  TEXT
);

COMMENT ON TABLE turismo.temporada_turistica IS 'Temporadas o periodos utiles para planificacion turistica.';
COMMENT ON COLUMN turismo.temporada_turistica.id_temporada IS 'Identificador unico de la temporada turistica.';
COMMENT ON COLUMN turismo.temporada_turistica.codigo IS 'Codigo estable de la temporada.';
COMMENT ON COLUMN turismo.temporada_turistica.nombre IS 'Nombre de la temporada.';
COMMENT ON COLUMN turismo.temporada_turistica.meses IS 'Meses o periodo del anio asociado a la temporada.';
COMMENT ON COLUMN turismo.temporada_turistica.descripcion IS 'Descripcion de condiciones o recomendaciones generales de la temporada.';
-- ============================================================
-- Destinos turisticos
-- ============================================================
CREATE TABLE IF NOT EXISTS turismo.destino_turistico (
    id_destino                 INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    codigo                     VARCHAR(80)  NOT NULL UNIQUE,
    nombre                     VARCHAR(220) NOT NULL,
    tipo                       turismo.tipo_destino NOT NULL,
    departamento_id            INT NOT NULL REFERENCES geografia.departamento(id),
    municipio_id               INT REFERENCES geografia.municipio(id),
    region_turistica_id        INT REFERENCES turismo.region_turistica(id_region),
    descripcion                TEXT NOT NULL,
    direccion_referencia       VARCHAR(500),
    latitud                    NUMERIC(10, 7),
    longitud                   NUMERIC(10, 7),
    altitud_msnm               INT,
    dificultad                 turismo.dificultad_destino NOT NULL DEFAULT 'BAJA',
    tiempo_recomendado         VARCHAR(120),
    costo_aprox_nacional_q     NUMERIC(10, 2),
    costo_aprox_extranjero_q   NUMERIC(10, 2),
    horario                    VARCHAR(250),
    es_area_protegida          BOOLEAN NOT NULL DEFAULT FALSE,
    fuente_principal_id        INT REFERENCES turismo.fuente_turistica(id_fuente),
    activo                     BOOLEAN NOT NULL DEFAULT TRUE
);

COMMENT ON TABLE turismo.destino_turistico IS 'Destinos turisticos reales de Guatemala documentados para consulta, ETL y analitica BI.';
COMMENT ON COLUMN turismo.destino_turistico.id_destino IS 'Identificador unico del destino turistico.';
COMMENT ON COLUMN turismo.destino_turistico.codigo IS 'Codigo estable del destino turistico para migraciones y ETL.';
COMMENT ON COLUMN turismo.destino_turistico.nombre IS 'Nombre del destino turistico.';
COMMENT ON COLUMN turismo.destino_turistico.tipo IS 'Tipo general del destino turistico.';
COMMENT ON COLUMN turismo.destino_turistico.departamento_id IS 'Departamento oficial donde se ubica el destino, referenciado desde geografia.departamento.';
COMMENT ON COLUMN turismo.destino_turistico.municipio_id IS 'Municipio oficial donde se ubica el destino, referenciado desde geografia.municipio cuando se conoce.';
COMMENT ON COLUMN turismo.destino_turistico.region_turistica_id IS 'Region turistica principal asociada al destino. Se usa para evitar ambiguedad en departamentos que participan parcialmente en mas de una region turistica.';
COMMENT ON COLUMN turismo.destino_turistico.descripcion IS 'Descripcion documentada del destino turistico.';
COMMENT ON COLUMN turismo.destino_turistico.direccion_referencia IS 'Referencia textual de ubicacion, acceso o zona del destino.';
COMMENT ON COLUMN turismo.destino_turistico.latitud IS 'Latitud aproximada del destino turistico.';
COMMENT ON COLUMN turismo.destino_turistico.longitud IS 'Longitud aproximada del destino turistico.';
COMMENT ON COLUMN turismo.destino_turistico.altitud_msnm IS 'Altitud aproximada sobre el nivel del mar, cuando se conoce.';
COMMENT ON COLUMN turismo.destino_turistico.dificultad IS 'Nivel de dificultad general para visitar el destino.';
COMMENT ON COLUMN turismo.destino_turistico.tiempo_recomendado IS 'Tiempo recomendado de visita.';
COMMENT ON COLUMN turismo.destino_turistico.costo_aprox_nacional_q IS 'Costo aproximado para visitante nacional, en quetzales, cuando existe dato publico.';
COMMENT ON COLUMN turismo.destino_turistico.costo_aprox_extranjero_q IS 'Costo aproximado para visitante extranjero, en quetzales, cuando existe dato publico.';
COMMENT ON COLUMN turismo.destino_turistico.horario IS 'Horario de visita o atencion cuando se tiene publicado.';
COMMENT ON COLUMN turismo.destino_turistico.es_area_protegida IS 'Indica si el destino pertenece o se relaciona con un area protegida.';
COMMENT ON COLUMN turismo.destino_turistico.fuente_principal_id IS 'Fuente turistica principal usada para documentar el destino.';
COMMENT ON COLUMN turismo.destino_turistico.activo IS 'Indica si el destino se mantiene activo para consulta.';
CREATE INDEX IF NOT EXISTS ix_destino_departamento ON turismo.destino_turistico(departamento_id);
CREATE INDEX IF NOT EXISTS ix_destino_municipio ON turismo.destino_turistico(municipio_id);
CREATE INDEX IF NOT EXISTS ix_destino_region ON turismo.destino_turistico(region_turistica_id);
CREATE INDEX IF NOT EXISTS ix_destino_tipo ON turismo.destino_turistico(tipo);
CREATE INDEX IF NOT EXISTS ix_destino_area_protegida ON turismo.destino_turistico(es_area_protegida);

CREATE TABLE IF NOT EXISTS turismo.destino_categoria (
    destino_id   INT NOT NULL REFERENCES turismo.destino_turistico(id_destino) ON DELETE CASCADE,
    categoria_id INT NOT NULL REFERENCES turismo.categoria_destino(id_categoria),
    PRIMARY KEY (destino_id, categoria_id)
);

COMMENT ON TABLE turismo.destino_categoria IS 'Relacion muchos a muchos entre destinos turisticos y categorias.';
COMMENT ON COLUMN turismo.destino_categoria.destino_id IS 'Destino turistico clasificado.';
COMMENT ON COLUMN turismo.destino_categoria.categoria_id IS 'Categoria asignada al destino.';
CREATE TABLE IF NOT EXISTS turismo.destino_actividad (
    destino_id    INT NOT NULL REFERENCES turismo.destino_turistico(id_destino) ON DELETE CASCADE,
    actividad_id  INT NOT NULL REFERENCES turismo.actividad_turistica(id_actividad),
    notas         VARCHAR(500),
    PRIMARY KEY (destino_id, actividad_id)
);

COMMENT ON TABLE turismo.destino_actividad IS 'Relacion muchos a muchos entre destinos y actividades turisticas.';
COMMENT ON COLUMN turismo.destino_actividad.destino_id IS 'Destino turistico asociado a la actividad.';
COMMENT ON COLUMN turismo.destino_actividad.actividad_id IS 'Actividad turistica disponible o recomendada.';
COMMENT ON COLUMN turismo.destino_actividad.notas IS 'Notas sobre alcance o condiciones de la actividad en el destino.';
CREATE TABLE IF NOT EXISTS turismo.destino_temporada (
    destino_id      INT NOT NULL REFERENCES turismo.destino_turistico(id_destino) ON DELETE CASCADE,
    temporada_id    INT NOT NULL REFERENCES turismo.temporada_turistica(id_temporada),
    recomendacion   VARCHAR(600),
    PRIMARY KEY (destino_id, temporada_id)
);

COMMENT ON TABLE turismo.destino_temporada IS 'Relacion entre destinos y temporadas recomendadas para visita.';
COMMENT ON COLUMN turismo.destino_temporada.destino_id IS 'Destino turistico asociado a la temporada.';
COMMENT ON COLUMN turismo.destino_temporada.temporada_id IS 'Temporada recomendada o relevante.';
COMMENT ON COLUMN turismo.destino_temporada.recomendacion IS 'Recomendacion especifica para visitar el destino en la temporada indicada.';
CREATE TABLE IF NOT EXISTS turismo.destino_fuente (
    destino_id INT NOT NULL REFERENCES turismo.destino_turistico(id_destino) ON DELETE CASCADE,
    fuente_id  INT NOT NULL REFERENCES turismo.fuente_turistica(id_fuente),
    detalle    VARCHAR(600),
    PRIMARY KEY (destino_id, fuente_id)
);

COMMENT ON TABLE turismo.destino_fuente IS 'Fuentes documentales que respaldan la informacion de cada destino turistico.';
COMMENT ON COLUMN turismo.destino_fuente.destino_id IS 'Destino turistico documentado.';
COMMENT ON COLUMN turismo.destino_fuente.fuente_id IS 'Fuente turistica relacionada con el destino.';
COMMENT ON COLUMN turismo.destino_fuente.detalle IS 'Detalle sobre el uso de la fuente para el destino.';
-- ============================================================
-- Patrimonio, rutas y recomendaciones
-- ============================================================
CREATE TABLE IF NOT EXISTS turismo.patrimonio_turistico (
    id_patrimonio     INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    codigo            VARCHAR(80)  NOT NULL UNIQUE,
    tipo              turismo.tipo_patrimonio NOT NULL,
    nombre            VARCHAR(220) NOT NULL,
    organismo         VARCHAR(160) NOT NULL,
    anio_inscripcion  INT,
    descripcion       TEXT,
    fuente_id         INT REFERENCES turismo.fuente_turistica(id_fuente)
);

COMMENT ON TABLE turismo.patrimonio_turistico IS 'Patrimonios UNESCO, nacionales o intangibles vinculados con el turismo en Guatemala.';
COMMENT ON COLUMN turismo.patrimonio_turistico.id_patrimonio IS 'Identificador unico del patrimonio turistico.';
COMMENT ON COLUMN turismo.patrimonio_turistico.codigo IS 'Codigo estable del patrimonio.';
COMMENT ON COLUMN turismo.patrimonio_turistico.tipo IS 'Tipo de reconocimiento patrimonial.';
COMMENT ON COLUMN turismo.patrimonio_turistico.nombre IS 'Nombre del patrimonio o expresion cultural.';
COMMENT ON COLUMN turismo.patrimonio_turistico.organismo IS 'Organismo que reconoce o respalda el patrimonio.';
COMMENT ON COLUMN turismo.patrimonio_turistico.anio_inscripcion IS 'Anio de inscripcion o reconocimiento, cuando aplica.';
COMMENT ON COLUMN turismo.patrimonio_turistico.descripcion IS 'Descripcion resumida del valor patrimonial.';
COMMENT ON COLUMN turismo.patrimonio_turistico.fuente_id IS 'Fuente principal que respalda el patrimonio.';
CREATE TABLE IF NOT EXISTS turismo.destino_patrimonio (
    destino_id     INT NOT NULL REFERENCES turismo.destino_turistico(id_destino) ON DELETE CASCADE,
    patrimonio_id  INT NOT NULL REFERENCES turismo.patrimonio_turistico(id_patrimonio),
    observacion    VARCHAR(600),
    PRIMARY KEY (destino_id, patrimonio_id)
);

COMMENT ON TABLE turismo.destino_patrimonio IS 'Relacion entre destinos turisticos y reconocimientos patrimoniales.';
COMMENT ON COLUMN turismo.destino_patrimonio.destino_id IS 'Destino turistico asociado al patrimonio.';
COMMENT ON COLUMN turismo.destino_patrimonio.patrimonio_id IS 'Patrimonio asociado al destino.';
COMMENT ON COLUMN turismo.destino_patrimonio.observacion IS 'Observacion de la relacion entre destino y patrimonio.';
CREATE TABLE IF NOT EXISTS turismo.ruta_turistica (
    id_ruta       INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    codigo        VARCHAR(80)  NOT NULL UNIQUE,
    nombre        VARCHAR(180) NOT NULL,
    region_id     INT REFERENCES turismo.region_turistica(id_region),
    descripcion   TEXT,
    duracion_dias INT,
    fuente_id     INT REFERENCES turismo.fuente_turistica(id_fuente)
);

COMMENT ON TABLE turismo.ruta_turistica IS 'Rutas turisticas sugeridas para recorrer destinos relacionados.';
COMMENT ON COLUMN turismo.ruta_turistica.id_ruta IS 'Identificador unico de la ruta turistica.';
COMMENT ON COLUMN turismo.ruta_turistica.codigo IS 'Codigo estable de la ruta.';
COMMENT ON COLUMN turismo.ruta_turistica.nombre IS 'Nombre de la ruta turistica.';
COMMENT ON COLUMN turismo.ruta_turistica.region_id IS 'Region turistica principal asociada a la ruta.';
COMMENT ON COLUMN turismo.ruta_turistica.descripcion IS 'Descripcion general de la ruta.';
COMMENT ON COLUMN turismo.ruta_turistica.duracion_dias IS 'Duracion sugerida de la ruta en dias.';
COMMENT ON COLUMN turismo.ruta_turistica.fuente_id IS 'Fuente principal usada para documentar la ruta.';
CREATE TABLE IF NOT EXISTS turismo.ruta_destino (
    ruta_id         INT NOT NULL REFERENCES turismo.ruta_turistica(id_ruta) ON DELETE CASCADE,
    destino_id      INT NOT NULL REFERENCES turismo.destino_turistico(id_destino),
    orden_visita    INT NOT NULL,
    tiempo_sugerido VARCHAR(120),
    PRIMARY KEY (ruta_id, destino_id),
    CONSTRAINT uq_ruta_orden UNIQUE (ruta_id, orden_visita)
);

COMMENT ON TABLE turismo.ruta_destino IS 'Detalle de destinos incluidos en cada ruta turistica sugerida.';
COMMENT ON COLUMN turismo.ruta_destino.ruta_id IS 'Ruta turistica que contiene el destino.';
COMMENT ON COLUMN turismo.ruta_destino.destino_id IS 'Destino incluido en la ruta.';
COMMENT ON COLUMN turismo.ruta_destino.orden_visita IS 'Orden sugerido de visita dentro de la ruta.';
COMMENT ON COLUMN turismo.ruta_destino.tiempo_sugerido IS 'Tiempo sugerido para visitar el destino dentro de la ruta.';
CREATE TABLE IF NOT EXISTS turismo.recomendacion_destino (
    id_recomendacion INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    destino_id       INT NOT NULL REFERENCES turismo.destino_turistico(id_destino) ON DELETE CASCADE,
    tipo             turismo.tipo_recomendacion NOT NULL,
    recomendacion    VARCHAR(800) NOT NULL
);

COMMENT ON TABLE turismo.recomendacion_destino IS 'Recomendaciones turisticas, logisticas, culturales, ambientales, de seguridad o temporada por destino.';
COMMENT ON COLUMN turismo.recomendacion_destino.id_recomendacion IS 'Identificador unico de la recomendacion.';
COMMENT ON COLUMN turismo.recomendacion_destino.destino_id IS 'Destino al que aplica la recomendacion.';
COMMENT ON COLUMN turismo.recomendacion_destino.tipo IS 'Tipo de recomendacion.';
COMMENT ON COLUMN turismo.recomendacion_destino.recomendacion IS 'Texto de la recomendacion.';
-- ============================================================
-- Trigger de validacion geografia: municipio debe pertenecer al departamento indicado
-- ============================================================
CREATE OR REPLACE FUNCTION turismo.fn_validar_destino_geografia()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_departamento_municipio INT;
BEGIN
    IF NEW.municipio_id IS NOT NULL THEN
        SELECT m.departamento_id
          INTO v_departamento_municipio
          FROM geografia.municipio m
         WHERE m.id = NEW.municipio_id;

        IF v_departamento_municipio IS DISTINCT FROM NEW.departamento_id THEN
            RAISE EXCEPTION 'El municipio_id % no pertenece al departamento_id % para el destino %',
                NEW.municipio_id, NEW.departamento_id, NEW.nombre;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION turismo.fn_validar_destino_geografia() IS 'Valida que el municipio referenciado por un destino pertenezca al departamento indicado.';

DROP TRIGGER IF EXISTS trg_validar_destino_geografia ON turismo.destino_turistico;
CREATE TRIGGER trg_validar_destino_geografia
BEFORE INSERT OR UPDATE OF departamento_id, municipio_id
ON turismo.destino_turistico
FOR EACH ROW
EXECUTE FUNCTION turismo.fn_validar_destino_geografia();
-- **********************************************************************
-- Fin schema TURISMO
-- **********************************************************************

