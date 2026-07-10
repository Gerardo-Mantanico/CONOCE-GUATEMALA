-- ============================================================
-- ARCHIVO: 03_consultas_metadatos.sql
-- Proyecto: Conoce Guate / Base Nacional de Datos
-- Objetivo:
--   Manual de consultas SQL para explorar la estructura física,
--   los metadatos, fuentes, reglas de calidad, revisiones por pares,
--   decisiones de modelado y datos principales del proyecto.
--



-- ============================================================
-- CONSULTAR VERSIONES DEL PROYECTO
-- ============================================================
-- Sirve para saber qué versiones existen y qué incluye cada una.

SELECT
    id_version,
    numero_version,
    nombre_version,
    fecha_version,
    descripcion,
    cambios_principales,
    responsable,
    estado
FROM meta.version_proyecto
ORDER BY fecha_version DESC;


-- ============================================================
-- 2. VER TODOS LOS ESQUEMAS DOCUMENTADOS
-- ============================================================
-- Sirve para saber qué áreas temáticas existen en la base de datos.

SELECT
    id_esquema,
    nombre_esquema,
    titulo,
    descripcion,
    objetivo,
    alcance,
    fuera_de_alcance,
    responsable,
    estado
FROM meta.esquema_datos
ORDER BY nombre_esquema;


-- ============================================================
-- 3. VER QUÉ CONTIENE UN ESQUEMA ESPECÍFICO
-- ============================================================
-- Ejemplo: turismo.

SELECT
    nombre_esquema,
    titulo,
    descripcion,
    objetivo,
    alcance,
    fuera_de_alcance
FROM meta.esquema_datos
WHERE nombre_esquema = 'turismo';


-- ============================================================
-- 4. VER TODAS LAS TABLAS DOCUMENTADAS DEL PROYECTO
-- ============================================================

SELECT
    e.nombre_esquema,
    t.nombre_tabla,
    t.titulo,
    t.descripcion,
    t.tipo_tabla,
    t.granularidad,
    t.estado
FROM meta.tabla_datos t
JOIN meta.esquema_datos e
    ON e.id_esquema = t.id_esquema
ORDER BY
    e.nombre_esquema,
    t.nombre_tabla;


-- ============================================================
-- 5. VER TODAS LAS TABLAS DE UN ESQUEMA
-- ============================================================
-- Ejemplo: turismo.

SELECT
    t.nombre_tabla,
    t.titulo,
    t.descripcion,
    t.tipo_tabla,
    t.granularidad,
    t.criterio_inclusion,
    t.criterio_exclusion,
    t.ejemplo_uso
FROM meta.tabla_datos t
JOIN meta.esquema_datos e
    ON e.id_esquema = t.id_esquema
WHERE e.nombre_esquema = 'turismo'
ORDER BY t.nombre_tabla;


-- ============================================================
-- 6. VER DICCIONARIO DE COLUMNAS DE UNA TABLA
-- ============================================================
-- Ejemplo: turismo.destino_turistico.

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
    ON e.id_esquema = t.id_esquema
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_turistico'
ORDER BY c.id_columna;


-- ============================================================
-- 7. BUSCAR UNA COLUMNA POR NOMBRE O DESCRIPCIÓN
-- ============================================================
-- Ejemplo: buscar columnas relacionadas con departamento.

SELECT
    e.nombre_esquema,
    t.nombre_tabla,
    c.nombre_columna,
    c.tipo_dato,
    c.descripcion
FROM meta.columna_datos c
JOIN meta.tabla_datos t
    ON t.id_tabla = c.id_tabla
JOIN meta.esquema_datos e
    ON e.id_esquema = t.id_esquema
WHERE LOWER(c.nombre_columna) LIKE '%departamento%'
   OR LOWER(c.descripcion) LIKE '%departamento%'
ORDER BY
    e.nombre_esquema,
    t.nombre_tabla,
    c.nombre_columna;


-- ============================================================
-- 8. BUSCAR INFORMACIÓN POR TEMA
-- ============================================================
-- Ejemplo: buscar todo lo relacionado con turismo.

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
    ON cd.id_columna = ot.id_columna
WHERE LOWER(tema.nombre_tema) LIKE '%turismo%'
   OR LOWER(tema.palabras_clave) LIKE '%turismo%'
   OR LOWER(ot.justificacion) LIKE '%turismo%'
ORDER BY
    tema.nombre_tema,
    ot.nivel_objeto,
    e.nombre_esquema,
    td.nombre_tabla;


-- ============================================================
-- BUSCAR SI YA EXISTE INFORMACIÓN RELACIONADA CON ALGUN TEMA
-- ============================================================
-- Esta consulta ayuda a decidir si debe crearse un nuevo esquema.

SELECT
    tema.nombre_tema,
    tema.palabras_clave,
    ot.nivel_objeto,
    e.nombre_esquema,
    td.nombre_tabla,
    cd.nombre_columna,
    ot.relevancia,
    ot.justificacion
FROM meta.objeto_tema ot
JOIN meta.tema_datos tema
    ON tema.id_tema = ot.id_tema
LEFT JOIN meta.esquema_datos e
    ON e.id_esquema = ot.id_esquema
LEFT JOIN meta.tabla_datos td
    ON td.id_tabla = ot.id_tabla
LEFT JOIN meta.columna_datos cd
    ON cd.id_columna = ot.id_columna
WHERE LOWER(tema.nombre_tema) LIKE '%deporte%'
   OR LOWER(tema.palabras_clave) LIKE '%deporte%'
   OR LOWER(ot.justificacion) LIKE '%deporte%'
ORDER BY
    ot.relevancia DESC,
    e.nombre_esquema,
    td.nombre_tabla;


-- ============================================================
--  CONSULTAR DECISIONES DE MODELADO
-- ============================================================

SELECT
    dm.tema,
    dm.pregunta,
    dm.decision,
    dm.justificacion,
    dm.ejemplo,
    e.nombre_esquema AS esquema_recomendado,
    t.nombre_tabla AS tabla_recomendada,
    dm.alternativa,
    dm.responsable,
    dm.fecha_decision,
    dm.estado
FROM meta.decision_modelado dm
LEFT JOIN meta.esquema_datos e
    ON e.id_esquema = dm.id_esquema_recomendado
LEFT JOIN meta.tabla_datos t
    ON t.id_tabla = dm.id_tabla_recomendada
ORDER BY dm.fecha_decision DESC;


-- ============================================================
-- 12. BUSCAR DECISIONES SOBRE FESTIVIDADES
-- ============================================================

SELECT
    tema,
    pregunta,
    decision,
    justificacion,
    ejemplo,
    alternativa,
    responsable,
    fecha_decision,
    estado
FROM meta.decision_modelado
WHERE LOWER(tema) LIKE '%festividad%'
   OR LOWER(pregunta) LIKE '%festividad%'
   OR LOWER(decision) LIKE '%festividad%'
   OR LOWER(justificacion) LIKE '%festividad%';


-- ============================================================
-- 13. BUSCAR DECISIONES SOBRE DEPORTES
-- ============================================================

SELECT
    tema,
    pregunta,
    decision,
    justificacion,
    ejemplo,
    alternativa,
    responsable,
    fecha_decision,
    estado
FROM meta.decision_modelado
WHERE LOWER(tema) LIKE '%deporte%'
   OR LOWER(pregunta) LIKE '%deporte%'
   OR LOWER(decision) LIKE '%deporte%'
   OR LOWER(justificacion) LIKE '%deporte%';


-- ============================================================
-- 14. VER FUENTES REGISTRADAS
-- ============================================================

SELECT
    codigo_fuente,
    nombre_fuente,
    institucion,
    tipo_fuente,
    url,
    fecha_consulta,
    descripcion,
    confiabilidad,
    cobertura_geografica,
    licencia_uso,
    estado
FROM meta.fuente_datos
ORDER BY codigo_fuente;


-- ============================================================
-- 15. VER QUÉ FUENTES RESPALDAN CADA TABLA
-- ============================================================

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
    ON c.id_columna = tf.id_columna
ORDER BY
    e.nombre_esquema,
    t.nombre_tabla,
    f.codigo_fuente;


-- ============================================================
-- 16. VER FUENTES DE UN ESQUEMA ESPECÍFICO
-- ============================================================
-- Ejemplo: turismo.

SELECT
    f.codigo_fuente,
    f.nombre_fuente,
    f.institucion,
    f.tipo_fuente,
    f.url,
    f.confiabilidad,
    tf.nivel_respaldo,
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
    ON c.id_columna = tf.id_columna
WHERE e.nombre_esquema = 'turismo'
   OR t.id_esquema = (
        SELECT id_esquema
        FROM meta.esquema_datos
        WHERE nombre_esquema = 'turismo'
   )
ORDER BY
    t.nombre_tabla,
    f.codigo_fuente;


-- ============================================================
-- 17. VER REGLAS DE CALIDAD DE DATOS
-- ============================================================

SELECT
    e.nombre_esquema,
    t.nombre_tabla,
    c.nombre_columna,
    r.nombre_regla,
    r.descripcion,
    r.tipo_regla,
    r.severidad,
    r.expresion_validacion,
    r.accion_si_falla,
    r.estado
FROM meta.regla_calidad r
JOIN meta.tabla_datos t
    ON t.id_tabla = r.id_tabla
JOIN meta.esquema_datos e
    ON e.id_esquema = t.id_esquema
LEFT JOIN meta.columna_datos c
    ON c.id_columna = r.id_columna
ORDER BY
    e.nombre_esquema,
    t.nombre_tabla,
    r.severidad DESC;


-- ============================================================
-- 18. VER REGLAS DE CALIDAD DE UNA TABLA
-- ============================================================
-- Ejemplo: turismo.destino_turistico.

SELECT
    r.nombre_regla,
    r.descripcion,
    r.tipo_regla,
    r.severidad,
    r.expresion_validacion,
    r.accion_si_falla,
    r.estado
FROM meta.regla_calidad r
JOIN meta.tabla_datos t
    ON t.id_tabla = r.id_tabla
JOIN meta.esquema_datos e
    ON e.id_esquema = t.id_esquema
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_turistico'
ORDER BY r.severidad DESC;


-- ============================================================
-- 19. VER REVISIONES POR PARES
-- ============================================================

SELECT
    rp.nivel_revision,
    e.nombre_esquema,
    t.nombre_tabla,
    c.nombre_columna,
    rp.tipo_revision,
    rp.descripcion_revision,
    rp.revisor_1,
    rp.estado_revisor_1,
    rp.fecha_revisor_1,
    rp.revisor_2,
    rp.estado_revisor_2,
    rp.fecha_revisor_2,
    rp.estado_final,
    rp.observaciones
FROM meta.revision_pares rp
LEFT JOIN meta.esquema_datos e
    ON e.id_esquema = rp.id_esquema
LEFT JOIN meta.tabla_datos t
    ON t.id_tabla = rp.id_tabla
LEFT JOIN meta.columna_datos c
    ON c.id_columna = rp.id_columna
ORDER BY
    rp.estado_final,
    e.nombre_esquema,
    t.nombre_tabla;


-- ============================================================
-- 20. VER QUÉ TABLAS YA ESTÁN APROBADAS POR PARES
-- ============================================================

SELECT
    e.nombre_esquema,
    t.nombre_tabla,
    rp.tipo_revision,
    rp.revisor_1,
    rp.estado_revisor_1,
    rp.revisor_2,
    rp.estado_revisor_2,
    rp.estado_final
FROM meta.revision_pares rp
JOIN meta.tabla_datos t
    ON t.id_tabla = rp.id_tabla
JOIN meta.esquema_datos e
    ON e.id_esquema = t.id_esquema
WHERE rp.nivel_revision = 'TABLA'
  AND rp.estado_final = 'APROBADO'
ORDER BY
    e.nombre_esquema,
    t.nombre_tabla;


-- ============================================================
-- 21. VER CARGAS DE DATOS REALIZADAS
-- ============================================================

SELECT
    c.id,
    f.codigo_fuente,
    f.nombre_fuente,
    ec.nombre AS estado_carga,
    c.nombre_script,
    c.archivo_fuente,
    c.hash_archivo,
    c.ejecutado_por,
    c.iniciado_en,
    c.finalizado_en,
    c.filas_procesadas,
    c.filas_insertadas,
    c.filas_actualizadas,
    c.filas_rechazadas,
    c.notas
FROM meta.carga c
JOIN meta.fuente_datos f
    ON f.id_fuente = c.id_fuente
JOIN meta.estado_carga ec
    ON ec.id_estado_carga = c.id_estado_carga
ORDER BY c.iniciado_en DESC;


-- ============================================================
-- 22. VER QUÉ TABLAS FUERON AFECTADAS POR CADA CARGA
-- ============================================================

SELECT
    c.id AS id_carga,
    f.codigo_fuente,
    f.nombre_fuente,
    cc.schema_destino,
    cc.tabla_destino,
    cc.periodo_inicio,
    cc.periodo_fin,
    cc.notas
FROM meta.cobertura_carga cc
JOIN meta.carga c
    ON c.id = cc.carga_id
JOIN meta.fuente_datos f
    ON f.id_fuente = c.id_fuente
ORDER BY
    c.id DESC,
    cc.schema_destino,
    cc.tabla_destino;


-- ============================================================
-- 23. VER ESTRUCTURA FÍSICA REAL DESDE POSTGRESQL
-- ============================================================
-- Esta consulta no usa metadatos manuales, sino el catálogo interno.

SELECT
    table_schema,
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY
    table_schema,
    table_name;


-- ============================================================
-- 24. VER COLUMNAS FÍSICAS REALES DESDE POSTGRESQL
-- ============================================================

SELECT
    table_schema,
    table_name,
    column_name,
    data_type,
    is_nullable,
    character_maximum_length,
    numeric_precision,
    numeric_scale
FROM information_schema.columns
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY
    table_schema,
    table_name,
    ordinal_position;


-- ============================================================
-- 25. COMPARAR TABLAS FÍSICAS CONTRA TABLAS DOCUMENTADAS
-- ============================================================
-- Si devuelve registros, existen tablas no documentadas en meta.tabla_datos.

SELECT
    physical.table_schema,
    physical.table_name
FROM information_schema.tables physical
WHERE physical.table_schema NOT IN ('pg_catalog', 'information_schema')
  AND physical.table_type = 'BASE TABLE'
  AND NOT EXISTS (
      SELECT 1
      FROM meta.tabla_datos td
      JOIN meta.esquema_datos ed
          ON ed.id_esquema = td.id_esquema
      WHERE ed.nombre_esquema = physical.table_schema
        AND td.nombre_tabla = physical.table_name
  )
ORDER BY
    physical.table_schema,
    physical.table_name;


-- ============================================================
-- 26. COMPARAR COLUMNAS FÍSICAS CONTRA COLUMNAS DOCUMENTADAS
-- ============================================================
-- Si devuelve registros, existen columnas no documentadas en meta.columna_datos.

SELECT
    physical.table_schema,
    physical.table_name,
    physical.column_name,
    physical.data_type
FROM information_schema.columns physical
WHERE physical.table_schema NOT IN ('pg_catalog', 'information_schema')
  AND NOT EXISTS (
      SELECT 1
      FROM meta.columna_datos cd
      JOIN meta.tabla_datos td
          ON td.id_tabla = cd.id_tabla
      JOIN meta.esquema_datos ed
          ON ed.id_esquema = td.id_esquema
      WHERE ed.nombre_esquema = physical.table_schema
        AND td.nombre_tabla = physical.table_name
        AND cd.nombre_columna = physical.column_name
  )
ORDER BY
    physical.table_schema,
    physical.table_name,
    physical.ordinal_position;


-- ============================================================
-- 27. VER LLAVES FORÁNEAS REALES DE LA BASE
-- ============================================================

SELECT
    tc.table_schema AS esquema_origen,
    tc.table_name AS tabla_origen,
    kcu.column_name AS columna_origen,
    ccu.table_schema AS esquema_referenciado,
    ccu.table_name AS tabla_referenciada,
    ccu.column_name AS columna_referenciada,
    tc.constraint_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
   AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_name = tc.constraint_name
   AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
ORDER BY
    tc.table_schema,
    tc.table_name,
    kcu.column_name;


-- ============================================================
-- 28. CONSULTAR COMENTARIOS FÍSICOS DE TABLAS
-- ============================================================

SELECT
    n.nspname AS esquema,
    c.relname AS tabla,
    obj_description(c.oid) AS comentario
FROM pg_class c
JOIN pg_namespace n
    ON n.oid = c.relnamespace
WHERE c.relkind = 'r'
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY
    n.nspname,
    c.relname;


-- ============================================================
-- 29. CONSULTAR COMENTARIOS FÍSICOS DE COLUMNAS
-- ============================================================

SELECT
    n.nspname AS esquema,
    c.relname AS tabla,
    a.attname AS columna,
    col_description(c.oid, a.attnum) AS comentario
FROM pg_class c
JOIN pg_namespace n
    ON n.oid = c.relnamespace
JOIN pg_attribute a
    ON a.attrelid = c.oid
WHERE c.relkind = 'r'
  AND a.attnum > 0
  AND NOT a.attisdropped
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY
    n.nspname,
    c.relname,
    a.attnum;


-- ============================================================
--  CONSULTA GENERAL PARA EXPLORAR TODO EL CATÁLOGO
-- ============================================================

SELECT
    e.nombre_esquema,
    e.titulo AS titulo_esquema,
    t.nombre_tabla,
    t.titulo AS titulo_tabla,
    t.tipo_tabla,
    t.descripcion AS descripcion_tabla,
    t.criterio_inclusion,
    t.criterio_exclusion,
    c.nombre_columna,
    c.tipo_dato,
    c.descripcion AS descripcion_columna,
    c.ejemplo_valor
FROM meta.esquema_datos e
LEFT JOIN meta.tabla_datos t
    ON t.id_esquema = e.id_esquema
LEFT JOIN meta.columna_datos c
    ON c.id_tabla = t.id_tabla
ORDER BY
    e.nombre_esquema,
    t.nombre_tabla,
    c.id_columna;


-- ============================================================
-- FIN DEL ARCHIVO
-- ============================================================