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




