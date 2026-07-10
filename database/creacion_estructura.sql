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