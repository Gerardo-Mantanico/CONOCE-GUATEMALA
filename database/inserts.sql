
-- ¡¡IMPORTANTE!!
-- Adecuar la ruta para que señale al archivo de creación de la base de datos
\set script_ddl `cat ~/Desktop/CONOCE-GUATEMALA/database/creacion_estructura.sql`

INSERT INTO meta.version_proyecto (numero_version, nombre_version, fecha_version, descripcion, cambios_principales) VALUES
('1.0', 'Primera Versión', '10-07-2026', :'script_ddl', 'Incluye esquemas meta, auditoria, geografia, turismo, justicia, clima, artesanías, entre otros.');


-- ************************************
--  METADATOS auditoria
-- ************************************
INSERT INTO meta.esquema_datos (nombre_esquema, titulo, id_version_desde, descripcion, objetivo, alcance, fuera_de_alcance) VALUES
    ('auditoria', 'Auditoria', (SELECT id_version from meta.version_proyecto where nombre_version = '1.0'),
     'Registro automatico y centralizado de los cambios (INSERT, UPDATE, DELETE) sobre las tablas de dominio.',
     'Mantener una bitacora confiable de las modificaciones de datos para trazabilidad y control.',
     'Cambios a nivel de fila en las tablas de los esquemas de dominio auditados.',
     'No registra consultas de solo lectura ni cambios en los esquemas de sistema o de metadatos.');

INSERT INTO meta.tabla_datos (id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla,
                              granularidad, criterio_inclusion, criterio_exclusion, ejemplo_uso) VALUES
    ((SELECT id_esquema from meta.esquema_datos where nombre_esquema = 'auditoria'), 'registro', 'Bitacora de auditoria',
     'Bitacora central que guarda el estado previo y posterior de cada fila modificada, en formato JSONB.',
     'HISTORICA', 'Una fila por operacion (INSERT, UPDATE o DELETE) registrada.',
     'Toda modificacion de datos en las tablas de dominio auditadas.',
     'No incluye lecturas ni cambios en esquemas de sistema o de metadatos.',
     'Consultar quien y cuando modifico un registro y que valores cambiaron.');

INSERT INTO meta.columna_datos
(id_tabla, nombre_columna, tipo_dato, descripcion,
 obligatorio, es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
 valores_permitidos, ejemplo_valor, regla_validacion) VALUES
-- auditoria.registro
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro'), 'id', 'BIGINT', 'Identificador unico autogenerado del registro de auditoria.',
 TRUE, TRUE, FALSE, NULL, NULL, NULL, '1', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro'), 'esquema', 'TEXT', 'Nombre del esquema donde ocurrio la modificacion.',
 TRUE, FALSE, FALSE, NULL, NULL, NULL, 'geografia', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro'), 'tabla', 'TEXT', 'Nombre de la tabla donde ocurrio la modificacion.',
 TRUE, FALSE, FALSE, NULL, NULL, NULL, 'municipio', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro'), 'operacion', 'TEXT', 'Tipo de operacion DML realizada.',
 TRUE, FALSE, FALSE, NULL, NULL, 'INSERT, UPDATE, DELETE', 'UPDATE', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro'), 'pk', 'TEXT', 'Valor de la columna id de la fila afectada, si la tabla la tiene.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, '42', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro'), 'datos_old', 'JSONB', 'Estado previo de la fila en formato JSONB (operaciones UPDATE y DELETE).',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro'), 'datos_new', 'JSONB', 'Nuevo estado de la fila en formato JSONB (operaciones INSERT y UPDATE).',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro'), 'usuario_bd', 'TEXT', 'Rol o usuario de PostgreSQL que ejecuto la operacion.',
 TRUE, FALSE, FALSE, NULL, NULL, NULL, 'postgres', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro'), 'app_usuario', 'TEXT', 'Usuario de la aplicacion o proceso ETL responsable del cambio.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro'), 'fecha', 'TIMESTAMPTZ', 'Fecha y hora en que se registro la operacion.',
 TRUE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL);

INSERT INTO meta.tema_datos (nombre_tema, descripcion, palabras_clave) VALUES
    ('Auditoria',
     'Trazabilidad y control de los cambios en los datos de la base.',
     'auditoria, cambios, trazabilidad, historial, bitacora, control')
ON CONFLICT (nombre_tema) DO UPDATE SET
                                        descripcion = EXCLUDED.descripcion,
                                        palabras_clave = EXCLUDED.palabras_clave;

INSERT INTO meta.objeto_tema (id_tema, nivel_objeto, id_esquema, id_tabla, id_columna, relevancia, justificacion) VALUES
    ((SELECT id_tema FROM meta.tema_datos WHERE nombre_tema = 'Auditoria'),
        'ESQUEMA', (SELECT id_esquema from meta.esquema_datos where nombre_esquema = 'auditoria'), NULL, NULL, 'ALTA',
        'Todo el esquema registra los cambios de datos de la base.'),
    ((SELECT id_tema FROM meta.tema_datos WHERE nombre_tema = 'Auditoria'),
    'TABLA', (SELECT id_esquema from meta.esquema_datos where nombre_esquema = 'auditoria'), (SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro'),NULL, 'ALTA',
'Bitácora central de los cambios.');



-- **********************************************************************
-- Schema: geografia
-- **********************************************************************

-- ************************************
--  METADATOS geografia
INSERT INTO meta.esquema_datos (nombre_esquema, titulo, id_version_desde, descripcion, objetivo, alcance, fuera_de_alcance) VALUES
    ('geografia', 'Geografia', (SELECT id_version from meta.version_proyecto where nombre_version = '1.0'),
    'Entidades geograficas del pais: paises, departamentos y municipios, con sus codigos, superficie y centroides.',
    'Proveer la referencia territorial comun para ubicar y cruzar los datos del resto de los dominios.',
    'Division politico-administrativa de Guatemala hasta el nivel de municipio.',
    'No incluye limites geometricos detallados ni divisiones por debajo del municipio.');

INSERT INTO meta.tabla_datos (id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla, granularidad, criterio_inclusion, criterio_exclusion, ejemplo_uso) VALUES
    ((SELECT id_esquema from meta.esquema_datos where nombre_esquema = 'geografia'), 'pais', 'Paises',
     'Catalogo de paises usados como nivel geografico principal.',
     'CATALOGO', 'Una fila por pais.',
     'Paises referenciados por el sistema.', NULL,
     'Obtener el pais al que pertenece un departamento.'),
    
    ((SELECT id_esquema from meta.esquema_datos where nombre_esquema = 'geografia'), 'departamento', 'Departamentos',
     'Divisiones administrativas de primer nivel (departamentos) asociadas a un pais.',
     'CATALOGO', 'Una fila por departamento.',
     'Departamentos de los paises registrados.', NULL,
     'Listar los departamentos de Guatemala y su superficie.'),
    
    ((SELECT id_esquema from meta.esquema_datos where nombre_esquema = 'geografia'), 'municipio', 'Municipios',
     'Municipios asociados a un departamento.',
     'CATALOGO', 'Una fila por municipio.',
     'Municipios de los departamentos registrados.', NULL,
     'Ubicar una estacion meteorologica en su municipio.');

INSERT INTO meta.columna_datos (id_tabla, nombre_columna, tipo_dato, descripcion,
                                obligatorio, es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
                                valores_permitidos, ejemplo_valor, regla_validacion) VALUES
-- geografia.pais
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'pais'), 'id', 'INT', 'Identificador unico del pais.',
 TRUE, TRUE, FALSE, NULL, NULL, NULL, '1', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'pais'), 'nombre', 'VARCHAR(100)', 'Nombre oficial del pais.',
 TRUE, FALSE, FALSE, NULL, NULL, NULL, 'Guatemala', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'pais'), 'pcode', 'VARCHAR(12)', 'Codigo geografico estandarizado (P-Code OCHA/HDX) del pais.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, 'GT', 'Unico'),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'pais'), 'iso2', 'CHAR(2)', 'Codigo ISO 3166-1 alfa-2 del pais.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, 'GT', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'pais'), 'iso3', 'CHAR(3)', 'Codigo ISO 3166-1 alfa-3 del pais.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, 'GTM', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'pais'), 'area_km2', 'NUMERIC(14,4)', 'Superficie del pais en kilometros cuadrados.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, '108889.0000', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'pais'), 'centro_lat', 'NUMERIC(11,8)', 'Latitud del centroide geografico del pais.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, '15.77944598', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'pais'), 'centro_lon', 'NUMERIC(11,8)', 'Longitud del centroide geografico del pais.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, '-90.38466276', NULL),

-- geografia.departamento
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'departamento'), 'id', 'INT', 'Identificador unico del departamento.',
 TRUE, TRUE, FALSE, NULL, NULL, NULL, '1', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'departamento'), 'nombre', 'VARCHAR(100)', 'Nombre oficial del departamento.',
 TRUE, FALSE, FALSE, NULL, NULL, NULL, 'Quetzaltenango', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'departamento'), 'pais_id', 'INT', 'Pais al que pertenece el departamento.',
 TRUE, FALSE, TRUE, 'geografia.pais', 'id', NULL, '1', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'departamento'), 'pcode', 'VARCHAR(12)', 'Codigo geografico estandarizado (P-Code OCHA/HDX) del departamento.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, 'GT09', 'Unico'),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'departamento'), 'area_km2', 'NUMERIC(14,4)', 'Superficie del departamento en kilometros cuadrados.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'departamento'), 'centro_lat', 'NUMERIC(11,8)', 'Latitud del centroide geografico del departamento.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'departamento'), 'centro_lon', 'NUMERIC(11,8)', 'Longitud del centroide geografico del departamento.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL),

-- geografia.municipio
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'municipio'), 'id', 'INT', 'Identificador unico del municipio.',
 TRUE, TRUE, FALSE, NULL, NULL, NULL, '1', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'municipio'), 'departamento_id', 'INT', 'Departamento al que pertenece el municipio.',
 TRUE, FALSE, TRUE, 'geografia.departamento', 'id', NULL, '1', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'municipio'), 'nombre', 'VARCHAR(100)', 'Nombre oficial del municipio.',
 TRUE, FALSE, FALSE, NULL, NULL, NULL, 'Coatepeque', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'municipio'), 'pcode', 'VARCHAR(12)', 'Codigo geografico estandarizado (P-Code OCHA/HDX) del municipio.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, 'GT0411', 'Unico'),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'municipio'), 'area_km2', 'NUMERIC(14,4)', 'Superficie del municipio en kilometros cuadrados.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'municipio'), 'centro_lat', 'NUMERIC(11,8)', 'Latitud del centroide geografico del municipio.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'municipio'), 'centro_lon', 'NUMERIC(11,8)', 'Longitud del centroide geografico del municipio.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL);

INSERT INTO meta.tema_datos (nombre_tema, descripcion, palabras_clave) VALUES
    ('Geografia', 'Ubicacion y division territorial del pais.',
     'geografia, territorio, pais, departamento, municipio, ubicacion, coordenadas, division administrativa')
ON CONFLICT (nombre_tema) DO UPDATE SET
    descripcion = EXCLUDED.descripcion,
    palabras_clave = EXCLUDED.palabras_clave;

INSERT INTO meta.objeto_tema (id_tema, nivel_objeto, id_esquema, id_tabla, id_columna, relevancia, justificacion) VALUES
    (
        (SELECT id_tema FROM meta.tema_datos WHERE nombre_tema = 'Geografia'),
    'ESQUEMA', (SELECT id_esquema from meta.esquema_datos where nombre_esquema = 'geografia'), NULL, NULL, 'ALTA',
    'Contiene la referencia territorial del pais.'),
    (
        (SELECT id_tema FROM meta.tema_datos WHERE nombre_tema = 'Geografia'),
       'TABLA', (SELECT id_esquema from meta.esquema_datos where nombre_esquema = 'geografia'), (SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'departamento'), NULL, 'ALTA',
    'Departamentos del pais.'),
    (
        (SELECT id_tema FROM meta.tema_datos WHERE nombre_tema = 'Geografia'),
    'TABLA', (SELECT id_esquema from meta.esquema_datos where nombre_esquema = 'geografia'), (SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'municipio'), NULL, 'ALTA',
'Municipios del pais.');


INSERT INTO geografia.pais (id, nombre, pcode, iso2, iso3, area_km2, centro_lat, centro_lon) OVERRIDING SYSTEM VALUE VALUES
    (1, 'Guatemala', 'GT', 'GT', 'GTM', 108231.3668, 15.77944598, -90.38466276);

SELECT pg_catalog.setval('geografia.pais_id_seq', 1, true);


INSERT INTO geografia.departamento (id, nombre, pais_id, pcode, area_km2, centro_lat, centro_lon) OVERRIDING SYSTEM VALUE VALUES
    (1, 'Guatemala', 1, 'GT01', 2205.5621, 14.57894067, -90.45294933),
    (2, 'El Progreso', 1, 'GT02', 1835.2705, 14.91061623, -90.0680932),
    (3, 'Sacatepéquez', 1, 'GT03', 536.2045, 14.55029776, -90.75735894),
    (4, 'Chimaltenango', 1, 'GT04', 1864.1048, 14.65656179, -90.92908161),
    (5, 'Escuintla', 1, 'GT05', 4504.3636, 14.19074908, -91.02750779),
    (6, 'Santa Rosa', 1, 'GT06', 3160.7011, 14.14646883, -90.35879119),
    (7, 'Sololá', 1, 'GT07', 1167.0620, 14.70769190, -91.28248851),
    (8, 'Totonicapán', 1, 'GT08', 1076.4072, 15.03754075, -91.40818841),
    (9, 'Quetzaltenango', 1, 'GT09', 2132.9465, 14.85894716, -91.59998991),
    (10, 'Suchitepéquez', 1, 'GT10', 2149.9252, 14.37526749, -91.36514000),
    (11, 'Retalhuleu', 1, 'GT11', 1943.7588, 14.41922288, -91.82856356),
    (12, 'San Marcos', 1, 'GT12', 3554.1396, 14.95444864, -91.91189045),
    (13, 'Huehuetenango', 1, 'GT13', 7362.0118, 15.60643774, -91.64453108),
    (14, 'Quiché', 1, 'GT14', 7278.7695, 15.42829560, -91.00758637),
    (15, 'Baja Verapaz', 1, 'GT15', 3017.9901, 15.11112607, -90.41206264),
    (16, 'Alta Verapaz', 1, 'GT16', 10597.4892, 15.59558655, -90.09109722),
    (17, 'Petén', 1, 'GT17', 35903.0890, 16.83219875, -90.04571116),
    (18, 'Izabal', 1, 'GT18', 7490.5338, 15.51702781, -88.72512466),
    (19, 'Zacapa', 1, 'GT19', 2687.6960, 15.01904936, -89.48344981),
    (20, 'Chiquimula', 1, 'GT20', 2415.3086, 14.67630947, -89.39823989),
    (21, 'Jalapa', 1, 'GT21', 2030.3980, 14.64782866, -89.94635212),
    (22, 'Jutiapa', 1, 'GT22', 3317.6350, 14.14861435, -89.89419055);

SELECT pg_catalog.setval('geografia.departamento_id_seq', 22, true);


INSERT INTO geografia.municipio (id, departamento_id, nombre, pcode, area_km2, centro_lat, centro_lon) OVERRIDING SYSTEM VALUE VALUES
    (1, 1, 'Lago De Amatitlan', 'GT0100', 15.2058, 14.45549818, -90.56637107),
    (2, 1, 'Guatemala', 'GT0101', 214.8123, 14.62678724, -90.48001608),
    (3, 1, 'Santa Catarina Pinula', 'GT0102', 67.2743, 14.56775074, -90.46999050),
    (4, 1, 'San José Pinula', 'GT0103', 197.7613, 14.54993695, -90.34978078),
    (5, 1, 'San José del Golfo', 'GT0104', 76.3983, 14.78496624, -90.36429456),
    (6, 1, 'Palencia', 'GT0105', 217.4581, 14.67855916, -90.30633279),
    (7, 1, 'Chinautla', 'GT0106', 66.9874, 14.73561057, -90.49323224),
    (8, 1, 'San Pedro Ayampuc', 'GT0107', 106.7144, 14.76675496, -90.44640971),
    (9, 1, 'Mixco', 'GT0108', 90.2466, 14.64472422, -90.60290865),
    (10, 1, 'San Pedro Sacatepéquez', 'GT0109', 28.8570, 14.68635816, -90.64045778),
    (11, 1, 'San Juan Sacatepéquez', 'GT0110', 272.6832, 14.77907464, -90.65708508),
    (12, 1, 'San Raimundo', 'GT0111', 124.8674, 14.79668275, -90.54372922),
    (13, 1, 'Chuarrancho', 'GT0112', 117.8562, 14.85294055, -90.46483806),
    (14, 1, 'Fraijanes', 'GT0113', 115.0470, 14.45569432, -90.44377866),
    (15, 1, 'Amatitlán', 'GT0114', 100.8784, 14.45564165, -90.61014206),
    (16, 1, 'Villa Nueva', 'GT0115', 88.9921, 14.53265318, -90.61100022),
    (17, 1, 'Villa Canales', 'GT0116', 279.7491, 14.39983099, -90.51001949),
    (18, 1, 'Petapa', 'GT0117', 23.7732, 14.50739941, -90.55823423),
    (19, 2, 'Guastatoya', 'GT0201', 217.8783, 14.85220117, -90.09149415),
    (20, 2, 'Morazán', 'GT0202', 347.3274, 14.99197756, -90.14312729),
    (21, 2, 'San Agustín Acasaguastlán', 'GT0203', 425.8253, 15.01726830, -89.99176399),
    (22, 2, 'San Cristóbal Acasaguastlán', 'GT0204', 164.5413, 15.00564535, -89.88664909),
    (23, 2, 'El Jícaro', 'GT0205', 114.4137, 14.88875714, -89.91784062),
    (24, 2, 'Sanarate', 'GT0206', 274.0198, 14.77693477, -90.19970178),
    (25, 2, 'Sansare', 'GT0207', 143.9504, 14.75246044, -90.10294503),
    (26, 2, 'San Antonio La Paz', 'GT0208', 147.3143, 14.74175695, -90.27449548),
    (27, 3, 'Antigua Guatemala', 'GT0301', 68.8890, 14.53765667, -90.72173015),
    (28, 3, 'Jocotenango', 'GT0302', 9.9514, 14.58564216, -90.73753600),
    (29, 3, 'Pastores', 'GT0303', 39.1741, 14.60233666, -90.76653139),
    (30, 3, 'Sumpango', 'GT0304', 50.5208, 14.66362621, -90.74634341),
    (31, 3, 'Santo Domingo Xenacoj', 'GT0305', 24.7656, 14.68026849, -90.70087430),
    (32, 3, 'Santiago Sacatepéquez', 'GT0306', 40.4532, 14.64122653, -90.68044595),
    (33, 3, 'San Bartolomé Milpas Altas', 'GT0307', 8.3492, 14.60094132, -90.68283085),
    (34, 3, 'San Lucas Sacatepéquez', 'GT0308', 23.2715, 14.59527068, -90.65189180),
    (35, 3, 'Santa Lucía Milpas Altas', 'GT0309', 9.1945, 14.56830084, -90.67699042),
    (36, 3, 'Magdalena Milpas Altas', 'GT0310', 14.5625, 14.54144679, -90.67547209),
    (37, 3, 'Santa María de Jesús', 'GT0311', 60.7991, 14.47662008, -90.70521240),
    (38, 3, 'Ciudad Vieja', 'GT0312', 35.7252, 14.50783853, -90.78189395),
    (39, 3, 'San Miguel Dueñas', 'GT0313', 44.7559, 14.53035397, -90.82868440),
    (40, 3, 'Alotenango', 'GT0314', 90.0986, 14.44136871, -90.81187131),
    (41, 3, 'San Antonio Aguas Calientes', 'GT0315', 5.1483, 14.55326576, -90.77667902),
    (42, 3, 'Santa Catarina Barahona', 'GT0316', 10.5455, 14.55714489, -90.80907796),
    (43, 4, 'Chimaltenango', 'GT0401', 49.0645, 14.68601999, -90.83600707),
    (44, 4, 'San José Poaquil', 'GT0402', 96.5454, 14.86122878, -90.91387309),
    (45, 4, 'San Martín Jilotepeque', 'GT0403', 409.8753, 14.82942203, -90.77281732),
    (46, 4, 'Comalapa', 'GT0404', 85.7143, 14.75227626, -90.89981622),
    (47, 4, 'Santa Apolonia', 'GT0405', 46.1257, 14.83720559, -90.95391834),
    (48, 4, 'Tecpán Guatemala', 'GT0406', 247.8217, 14.81093098, -91.01775151),
    (49, 4, 'Patzún', 'GT0407', 184.1335, 14.65656179, -91.03147850),
    (50, 4, 'Pochuta', 'GT0408', 129.4744, 14.53146344, -91.08123180),
    (51, 4, 'Patzicía', 'GT0409', 64.7168, 14.63903438, -90.93569023),
    (52, 4, 'Santa Cruz Balanyá', 'GT0410', 19.8051, 14.69571905, -90.93084312),
    (53, 4, 'Acatenango', 'GT0411', 130.9309, 14.55013370, -90.95389724),
    (54, 4, 'Yepocapa', 'GT0412', 205.3999, 14.45007843, -91.00693657),
    (55, 4, 'San Andrés Itzapa', 'GT0413', 67.6319, 14.60316512, -90.86150994),
    (56, 4, 'Parramos', 'GT0414', 29.4275, 14.59359077, -90.82441665),
    (57, 4, 'Zaragoza', 'GT0415', 51.8991, 14.67975066, -90.88956442),
    (58, 4, 'El Tejar', 'GT0416', 45.5389, 14.67960820, -90.79006957),
    (59, 5, 'Escuintla', 'GT0501', 546.3785, 14.30792903, -90.80437405),
    (60, 5, 'Santa Lucía Cotzumalguapa', 'GT0502', 454.7305, 14.29445644, -91.07616737),
    (61, 5, 'La Democracia', 'GT0503', 289.6529, 14.12118907, -90.95852841),
    (62, 5, 'Siquinalá', 'GT0504', 184.4208, 14.36247457, -90.93784811),
    (63, 5, 'Masagua', 'GT0505', 473.4475, 14.09872282, -90.81774325),
    (64, 5, 'Tiquisate', 'GT0506', 471.6408, 14.17174751, -91.40042802),
    (65, 5, 'La Gomera', 'GT0507', 518.4862, 14.08413805, -91.12763100),
    (66, 5, 'Guanagazapa', 'GT0508', 227.4484, 14.15862264, -90.65063352),
    (67, 5, 'San José', 'GT0509', 217.8067, 13.97112109, -90.88881212),
    (68, 5, 'Iztapa', 'GT0510', 65.1883, 13.97426234, -90.69023719),
    (69, 5, 'Palín', 'GT0511', 110.9892, 14.39455468, -90.69844768),
    (70, 5, 'San Vicente Pacaya', 'GT0512', 150.0260, 14.33841492, -90.65911558),
    (71, 5, 'Nueva Concepción', 'GT0513', 524.3672, 14.12926063, -91.29301203),
    (72, 5, 'Sipacate', 'GT0514', 269.7806, 13.96283377, -91.14763052),
    (73, 6, 'Cuilapa', 'GT0601', 213.6605, 14.24797179, -90.28868850),
    (74, 6, 'Barberena', 'GT0602', 224.4194, 14.30284599, -90.39959757),
    (75, 6, 'Santa Rosa de Lima', 'GT0603', 134.0372, 14.43553494, -90.35914014),
    (76, 6, 'Casillas', 'GT0604', 204.4023, 14.38959072, -90.15871636),
    (77, 6, 'San Rafael Las Flores', 'GT0605', 85.1037, 14.44691572, -90.15683399),
    (78, 6, 'Oratorio', 'GT0606', 310.1858, 14.11671548, -90.13282838),
    (79, 6, 'San Juan Tecuaco', 'GT0607', 33.6320, 14.07346655, -90.26163142),
    (80, 6, 'Chiquimulilla', 'GT0608', 600.2218, 13.98732828, -90.36163193),
    (81, 6, 'Taxisco', 'GT0609', 639.9725, 14.03897903, -90.55636058),
    (82, 6, 'Santa María Ixhuatán', 'GT0610', 164.6845, 14.14670499, -90.25924160),
    (83, 6, 'Guazacapán', 'GT0611', 109.5195, 14.00642778, -90.42976504),
    (84, 6, 'Santa Cruz Naranjo', 'GT0612', 58.4494, 14.38324873, -90.37029686),
    (85, 6, 'Pueblo Nuevo Viñas', 'GT0613', 250.4350, 14.23362797, -90.52529506),
    (86, 6, 'Nueva Santa Rosa', 'GT0614', 131.9775, 14.39017913, -90.26790728),
    (87, 7, 'Lago De Atitlan', 'GT0700', 127.2226, 14.67857760, -91.18405340),
    (88, 7, 'Sololá', 'GT0701', 151.3469, 14.81741441, -91.18214239),
    (89, 7, 'San José Chacayá', 'GT0702', 15.7894, 14.77617079, -91.22760515),
    (90, 7, 'Santa María Visitación', 'GT0703', 20.7566, 14.70119085, -91.33276605),
    (91, 7, 'Santa Lucía Utatlán', 'GT0704', 51.0650, 14.78219735, -91.26900629),
    (92, 7, 'Nahualá', 'GT0705', 186.2306, 14.73419271, -91.44310806),
    (93, 7, 'Santa Catarina Ixtahuacán', 'GT0706', 189.7769, 14.71181291, -91.38103715),
    (94, 7, 'Santa Clara La Laguna', 'GT0707', 14.3572, 14.72052863, -91.29714845),
    (95, 7, 'Concepción', 'GT0708', 14.9727, 14.78357133, -91.13415119),
    (96, 7, 'San Andrés Semetabaj', 'GT0709', 52.9632, 14.75412428, -91.11076286),
    (97, 7, 'Panajachel', 'GT0710', 7.7225, 14.74905022, -91.15340546),
    (98, 7, 'Santa Catarina Palopó', 'GT0711', 4.7299, 14.71902498, -91.12887737),
    (99, 7, 'San Antonio Palopó', 'GT0712', 26.1152, 14.66565633, -91.10323988),
    (100, 7, 'San Lucas Tolimán', 'GT0713', 73.6749, 14.58998829, -91.14958981),
    (101, 7, 'Santa Cruz La Laguna', 'GT0714', 11.2668, 14.74481946, -91.22322497),
    (102, 7, 'San Pablo La Laguna', 'GT0715', 6.1349, 14.73550827, -91.28131681),
    (103, 7, 'San Marcos La Laguna', 'GT0716', 9.1849, 14.73259576, -91.26006063),
    (104, 7, 'San Juan La Laguna', 'GT0717', 37.1762, 14.67337172, -91.30744055),
    (105, 7, 'San Pedro La Laguna', 'GT0718', 50.6593, 14.64782339, -91.26826069),
    (106, 7, 'Santiago Atitlán', 'GT0719', 115.9165, 14.59905044, -91.24231194),
    (107, 8, 'Totonicapán', 'GT0801', 244.5335, 14.89211957, -91.31048085),
    (108, 8, 'San Cristóbal Totonicapán', 'GT0802', 44.2683, 14.92637573, -91.46263263),
    (109, 8, 'San Francisco El Alto', 'GT0803', 72.6481, 14.97567410, -91.49795111),
    (110, 8, 'San Andrés Xecul', 'GT0804', 16.4943, 14.91069052, -91.49734004),
    (111, 8, 'Momostenango', 'GT0805', 359.2305, 15.10969300, -91.36602100),
    (112, 8, 'Santa María Chiquimula', 'GT0806', 237.5008, 15.03675029, -91.32542032),
    (113, 8, 'Santa Lucía La Reforma', 'GT0807', 45.4064, 15.15241186, -91.28132220),
    (114, 8, 'San Bartolo', 'GT0808', 56.3253, 15.10887437, -91.46929748),
    (115, 9, 'Quetzaltenango', 'GT0901', 126.8547, 14.81360518, -91.54274268),
    (116, 9, 'Salcajá', 'GT0902', 16.8823, 14.87709663, -91.46233767),
    (117, 9, 'Olintepeque', 'GT0903', 32.1851, 14.89361524, -91.53822394),
    (118, 9, 'San Carlos Sija', 'GT0904', 226.5891, 15.07910462, -91.56767571),
    (119, 9, 'Sibilia', 'GT0905', 41.0776, 14.99103714, -91.63927714),
    (120, 9, 'Cabricán', 'GT0906', 83.6883, 15.10605065, -91.65757698),
    (121, 9, 'Cajolá', 'GT0907', 20.5348, 14.93686767, -91.62004981),
    (122, 9, 'San Miguel Sigüila', 'GT0908', 17.1329, 14.90153407, -91.60454506),
    (123, 9, 'Ostuncalco', 'GT0909', 109.0417, 14.86160385, -91.69615177),
    (124, 9, 'San Mateo', 'GT0910', 10.8261, 14.84290446, -91.58263581),
    (125, 9, 'Concepción Chiquirichapa', 'GT0911', 21.8977, 14.84377165, -91.61897734),
    (126, 9, 'San Martín Sacatepéquez', 'GT0912', 143.8001, 14.78439164, -91.65857282),
    (127, 9, 'Almolonga', 'GT0913', 12.5508, 14.81138930, -91.48594163),
    (128, 9, 'Cantel', 'GT0914', 49.7435, 14.81404880, -91.43714759),
    (129, 9, 'Huitán', 'GT0915', 36.3485, 15.04259788, -91.63424012),
    (130, 9, 'Zunil', 'GT0916', 77.4741, 14.74273165, -91.49677460),
    (131, 9, 'Colomba', 'GT0917', 205.7289, 14.69749463, -91.75074160),
    (132, 9, 'San Francisco La Unión', 'GT0918', 16.8913, 14.92588094, -91.54656905),
    (133, 9, 'El Palmar', 'GT0919', 175.9270, 14.69826049, -91.59945244),
    (134, 9, 'Coatepeque', 'GT0920', 418.6571, 14.63178130, -92.01066430),
    (135, 9, 'Génova', 'GT0921', 168.3563, 14.58774307, -91.83539417),
    (136, 9, 'Flores Costa Cuca', 'GT0922', 72.4742, 14.63298367, -91.86439635),
    (137, 9, 'La Esperanza', 'GT0923', 12.2518, 14.87655534, -91.57649237),
    (138, 9, 'Palestina de Los Altos', 'GT0924', 36.0325, 14.93602719, -91.67005332),
    (139, 10, 'Mazatenango', 'GT1001', 65.2610, 14.50547479, -91.53765759),
    (140, 10, 'Cuyotenango', 'GT1002', 89.2162, 14.49509667, -91.56817510),
    (141, 10, 'San Francisco Zapotitlán', 'GT1003', 48.9056, 14.63287513, -91.52072578),
    (142, 10, 'San Bernardino', 'GT1004', 14.3168, 14.53320095, -91.45579220),
    (143, 10, 'San José El Ídolo', 'GT1005', 137.7454, 14.37293658, -91.42863824),
    (144, 10, 'Santo Domingo Suchitepéquez', 'GT1006', 236.1290, 14.28239874, -91.49705019),
    (145, 10, 'San Lorenzo', 'GT1007', 284.9521, 14.27978384, -91.52206681),
    (146, 10, 'Samayac', 'GT1008', 25.8287, 14.57266946, -91.47045320),
    (147, 10, 'San Pablo Jocopilas', 'GT1009', 26.1180, 14.59453003, -91.43108291),
    (148, 10, 'San Antonio Suchitepéquez', 'GT1010', 75.0245, 14.51442074, -91.40782908),
    (149, 10, 'San Miguel Panán', 'GT1011', 28.8020, 14.50363212, -91.35911699),
    (150, 10, 'San Gabriel', 'GT1012', 6.6020, 14.50870651, -91.51372005),
    (151, 10, 'Chicacao', 'GT1013', 211.0382, 14.48668272, -91.33029306),
    (152, 10, 'Patulul', 'GT1014', 338.8496, 14.38699232, -91.18643141),
    (153, 10, 'Santa Bárbara', 'GT1015', 177.0638, 14.47283129, -91.24756514),
    (154, 10, 'San Juan Bautista', 'GT1016', 34.6122, 14.43379222, -91.18784916),
    (155, 10, 'Santo Tomás La Unión', 'GT1017', 12.4830, 14.61924030, -91.41188815),
    (156, 10, 'Zunilito', 'GT1018', 13.0927, 14.63285542, -91.49701025),
    (157, 10, 'Pueblo Nuevo', 'GT1019', 18.5178, 14.66806351, -91.53010501),
    (158, 10, 'Río Bravo', 'GT1020', 158.2622, 14.38555576, -91.33605867),
    (159, 10, 'San José La Máquina', 'GT1021', 147.1046, 14.26571415, -91.58252105),
    (160, 11, 'Retalhuleu', 'GT1101', 807.6660, 14.39097844, -91.73697407),
    (161, 11, 'San Sebastián', 'GT1102', 17.7207, 14.55964126, -91.65181845),
    (162, 11, 'Santa Cruz Muluá', 'GT1103', 128.2177, 14.44989196, -91.65451144),
    (163, 11, 'San Martín Zapotitlán', 'GT1104', 9.3942, 14.61404146, -91.59544396),
    (164, 11, 'San Felipe', 'GT1105', 36.6189, 14.63769630, -91.57308079),
    (165, 11, 'San Andrés Villa Seca', 'GT1106', 435.8451, 14.38057069, -91.63400499),
    (166, 11, 'Champerico', 'GT1107', 328.0790, 14.33391183, -91.87756515),
    (167, 11, 'Nuevo San Carlos', 'GT1108', 86.5453, 14.62893547, -91.68993023),
    (168, 11, 'El Asintal', 'GT1109', 93.6721, 14.58869851, -91.74958783),
    (169, 12, 'San Marcos', 'GT1201', 120.5935, 14.99345146, -91.83651888),
    (170, 12, 'San Pedro Sacatepéquez', 'GT1202', 77.3990, 14.95637878, -91.76935819),
    (171, 12, 'San Antonio Sacatepéquez', 'GT1203', 47.3244, 14.96645886, -91.71251654),
    (172, 12, 'Comitancillo', 'GT1204', 134.8362, 15.11975292, -91.73259064),
    (173, 12, 'San Miguel Ixtahuacán', 'GT1205', 196.2395, 15.26957938, -91.71889801),
    (174, 12, 'Concepción Tutuapa', 'GT1206', 224.2377, 15.29024727, -91.87642662),
    (175, 12, 'Tacaná', 'GT1207', 362.1949, 15.29520003, -92.13363089),
    (176, 12, 'Sibinal', 'GT1208', 104.4530, 15.12644601, -92.05658258),
    (177, 12, 'Tajumulco', 'GT1209', 251.5151, 15.05857027, -91.97387648),
    (178, 12, 'Tejutla', 'GT1210', 143.0606, 15.15374167, -91.81761150),
    (179, 12, 'San Rafael Pie de la Cuesta', 'GT1211', 45.2226, 14.93212847, -91.90791973),
    (180, 12, 'Nuevo Progreso', 'GT1212', 140.4694, 14.81517060, -91.88869199),
    (181, 12, 'El Tumbador', 'GT1213', 165.7848, 14.84475520, -91.94261667),
    (182, 12, 'El Rodeo', 'GT1214', 51.7330, 14.88661189, -92.00063622),
    (183, 12, 'Malacatán', 'GT1215', 212.6165, 14.91440996, -92.09153384),
    (184, 12, 'Catarina', 'GT1216', 81.4514, 14.84809737, -92.07018059),
    (185, 12, 'Ayutla', 'GT1217', 118.7274, 14.70609659, -92.13511246),
    (186, 12, 'Ocós', 'GT1218', 54.2759, 14.55894528, -92.18078353),
    (187, 12, 'San Pablo', 'GT1219', 139.3016, 14.97664872, -91.93276170),
    (188, 12, 'El Quetzal', 'GT1220', 87.5037, 14.79464287, -91.79450045),
    (189, 12, 'La Reforma', 'GT1221', 74.1557, 14.82005313, -91.82321254),
    (190, 12, 'Pajapita', 'GT1222', 131.1955, 14.71819480, -92.07142348),
    (191, 12, 'Ixchiguán', 'GT1223', 104.4812, 15.13228212, -91.90669865),
    (192, 12, 'San José Ojetenam', 'GT1224', 78.6550, 15.23766478, -91.96446736),
    (193, 12, 'San Cristóbal Cucho', 'GT1225', 29.7153, 14.88495757, -91.76306813),
    (194, 12, 'Sipacapa', 'GT1226', 151.4631, 15.19451618, -91.65897648),
    (195, 12, 'Esquipulas Palo Gordo', 'GT1227', 50.5406, 14.92479906, -91.84167300),
    (196, 12, 'Río Blanco', 'GT1228', 31.2043, 15.04773955, -91.67954807),
    (197, 12, 'San Lorenzo', 'GT1229', 44.8422, 15.02648221, -91.74679430),
    (198, 12, 'La Blanca', 'GT1230', 98.9466, 14.55125141, -92.11296755),
    (199, 13, 'Huehuetenango', 'GT1301', 189.5466, 15.30295864, -91.33459996),
    (200, 13, 'Chiantla', 'GT1302', 543.2913, 15.50052988, -91.42516693),
    (201, 13, 'Malacatancito', 'GT1303', 412.0239, 15.23432658, -91.47776712),
    (202, 13, 'Cuilco', 'GT1304', 442.9161, 15.45636943, -91.97300474),
    (203, 13, 'Nentón', 'GT1305', 762.8958, 15.93400132, -91.68067318),
    (204, 13, 'San Pedro Necta', 'GT1306', 75.8357, 15.53235410, -91.75188585),
    (205, 13, 'Jacaltenango', 'GT1307', 163.3808, 15.74940077, -91.72100944),
    (206, 13, 'Soloma', 'GT1308', 127.2260, 15.69700161, -91.43076930),
    (207, 13, 'Ixtahuacán', 'GT1309', 239.9554, 15.42539397, -91.80929304),
    (208, 13, 'Santa Bárbara', 'GT1310', 149.4966, 15.33214936, -91.62027590),
    (209, 13, 'La Libertad', 'GT1311', 95.7325, 15.53918425, -91.88223590),
    (210, 13, 'La Democracia', 'GT1312', 241.2880, 15.61770156, -91.86893015),
    (211, 13, 'San Miguel Acatán', 'GT1313', 129.1048, 15.74887878, -91.62532522),
    (212, 13, 'San Rafael La Independencia',  'GT1314', 51.2388, 15.72810991, -91.52112910),
    (213, 13, 'Todos Santos Cuchumatán', 'GT1315', 289.4228, 15.56225369, -91.60469111),
    (214, 13, 'San Juan Atitán', 'GT1316', 76.1009, 15.47407543, -91.62581130),
    (215, 13, 'Santa Eulalia', 'GT1317', 360.3513, 15.75035703, -91.31794493),
    (216, 13, 'San Mateo Ixtatán', 'GT1318', 547.6916, 15.93107950, -91.44621431),
    (217, 13, 'Colotenango', 'GT1319', 63.3221, 15.44293500, -91.71013042),
    (218, 13, 'San Sebastián Huehuetenango', 'GT1320', 128.1717, 15.42655388, -91.55561575),
    (219, 13, 'Tectitán', 'GT1321', 204.2409, 15.36268415, -92.02734205),
    (220, 13, 'Concepción Huista', 'GT1322', 117.3404, 15.64242849, -91.66424195),
    (221, 13, 'San Juan Ixcoy', 'GT1323', 185.7173, 15.64143008, -91.42661424),
    (222, 13, 'San Antonio Huista', 'GT1324', 106.9266, 15.65681076, -91.78453437),
    (223, 13, 'San Sebastián Coatán', 'GT1325', 170.7549, 15.80100593, -91.59179025),
    (224, 13, 'Barillas', 'GT1326', 889.5115, 15.91414717, -91.19274398),
    (225, 13, 'Aguacatán', 'GT1327', 247.8046, 15.40556793, -91.31827615),
    (226, 13, 'San Rafael Petzal', 'GT1328', 36.2275, 15.41075185, -91.67141601),
    (227, 13, 'San Gaspar Ixchil', 'GT1329', 27.8144, 15.37481783, -91.71000620),
    (228, 13, 'Santiago Chimaltenango', 'GT1330', 47.6341, 15.51014565, -91.68715265),
    (229, 13, 'Santa Ana Huista', 'GT1331', 177.9717, 15.74644703, -91.84482510),
    (230, 13, 'Unión Cantinil', 'GT1332', 44.3996, 15.58729889, -91.73774525),
    (231, 13, 'Petatán', 'GT1333', 16.6758, 15.61383960, -91.75404207),
    (232, 14, 'Santa Cruz del Quiché', 'GT1401', 112.2398, 15.02645363, -91.12657243),
    (233, 14, 'Chiché', 'GT1402', 115.7884, 15.00892609, -91.03378402),
    (234, 14, 'Chinique', 'GT1403', 61.1966, 15.06908017, -91.02283464),
    (235, 14, 'Zacualpa', 'GT1404', 247.6070, 15.09133482, -90.88903278),
    (236, 14, 'Chajul', 'GT1405', 525.6499, 15.60680386, -90.99863123),
    (237, 14, 'Chichicastenango', 'GT1406', 245.7858, 14.88896500, -91.09244325),
    (238, 14, 'Patzité', 'GT1407', 53.1767, 14.97086840, -91.19668798),
    (239, 14, 'San Antonio Ilotenango', 'GT1408', 138.7057, 15.05648417, -91.21709407),
    (240, 14, 'San Pedro Jocopilas', 'GT1409', 294.8941, 15.16251514, -91.16325517),
    (241, 14, 'Cunén', 'GT1410', 225.9572, 15.37089848, -91.02288053),
    (242, 14, 'San Juan Cotzal', 'GT1411', 162.9758, 15.42591491, -91.00945689),
    (243, 14, 'Joyabaj', 'GT1412', 472.5898, 15.00777258, -90.81477413),
    (244, 14, 'Nebaj', 'GT1413', 851.2417, 15.60570087, -91.18285149),
    (245, 14, 'San Andrés Sajcabajá', 'GT1414', 169.3146, 15.22375691, -90.93148316),
    (246, 14, 'Uspantán', 'GT1415', 836.8656, 15.48202001, -90.84182243),
    (247, 14, 'Sacapulas', 'GT1416', 368.1551, 15.26713227, -91.12554748),
    (248, 14, 'San Bartolomé Jocotenango', 'GT1417', 103.4090, 15.18237355, -91.01589716),
    (249, 14, 'Canillá', 'GT1418', 102.0943, 15.20208676, -90.86194139),
    (250, 14, 'Chicamán', 'GT1419', 566.2553, 15.39897613, -90.74479982),
    (251, 14, 'Ixcán', 'GT1420', 1583.0695, 15.88050724, -90.90351722),
    (252, 14, 'Pachalum', 'GT1421', 41.7977, 14.92684251, -90.66008886),
    (253, 15, 'Salamá', 'GT1501', 675.0349, 15.05278598, -90.32461512),
    (254, 15, 'San Miguel Chicaj', 'GT1502', 327.0803, 15.14100412, -90.41989469),
    (255, 15, 'Rabinal', 'GT1503', 311.8518, 15.13264011, -90.52974402),
    (256, 15, 'Cubulco', 'GT1504', 691.5381, 15.15498599, -90.69486310),
    (257, 15, 'Granados', 'GT1505', 154.5649, 14.94084995, -90.57650988),
    (258, 15, 'El Chol', 'GT1506', 119.1930, 14.94921383, -90.49303234),
    (259, 15, 'San Jerónimo', 'GT1507', 221.7197, 15.05152250, -90.21072757),
    (260, 15, 'Purulhá', 'GT1508', 517.0073, 15.21776189, -90.01990584),
    (261, 16, 'Cobán', 'GT1601', 2266.9404, 15.68480537, -90.55782101),
    (262, 16, 'Santa Cruz Verapaz', 'GT1602', 78.0313, 15.33356531, -90.40740039),
    (263, 16, 'San Cristóbal Verapaz', 'GT1603', 384.3463, 15.38356228, -90.57564198),
    (264, 16, 'Tactic', 'GT1604', 116.4137, 15.29386371, -90.34026982),
    (265, 16, 'Tamahú', 'GT1605', 69.9044, 15.30301747, -90.24431211),
    (266, 16, 'Tucurú', 'GT1606', 219.0914, 15.30697887, -90.06985947),
    (267, 16, 'Panzós', 'GT1607', 729.0742, 15.32323572, -89.66896432),
    (268, 16, 'Senahú', 'GT1608', 705.4743, 15.42565352, -89.79781195),
    (269, 16, 'San Pedro Carchá', 'GT1609', 1314.5027, 15.57678591, -90.20255940),
    (270, 16, 'San Juan Chamelco', 'GT1610', 186.9415, 15.39497743, -90.24957344),
    (271, 16, 'Lanquín', 'GT1611', 236.1797, 15.57630082, -89.98828373),
    (272, 16, 'Cahabón', 'GT1612', 760.4837, 15.61157084, -89.73411652),
    (273, 16, 'Chisec', 'GT1613', 1094.4896, 15.88928409, -90.33884298),
    (274, 16, 'Chahal', 'GT1614', 459.4934, 15.73783955, -89.56825193),
    (275, 16, 'Fray Bartolomé de Las Casas', 'GT1615', 1210.9656, 15.88580829, -89.72556532),
    (276, 16, 'Santa Catalina La Tinta', 'GT1616', 197.3063, 15.25066148, -89.83074157),
    (277, 16, 'Raxruhá', 'GT1617', 567.8506, 15.89132475, -90.10511329),
    (278, 17, 'Flores', 'GT1701', 3865.7596, 17.35403899, -89.51882178),
    (279, 17, 'San José', 'GT1702', 2086.6323, 17.37374458, -89.80942323),
    (280, 17, 'San Benito', 'GT1703', 545.1273, 16.98263308, -90.10364703),
    (281, 17, 'San Andrés', 'GT1704', 8035.4897, 17.38799276, -90.45187272),
    (282, 17, 'La Libertad', 'GT1705', 4981.5518, 16.99345299, -90.64256054),
    (283, 17, 'San Francisco', 'GT1706', 1577.0599, 16.62384831, -90.03089498),
    (284, 17, 'Santa Ana', 'GT1707', 1484.9365, 16.83077604, -89.61291826),
    (285, 17, 'Dolores', 'GT1708', 1657.9644, 16.64511632, -89.35974829),
    (286, 17, 'San Luis', 'GT1709', 3087.4697, 16.05650217, -89.64010502),
    (287, 17, 'Sayaxché', 'GT1710', 2667.7155, 16.29759356, -90.16868055),
    (288, 17, 'Melchor de Mencos', 'GT1711', 2105.7165, 17.32159467, -89.24412700),
    (289, 17, 'Poptún', 'GT1712', 1089.9128, 16.33494765, -89.52598955),
    (290, 17, 'Las Cruces', 'GT1713', 1759.8994, 16.86040321, -90.85309424),
    (291, 17, 'El Chal', 'GT1714', 957.8535, 16.51558379, -89.72766941),
    (292, 18, 'Puerto Barrios', 'GT1801', 1196.5547, 15.73437696, -88.43142067),
    (293, 18, 'Lívingston', 'GT1802', 2352.5292, 15.74925566, -89.17770577),
    (294, 18, 'El Estor', 'GT1803', 1574.4585, 15.43535922, -89.42918263),
    (295, 18, 'Morales', 'GT1804', 1324.7152, 15.42161962, -88.81136643),
    (296, 18, 'Los Amates', 'GT1805', 1042.2762, 15.29129930, -89.08558357),
    (297, 19, 'Zacapa', 'GT1901', 410.5068, 14.97301003, -89.44423114),
    (298, 19, 'Estanzuela', 'GT1902', 95.4844, 14.97439270, -89.60949850),
    (299, 19, 'Río Hondo', 'GT1903', 456.9470, 15.09375540, -89.60731642),
    (300, 19, 'Gualán', 'GT1904', 781.1521, 15.15150376, -89.31565208),
    (301, 19, 'Teculután', 'GT1905', 211.8045, 15.06512895, -89.75555759),
    (302, 19, 'Usumatlán', 'GT1906', 108.1394, 15.00534010, -89.81042874),
    (303, 19, 'Cabañas', 'GT1907', 138.4698, 14.89048370, -89.78261277),
    (304, 19, 'San Diego', 'GT1908', 103.4306, 14.79605710, -89.75857230),
    (305, 19, 'La Unión', 'GT1909', 214.5567, 14.95825838, -89.25894863),
    (306, 19, 'Huité', 'GT1910', 84.8967, 14.91221613, -89.68843365),
    (307, 19, 'San Jorge', 'GT1911', 82.3079, 14.91622605, -89.58892485),
    (308, 20, 'Chiquimula', 'GT2001', 365.0138, 14.79209508, -89.59137527),
    (309, 20, 'San José La Arada', 'GT2002', 115.3292, 14.71528836, -89.60862079),
    (310, 20, 'San Juan Ermita', 'GT2003', 80.4855, 14.74332934, -89.43160666),
    (311, 20, 'Jocotán', 'GT2004', 251.0107, 14.81416675, -89.41027179),
    (312, 20, 'Camotán', 'GT2005', 230.4658, 14.86749377, -89.29574141),
    (313, 20, 'Olopa', 'GT2006', 112.1088, 14.69748673, -89.32336410),
    (314, 20, 'Esquipulas', 'GT2007', 500.7713, 14.63169535, -89.25923558),
    (315, 20, 'Concepción Las Minas', 'GT2008', 214.8544, 14.48960065, -89.45180088),
    (316, 20, 'Quezaltepeque', 'GT2009', 244.4841, 14.61313098, -89.45852339),
    (317, 20, 'San Jacinto', 'GT2010', 70.7518, 14.67839004, -89.51536810),
    (318, 20, 'Ipala', 'GT2011', 230.0331, 14.57971394, -89.62151362),
    (319, 21, 'Jalapa', 'GT2101', 685.1906, 14.62556854, -90.06517414),
    (320, 21, 'San Pedro Pinula', 'GT2102', 530.7316, 14.71363827, -89.84193282),
    (321, 21, 'San Luis Jilotepeque', 'GT2103', 209.9876, 14.64982426, -89.71950364),
    (322, 21, 'San Manuel Chaparrón', 'GT2104', 128.7416, 14.53435920, -89.75946955),
    (323, 21, 'San Carlos Alzatate', 'GT2105', 89.7915, 14.47407507, -90.07479466),
    (324, 21, 'Monjas', 'GT2106', 148.0728, 14.50697149, -89.89836036),
    (325, 21, 'Mataquescuintla', 'GT2107', 237.8822, 14.56776562, -90.20868031),
    (326, 22, 'Jutiapa', 'GT2201', 624.5342, 14.31111918, -89.95036491),
    (327, 22, 'El Progreso', 'GT2202', 99.4544, 14.38132337, -89.85342230),
    (328, 22, 'Santa Catarina Mita', 'GT2203', 202.1593, 14.44470246, -89.76877289),
    (329, 22, 'Agua Blanca', 'GT2204', 238.6644, 14.46112335, -89.59033215),
    (330, 22, 'Asunción Mita', 'GT2205', 502.7620, 14.30814418, -89.67786513),
    (331, 22, 'Yupiltepeque', 'GT2206', 55.5559, 14.16612522, -89.77543365),
    (332, 22, 'Atescatempa', 'GT2207', 85.5701, 14.17116812, -89.72200991),
    (333, 22, 'Jerez', 'GT2208', 52.3030, 14.08083340, -89.76155725),
    (334, 22, 'El Adelanto', 'GT2209', 29.7389, 14.17988514, -89.85269503),
    (335, 22, 'Zapotitlán', 'GT2210', 78.5114, 14.11056804, -89.81783754),
    (336, 22, 'Comapa', 'GT2211', 173.7904, 14.11977523, -89.89442552),
    (337, 22, 'Jalpatagua', 'GT2212', 228.6771, 14.11029163, -90.01606849),
    (338, 22, 'Conguaco', 'GT2213', 132.2499, 14.00057325, -90.01489810),
    (339, 22, 'Moyuta', 'GT2214', 412.5998, 13.90821011, -90.11399762),
    (340, 22, 'Pasaco', 'GT2215', 148.8590, 13.89525078, -90.20587193),
    (341, 22, 'San José Acatempa', 'GT2216', 112.4052, 14.26863677, -90.16280708),
(342, 22, 'Quesada', 'GT2217', 139.8001, 14.28291102, -90.05420337);

SELECT pg_catalog.setval('geografia.municipio_id_seq', 342, true);


-- **********************************************************************
-- Fin schema geografia
-- **********************************************************************





-- **********************************************************************
-- **********************************************************************
-- Schema: clima
-- Climatología registrada por estaciones meteorológicas.
-- **********************************************************************
-- **********************************************************************


-- ************************************
--              METADATOS
-- ************************************
INSERT INTO meta.esquema_datos (nombre_esquema, titulo, id_version_desde, descripcion, objetivo, alcance, fuera_de_alcance) VALUES
('clima', 'Clima', (SELECT id_version from meta.version_proyecto where nombre_version = '1.0'),
 'Estaciones meteorologicas y sus registros climaticos diarios (lluvia, temperatura, humedad, viento y mas).',
 'Almacenar la climatologia historica por estacion para su analisis y cruce con otros dominios.',
 'Mediciones diarias reportadas por las estaciones meteorologicas.',
 'No incluye pronosticos meteorologicos ni alertas en tiempo real.');

INSERT INTO meta.tabla_datos (id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla,
     granularidad, criterio_inclusion, criterio_exclusion, ejemplo_uso) VALUES
((SELECT id_esquema from meta.esquema_datos where nombre_esquema = 'clima'), 'estacion', 'Estaciones meteorologicas',
 'Estaciones que reportan datos climaticos, con su codigo, ubicacion y coordenadas.',
 'CATALOGO', 'Una fila por estacion.',
 'Estaciones cuyo dato climatico se carga al sistema.', NULL,
 'Encontrar las estaciones de un municipio o departamento.'),

((SELECT id_esquema from meta.esquema_datos where nombre_esquema = 'clima'), 'registro_climatico', 'Registros climaticos diarios',
 'Mediciones climaticas diarias por estacion; una fila por estacion y fecha.',
 'TRANSACCIONAL', 'Una fila por estacion y dia.',
 'Mediciones diarias reportadas por cada estacion.',
 'Cada medicion es opcional: queda vacia si la estacion no cuenta con ese sensor.',
 'Calcular la lluvia acumulada mensual de una estacion.');

INSERT INTO meta.columna_datos
    (id_tabla, nombre_columna, tipo_dato, descripcion,
     obligatorio, es_llave_primaria, es_llave_foranea, tabla_referenciada,
     columna_referenciada, valores_permitidos, ejemplo_valor, regla_validacion) VALUES
-- clima.estacion
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'estacion'), 'id', 'INT', 'Identificador unico de la estacion.',
 TRUE, TRUE, FALSE, NULL, NULL, NULL, '1', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'estacion'), 'codigo', 'VARCHAR(50)', 'Codigo de la estacion segun la fuente. Clave natural.',
 TRUE, FALSE, FALSE, NULL, NULL, NULL, 'QZ01', 'Unico'),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'estacion'), 'nombre', 'VARCHAR(200)', 'Nombre de la estacion.',
 TRUE, FALSE, FALSE, NULL, NULL, NULL, 'Estacion Quetzaltenango', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'estacion'), 'ubicacion', 'TEXT', 'Ubicacion o descripcion del sitio de la estacion.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'estacion'), 'municipio', 'INT', 'Municipio donde se ubica la estacion.',
 FALSE, FALSE, TRUE, 'geografia.municipio', 'id', NULL, '1', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'estacion'), 'latitud', 'NUMERIC(10,7)', 'Latitud de la estacion en grados decimales.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, '14.8451000', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'estacion'), 'longitud', 'NUMERIC(10,7)', 'Longitud de la estacion en grados decimales.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, '-91.5180000', NULL),

-- clima.registro_climatico
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro_climatico'), 'id', 'BIGINT', 'Identificador unico del registro climatico.',
 TRUE, TRUE, FALSE, NULL, NULL, NULL, '1', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro_climatico'), 'estacion_id', 'INT', 'Estacion que produjo el registro.',
 TRUE, FALSE, TRUE, 'clima.estacion', 'id', NULL, '1', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro_climatico'), 'fecha', 'DATE', 'Fecha del registro (dia).',
 TRUE, FALSE, FALSE, NULL, NULL, NULL, '2024-01-01', 'Formato YYYY-MM-DD'),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro_climatico'), 'lluvia', 'NUMERIC', 'Precipitacion (lluvia) del dia, en mm.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, '12.4', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro_climatico'), 'temperatura_maxima', 'NUMERIC', 'Temperatura maxima del dia, en grados Celsius.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, '26.0', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro_climatico'), 'temperatura_minima', 'NUMERIC', 'Temperatura minima del dia, en grados Celsius.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, '12.5', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro_climatico'), 'temperatura_media', 'NUMERIC', 'Temperatura media del dia, en grados Celsius.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, '18.7', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro_climatico'), 'evaporacion_tanque', 'NUMERIC', 'Evaporacion medida en tanque, en mm.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro_climatico'), 'humedad_relativa', 'NUMERIC', 'Humedad relativa, en porcentaje.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, '78', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro_climatico'), 'brillo_solar', 'NUMERIC', 'Brillo solar (horas de sol).',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro_climatico'), 'nubosidad', 'NUMERIC', 'Nubosidad reportada por la estacion.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro_climatico'), 'velocidad_viento', 'NUMERIC', 'Velocidad del viento segun la fuente.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro_climatico'), 'direccion_viento', 'NUMERIC', 'Direccion del viento, en grados.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, '180', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro_climatico'), 'presion_atmosferica', 'NUMERIC', 'Presion atmosferica, en hPa.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, '780.2', NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro_climatico'), 'temperatura_suelo_50cm', 'NUMERIC', 'Temperatura del suelo a 50 cm, en grados Celsius.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro_climatico'), 'temperatura_suelo_100cm', 'NUMERIC', 'Temperatura del suelo a 100 cm, en grados Celsius.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL),
((SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro_climatico'), 'radiacion', 'NUMERIC', 'Radiacion solar segun la fuente.',
 FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL);

INSERT INTO meta.tema_datos (nombre_tema, descripcion, palabras_clave) VALUES
('Medio ambiente', 'Temas relacionados con el ambiente, la naturaleza y las condiciones fisicas del territorio.', 'ambiente, naturaleza, ecologia, clima, meteorologia')
ON CONFLICT (nombre_tema) DO UPDATE SET
    descripcion = EXCLUDED.descripcion,
    palabras_clave = EXCLUDED.palabras_clave;

INSERT INTO meta.tema_datos (nombre_tema, descripcion, palabras_clave, tema_padre_id) VALUES
('Clima',
 'Condiciones climaticas y meteorologicas registradas por estaciones.',
 'clima, temperatura, lluvia, precipitacion, viento, humedad, meteorologia, estacion, radiacion',
 (SELECT id_tema FROM meta.tema_datos WHERE nombre_tema = 'Medio ambiente'))
ON CONFLICT (nombre_tema) DO UPDATE SET
    descripcion = EXCLUDED.descripcion,
    palabras_clave = EXCLUDED.palabras_clave,
    tema_padre_id = EXCLUDED.tema_padre_id;

INSERT INTO meta.objeto_tema
    (id_tema, nivel_objeto, id_esquema, id_tabla, id_columna, relevancia, justificacion)
VALUES
((SELECT id_tema FROM meta.tema_datos WHERE nombre_tema = 'Clima'),
 'ESQUEMA', (SELECT id_esquema from meta.esquema_datos where nombre_esquema = 'clima'), NULL, NULL, 'ALTA',
 'Datos climaticos por estacion.'),
((SELECT id_tema FROM meta.tema_datos WHERE nombre_tema = 'Clima'),
 'TABLA', (SELECT id_esquema from meta.esquema_datos where nombre_esquema = 'clima'), (SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'estacion'), NULL, 'ALTA',
 'Estaciones meteorologicas.'),
((SELECT id_tema FROM meta.tema_datos WHERE nombre_tema = 'Clima'),
 'TABLA', (SELECT id_esquema from meta.esquema_datos where nombre_esquema = 'clima'), (SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro_climatico'), NULL, 'ALTA',
 'Mediciones climaticas diarias.'),
((SELECT id_tema FROM meta.tema_datos WHERE nombre_tema = 'Clima'),
 'COLUMNA', (SELECT id_esquema from meta.esquema_datos where nombre_esquema = 'clima'), (SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro_climatico'), (SELECT id_columna from meta.columna_datos where nombre_columna = 'lluvia'), 'MEDIA',
 'Precipitacion diaria registrada.'),
((SELECT id_tema FROM meta.tema_datos WHERE nombre_tema = 'Clima'),
 'COLUMNA', (SELECT id_esquema from meta.esquema_datos where nombre_esquema = 'clima'), (SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro_climatico'),  (SELECT id_columna from meta.columna_datos where nombre_columna = 'temperatura_media'), 'MEDIA',
 'Temperatura media diaria registrada.'),

((SELECT id_tema FROM meta.tema_datos WHERE nombre_tema = 'Medio ambiente'),
 'ESQUEMA', (SELECT id_esquema from meta.esquema_datos where nombre_esquema = 'clima'), NULL, NULL, 'ALTA',
 'El clima es parte del medio ambiente.'),
((SELECT id_tema FROM meta.tema_datos WHERE nombre_tema = 'Medio ambiente'),
 'TABLA', (SELECT id_esquema from meta.esquema_datos where nombre_esquema = 'clima'), (SELECT id_tabla from meta.tabla_datos where nombre_tabla = 'registro_climatico'), NULL, 'MEDIA',
 'Mediciones ambientales diarias.');


INSERT INTO clima.estacion (id, codigo, nombre, municipio, ubicacion, latitud, longitud) OVERRIDING SYSTEM VALUE VALUES
(1, 'INS090101CV', 'ESTACIÓN Los Altos, Quetzaltenango', 115, 'Diagonal 10, 13-45 zona 6, interior del aeropuerto de Quetzaltenango', 14.8599015, -91.5080728),
(2, 'INS090301CV', 'ESTACIÓN Labor Ovalle, Quetzaltenango', 117, NULL, 14.8713340, -91.5144380),
(3, 'INS010101CV', 'ESTACIÓN INSIVUMEH, Guatemala', 2, '7 Av. 14-57 Zona 13, Ciudad de Guatemala', 14.5872670, -90.5326790),
(4, 'INS010102CV', 'ESTACIÓN La Aurora, Guatemala', 2, '9a Avenida 14-75, Zona 13, Ciudad de Guatemala', 14.5861900, -90.5277300),
(5, 'INS030101AT', 'ESTACIÓN Antigua Guatemala', 27, NULL, 14.5397400, -90.7383000),
(6, 'INS140101AT', 'ESTACIÓN Santa Cruz Quiché', 232, 'Entre 0 y 1ra avenida, 3ra calle zona 5, Edificio Municipal de Santa Cruz del Quiché', 15.0501600, -91.1539500),
(7, 'INS180101CV', 'ESTACIÓN Puerto Barrios PHC, Izabal', 292, '6ta calle, 6ta avenida, Edificio de Correos, Puerto Barrios, Izabal', 15.7301610, -88.5843950),
(8, 'INS160101CV', 'ESTACIÓN Cobán, Alta Verapaz', 261, '3ra calle 2-02 zona 3, Cobán, Alta Verapaz (Edificio de Correos)', 15.4699200, -90.4055180);

SELECT pg_catalog.setval('clima.estacion_id_seq', 8, true);


INSERT INTO clima.registro_climatico (id, estacion_id, fecha, lluvia, temperatura_maxima, temperatura_minima, temperatura_media, evaporacion_tanque, humedad_relativa, brillo_solar, nubosidad, velocidad_viento, direccion_viento, presion_atmosferica, temperatura_suelo_50cm, temperatura_suelo_100cm, radiacion) OVERRIDING SYSTEM VALUE VALUES
(1, 3, '2026-06-06', 15.4, 28.2, 17.4, 22.1, 5.6, 88.0, 3.1, 8.0, 3.3, 9.0, NULL, 22.5, 23.2, NULL),
(2, 3, '2026-06-07', 1.7, 24.8, 18.1, 19.9, NULL, 95.0, 1.4, 8.0, 1.3, 270.0, NULL, NULL, 23.3, NULL),
(3, 3, '2026-06-08', 4.1, 25.5, 18.6, 21.3, NULL, 87.0, 3.5, 6.0, 1.7, 135.0, NULL, 22.8, 23.4, NULL),
(4, 3, '2026-06-09', 11.2, 26.1, 17.6, 21.5, 0.9, 80.0, 4.3, 8.0, 5.0, 180.0, NULL, 22.7, 23.4, NULL),
(5, 3, '2026-06-10', 8.5, 24.4, 17.5, 20.4, 2.9, 86.0, 0.6, 8.0, 4.3, 180.0, NULL, 22.6, 23.4, NULL),
(6, 3, '2026-06-11', 14.3, 20.9, 17.5, 18.6, 7.0, 96.0, 0.0, 8.0, 1.7, 180.0, NULL, NULL, 23.4, NULL),
(7, 3, '2026-06-12', 0.0, 23.8, 17.1, 20.5, NULL, 82.0, NULL, 8.0, 3.7, 180.0, NULL, 22.5, 23.2, NULL),
(8, 3, '2026-06-13', 0.0, 28.4, 16.8, 21.8, 0.9, 84.0, 3.7, 5.0, 0.7, 0.0, NULL, 22.5, 23.2, NULL),
(9, 3, '2026-06-14', 0.0, 27.1, 18.3, 23.4, NULL, 70.0, 5.8, 3.0, 4.7, 360.0, NULL, NULL, 23.4, NULL),
(10, 3, '2026-06-15', 2.4, 29.9, 18.7, 21.2, 3.7, 90.0, 8.3, 8.0, 9.5, 112.5, NULL, 22.8, 22.3, NULL),
(11, 3, '2026-06-16', 1.8, 25.9, 17.3, 21.5, 2.7, 81.0, 7.8, 6.0, 4.7, 180.0, NULL, 22.5, 23.1, NULL),
(12, 3, '2026-06-17', 0.0, 26.3, 17.7, 22.0, 2.4, 77.0, 7.8, 4.0, 5.3, 9.0, NULL, 22.5, 23.0, NULL),
(13, 3, '2026-06-18', 0.0, 25.7, 17.9, 22.1, 1.7, 70.0, 9.0, 3.0, 9.7, 9.0, NULL, 22.6, 23.0, NULL),
(14, 3, '2026-06-19', 0.0, 28.3, 16.4, 22.4, 2.0, 72.0, 8.8, 6.0, 3.0, 180.0, NULL, 22.4, 23.0, NULL),
(15, 3, '2026-06-20', 0.0, 27.6, 17.5, 23.3, 7.2, 71.0, NULL, 5.0, 9.7, 90.0, NULL, 22.3, 23.0, NULL),
(16, 3, '2026-06-21', 3.6, 26.2, 17.7, 22.4, NULL, 74.0, NULL, 0.0, 4.3, 45.0, NULL, 22.2, 23.0, NULL),
(17, 3, '2026-06-22', 61.0, 21.6, 17.6, 19.5, NULL, 91.0, 2.3, 8.0, 0.7, 0.0, NULL, 22.3, 23.0, NULL),
(18, 3, '2026-06-23', 0.0, 26.3, 16.7, 22.1, 5.1, 75.0, 9.2, 3.0, 7.0, 360.0, NULL, 22.0, 22.8, NULL),
(19, 3, '2026-06-24', 0.0, 26.8, 17.9, 22.3, 2.9, 68.0, 7.1, 3.0, 7.0, 270.0, NULL, 21.6, 22.6, NULL),
(20, 3, '2026-06-25', 0.1, 24.3, 17.8, 21.2, 3.5, 74.0, 6.4, 6.0, 4.0, 360.0, NULL, 21.9, 22.7, NULL),
(21, 3, '2026-06-26', 1.4, 26.4, 17.3, 21.9, 2.4, 74.0, 6.5, 2.0, 3.3, 45.0, NULL, 21.6, 22.6, NULL),
(22, 3, '2026-06-27', 0.0, 26.3, 17.9, 15.8, 1.4, 80.0, 6.5, 6.0, 10.5, 315.0, NULL, 21.7, 22.7, NULL),
(23, 3, '2026-06-28', 0.0, 27.0, 17.8, 22.3, 3.3, 69.0, NULL, 0.0, 4.3, 360.0, NULL, 21.7, 22.7, NULL),
(24, 3, '2026-06-29', 0.0, 26.3, 17.0, 21.6, NULL, 76.0, 8.4, 5.0, 9.0, 270.0, NULL, 21.9, 22.7, NULL),
(25, 3, '2026-06-30', 0.0, 27.6, 17.4, 23.2, 4.1, 71.0, 7.4, 3.0, 8.0, 360.0, NULL, 21.7, 22.6, NULL),
(26, 3, '2026-07-01', 0.0, 28.3, 18.9, 23.6, 2.5, 54.0, 8.7, 2.0, 5.3, 360.0, NULL, 21.7, 22.6, NULL),
(27, 3, '2026-07-02', 0.0, 26.8, 18.4, 22.7, 1.9, 71.0, 7.4, 5.0, 4.3, 360.0, NULL, 21.8, 22.6, NULL),
(28, 3, '2026-07-03', 0.0, 28.6, 17.9, 23.2, 6.0, 70.0, NULL, 6.0, 6.0, 360.0, NULL, 22.0, 22.6, NULL),
(29, 3, '2026-07-04', 0.0, 28.3, 17.6, 23.6, 4.0, 70.0, 9.0, 5.0, 2.7, 9.0, NULL, 22.2, 22.9, NULL),
(30, 3, '2026-07-05', 2.9, 27.9, 17.3, 23.1, 0.2, 75.0, 6.8, 3.0, 1.7, 90.0, NULL, 22.2, 22.6, NULL),
(31, 3, '2026-07-06', NULL, NULL, 17.7, 21.0, 8.2, 74.0, NULL, 7.0, 3.0, 247.5, NULL, 22.2, 22.2, NULL),
(32, 4, '2026-06-06', 15.0, 27.8, 17.6, 22.3, NULL, 79.0, NULL, 5.0, 6.2, 225.0, 638.1, NULL, NULL, NULL),
(33, 4, '2026-06-07', 1.6, 25.6, 17.8, 20.2, NULL, 91.0, NULL, 8.0, 14.8, 180.0, 637.9, NULL, NULL, NULL),
(34, 4, '2026-06-08', 0.5, 25.8, 15.4, 21.5, NULL, 80.0, NULL, 7.0, 17.3, 180.0, 638.8, NULL, NULL, NULL),
(35, 4, '2026-06-09', 12.1, 26.6, 17.6, 21.6, NULL, 79.0, NULL, 8.0, 16.0, 180.0, 638.9, NULL, NULL, NULL),
(36, 4, '2026-06-10', 7.0, 25.2, 17.4, 20.5, NULL, 84.0, NULL, 8.0, 8.6, 180.0, 637.7, NULL, NULL, NULL),
(37, 4, '2026-06-11', 16.0, 21.4, 17.6, 18.7, NULL, 94.0, NULL, 8.0, 9.9, 180.0, 637.2, NULL, NULL, NULL),
(38, 4, '2026-06-12', 0.0, 24.4, 16.8, 21.0, NULL, 75.0, NULL, 8.0, 13.6, 225.0, 638.2, NULL, NULL, NULL),
(39, 4, '2026-06-13', 0.1, 28.4, 16.6, 21.7, NULL, 76.0, NULL, 8.0, 3.7, 9.0, 639.4, NULL, NULL, NULL),
(40, 4, '2026-06-14', 0.0, 28.2, 18.4, 23.5, NULL, 76.0, NULL, 3.0, 17.3, 360.0, 640.2, NULL, NULL, NULL),
(41, 4, '2026-06-15', 2.6, 28.8, 18.6, 23.9, NULL, 68.0, NULL, 7.0, 18.5, 45.0, 639.6, NULL, NULL, NULL),
(42, 4, '2026-06-16', 2.5, 27.2, 15.0, 21.9, NULL, 75.0, NULL, 7.0, 14.8, 180.0, 639.8, NULL, NULL, NULL),
(43, 4, '2026-06-17', 0.0, 27.2, 16.0, 22.9, NULL, 68.0, NULL, 7.0, 12.3, 180.0, 639.9, NULL, NULL, NULL),
(44, 4, '2026-06-18', 0.0, 26.2, 17.8, 22.4, NULL, 66.0, NULL, 3.0, 17.3, 180.0, 639.9, NULL, NULL, NULL),
(45, 4, '2026-06-19', 0.0, 28.2, 16.4, 22.6, NULL, 69.0, NULL, 8.0, 14.8, 180.0, 639.7, NULL, NULL, NULL),
(46, 4, '2026-06-20', 0.0, 28.6, 16.8, 23.7, NULL, 64.0, NULL, 2.0, 18.5, 45.0, 638.8, NULL, NULL, NULL),
(47, 4, '2026-06-21', 3.4, 27.4, 17.0, 23.0, NULL, 63.0, NULL, 5.0, 12.3, 360.0, 638.6, NULL, NULL, NULL),
(48, 4, '2026-06-22', 59.7, 24.8, 17.4, 19.3, NULL, 90.0, NULL, 8.0, 9.9, 360.0, 640.1, NULL, NULL, NULL),
(49, 4, '2026-06-23', 0.0, 26.0, 16.8, 22.3, NULL, 69.0, NULL, 3.0, 22.2, 360.0, 640.3, NULL, NULL, NULL),
(50, 4, '2026-06-24', 0.0, 26.6, 17.4, 22.2, NULL, 67.0, NULL, 6.0, 24.6, 360.0, 639.5, NULL, NULL, NULL),
(51, 4, '2026-06-25', 0.3, 24.4, 17.8, 21.2, NULL, 68.0, NULL, 8.0, 24.7, 360.0, 639.5, NULL, NULL, NULL),
(52, 4, '2026-06-26', 1.2, 26.4, 17.2, 21.9, NULL, 69.0, NULL, 5.0, 27.1, 360.0, 639.9, NULL, NULL, NULL),
(53, 4, '2026-06-27', 0.0, 26.2, 18.0, 21.9, NULL, 71.0, NULL, 8.0, 25.9, 45.0, 639.4, NULL, NULL, NULL),
(54, 4, '2026-06-28', 0.0, 26.8, 17.8, 22.3, NULL, 62.0, NULL, 6.0, 24.7, 360.0, 639.4, NULL, NULL, NULL),
(55, 4, '2026-06-29', 0.0, 26.2, 16.4, 22.1, NULL, 63.0, NULL, 8.0, 24.7, 360.0, 639.3, NULL, NULL, NULL),
(56, 4, '2026-06-30', 0.0, 27.2, 17.4, 22.9, NULL, 69.0, NULL, 5.0, 23.4, 45.0, 639.1, NULL, NULL, NULL),
(57, 4, '2026-07-01', 0.0, 27.8, 18.8, 23.3, NULL, 65.0, NULL, 1.0, 24.7, 45.0, 639.0, NULL, NULL, NULL),
(58, 4, '2026-07-02', 0.0, 27.0, 18.0, 22.7, NULL, 65.0, NULL, 8.0, 27.1, 360.0, 639.5, NULL, NULL, NULL),
(59, 4, '2026-07-03', 0.0, 27.8, 17.6, 23.3, NULL, 63.0, NULL, 8.0, 22.2, 360.0, 640.5, NULL, NULL, NULL),
(60, 4, '2026-07-04', 0.0, 28.0, 16.6, 22.6, NULL, 58.0, NULL, 4.0, 24.7, 45.0, 640.4, NULL, NULL, NULL),
(61, 4, '2026-07-05', 4.2, 28.2, 16.2, 23.1, NULL, 61.0, NULL, 7.0, 19.7, 45.0, 639.7, NULL, NULL, NULL),
(62, 4, '2026-07-06', NULL, NULL, 15.9, 21.4, NULL, 72.0, NULL, 8.0, 13.0, 50.0, 639.6, NULL, NULL, NULL),
(63, 5, '2026-06-06', 8.6, NULL, NULL, NULL, NULL, NULL, NULL, 7.0, 9.0, 180.0, NULL, NULL, NULL, NULL),
(64, 5, '2026-06-07', 2.7, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 11.0, 45.0, NULL, NULL, NULL, NULL),
(65, 5, '2026-06-08', 17.6, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 9.0, 180.0, NULL, NULL, NULL, NULL),
(66, 5, '2026-06-09', 6.0, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 9.0, 180.0, NULL, NULL, NULL, NULL),
(67, 5, '2026-06-10', 0.3, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 9.0, 180.0, NULL, NULL, NULL, NULL),
(68, 5, '2026-06-11', 3.0, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 7.0, 180.0, NULL, NULL, NULL, NULL),
(69, 5, '2026-06-12', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 9.0, 180.0, NULL, NULL, NULL, NULL),
(71, 5, '2026-06-14', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 3.0, 13.3, 225.0, NULL, NULL, NULL, NULL),
(70, 5, '2026-06-13', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 5.0, 9.0, 315.0, NULL, NULL, NULL, NULL),
(72, 5, '2026-06-15', 17.5, NULL, NULL, NULL, NULL, NULL, NULL, 5.0, 13.3, 45.0, NULL, NULL, NULL, NULL),
(73, 5, '2026-06-16', 1.2, NULL, NULL, NULL, NULL, NULL, NULL, 6.0, 13.3, 180.0, NULL, NULL, NULL, NULL),
(74, 5, '2026-06-17', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 5.0, 11.0, 180.0, NULL, NULL, NULL, NULL),
(75, 5, '2026-06-18', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 6.0, 13.3, 180.0, NULL, NULL, NULL, NULL),
(76, 5, '2026-06-19', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 7.0, 13.3, 45.0, NULL, NULL, NULL, NULL),
(77, 5, '2026-06-20', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 6.0, 11.0, 45.0, NULL, NULL, NULL, NULL),
(78, 5, '2026-06-21', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 6.0, 13.3, 9.0, NULL, NULL, NULL, NULL),
(79, 5, '2026-06-22', 17.7, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 9.0, 360.0, NULL, NULL, NULL, NULL),
(80, 5, '2026-06-23', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 5.0, 9.0, 180.0, NULL, NULL, NULL, NULL),
(81, 5, '2026-06-24', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 4.0, 11.3, 180.0, NULL, NULL, NULL, NULL),
(82, 5, '2026-06-25', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 9.0, 180.0, NULL, NULL, NULL, NULL),
(83, 5, '2026-06-26', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 4.0, 11.0, 45.0, NULL, NULL, NULL, NULL),
(84, 5, '2026-06-27', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 5.0, 13.3, 180.0, NULL, NULL, NULL, NULL),
(85, 5, '2026-06-28', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 7.0, 13.3, 180.0, NULL, NULL, NULL, NULL),
(86, 5, '2026-06-29', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 6.0, 13.3, 180.0, NULL, NULL, NULL, NULL),
(87, 5, '2026-06-30', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 5.0, 13.3, 90.0, NULL, NULL, NULL, NULL),
(88, 5, '2026-07-01', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 6.0, 11.0, 45.0, NULL, NULL, NULL, NULL),
(89, 5, '2026-07-02', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 7.0, 13.3, 180.0, NULL, NULL, NULL, NULL),
(90, 5, '2026-07-03', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 6.0, 11.0, 180.0, NULL, NULL, NULL, NULL),
(91, 5, '2026-07-04', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 13.3, 180.0, NULL, NULL, NULL, NULL),
(92, 5, '2026-07-05', 1.7, NULL, NULL, NULL, NULL, NULL, NULL, 7.0, 13.3, 180.0, NULL, NULL, NULL, NULL),
(93, 5, '2026-07-06', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 13.5, 135.0, NULL, NULL, NULL, NULL),
(94, 1, '2026-06-06', 0.0, 25.0, 11.6, 17.7, 2.3, 80.0, 3.8, 8.0, 4.9, 0.0, 578.9, NULL, NULL, NULL),
(95, 1, '2026-06-07', 0.5, 21.0, 13.0, 17.3, 4.1, 81.0, 1.4, 8.0, 2.5, 0.0, 578.7, NULL, NULL, NULL),
(96, 1, '2026-06-08', 0.4, 22.0, 12.4, 17.0, 4.0, 82.0, 2.0, 8.0, 4.9, 0.0, 579.6, NULL, NULL, NULL),
(97, 1, '2026-06-09', 6.1, 23.0, 12.0, 16.3, 2.5, 84.0, 3.4, 8.0, 4.9, 0.0, 580.0, NULL, NULL, NULL),
(98, 1, '2026-06-10', 21.0, 22.0, 11.8, 15.4, 1.9, 86.0, 2.1, 8.0, 3.7, 0.0, 578.6, NULL, NULL, NULL),
(99, 1, '2026-06-11', 5.8, 18.2, 12.8, 15.4, 2.2, 89.0, 0.0, 8.0, 0.0, 0.0, 580.9, NULL, NULL, NULL),
(100, 1, '2026-06-12', 0.2, 20.2, 12.0, 15.9, 3.8, 83.0, 3.0, 8.0, 9.9, 180.0, 578.9, NULL, NULL, NULL),
(101, 1, '2026-06-13', 0.3, 24.2, 11.6, 17.9, 3.5, 73.0, 7.2, 6.0, 4.9, 0.0, 580.2, NULL, NULL, NULL),
(102, 1, '2026-06-14', 0.8, 27.4, 11.6, 18.6, 4.2, 73.0, 4.6, 4.0, 3.7, 0.0, 580.3, NULL, NULL, NULL),
(103, 1, '2026-06-15', 17.0, 26.0, 8.2, 17.3, 4.5, 83.0, 5.3, 2.0, 4.9, 0.0, 581.1, NULL, NULL, NULL),
(104, 1, '2026-06-16', 0.0, 23.4, 10.6, 16.3, 3.7, 78.0, 5.8, 3.0, 3.7, 0.0, 580.6, NULL, NULL, NULL),
(105, 1, '2026-06-17', 8.8, 23.0, 10.4, 16.5, 4.2, 80.0, 3.5, 7.0, 6.2, 0.0, 580.7, NULL, NULL, NULL),
(106, 1, '2026-06-18', 0.0, 23.2, 7.6, 16.4, 3.1, 79.0, 6.8, 3.0, 6.2, 0.0, 580.7, NULL, NULL, NULL),
(107, 1, '2026-06-19', 0.0, 24.6, 9.4, 17.5, 3.5, 74.0, 8.5, 6.0, 6.2, 0.0, 580.5, NULL, NULL, NULL),
(108, 1, '2026-06-20', 0.0, 25.6, 8.8, 18.4, 3.5, 68.0, 8.9, 2.0, 7.4, 0.0, 579.8, NULL, NULL, NULL),
(109, 1, '2026-06-21', 1.8, 24.4, 8.0, 16.8, 4.9, 75.0, 5.4, 6.0, 6.2, 0.0, 579.5, NULL, NULL, NULL),
(110, 1, '2026-06-22', 4.3, 21.8, 10.8, 16.3, 2.8, 85.0, 3.0, 7.0, 3.7, 0.0, 580.5, NULL, NULL, NULL),
(111, 1, '2026-06-23', 0.7, 23.0, 11.8, 17.5, 3.9, 76.0, 5.9, 5.0, 13.6, 360.0, 580.8, NULL, NULL, NULL),
(112, 1, '2026-06-24', 0.0, 23.6, 11.6, 17.7, 3.7, 76.0, 4.7, 5.0, 13.6, 45.0, 580.2, NULL, NULL, NULL),
(113, 1, '2026-06-25', 0.0, 22.2, 10.6, 16.5, 4.1, 75.0, 7.2, 6.0, 14.8, 360.0, 579.9, NULL, NULL, NULL),
(114, 1, '2026-06-26', 0.0, 23.0, 5.6, 15.7, 4.3, 80.0, 7.9, 5.0, 14.8, 360.0, 580.4, NULL, NULL, NULL),
(115, 1, '2026-06-27', 0.0, 23.6, 12.2, 18.1, 4.0, 77.0, 6.3, 8.0, 13.6, 45.0, 580.2, NULL, NULL, NULL),
(116, 1, '2026-06-28', 0.0, 23.6, 9.0, 18.1, 2.0, 55.0, 10.4, 3.0, 16.0, 45.0, 580.1, NULL, NULL, NULL),
(117, 1, '2026-06-29', 0.0, 24.2, 9.2, 17.9, 5.5, 60.0, 9.0, 7.0, 17.3, 45.0, 579.8, NULL, NULL, NULL),
(118, 1, '2026-06-30', 0.3, 26.2, 5.8, 18.4, 4.9, 64.0, 5.2, 4.0, 4.9, 0.0, 580.0, NULL, NULL, NULL),
(119, 1, '2026-07-01', 0.0, 26.6, 8.6, 18.8, 2.4, 61.0, 5.6, 4.0, 6.2, 0.0, 580.0, NULL, NULL, NULL),
(120, 1, '2026-07-02', 0.0, 24.2, 7.8, 17.5, 3.2, 65.0, 9.0, 8.0, 12.3, 45.0, 580.3, NULL, NULL, NULL),
(121, 1, '2026-07-03', 0.0, 25.0, 7.4, 17.9, 4.8, 62.0, 7.8, 7.0, 13.6, 45.0, 581.2, NULL, NULL, NULL),
(122, 1, '2026-07-04', 0.0, 25.8, 7.4, 18.6, 3.5, 57.0, 10.8, 2.0, 16.0, 45.0, 581.1, NULL, NULL, NULL),
(123, 1, '2026-07-05', 0.0, 24.6, 5.0, 17.0, 5.9, 65.0, 8.1, 5.0, 8.6, 45.0, 580.3, NULL, NULL, NULL),
(124, 1, '2026-07-06', NULL, NULL, 11.4, 13.2, 3.5, 94.0, NULL, 8.0, 0.0, 0.0, 580.2, NULL, NULL, NULL),
(125, 2, '2026-06-06', 0.0, 26.0, 11.8, 18.0, 1.9, 78.0, 3.8, 7.0, 6.2, 90.0, 579.2, NULL, NULL, NULL),
(126, 2, '2026-06-07', 0.7, 23.0, 12.0, 16.5, 2.5, 84.0, 0.8, 8.0, 3.7, 45.0, 579.1, NULL, NULL, NULL),
(127, 2, '2026-06-08', 0.0, 22.4, 13.2, 17.2, 0.8, 80.0, 3.4, 8.0, 5.6, 180.0, 578.7, NULL, NULL, NULL),
(128, 2, '2026-06-09', 18.6, 23.2, 11.8, 16.9, 2.0, 84.0, 4.3, 8.0, 4.9, 0.0, 578.9, NULL, NULL, NULL),
(129, 2, '2026-06-10', 17.1, 22.8, 11.4, 15.9, 3.0, 87.0, 2.3, 8.0, 0.0, 0.0, 578.2, NULL, NULL, NULL),
(130, 2, '2026-06-11', 3.2, 18.8, 12.8, 15.5, 2.5, 87.0, 0.0, 8.0, 2.5, 0.0, 577.4, NULL, NULL, NULL),
(131, 2, '2026-06-12', 0.4, 20.4, 12.4, 16.3, 0.1, 81.0, 2.1, 8.0, 7.4, 180.0, 578.2, NULL, NULL, NULL),
(132, 2, '2026-06-13', 0.5, 25.2, 12.0, 18.9, 3.0, 73.0, 5.8, 6.0, 2.5, 0.0, 578.9, NULL, NULL, NULL),
(133, 2, '2026-06-14', 0.3, 27.4, 11.6, 18.9, 3.9, 73.0, 4.1, 4.0, 0.0, 0.0, 579.6, NULL, NULL, NULL),
(134, 2, '2026-06-15', 14.2, 26.6, 8.4, 18.3, 0.1, 75.0, 6.0, 6.0, 2.5, 45.0, 579.4, NULL, NULL, NULL),
(135, 2, '2026-06-16', 0.0, 23.6, 11.0, 16.4, 3.8, 54.0, 5.8, 5.0, 6.2, 90.0, 579.3, NULL, NULL, NULL),
(136, 2, '2026-06-17', 7.8, 23.4, 10.6, 16.0, 3.2, 82.0, 3.5, 8.0, 2.5, 45.0, 579.2, NULL, NULL, NULL),
(137, 2, '2026-06-18', 0.0, 22.4, 8.2, 15.3, 1.9, 83.0, 6.3, 5.0, 8.6, 45.0, 579.3, NULL, NULL, NULL),
(138, 2, '2026-06-19', 0.0, 25.4, 10.0, 17.0, 1.7, 75.0, 8.0, 5.0, 6.1, 45.0, 579.3, NULL, NULL, NULL),
(139, 2, '2026-06-20', 0.0, 26.0, 9.0, 18.3, 4.0, 71.0, 9.2, 5.0, 6.2, 45.0, 579.3, NULL, NULL, NULL),
(140, 2, '2026-06-21', 8.9, 23.6, 8.4, 16.1, 4.9, 75.0, 6.7, 7.0, 6.1, 90.0, 579.1, NULL, NULL, NULL),
(141, 2, '2026-06-22', 3.7, 23.4, 10.0, 15.9, 2.0, 81.0, 3.3, 7.0, 4.9, 45.0, 579.1, NULL, NULL, NULL),
(142, 2, '2026-06-23', 0.4, 24.0, 12.0, 17.4, 2.9, 72.0, 6.6, 6.0, 2.5, 0.0, 579.3, NULL, NULL, NULL),
(143, 2, '2026-06-24', 0.0, 24.2, 11.2, 17.5, 3.0, 73.0, 4.8, 7.0, 6.2, 0.0, 579.0, NULL, NULL, NULL),
(144, 2, '2026-06-25', 0.0, 21.4, 12.0, 17.0, 3.6, 68.0, 8.3, 5.0, 11.1, 45.0, 579.1, NULL, NULL, NULL),
(145, 2, '2026-06-26', 0.0, 23.8, 6.4, 16.3, 2.6, 72.0, 7.3, 3.0, 10.5, 45.0, 579.3, NULL, NULL, NULL),
(146, 2, '2026-06-27', 0.0, 24.0, 13.0, 19.1, 4.0, 68.0, 6.9, 8.0, 12.3, 45.0, 579.0, NULL, NULL, NULL),
(147, 2, '2026-06-28', 0.0, 23.4, 9.4, 17.7, 4.1, 60.0, 10.4, 0.0, 12.3, 45.0, 579.1, NULL, NULL, NULL),
(148, 2, '2026-06-29', 0.0, 24.2, 10.0, 18.1, 2.3, 64.0, 10.2, 1.0, 9.9, 45.0, 578.9, NULL, NULL, NULL),
(149, 2, '2026-06-30', 0.1, 26.2, 7.6, 18.1, 3.1, 66.0, 6.1, 5.0, 7.4, 0.0, 578.8, NULL, NULL, NULL),
(150, 2, '2026-07-01', 0.0, 26.0, 9.6, 17.9, 5.5, 74.0, 5.6, 5.0, 4.9, 45.0, 579.3, NULL, NULL, NULL),
(151, 2, '2026-07-02', 0.0, 23.8, 9.2, 16.5, 2.9, 75.0, 8.4, 7.0, 8.6, 90.0, 579.2, NULL, NULL, NULL),
(152, 2, '2026-07-03', 0.0, 24.2, 8.4, 15.9, 4.1, 75.0, 6.1, 8.0, 7.3, 9.0, 579.2, NULL, NULL, NULL),
(153, 2, '2026-07-04', 0.0, 26.4, 7.8, 17.3, 1.6, 72.0, 8.6, 5.0, 2.5, 45.0, 579.3, NULL, NULL, NULL),
(154, 2, '2026-07-05', 0.5, 25.8, 5.4, 16.3, 5.8, 71.0, 8.3, 6.0, 3.7, 45.0, 579.4, NULL, NULL, NULL),
(155, 2, '2026-07-06', NULL, NULL, 12.0, 18.2, 0.6, 68.0, NULL, 8.0, 0.0, 0.0, 578.9, NULL, NULL, NULL),
(156, 6, '2026-06-06', 3.1, NULL, NULL, NULL, NULL, NULL, NULL, 6.0, 11.0, 270.0, NULL, NULL, NULL, NULL),
(157, 6, '2026-06-07', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 9.0, 270.0, NULL, NULL, NULL, NULL),
(158, 6, '2026-06-08', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 16.0, 270.0, NULL, NULL, NULL, NULL),
(159, 6, '2026-06-09', 6.8, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 8.7, 270.0, NULL, NULL, NULL, NULL),
(160, 6, '2026-06-10', 20.2, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 9.0, 270.0, NULL, NULL, NULL, NULL),
(161, 6, '2026-06-11', 9.5, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 7.3, 315.0, NULL, NULL, NULL, NULL),
(162, 6, '2026-06-12', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 10.0, 285.0, NULL, NULL, NULL, NULL),
(163, 6, '2026-06-13', 6.2, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 11.0, 270.0, NULL, NULL, NULL, NULL),
(164, 6, '2026-06-14', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 7.0, 7.0, 270.0, NULL, NULL, NULL, NULL),
(165, 6, '2026-06-15', 6.3, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 10.0, 195.0, NULL, NULL, NULL, NULL),
(166, 6, '2026-06-16', 0.6, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 8.7, 315.0, NULL, NULL, NULL, NULL),
(167, 6, '2026-06-17', 2.9, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 11.3, 270.0, NULL, NULL, NULL, NULL),
(168, 6, '2026-06-18', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 9.0, 270.0, NULL, NULL, NULL, NULL),
(169, 6, '2026-06-19', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 6.0, 11.0, 270.0, NULL, NULL, NULL, NULL),
(170, 6, '2026-06-20', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 7.2, 187.5, NULL, NULL, NULL, NULL),
(171, 6, '2026-06-21', 2.3, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 9.0, 270.0, NULL, NULL, NULL, NULL),
(172, 6, '2026-06-22', 12.5, NULL, NULL, NULL, NULL, NULL, NULL, 7.0, 11.0, 270.0, NULL, NULL, NULL, NULL),
(173, 6, '2026-06-23', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 7.0, 11.0, 270.0, NULL, NULL, NULL, NULL),
(174, 6, '2026-06-24', 0.4, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 13.3, 225.0, NULL, NULL, NULL, NULL),
(175, 6, '2026-06-25', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 5.3, 270.0, NULL, NULL, NULL, NULL),
(176, 6, '2026-06-26', 0.4, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 8.4, 198.0, NULL, NULL, NULL, NULL),
(177, 6, '2026-06-27', 0.3, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 11.0, 270.0, NULL, NULL, NULL, NULL),
(178, 6, '2026-06-28', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 9.3, 270.0, NULL, NULL, NULL, NULL),
(179, 6, '2026-06-29', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 9.0, 9.0, NULL, NULL, NULL, NULL),
(180, 6, '2026-06-30', 0.2, NULL, NULL, NULL, NULL, NULL, NULL, 7.0, 9.7, 270.0, NULL, NULL, NULL, NULL),
(181, 6, '2026-07-01', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 7.0, 15.3, 270.0, NULL, NULL, NULL, NULL),
(182, 6, '2026-07-02', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 9.0, 270.0, NULL, NULL, NULL, NULL),
(183, 6, '2026-07-03', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 9.0, 270.0, NULL, NULL, NULL, NULL),
(184, 6, '2026-07-04', 0.0, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 11.0, 270.0, NULL, NULL, NULL, NULL),
(185, 6, '2026-07-05', 1.6, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 11.0, 270.0, NULL, NULL, NULL, NULL),
(186, 6, '2026-07-06', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 8.0, 11.0, 270.0, NULL, NULL, NULL, NULL),
(187, 8, '2026-06-06', 0.0, 29.8, 15.6, 23.3, 4.0, 79.0, 7.3, 6.0, 6.2, 45.0, 652.5, NULL, NULL, NULL),
(188, 8, '2026-06-07', 4.4, 29.4, 15.4, 22.7, 4.5, 83.0, 5.5, 7.0, 2.5, 0.0, 652.0, NULL, NULL, NULL),
(189, 8, '2026-06-08', 0.0, 31.0, 17.0, 24.4, 4.0, 78.0, 6.4, 8.0, 6.2, 0.0, 652.2, NULL, NULL, NULL),
(190, 8, '2026-06-09', 1.8, 29.8, 16.4, 23.5, 5.0, 82.0, 6.0, 3.0, 4.7, 9.0, 652.9, NULL, NULL, NULL),
(191, 8, '2026-06-10', 0.0, 28.0, 15.6, 22.7, 3.8, 84.0, 3.0, 8.0, 2.3, 0.0, 651.7, NULL, NULL, NULL),
(192, 8, '2026-06-11', 10.0, 25.6, 16.2, 21.4, 2.7, 87.0, 0.0, 8.0, 0.0, 0.0, 651.1, NULL, NULL, NULL),
(193, 8, '2026-06-12', 0.6, 28.4, 16.0, 23.1, 2.1, 78.0, 2.5, 8.0, 2.3, 0.0, 651.9, NULL, NULL, NULL),
(194, 8, '2026-06-13', 0.0, 31.0, 16.6, 24.3, 3.0, 75.0, 4.6, 6.0, 2.3, 0.0, 653.4, NULL, NULL, NULL),
(195, 8, '2026-06-14', 0.0, 20.4, 17.6, 23.8, 4.8, 75.0, 4.5, 6.0, 4.7, 45.0, 654.2, NULL, NULL, NULL),
(196, 8, '2026-06-15', 13.4, 31.4, 15.4, 24.5, 1.7, 68.0, 9.4, 2.0, 7.3, 45.0, 653.4, NULL, NULL, NULL),
(197, 8, '2026-06-16', 1.3, 32.6, 15.6, 24.7, 7.0, 73.0, 7.4, 4.0, 2.5, 0.0, 652.7, NULL, NULL, NULL),
(198, 8, '2026-06-17', 2.1, 33.0, 15.4, 25.3, 5.7, 67.0, 8.0, 3.0, 3.7, 0.0, 652.8, NULL, NULL, NULL),
(199, 8, '2026-06-18', 0.0, 31.6, 17.0, 24.6, 6.3, 68.0, 8.6, 4.0, 3.7, 0.0, 652.7, NULL, NULL, NULL),
(200, 8, '2026-06-19', 15.0, 32.4, 15.2, 24.1, 5.5, 70.0, 7.6, 5.0, 2.5, 0.0, 653.0, NULL, NULL, NULL),
(201, 8, '2026-06-20', 0.0, 29.6, 12.8, 22.5, 5.1, 69.0, 8.1, 2.0, 2.5, 0.0, 653.1, NULL, NULL, NULL),
(202, 8, '2026-06-21', 4.5, 28.6, 12.4, 20.6, 5.7, 81.0, 7.7, 4.0, 3.7, 0.0, 653.0, NULL, NULL, NULL),
(203, 8, '2026-06-22', 18.2, 27.0, 14.0, 21.4, 5.2, 81.0, 3.5, 7.0, 4.9, 90.0, 653.6, NULL, NULL, NULL),
(204, 8, '2026-06-23', 12.3, 28.0, 15.4, 22.1, 3.7, 80.0, 6.0, 6.0, 6.0, 45.0, 654.3, NULL, NULL, NULL),
(205, 8, '2026-06-24', 7.2, 27.2, 15.0, 21.7, 4.2, 80.0, 6.6, 4.0, 11.0, 45.0, 653.9, NULL, NULL, NULL),
(206, 8, '2026-06-25', 3.1, 24.2, 15.0, 19.9, 1.6, 87.0, 3.3, 8.0, 3.7, 0.0, 654.0, NULL, NULL, NULL),
(207, 8, '2026-06-26', 35.7, 27.4, 14.8, 21.9, 0.8, 78.0, 5.8, 4.0, 6.0, 0.0, 654.2, NULL, NULL, NULL),
(208, 8, '2026-06-27', 0.0, 26.8, 14.4, 21.7, 2.8, 80.0, 8.3, 7.0, 6.0, 90.0, 653.8, NULL, NULL, NULL),
(209, 8, '2026-06-28', 1.4, 27.8, 16.8, 23.0, 4.7, 74.0, 7.0, 3.0, 5.0, 0.0, 654.1, NULL, NULL, NULL),
(210, 8, '2026-06-29', 1.4, 26.4, 13.2, 20.5, 5.2, 84.0, 2.4, 7.0, 4.7, 45.0, 653.8, NULL, NULL, NULL),
(211, 8, '2026-06-30', 3.4, 28.2, 14.0, 22.5, 2.5, 77.0, 9.1, 3.0, 6.2, 9.0, 653.5, NULL, NULL, NULL),
(212, 8, '2026-07-01', 1.6, 28.2, 16.4, 22.9, 5.0, 78.0, 6.2, 6.0, 3.7, 0.0, 653.3, NULL, NULL, NULL),
(213, 8, '2026-07-02', 0.9, 27.8, 15.4, 22.6, 4.0, 76.0, 4.8, 8.0, 4.9, 0.0, 654.0, NULL, NULL, NULL),
(214, 8, '2026-07-03', 0.0, 28.4, 15.4, 22.3, 4.3, 77.0, 6.8, 6.0, 3.7, 0.0, 655.0, NULL, NULL, NULL),
(215, 8, '2026-07-04', 0.0, 28.6, 10.0, 20.5, 4.6, 73.0, 9.7, 3.0, 4.9, 0.0, 654.9, NULL, NULL, NULL),
(216, 8, '2026-07-05', 17.0, 28.2, 10.2, 20.1, 4.8, 80.0, 8.6, 5.0, 3.7, 0.0, 654.4, NULL, NULL, NULL),
(217, 8, '2026-07-06', NULL, NULL, 14.4, 20.9, 4.5, 80.0, NULL, 8.0, 3.7, 35.0, 653.6, NULL, NULL, NULL),
(218, 7, '2026-06-06', 8.4, 33.6, 25.0, 29.4, 6.9, 80.0, 10.0, 8.0, 2.3, 0.0, 755.1, NULL, NULL, NULL),
(219, 7, '2026-06-07', 22.0, 31.8, 25.6, 28.9, 5.1, 88.0, 4.5, 3.0, 8.3, 315.0, 754.4, NULL, NULL, NULL),
(220, 7, '2026-06-08', 24.0, 33.4, 24.8, 30.1, NULL, 79.0, 9.5, 4.0, 8.3, 9.0, 755.1, NULL, NULL, NULL),
(221, 7, '2026-06-09', 11.0, 34.0, 24.0, 29.7, NULL, 84.0, 10.0, 6.0, 11.0, 9.0, 755.9, NULL, NULL, NULL),
(222, 7, '2026-06-10', 6.4, 33.0, 24.4, 28.9, NULL, 86.0, 5.4, 8.0, 9.7, 315.0, 754.2, NULL, NULL, NULL),
(223, 7, '2026-06-11', 5.0, 31.0, 24.2, 27.8, 6.4, 90.0, 0.0, 8.0, 6.0, 0.0, 754.0, NULL, NULL, NULL),
(224, 7, '2026-06-12', 5.4, 34.0, 24.8, 28.9, 4.7, 88.0, 9.2, 4.0, 7.3, 90.0, 754.6, NULL, NULL, NULL),
(225, 7, '2026-06-13', 37.5, 32.0, 24.0, 29.1, 6.8, 83.0, 3.7, 8.0, 9.7, 9.0, 756.5, NULL, NULL, NULL),
(226, 7, '2026-06-14', 5.0, 32.4, 24.0, 28.8, NULL, 86.0, 5.4, 4.0, 9.7, NULL, 757.5, NULL, NULL, NULL),
(227, 7, '2026-06-15', 0.0, 33.4, 25.4, 29.6, 5.8, 83.0, 9.4, 5.0, 6.0, 0.0, 756.9, NULL, NULL, NULL),
(228, 7, '2026-06-16', 6.0, 33.8, 25.6, 30.1, 5.7, 82.0, 9.4, 7.0, 9.7, 9.0, 755.9, NULL, NULL, NULL),
(229, 7, '2026-06-17', 16.0, 33.4, 22.6, 29.0, 7.7, 79.0, 10.8, 4.0, 7.3, 9.0, 756.2, NULL, NULL, NULL),
(230, 7, '2026-06-18', 0.0, 34.2, 23.2, 29.6, 8.5, 77.0, 10.5, 4.0, 11.0, 45.0, 756.0, NULL, NULL, NULL),
(231, 7, '2026-06-19', 0.0, 34.6, 24.2, 30.5, 4.4, 77.0, 11.3, 1.0, 3.7, 0.0, 755.8, NULL, NULL, NULL),
(232, 7, '2026-06-20', 0.0, 35.0, 24.6, 29.9, 7.4, 77.0, 11.0, 5.0, 7.3, 9.0, 756.1, NULL, NULL, NULL),
(233, 7, '2026-06-21', 0.0, 33.8, 23.4, 28.8, 5.8, 78.0, 10.0, 5.0, 5.0, 0.0, 756.5, NULL, NULL, NULL),
(234, 7, '2026-06-22', 29.4, 31.6, 24.0, 26.9, 6.4, 86.0, 3.9, 8.0, 6.0, 0.0, 758.0, NULL, NULL, NULL),
(235, 7, '2026-06-23', 14.6, 32.4, 23.0, 28.7, 9.4, 83.0, 8.3, 6.0, 2.3, 0.0, 758.3, NULL, NULL, NULL),
(236, 7, '2026-06-24', 0.0, 32.0, 24.8, 28.9, 10.6, 82.0, 6.7, 7.0, 11.0, 45.0, 757.8, NULL, NULL, NULL),
(237, 7, '2026-06-25', 60.8, 31.4, 24.8, 27.5, 2.0, 85.0, 6.1, 7.0, 14.7, 90.0, 757.7, NULL, NULL, NULL),
(238, 7, '2026-06-26', 39.6, 33.0, 24.0, 29.1, NULL, 82.0, 7.9, 8.0, 13.3, 90.0, 757.9, NULL, NULL, NULL),
(239, 7, '2026-06-27', 0.4, 32.0, 25.0, 28.4, NULL, 84.0, 8.4, 5.0, 13.3, 90.0, 757.6, NULL, NULL, NULL),
(240, 7, '2026-06-28', 3.2, 33.0, 25.0, 29.7, 1.1, 78.0, 10.2, 6.0, 11.0, 45.0, 757.6, NULL, NULL, NULL),
(241, 7, '2026-06-29', 0.9, 31.8, 24.0, 28.7, 5.7, 80.0, 2.5, 8.0, 10.0, 90.0, 757.4, NULL, NULL, NULL),
(242, 7, '2026-06-30', 22.4, 32.0, 24.8, 28.4, 4.4, 87.0, 5.7, 8.0, 5.0, 0.0, 756.9, NULL, NULL, NULL),
(243, 7, '2026-07-01', 35.4, 33.0, 24.6, 29.3, NULL, 80.0, 7.8, 8.0, 9.7, 90.0, 756.1, NULL, NULL, NULL),
(244, 7, '2026-07-02', 2.5, 31.6, 25.0, 28.2, NULL, 86.0, 8.5, 8.0, 5.0, 0.0, 757.5, NULL, NULL, NULL),
(245, 7, '2026-07-03', 1.2, 33.0, 24.8, 29.7, 5.0, 79.0, 9.5, 7.0, 8.7, 90.0, 758.4, NULL, NULL, NULL),
(246, 7, '2026-07-04', 0.0, 32.4, 24.8, 29.1, 1.9, 77.0, 10.4, 5.0, 6.0, 0.0, 758.7, NULL, NULL, NULL),
(247, 7, '2026-07-05', 8.0, 32.2, 24.8, 28.1, 4.0, 87.0, 6.0, 7.0, 5.0, 0.0, 757.9, NULL, NULL, NULL),
(248, 7, '2026-07-06', NULL, NULL, 24.4, 27.9, 4.8, 84.0, NULL, 8.0, 0.4, 30.0, 757.6, NULL, NULL, NULL);

SELECT pg_catalog.setval('clima.registro_climatico_id_seq', 248, true);

CREATE TRIGGER trg_auditoria AFTER INSERT OR DELETE OR UPDATE ON clima.estacion FOR EACH ROW EXECUTE FUNCTION auditoria.fn_auditar();
CREATE TRIGGER trg_auditoria AFTER INSERT OR DELETE OR UPDATE ON clima.registro_climatico FOR EACH ROW EXECUTE FUNCTION auditoria.fn_auditar();


-- **********************************************************************
-- Fin schema clima
-- **********************************************************************

-- **********************************************************************
-- Inicio schema TURISMO
-- **********************************************************************
BEGIN;


-- ============================================================
-- METADATOS TURISMO
-- ============================================================


INSERT INTO meta.esquema_datos (
    nombre_esquema, titulo, descripcion, objetivo, alcance, fuera_de_alcance,
    responsable, id_version_desde, estado, observaciones
)
SELECT
    'meta', 'Metadatos y catálogo de datos', 'Contiene el catálogo central del proyecto: versiones, esquemas, tablas, columnas, temas, fuentes, reglas de calidad, revisiones por pares y decisiones de modelado.', 'Permitir que una persona externa pueda entender qué datos existen, dónde están, qué significan, qué fuentes los respaldan y cómo decidir si un nuevo dato pertenece a un esquema existente o requiere uno nuevo.', 'Documentación estructurada y consultable de todos los esquemas del proyecto.', 'No almacena datos temáticos finales, como destinos turísticos, municipios, clima o denuncias. Solo almacena metadatos y criterios de organización.',
    'Equipo de metadatos', v.id_version, 'ACTIVO',
    'Esquema documentado en el catálogo meta para facilitar búsqueda, comprensión y crecimiento del proyecto.'
FROM meta.version_proyecto v
WHERE v.numero_version = '1.0'
ON CONFLICT (nombre_esquema) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    objetivo = EXCLUDED.objetivo,
    alcance = EXCLUDED.alcance,
    fuera_de_alcance = EXCLUDED.fuera_de_alcance,
    responsable = EXCLUDED.responsable,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.esquema_datos (
    nombre_esquema, titulo, descripcion, objetivo, alcance, fuera_de_alcance,
    responsable, id_version_desde, estado, observaciones
)
SELECT
    'turismo', 'Turismo y Patrimonio', 'Contiene información turística de Guatemala: destinos, regiones turísticas, categorías, actividades, temporadas, patrimonio, rutas, recomendaciones y fuentes.', 'Organizar datos turísticos de forma estructurada y trazable, conectados con la geografía oficial del proyecto.', 'Destinos turísticos, patrimonio turístico, actividades, rutas, regiones turísticas, temporadas, recomendaciones y fuentes de información turística.', 'No almacena resultados deportivos, ligas, estadísticas de competencias, información económica general ni festividades culturales si no tienen enfoque turístico.',
    'Jhony Fuentes / Equipo Turismo', v.id_version, 'ACTIVO',
    'Esquema documentado en el catálogo meta para facilitar búsqueda, comprensión y crecimiento del proyecto.'
FROM meta.version_proyecto v
WHERE v.numero_version = '1.0'
ON CONFLICT (nombre_esquema) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    objetivo = EXCLUDED.objetivo,
    alcance = EXCLUDED.alcance,
    fuera_de_alcance = EXCLUDED.fuera_de_alcance,
    responsable = EXCLUDED.responsable,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;



-- ============================================================
-- Tablas del esquema turismo
-- ============================================================


INSERT INTO meta.tabla_datos (
    id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla, granularidad,
    criterio_inclusion, criterio_exclusion, ejemplo_uso, id_version_desde,
    estado, observaciones
)
SELECT
    e.id_esquema,
    'fuente_turistica',
    'Fuentes turísticas',
    'Fuentes documentales utilizadas para sustentar los datos reales del area de turismo.',
    'FUENTE',
    'Una fila representa una fuente documental, institucional o internacional utilizada para respaldar datos turísticos.',
    'Se incluyen fuentes con institución, URL y fecha de consulta que respalden destinos, regiones, rutas, patrimonio o actividades turísticas.',
    'No se incluyen opiniones sin respaldo, publicaciones sin origen identificable o enlaces que no permitan verificar la información.',
    'UNESCO_TIKAL, Guatemala Convention Bureau - Regiones de Guatemala, CONAP/SIGAP Turismo.',
    v.id_version,
    'ACTIVA',
    'Tabla documentada para que usuarios externos comprendan qué datos contiene y cuándo debe usarse.'
FROM meta.esquema_datos e
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
ON CONFLICT (id_esquema, nombre_tabla) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    tipo_tabla = EXCLUDED.tipo_tabla,
    granularidad = EXCLUDED.granularidad,
    criterio_inclusion = EXCLUDED.criterio_inclusion,
    criterio_exclusion = EXCLUDED.criterio_exclusion,
    ejemplo_uso = EXCLUDED.ejemplo_uso,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tabla_datos (
    id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla, granularidad,
    criterio_inclusion, criterio_exclusion, ejemplo_uso, id_version_desde,
    estado, observaciones
)
SELECT
    e.id_esquema,
    'region_turistica',
    'Regiones turísticas',
    'Regiones turisticas de Guatemala utilizadas para agrupar atractivos y destinos.',
    'CATALOGO',
    'Una fila representa una región turística utilizada para agrupar departamentos o destinos.',
    'Se incluyen regiones turísticas reconocidas o documentadas por fuentes institucionales de turismo.',
    'No se incluyen regiones administrativas oficiales; esas pertenecen a geografía.',
    'Altiplano Cultura Maya Viva, Petén Aventura en el Mundo Maya.',
    v.id_version,
    'ACTIVA',
    'Tabla documentada para que usuarios externos comprendan qué datos contiene y cuándo debe usarse.'
FROM meta.esquema_datos e
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
ON CONFLICT (id_esquema, nombre_tabla) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    tipo_tabla = EXCLUDED.tipo_tabla,
    granularidad = EXCLUDED.granularidad,
    criterio_inclusion = EXCLUDED.criterio_inclusion,
    criterio_exclusion = EXCLUDED.criterio_exclusion,
    ejemplo_uso = EXCLUDED.ejemplo_uso,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tabla_datos (
    id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla, granularidad,
    criterio_inclusion, criterio_exclusion, ejemplo_uso, id_version_desde,
    estado, observaciones
)
SELECT
    e.id_esquema,
    'departamento_region_turistica',
    'Departamentos por región turística',
    'Tabla puente entre regiones turisticas del esquema turismo y departamentos oficiales del esquema geografia.',
    'PUENTE',
    'Una fila relaciona un departamento oficial con una región turística.',
    'Se incluyen relaciones donde un departamento forma parte de una región turística documentada.',
    'No se registran departamentos nuevos ni nombres territoriales alternativos.',
    'Sacatepéquez asociado a Guatemala Moderna y Colonial.',
    v.id_version,
    'ACTIVA',
    'Tabla documentada para que usuarios externos comprendan qué datos contiene y cuándo debe usarse.'
FROM meta.esquema_datos e
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
ON CONFLICT (id_esquema, nombre_tabla) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    tipo_tabla = EXCLUDED.tipo_tabla,
    granularidad = EXCLUDED.granularidad,
    criterio_inclusion = EXCLUDED.criterio_inclusion,
    criterio_exclusion = EXCLUDED.criterio_exclusion,
    ejemplo_uso = EXCLUDED.ejemplo_uso,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tabla_datos (
    id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla, granularidad,
    criterio_inclusion, criterio_exclusion, ejemplo_uso, id_version_desde,
    estado, observaciones
)
SELECT
    e.id_esquema,
    'categoria_destino',
    'Categorías de destino turístico',
    'Categorias tematicas utilizadas para clasificar destinos turisticos.',
    'CATALOGO',
    'Una fila representa una categoría usada para clasificar destinos turísticos.',
    'Se incluyen categorías generales como arqueológico, natural, cultural, religioso, recreativo o urbano.',
    'No se incluyen etiquetas libres, opiniones o categorías duplicadas con distinto nombre.',
    'ARQUEOLOGICO, NATURAL, CULTURAL.',
    v.id_version,
    'ACTIVA',
    'Tabla documentada para que usuarios externos comprendan qué datos contiene y cuándo debe usarse.'
FROM meta.esquema_datos e
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
ON CONFLICT (id_esquema, nombre_tabla) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    tipo_tabla = EXCLUDED.tipo_tabla,
    granularidad = EXCLUDED.granularidad,
    criterio_inclusion = EXCLUDED.criterio_inclusion,
    criterio_exclusion = EXCLUDED.criterio_exclusion,
    ejemplo_uso = EXCLUDED.ejemplo_uso,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tabla_datos (
    id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla, granularidad,
    criterio_inclusion, criterio_exclusion, ejemplo_uso, id_version_desde,
    estado, observaciones
)
SELECT
    e.id_esquema,
    'actividad_turistica',
    'Actividades turísticas',
    'Actividades turisticas que pueden realizarse o recomendarse en los destinos.',
    'CATALOGO',
    'Una fila representa una actividad que puede realizarse en uno o varios destinos.',
    'Se incluyen actividades propias de visita turística como senderismo, fotografía, recorrido guiado, observación de fauna o visita cultural.',
    'No se incluyen deportes competitivos, ligas, resultados o actividades que no tengan enfoque turístico.',
    'Senderismo, fotografía, recorrido histórico.',
    v.id_version,
    'ACTIVA',
    'Tabla documentada para que usuarios externos comprendan qué datos contiene y cuándo debe usarse.'
FROM meta.esquema_datos e
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
ON CONFLICT (id_esquema, nombre_tabla) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    tipo_tabla = EXCLUDED.tipo_tabla,
    granularidad = EXCLUDED.granularidad,
    criterio_inclusion = EXCLUDED.criterio_inclusion,
    criterio_exclusion = EXCLUDED.criterio_exclusion,
    ejemplo_uso = EXCLUDED.ejemplo_uso,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tabla_datos (
    id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla, granularidad,
    criterio_inclusion, criterio_exclusion, ejemplo_uso, id_version_desde,
    estado, observaciones
)
SELECT
    e.id_esquema,
    'temporada_turistica',
    'Temporadas turísticas',
    'Temporadas o periodos utiles para planificacion turistica.',
    'CATALOGO',
    'Una fila representa una temporada o periodo recomendado de visita.',
    'Se incluyen temporadas generales documentadas o definidas para orientar la visita turística.',
    'No se incluyen calendarios completos de eventos o festividades específicas.',
    'Temporada seca, Semana Santa si se usa como periodo turístico general.',
    v.id_version,
    'ACTIVA',
    'Tabla documentada para que usuarios externos comprendan qué datos contiene y cuándo debe usarse.'
FROM meta.esquema_datos e
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
ON CONFLICT (id_esquema, nombre_tabla) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    tipo_tabla = EXCLUDED.tipo_tabla,
    granularidad = EXCLUDED.granularidad,
    criterio_inclusion = EXCLUDED.criterio_inclusion,
    criterio_exclusion = EXCLUDED.criterio_exclusion,
    ejemplo_uso = EXCLUDED.ejemplo_uso,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tabla_datos (
    id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla, granularidad,
    criterio_inclusion, criterio_exclusion, ejemplo_uso, id_version_desde,
    estado, observaciones
)
SELECT
    e.id_esquema,
    'destino_turistico',
    'Destinos turísticos',
    'Destinos turisticos reales de Guatemala documentados para consulta, ETL y analitica BI.',
    'OPERATIVA',
    'Una fila representa un destino turístico específico ubicado en un departamento y opcionalmente en un municipio.',
    'Se incluyen lugares físicos o territoriales que funcionan como atractivo turístico: sitios arqueológicos, parques, lagos, volcanes, reservas, ciudades o monumentos.',
    'No se incluyen eventos temporales, festividades, ligas deportivas ni entidades que no representen un destino turístico. Las festividades deben evaluarse como evento turístico o como dato cultural.',
    'Antigua Guatemala, Parque Nacional Tikal, Lago de Atitlán.',
    v.id_version,
    'ACTIVA',
    'Tabla documentada para que usuarios externos comprendan qué datos contiene y cuándo debe usarse.'
FROM meta.esquema_datos e
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
ON CONFLICT (id_esquema, nombre_tabla) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    tipo_tabla = EXCLUDED.tipo_tabla,
    granularidad = EXCLUDED.granularidad,
    criterio_inclusion = EXCLUDED.criterio_inclusion,
    criterio_exclusion = EXCLUDED.criterio_exclusion,
    ejemplo_uso = EXCLUDED.ejemplo_uso,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tabla_datos (
    id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla, granularidad,
    criterio_inclusion, criterio_exclusion, ejemplo_uso, id_version_desde,
    estado, observaciones
)
SELECT
    e.id_esquema,
    'destino_categoria',
    'Clasificación de destinos por categoría',
    'Relacion muchos a muchos entre destinos turisticos y categorias.',
    'PUENTE',
    'Una fila relaciona un destino turístico con una categoría.',
    'Se incluyen asociaciones verificables entre destinos y categorías turísticas.',
    'No se duplican categorías ni se registran clasificaciones sin justificación.',
    'Tikal asociado a arqueológico y natural.',
    v.id_version,
    'ACTIVA',
    'Tabla documentada para que usuarios externos comprendan qué datos contiene y cuándo debe usarse.'
FROM meta.esquema_datos e
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
ON CONFLICT (id_esquema, nombre_tabla) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    tipo_tabla = EXCLUDED.tipo_tabla,
    granularidad = EXCLUDED.granularidad,
    criterio_inclusion = EXCLUDED.criterio_inclusion,
    criterio_exclusion = EXCLUDED.criterio_exclusion,
    ejemplo_uso = EXCLUDED.ejemplo_uso,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tabla_datos (
    id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla, granularidad,
    criterio_inclusion, criterio_exclusion, ejemplo_uso, id_version_desde,
    estado, observaciones
)
SELECT
    e.id_esquema,
    'destino_actividad',
    'Actividades por destino',
    'Relacion muchos a muchos entre destinos y actividades turisticas.',
    'PUENTE',
    'Una fila relaciona un destino turístico con una actividad disponible o recomendada.',
    'Se incluyen actividades que un visitante puede realizar en el destino.',
    'No se incluyen actividades sin relación directa con la experiencia turística.',
    'Tikal asociado a recorrido guiado y fotografía.',
    v.id_version,
    'ACTIVA',
    'Tabla documentada para que usuarios externos comprendan qué datos contiene y cuándo debe usarse.'
FROM meta.esquema_datos e
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
ON CONFLICT (id_esquema, nombre_tabla) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    tipo_tabla = EXCLUDED.tipo_tabla,
    granularidad = EXCLUDED.granularidad,
    criterio_inclusion = EXCLUDED.criterio_inclusion,
    criterio_exclusion = EXCLUDED.criterio_exclusion,
    ejemplo_uso = EXCLUDED.ejemplo_uso,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tabla_datos (
    id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla, granularidad,
    criterio_inclusion, criterio_exclusion, ejemplo_uso, id_version_desde,
    estado, observaciones
)
SELECT
    e.id_esquema,
    'destino_temporada',
    'Temporadas por destino',
    'Relacion entre destinos y temporadas recomendadas para visita.',
    'PUENTE',
    'Una fila relaciona un destino con una temporada recomendada.',
    'Se incluyen recomendaciones de visita por temporada cuando son útiles para el visitante.',
    'No se incluyen eventos puntuales con fecha específica, salvo que se modelen como temporada general.',
    'Volcán Pacaya asociado a temporada seca.',
    v.id_version,
    'ACTIVA',
    'Tabla documentada para que usuarios externos comprendan qué datos contiene y cuándo debe usarse.'
FROM meta.esquema_datos e
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
ON CONFLICT (id_esquema, nombre_tabla) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    tipo_tabla = EXCLUDED.tipo_tabla,
    granularidad = EXCLUDED.granularidad,
    criterio_inclusion = EXCLUDED.criterio_inclusion,
    criterio_exclusion = EXCLUDED.criterio_exclusion,
    ejemplo_uso = EXCLUDED.ejemplo_uso,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tabla_datos (
    id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla, granularidad,
    criterio_inclusion, criterio_exclusion, ejemplo_uso, id_version_desde,
    estado, observaciones
)
SELECT
    e.id_esquema,
    'destino_fuente',
    'Fuentes por destino',
    'Fuentes documentales que respaldan la informacion de cada destino turistico.',
    'PUENTE',
    'Una fila relaciona un destino turístico con una fuente documental.',
    'Se incluyen todas las fuentes que respaldan datos de un destino.',
    'No se incluyen fuentes sin URL o sin identificación institucional.',
    'Tikal relacionado con UNESCO y SICultura.',
    v.id_version,
    'ACTIVA',
    'Tabla documentada para que usuarios externos comprendan qué datos contiene y cuándo debe usarse.'
FROM meta.esquema_datos e
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
ON CONFLICT (id_esquema, nombre_tabla) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    tipo_tabla = EXCLUDED.tipo_tabla,
    granularidad = EXCLUDED.granularidad,
    criterio_inclusion = EXCLUDED.criterio_inclusion,
    criterio_exclusion = EXCLUDED.criterio_exclusion,
    ejemplo_uso = EXCLUDED.ejemplo_uso,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tabla_datos (
    id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla, granularidad,
    criterio_inclusion, criterio_exclusion, ejemplo_uso, id_version_desde,
    estado, observaciones
)
SELECT
    e.id_esquema,
    'patrimonio_turistico',
    'Patrimonio turístico',
    'Patrimonios UNESCO, nacionales o intangibles vinculados con el turismo en Guatemala.',
    'CATALOGO',
    'Una fila representa un reconocimiento patrimonial nacional o internacional relacionado con turismo.',
    'Se incluyen reconocimientos UNESCO, nacionales o institucionales relacionados con destinos o manifestaciones patrimoniales.',
    'No se registran bienes sin reconocimiento o sin fuente verificable.',
    'Parque Nacional Tikal como Patrimonio Mundial UNESCO.',
    v.id_version,
    'ACTIVA',
    'Tabla documentada para que usuarios externos comprendan qué datos contiene y cuándo debe usarse.'
FROM meta.esquema_datos e
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
ON CONFLICT (id_esquema, nombre_tabla) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    tipo_tabla = EXCLUDED.tipo_tabla,
    granularidad = EXCLUDED.granularidad,
    criterio_inclusion = EXCLUDED.criterio_inclusion,
    criterio_exclusion = EXCLUDED.criterio_exclusion,
    ejemplo_uso = EXCLUDED.ejemplo_uso,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tabla_datos (
    id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla, granularidad,
    criterio_inclusion, criterio_exclusion, ejemplo_uso, id_version_desde,
    estado, observaciones
)
SELECT
    e.id_esquema,
    'destino_patrimonio',
    'Relación destino-patrimonio',
    'Relacion entre destinos turisticos y reconocimientos patrimoniales.',
    'PUENTE',
    'Una fila relaciona un destino turístico con un reconocimiento patrimonial.',
    'Se incluyen relaciones entre destinos y patrimonios reconocidos.',
    'No se incluyen relaciones especulativas o sin fuente.',
    'Antigua Guatemala relacionada con Patrimonio Mundial UNESCO.',
    v.id_version,
    'ACTIVA',
    'Tabla documentada para que usuarios externos comprendan qué datos contiene y cuándo debe usarse.'
FROM meta.esquema_datos e
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
ON CONFLICT (id_esquema, nombre_tabla) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    tipo_tabla = EXCLUDED.tipo_tabla,
    granularidad = EXCLUDED.granularidad,
    criterio_inclusion = EXCLUDED.criterio_inclusion,
    criterio_exclusion = EXCLUDED.criterio_exclusion,
    ejemplo_uso = EXCLUDED.ejemplo_uso,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tabla_datos (
    id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla, granularidad,
    criterio_inclusion, criterio_exclusion, ejemplo_uso, id_version_desde,
    estado, observaciones
)
SELECT
    e.id_esquema,
    'ruta_turistica',
    'Rutas turísticas',
    'Rutas turisticas sugeridas para recorrer destinos relacionados.',
    'OPERATIVA',
    'Una fila representa una ruta turística compuesta por uno o varios destinos.',
    'Se incluyen recorridos sugeridos, rutas institucionales o agrupaciones de destinos con sentido turístico.',
    'No se incluyen rutas de transporte público o movilidad general que no tengan enfoque turístico.',
    'Ruta de Patrimonio UNESCO, ruta del Altiplano.',
    v.id_version,
    'ACTIVA',
    'Tabla documentada para que usuarios externos comprendan qué datos contiene y cuándo debe usarse.'
FROM meta.esquema_datos e
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
ON CONFLICT (id_esquema, nombre_tabla) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    tipo_tabla = EXCLUDED.tipo_tabla,
    granularidad = EXCLUDED.granularidad,
    criterio_inclusion = EXCLUDED.criterio_inclusion,
    criterio_exclusion = EXCLUDED.criterio_exclusion,
    ejemplo_uso = EXCLUDED.ejemplo_uso,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tabla_datos (
    id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla, granularidad,
    criterio_inclusion, criterio_exclusion, ejemplo_uso, id_version_desde,
    estado, observaciones
)
SELECT
    e.id_esquema,
    'ruta_destino',
    'Destinos por ruta turística',
    'Detalle de destinos incluidos en cada ruta turistica sugerida.',
    'PUENTE',
    'Una fila indica que un destino forma parte de una ruta y su orden sugerido.',
    'Se incluyen destinos pertenecientes a una ruta turística y su orden de visita.',
    'No se registran trayectos de transporte sin relación turística.',
    'Ruta UNESCO: Antigua Guatemala, Tikal, Quiriguá, Tak’alik Ab’aj.',
    v.id_version,
    'ACTIVA',
    'Tabla documentada para que usuarios externos comprendan qué datos contiene y cuándo debe usarse.'
FROM meta.esquema_datos e
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
ON CONFLICT (id_esquema, nombre_tabla) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    tipo_tabla = EXCLUDED.tipo_tabla,
    granularidad = EXCLUDED.granularidad,
    criterio_inclusion = EXCLUDED.criterio_inclusion,
    criterio_exclusion = EXCLUDED.criterio_exclusion,
    ejemplo_uso = EXCLUDED.ejemplo_uso,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tabla_datos (
    id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla, granularidad,
    criterio_inclusion, criterio_exclusion, ejemplo_uso, id_version_desde,
    estado, observaciones
)
SELECT
    e.id_esquema,
    'recomendacion_destino',
    'Recomendaciones por destino',
    'Recomendaciones turisticas, logisticas, culturales, ambientales, de seguridad o temporada por destino.',
    'OPERATIVA',
    'Una fila representa una recomendación turística asociada a un destino.',
    'Se incluyen recomendaciones de seguridad, ambiente, cultura, logística o temporada.',
    'No se incluyen opiniones personales sin respaldo o comentarios no verificados.',
    'Recomendación logística para visitar un área protegida.',
    v.id_version,
    'ACTIVA',
    'Tabla documentada para que usuarios externos comprendan qué datos contiene y cuándo debe usarse.'
FROM meta.esquema_datos e
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
ON CONFLICT (id_esquema, nombre_tabla) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    tipo_tabla = EXCLUDED.tipo_tabla,
    granularidad = EXCLUDED.granularidad,
    criterio_inclusion = EXCLUDED.criterio_inclusion,
    criterio_exclusion = EXCLUDED.criterio_exclusion,
    ejemplo_uso = EXCLUDED.ejemplo_uso,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


-- ============================================================
-- 5. Autodocumentacion de tablas meta
-- ============================================================


INSERT INTO meta.tabla_datos (
    id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla, granularidad,
    criterio_inclusion, criterio_exclusion, ejemplo_uso, id_version_desde,
    estado, observaciones
)
SELECT
    e.id_esquema,
    'version_proyecto',
    'Versiones del proyecto',
    'Tabla del esquema meta: versiones del proyecto.',
    'METADATA',
    'Una fila representa una versión del proyecto.',
    'Versiones académicas o técnicas de la base.',
    'No almacena cambios de datos individuales.',
    'Versión 1.0.',
    v.id_version,
    'ACTIVA',
    'Tabla documentada para que usuarios externos comprendan qué datos contiene y cuándo debe usarse.'
FROM meta.esquema_datos e
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'meta'
ON CONFLICT (id_esquema, nombre_tabla) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    tipo_tabla = EXCLUDED.tipo_tabla,
    granularidad = EXCLUDED.granularidad,
    criterio_inclusion = EXCLUDED.criterio_inclusion,
    criterio_exclusion = EXCLUDED.criterio_exclusion,
    ejemplo_uso = EXCLUDED.ejemplo_uso,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tabla_datos (
    id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla, granularidad,
    criterio_inclusion, criterio_exclusion, ejemplo_uso, id_version_desde,
    estado, observaciones
)
SELECT
    e.id_esquema,
    'esquema_datos',
    'Catálogo de esquemas',
    'Tabla del esquema meta: catálogo de esquemas.',
    'METADATA',
    'Una fila representa un esquema de la base documentado.',
    'Esquemas creados o planificados en el proyecto.',
    'No almacena datos finales de los módulos.',
    'turismo, geografia.',
    v.id_version,
    'ACTIVA',
    'Tabla documentada para que usuarios externos comprendan qué datos contiene y cuándo debe usarse.'
FROM meta.esquema_datos e
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'meta'
ON CONFLICT (id_esquema, nombre_tabla) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    tipo_tabla = EXCLUDED.tipo_tabla,
    granularidad = EXCLUDED.granularidad,
    criterio_inclusion = EXCLUDED.criterio_inclusion,
    criterio_exclusion = EXCLUDED.criterio_exclusion,
    ejemplo_uso = EXCLUDED.ejemplo_uso,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tabla_datos (
    id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla, granularidad,
    criterio_inclusion, criterio_exclusion, ejemplo_uso, id_version_desde,
    estado, observaciones
)
SELECT
    e.id_esquema,
    'tabla_datos',
    'Catálogo de tablas',
    'Tabla del esquema meta: catálogo de tablas.',
    'METADATA',
    'Una fila representa una tabla documentada.',
    'Tablas reales o planificadas del proyecto.',
    'No almacena filas de datos temáticos.',
    'turismo.destino_turistico.',
    v.id_version,
    'ACTIVA',
    'Tabla documentada para que usuarios externos comprendan qué datos contiene y cuándo debe usarse.'
FROM meta.esquema_datos e
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'meta'
ON CONFLICT (id_esquema, nombre_tabla) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    tipo_tabla = EXCLUDED.tipo_tabla,
    granularidad = EXCLUDED.granularidad,
    criterio_inclusion = EXCLUDED.criterio_inclusion,
    criterio_exclusion = EXCLUDED.criterio_exclusion,
    ejemplo_uso = EXCLUDED.ejemplo_uso,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tabla_datos (
    id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla, granularidad,
    criterio_inclusion, criterio_exclusion, ejemplo_uso, id_version_desde,
    estado, observaciones
)
SELECT
    e.id_esquema,
    'columna_datos',
    'Diccionario de columnas',
    'Tabla del esquema meta: diccionario de columnas.',
    'METADATA',
    'Una fila representa una columna documentada.',
    'Columnas existentes en las tablas documentadas.',
    'No almacena valores transaccionales.',
    'destino_turistico.nombre.',
    v.id_version,
    'ACTIVA',
    'Tabla documentada para que usuarios externos comprendan qué datos contiene y cuándo debe usarse.'
FROM meta.esquema_datos e
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'meta'
ON CONFLICT (id_esquema, nombre_tabla) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    tipo_tabla = EXCLUDED.tipo_tabla,
    granularidad = EXCLUDED.granularidad,
    criterio_inclusion = EXCLUDED.criterio_inclusion,
    criterio_exclusion = EXCLUDED.criterio_exclusion,
    ejemplo_uso = EXCLUDED.ejemplo_uso,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tabla_datos (
    id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla, granularidad,
    criterio_inclusion, criterio_exclusion, ejemplo_uso, id_version_desde,
    estado, observaciones
)
SELECT
    e.id_esquema,
    'tema_datos',
    'Temas de datos',
    'Tabla del esquema meta: temas de datos.',
    'METADATA',
    'Una fila representa un tema o dominio de búsqueda.',
    'Temas para localizar información dentro del catálogo.',
    'No reemplaza esquemas temáticos finales.',
    'Turismo, Deportes, Festividades.',
    v.id_version,
    'ACTIVA',
    'Tabla documentada para que usuarios externos comprendan qué datos contiene y cuándo debe usarse.'
FROM meta.esquema_datos e
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'meta'
ON CONFLICT (id_esquema, nombre_tabla) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    tipo_tabla = EXCLUDED.tipo_tabla,
    granularidad = EXCLUDED.granularidad,
    criterio_inclusion = EXCLUDED.criterio_inclusion,
    criterio_exclusion = EXCLUDED.criterio_exclusion,
    ejemplo_uso = EXCLUDED.ejemplo_uso,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tabla_datos (
    id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla, granularidad,
    criterio_inclusion, criterio_exclusion, ejemplo_uso, id_version_desde,
    estado, observaciones
)
SELECT
    e.id_esquema,
    'objeto_tema',
    'Relación objeto-tema',
    'Tabla del esquema meta: relación objeto-tema.',
    'METADATA',
    'Una fila relaciona un tema con esquema, tabla o columna.',
    'Relaciones útiles para búsquedas por temas.',
    'No crea datos en los esquemas temáticos.',
    'Tema Turismo asociado a turismo.destino_turistico.',
    v.id_version,
    'ACTIVA',
    'Tabla documentada para que usuarios externos comprendan qué datos contiene y cuándo debe usarse.'
FROM meta.esquema_datos e
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'meta'
ON CONFLICT (id_esquema, nombre_tabla) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    tipo_tabla = EXCLUDED.tipo_tabla,
    granularidad = EXCLUDED.granularidad,
    criterio_inclusion = EXCLUDED.criterio_inclusion,
    criterio_exclusion = EXCLUDED.criterio_exclusion,
    ejemplo_uso = EXCLUDED.ejemplo_uso,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tabla_datos (
    id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla, granularidad,
    criterio_inclusion, criterio_exclusion, ejemplo_uso, id_version_desde,
    estado, observaciones
)
SELECT
    e.id_esquema,
    'fuente_datos',
    'Fuentes de datos',
    'Tabla del esquema meta: fuentes de datos.',
    'METADATA',
    'Una fila representa una fuente general del proyecto.',
    'Fuentes institucionales, oficiales, internacionales o académicas.',
    'No reemplaza la tabla de fuentes específica de un esquema si existe.',
    'UNESCO, CONAP, INGUAT.',
    v.id_version,
    'ACTIVA',
    'Tabla documentada para que usuarios externos comprendan qué datos contiene y cuándo debe usarse.'
FROM meta.esquema_datos e
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'meta'
ON CONFLICT (id_esquema, nombre_tabla) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    tipo_tabla = EXCLUDED.tipo_tabla,
    granularidad = EXCLUDED.granularidad,
    criterio_inclusion = EXCLUDED.criterio_inclusion,
    criterio_exclusion = EXCLUDED.criterio_exclusion,
    ejemplo_uso = EXCLUDED.ejemplo_uso,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tabla_datos (
    id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla, granularidad,
    criterio_inclusion, criterio_exclusion, ejemplo_uso, id_version_desde,
    estado, observaciones
)
SELECT
    e.id_esquema,
    'tabla_fuente',
    'Fuentes por tabla',
    'Tabla del esquema meta: fuentes por tabla.',
    'METADATA',
    'Una fila relaciona una fuente con un esquema, tabla, columna o registro.',
    'Fuentes que respaldan tablas o columnas.',
    'No almacena los datos originales descargados.',
    'UNESCO respalda turismo.patrimonio_turistico.',
    v.id_version,
    'ACTIVA',
    'Tabla documentada para que usuarios externos comprendan qué datos contiene y cuándo debe usarse.'
FROM meta.esquema_datos e
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'meta'
ON CONFLICT (id_esquema, nombre_tabla) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    tipo_tabla = EXCLUDED.tipo_tabla,
    granularidad = EXCLUDED.granularidad,
    criterio_inclusion = EXCLUDED.criterio_inclusion,
    criterio_exclusion = EXCLUDED.criterio_exclusion,
    ejemplo_uso = EXCLUDED.ejemplo_uso,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tabla_datos (
    id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla, granularidad,
    criterio_inclusion, criterio_exclusion, ejemplo_uso, id_version_desde,
    estado, observaciones
)
SELECT
    e.id_esquema,
    'regla_calidad',
    'Reglas de calidad',
    'Tabla del esquema meta: reglas de calidad.',
    'METADATA',
    'Una fila representa una regla de calidad aplicable a una tabla o columna.',
    'Validaciones esperadas para datos, fuentes, formatos o relaciones.',
    'No almacena resultados de ejecución si no se define un proceso separado.',
    'Todo destino debe tener fuente principal.',
    v.id_version,
    'ACTIVA',
    'Tabla documentada para que usuarios externos comprendan qué datos contiene y cuándo debe usarse.'
FROM meta.esquema_datos e
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'meta'
ON CONFLICT (id_esquema, nombre_tabla) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    tipo_tabla = EXCLUDED.tipo_tabla,
    granularidad = EXCLUDED.granularidad,
    criterio_inclusion = EXCLUDED.criterio_inclusion,
    criterio_exclusion = EXCLUDED.criterio_exclusion,
    ejemplo_uso = EXCLUDED.ejemplo_uso,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tabla_datos (
    id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla, granularidad,
    criterio_inclusion, criterio_exclusion, ejemplo_uso, id_version_desde,
    estado, observaciones
)
SELECT
    e.id_esquema,
    'revision_pares',
    'Revisión por pares',
    'Tabla del esquema meta: revisión por pares.',
    'METADATA',
    'Una fila representa una revisión de calidad por dos personas.',
    'Revisiones de esquemas, tablas, columnas, fuentes o reglas.',
    'No reemplaza evidencias de Git, pero las complementa.',
    'Revisión de turismo.destino_turistico.',
    v.id_version,
    'ACTIVA',
    'Tabla documentada para que usuarios externos comprendan qué datos contiene y cuándo debe usarse.'
FROM meta.esquema_datos e
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'meta'
ON CONFLICT (id_esquema, nombre_tabla) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    tipo_tabla = EXCLUDED.tipo_tabla,
    granularidad = EXCLUDED.granularidad,
    criterio_inclusion = EXCLUDED.criterio_inclusion,
    criterio_exclusion = EXCLUDED.criterio_exclusion,
    ejemplo_uso = EXCLUDED.ejemplo_uso,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tabla_datos (
    id_esquema, nombre_tabla, titulo, descripcion, tipo_tabla, granularidad,
    criterio_inclusion, criterio_exclusion, ejemplo_uso, id_version_desde,
    estado, observaciones
)
SELECT
    e.id_esquema,
    'decision_modelado',
    'Decisiones de modelado',
    'Tabla del esquema meta: decisiones de modelado.',
    'METADATA',
    'Una fila documenta una decisión sobre ubicación o tratamiento de datos.',
    'Criterios para decidir dónde se agregan nuevos datos.',
    'No almacena datos del dominio; almacena criterios.',
    'Festividades en turismo o cultura.',
    v.id_version,
    'ACTIVA',
    'Tabla documentada para que usuarios externos comprendan qué datos contiene y cuándo debe usarse.'
FROM meta.esquema_datos e
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'meta'
ON CONFLICT (id_esquema, nombre_tabla) DO UPDATE SET
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    tipo_tabla = EXCLUDED.tipo_tabla,
    granularidad = EXCLUDED.granularidad,
    criterio_inclusion = EXCLUDED.criterio_inclusion,
    criterio_exclusion = EXCLUDED.criterio_exclusion,
    ejemplo_uso = EXCLUDED.ejemplo_uso,
    id_version_desde = EXCLUDED.id_version_desde,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;

-- ============================================================
-- Diccionario de columnas de turismo
-- ============================================================


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'id_fuente',
    'INT',
    'Identificador unico de la fuente turistica dentro del esquema turismo.',
    TRUE,
    TRUE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Identificador técnico del registro.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'fuente_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'codigo',
    'VARCHAR(80)',
    'Codigo estable de la fuente para usar en migraciones, ETL y trazabilidad.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    'UNESCO_TIKAL',
    'Debe ser estable, legible y no duplicarse dentro de su tabla.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'fuente_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'nombre',
    'VARCHAR(220)',
    'Nombre oficial o descriptivo de la fuente consultada.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    'UNESCO World Heritage Centre - Tikal National Park',
    'Campo obligatorio para que el registro sea válido.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'fuente_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'institucion',
    'VARCHAR(180)',
    'Institucion, organismo o portal responsable de la fuente.',
    FALSE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo opcional; registrar solo si existe respaldo en la fuente.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'fuente_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'tipo',
    'VARCHAR(80)',
    'Tipo de fuente: oficial, internacional, cultural, conservacion, turismo u otro.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo obligatorio para que el registro sea válido.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'fuente_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'url',
    'VARCHAR(700)',
    'URL principal consultada.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo obligatorio para que el registro sea válido.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'fuente_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'fecha_consulta',
    'DATE',
    'Fecha de consulta de la fuente.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo obligatorio para que el registro sea válido.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'fuente_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'descripcion',
    'TEXT',
    'Descripcion del uso de la fuente dentro del modelo turismo.',
    FALSE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo opcional; registrar solo si existe respaldo en la fuente.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'fuente_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'id_region',
    'INT',
    'Identificador unico de la region turistica.',
    TRUE,
    TRUE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Identificador técnico del registro.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'region_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'codigo',
    'VARCHAR(50)',
    'Codigo estable de la region turistica.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Debe ser estable, legible y no duplicarse dentro de su tabla.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'region_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'nombre',
    'VARCHAR(150)',
    'Nombre de la region turistica.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    'Petén Aventura en el Mundo Maya',
    'Campo obligatorio para que el registro sea válido.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'region_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'descripcion',
    'TEXT',
    'Descripcion general de la region turistica.',
    FALSE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo opcional; registrar solo si existe respaldo en la fuente.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'region_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'fuente_id',
    'INT',
    'Fuente documental principal que respalda la definicion de la region.',
    FALSE,
    FALSE,
    TRUE,
    'turismo.fuente_turistica',
    'id_fuente',
    NULL,
    NULL,
    'Debe referenciar un registro existente cuando sea llave foránea.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'region_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'id_departamento_region',
    'INT',
    'Identificador unico de la relacion departamento-region turistica.',
    TRUE,
    TRUE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Identificador técnico del registro.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'departamento_region_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'region_turistica_id',
    'INT',
    'Region turistica a la que se asocia el departamento.',
    TRUE,
    FALSE,
    TRUE,
    'turismo.region_turistica',
    'id_region',
    NULL,
    NULL,
    'Debe referenciar un registro existente cuando sea llave foránea.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'departamento_region_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'departamento_id',
    'INT',
    'Departamento oficial registrado en geografia.departamento.',
    TRUE,
    FALSE,
    TRUE,
    'geografia.departamento',
    'id',
    NULL,
    NULL,
    'Debe referenciar un registro existente cuando sea llave foránea.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'departamento_region_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'observacion',
    'VARCHAR(400)',
    'Nota para casos donde un departamento participa parcialmente en mas de una region turistica.',
    FALSE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo opcional; registrar solo si existe respaldo en la fuente.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'departamento_region_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'id_categoria',
    'INT',
    'Identificador unico de la categoria turistica.',
    TRUE,
    TRUE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Identificador técnico del registro.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'categoria_destino'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'codigo',
    'VARCHAR(60)',
    'Codigo estable de la categoria.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Debe ser estable, legible y no duplicarse dentro de su tabla.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'categoria_destino'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'nombre',
    'VARCHAR(120)',
    'Nombre de la categoria.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    'Arqueológico',
    'Campo obligatorio para que el registro sea válido.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'categoria_destino'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'descripcion',
    'TEXT',
    'Descripcion de la categoria y criterio de uso.',
    FALSE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo opcional; registrar solo si existe respaldo en la fuente.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'categoria_destino'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'id_actividad',
    'INT',
    'Identificador unico de la actividad turistica.',
    TRUE,
    TRUE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Identificador técnico del registro.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'actividad_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'codigo',
    'VARCHAR(60)',
    'Codigo estable de la actividad.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Debe ser estable, legible y no duplicarse dentro de su tabla.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'actividad_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'nombre',
    'VARCHAR(140)',
    'Nombre de la actividad turistica.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    'Recorrido guiado',
    'Campo obligatorio para que el registro sea válido.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'actividad_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'descripcion',
    'TEXT',
    'Descripcion de la actividad y su uso analitico.',
    FALSE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo opcional; registrar solo si existe respaldo en la fuente.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'actividad_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'id_temporada',
    'INT',
    'Identificador unico de la temporada turistica.',
    TRUE,
    TRUE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Identificador técnico del registro.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'temporada_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'codigo',
    'VARCHAR(60)',
    'Codigo estable de la temporada.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Debe ser estable, legible y no duplicarse dentro de su tabla.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'temporada_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'nombre',
    'VARCHAR(120)',
    'Nombre de la temporada.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    'Temporada seca',
    'Campo obligatorio para que el registro sea válido.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'temporada_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'meses',
    'VARCHAR(120)',
    'Meses o periodo del anio asociado a la temporada.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo obligatorio para que el registro sea válido.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'temporada_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'descripcion',
    'TEXT',
    'Descripcion de condiciones o recomendaciones generales de la temporada.',
    FALSE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo opcional; registrar solo si existe respaldo en la fuente.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'temporada_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'id_destino',
    'INT',
    'Identificador unico del destino turistico.',
    TRUE,
    TRUE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Identificador técnico del registro.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_turistico'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'codigo',
    'VARCHAR(80)',
    'Codigo estable del destino turistico para migraciones y ETL.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    'PARQUE_NACIONAL_TIKAL',
    'Debe ser estable, legible y no duplicarse dentro de su tabla.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_turistico'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'nombre',
    'VARCHAR(220)',
    'Nombre del destino turistico.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    'Parque Nacional Tikal',
    'Campo obligatorio para que el registro sea válido.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_turistico'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'tipo',
    'turismo.tipo_destino',
    'Tipo general del destino turistico.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    'NATURAL, CULTURAL, ARQUEOLOGICO, URBANO, RELIGIOSO, RECREATIVO, MIXTO',
    'ARQUEOLOGICO',
    'Campo obligatorio para que el registro sea válido.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_turistico'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'departamento_id',
    'INT',
    'Departamento oficial donde se ubica el destino, referenciado desde geografia.departamento.',
    TRUE,
    FALSE,
    TRUE,
    'geografia.departamento',
    'id',
    NULL,
    NULL,
    'Debe referenciar un registro existente cuando sea llave foránea.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_turistico'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'municipio_id',
    'INT',
    'Municipio oficial donde se ubica el destino, referenciado desde geografia.municipio cuando se conoce.',
    FALSE,
    FALSE,
    TRUE,
    'geografia.municipio',
    'id',
    NULL,
    NULL,
    'Debe referenciar un registro existente cuando sea llave foránea.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_turistico'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'region_turistica_id',
    'INT',
    'Region turistica principal asociada al destino. Se usa para evitar ambiguedad en departamentos que participan parcialmente en mas de una region turistica.',
    FALSE,
    FALSE,
    TRUE,
    'turismo.region_turistica',
    'id_region',
    NULL,
    NULL,
    'Debe referenciar un registro existente cuando sea llave foránea.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_turistico'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'descripcion',
    'TEXT',
    'Descripcion documentada del destino turistico.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo obligatorio para que el registro sea válido.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_turistico'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'direccion_referencia',
    'VARCHAR(500)',
    'Referencia textual de ubicacion, acceso o zona del destino.',
    FALSE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo opcional; registrar solo si existe respaldo en la fuente.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_turistico'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'latitud',
    'NUMERIC(10, 7)',
    'Latitud aproximada del destino turistico.',
    FALSE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo opcional; registrar solo si existe respaldo en la fuente.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_turistico'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'longitud',
    'NUMERIC(10, 7)',
    'Longitud aproximada del destino turistico.',
    FALSE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo opcional; registrar solo si existe respaldo en la fuente.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_turistico'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'altitud_msnm',
    'INT',
    'Altitud aproximada sobre el nivel del mar, cuando se conoce.',
    FALSE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo opcional; registrar solo si existe respaldo en la fuente.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_turistico'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'dificultad',
    'turismo.dificultad_destino',
    'Nivel de dificultad general para visitar el destino.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    'BAJA, MEDIA, ALTA, VARIABLE',
    NULL,
    'Campo obligatorio para que el registro sea válido.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_turistico'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'tiempo_recomendado',
    'VARCHAR(120)',
    'Tiempo recomendado de visita.',
    FALSE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo opcional; registrar solo si existe respaldo en la fuente.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_turistico'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'costo_aprox_nacional_q',
    'NUMERIC(10, 2)',
    'Costo aproximado para visitante nacional, en quetzales, cuando existe dato publico.',
    FALSE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo opcional; registrar solo si existe respaldo en la fuente.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_turistico'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'costo_aprox_extranjero_q',
    'NUMERIC(10, 2)',
    'Costo aproximado para visitante extranjero, en quetzales, cuando existe dato publico.',
    FALSE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo opcional; registrar solo si existe respaldo en la fuente.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_turistico'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'horario',
    'VARCHAR(250)',
    'Horario de visita o atencion cuando se tiene publicado.',
    FALSE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo opcional; registrar solo si existe respaldo en la fuente.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_turistico'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'es_area_protegida',
    'BOOLEAN',
    'Indica si el destino pertenece o se relaciona con un area protegida.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    'TRUE, FALSE',
    NULL,
    'Campo obligatorio para que el registro sea válido.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_turistico'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'fuente_principal_id',
    'INT',
    'Fuente turistica principal usada para documentar el destino.',
    FALSE,
    FALSE,
    TRUE,
    'turismo.fuente_turistica',
    'id_fuente',
    NULL,
    NULL,
    'Debe referenciar un registro existente cuando sea llave foránea.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_turistico'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'activo',
    'BOOLEAN',
    'Indica si el destino se mantiene activo para consulta.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    'TRUE, FALSE',
    NULL,
    'Campo obligatorio para que el registro sea válido.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_turistico'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'destino_id',
    'INT',
    'Destino turistico clasificado.',
    TRUE,
    TRUE,
    TRUE,
    'turismo.destino_turistico',
    'id_destino',
    NULL,
    NULL,
    'Debe referenciar un registro existente cuando sea llave foránea.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_categoria'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'categoria_id',
    'INT',
    'Categoria asignada al destino.',
    TRUE,
    TRUE,
    TRUE,
    'turismo.categoria_destino',
    'id_categoria',
    NULL,
    NULL,
    'Debe referenciar un registro existente cuando sea llave foránea.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_categoria'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'destino_id',
    'INT',
    'Destino turistico asociado a la actividad.',
    TRUE,
    TRUE,
    TRUE,
    'turismo.destino_turistico',
    'id_destino',
    NULL,
    NULL,
    'Debe referenciar un registro existente cuando sea llave foránea.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_actividad'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'actividad_id',
    'INT',
    'Actividad turistica disponible o recomendada.',
    TRUE,
    TRUE,
    TRUE,
    'turismo.actividad_turistica',
    'id_actividad',
    NULL,
    NULL,
    'Debe referenciar un registro existente cuando sea llave foránea.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_actividad'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'notas',
    'VARCHAR(500)',
    'Notas sobre alcance o condiciones de la actividad en el destino.',
    FALSE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo opcional; registrar solo si existe respaldo en la fuente.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_actividad'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'destino_id',
    'INT',
    'Destino turistico asociado a la temporada.',
    TRUE,
    TRUE,
    TRUE,
    'turismo.destino_turistico',
    'id_destino',
    NULL,
    NULL,
    'Debe referenciar un registro existente cuando sea llave foránea.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_temporada'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'temporada_id',
    'INT',
    'Temporada recomendada o relevante.',
    TRUE,
    TRUE,
    TRUE,
    'turismo.temporada_turistica',
    'id_temporada',
    NULL,
    NULL,
    'Debe referenciar un registro existente cuando sea llave foránea.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_temporada'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'recomendacion',
    'VARCHAR(600)',
    'Recomendacion especifica para visitar el destino en la temporada indicada.',
    FALSE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo opcional; registrar solo si existe respaldo en la fuente.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_temporada'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'destino_id',
    'INT',
    'Destino turistico documentado.',
    TRUE,
    TRUE,
    TRUE,
    'turismo.destino_turistico',
    'id_destino',
    NULL,
    NULL,
    'Debe referenciar un registro existente cuando sea llave foránea.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_fuente'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'fuente_id',
    'INT',
    'Fuente turistica relacionada con el destino.',
    TRUE,
    TRUE,
    TRUE,
    'turismo.fuente_turistica',
    'id_fuente',
    NULL,
    NULL,
    'Debe referenciar un registro existente cuando sea llave foránea.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_fuente'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'detalle',
    'VARCHAR(600)',
    'Detalle sobre el uso de la fuente para el destino.',
    FALSE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo opcional; registrar solo si existe respaldo en la fuente.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_fuente'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'id_patrimonio',
    'INT',
    'Identificador unico del patrimonio turistico.',
    TRUE,
    TRUE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Identificador técnico del registro.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'patrimonio_turistico'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'codigo',
    'VARCHAR(80)',
    'Codigo estable del patrimonio.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    'UNESCO_TIKAL',
    'Debe ser estable, legible y no duplicarse dentro de su tabla.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'patrimonio_turistico'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'tipo',
    'turismo.tipo_patrimonio',
    'Tipo de reconocimiento patrimonial.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    'UNESCO_CULTURAL, UNESCO_NATURAL, UNESCO_MIXTO, UNESCO_INTANGIBLE, NACIONAL',
    NULL,
    'Campo obligatorio para que el registro sea válido.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'patrimonio_turistico'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'nombre',
    'VARCHAR(220)',
    'Nombre del patrimonio o expresion cultural.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo obligatorio para que el registro sea válido.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'patrimonio_turistico'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'organismo',
    'VARCHAR(160)',
    'Organismo que reconoce o respalda el patrimonio.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo obligatorio para que el registro sea válido.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'patrimonio_turistico'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'anio_inscripcion',
    'INT',
    'Anio de inscripcion o reconocimiento, cuando aplica.',
    FALSE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo opcional; registrar solo si existe respaldo en la fuente.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'patrimonio_turistico'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'descripcion',
    'TEXT',
    'Descripcion resumida del valor patrimonial.',
    FALSE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo opcional; registrar solo si existe respaldo en la fuente.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'patrimonio_turistico'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'fuente_id',
    'INT',
    'Fuente principal que respalda el patrimonio.',
    FALSE,
    FALSE,
    TRUE,
    'turismo.fuente_turistica',
    'id_fuente',
    NULL,
    NULL,
    'Debe referenciar un registro existente cuando sea llave foránea.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'patrimonio_turistico'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'destino_id',
    'INT',
    'Destino turistico asociado al patrimonio.',
    TRUE,
    TRUE,
    TRUE,
    'turismo.destino_turistico',
    'id_destino',
    NULL,
    NULL,
    'Debe referenciar un registro existente cuando sea llave foránea.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_patrimonio'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'patrimonio_id',
    'INT',
    'Patrimonio asociado al destino.',
    TRUE,
    TRUE,
    TRUE,
    'turismo.patrimonio_turistico',
    'id_patrimonio',
    NULL,
    NULL,
    'Debe referenciar un registro existente cuando sea llave foránea.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_patrimonio'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'observacion',
    'VARCHAR(600)',
    'Observacion de la relacion entre destino y patrimonio.',
    FALSE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo opcional; registrar solo si existe respaldo en la fuente.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'destino_patrimonio'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'id_ruta',
    'INT',
    'Identificador unico de la ruta turistica.',
    TRUE,
    TRUE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Identificador técnico del registro.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'ruta_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'codigo',
    'VARCHAR(80)',
    'Codigo estable de la ruta.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    'RUTA_PATRIMONIO_UNESCO',
    'Debe ser estable, legible y no duplicarse dentro de su tabla.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'ruta_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'nombre',
    'VARCHAR(180)',
    'Nombre de la ruta turistica.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo obligatorio para que el registro sea válido.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'ruta_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'region_id',
    'INT',
    'Region turistica principal asociada a la ruta.',
    FALSE,
    FALSE,
    TRUE,
    'turismo.region_turistica',
    'id_region',
    NULL,
    NULL,
    'Debe referenciar un registro existente cuando sea llave foránea.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'ruta_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'descripcion',
    'TEXT',
    'Descripcion general de la ruta.',
    FALSE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo opcional; registrar solo si existe respaldo en la fuente.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'ruta_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'duracion_dias',
    'INT',
    'Duracion sugerida de la ruta en dias.',
    FALSE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo opcional; registrar solo si existe respaldo en la fuente.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'ruta_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'fuente_id',
    'INT',
    'Fuente principal usada para documentar la ruta.',
    FALSE,
    FALSE,
    TRUE,
    'turismo.fuente_turistica',
    'id_fuente',
    NULL,
    NULL,
    'Debe referenciar un registro existente cuando sea llave foránea.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'ruta_turistica'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'ruta_id',
    'INT',
    'Ruta turistica que contiene el destino.',
    TRUE,
    TRUE,
    TRUE,
    'turismo.ruta_turistica',
    'id_ruta',
    NULL,
    NULL,
    'Debe referenciar un registro existente cuando sea llave foránea.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'ruta_destino'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'destino_id',
    'INT',
    'Destino incluido en la ruta.',
    TRUE,
    TRUE,
    TRUE,
    'turismo.destino_turistico',
    'id_destino',
    NULL,
    NULL,
    'Debe referenciar un registro existente cuando sea llave foránea.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'ruta_destino'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'orden_visita',
    'INT',
    'Orden sugerido de visita dentro de la ruta.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo obligatorio para que el registro sea válido.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'ruta_destino'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'tiempo_sugerido',
    'VARCHAR(120)',
    'Tiempo sugerido para visitar el destino dentro de la ruta.',
    FALSE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo opcional; registrar solo si existe respaldo en la fuente.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'ruta_destino'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'id_recomendacion',
    'INT',
    'Identificador unico de la recomendacion.',
    TRUE,
    TRUE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Identificador técnico del registro.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'recomendacion_destino'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'destino_id',
    'INT',
    'Destino al que aplica la recomendacion.',
    TRUE,
    FALSE,
    TRUE,
    'turismo.destino_turistico',
    'id_destino',
    NULL,
    NULL,
    'Debe referenciar un registro existente cuando sea llave foránea.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'recomendacion_destino'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'tipo',
    'turismo.tipo_recomendacion',
    'Tipo de recomendacion.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    'SEGURIDAD, AMBIENTAL, CULTURAL, LOGISTICA, TEMPORADA',
    'SEGURIDAD',
    'Campo obligatorio para que el registro sea válido.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'recomendacion_destino'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.columna_datos (
    id_tabla, nombre_columna, tipo_dato, descripcion, obligatorio,
    es_llave_primaria, es_llave_foranea, tabla_referenciada, columna_referenciada,
    valores_permitidos, ejemplo_valor, regla_validacion, id_version_desde,
    observaciones
)
SELECT
    t.id_tabla,
    'recomendacion',
    'VARCHAR(800)',
    'Texto de la recomendacion.',
    TRUE,
    FALSE,
    FALSE,
    NULL,
    NULL,
    NULL,
    NULL,
    'Campo obligatorio para que el registro sea válido.',
    v.id_version,
    'Columna documentada para consulta del diccionario de datos.'
FROM meta.tabla_datos t
JOIN meta.esquema_datos e ON e.id_esquema = t.id_esquema
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND t.nombre_tabla = 'recomendacion_destino'
ON CONFLICT (id_tabla, nombre_columna) DO UPDATE SET
    tipo_dato = EXCLUDED.tipo_dato,
    descripcion = EXCLUDED.descripcion,
    obligatorio = EXCLUDED.obligatorio,
    es_llave_primaria = EXCLUDED.es_llave_primaria,
    es_llave_foranea = EXCLUDED.es_llave_foranea,
    tabla_referenciada = EXCLUDED.tabla_referenciada,
    columna_referenciada = EXCLUDED.columna_referenciada,
    valores_permitidos = EXCLUDED.valores_permitidos,
    ejemplo_valor = EXCLUDED.ejemplo_valor,
    regla_validacion = EXCLUDED.regla_validacion,
    id_version_desde = EXCLUDED.id_version_desde,
    observaciones = EXCLUDED.observaciones;


-- ============================================================
-- 8. Temas de búsqueda del catálogo
-- ============================================================


INSERT INTO meta.tema_datos (nombre_tema, descripcion, palabras_clave, estado, observaciones)
VALUES ('Turismo', 'Datos relacionados con destinos, rutas, regiones, actividades, temporadas y recomendaciones para visitantes.', 'turismo, destino, viaje, ruta, visitante, atractivo, actividad turística', 'ACTIVO', 'Tema utilizado para ubicar objetos de datos y decidir si un nuevo conjunto de datos ya encaja en el modelo.')
ON CONFLICT (nombre_tema) DO UPDATE SET
    descripcion = EXCLUDED.descripcion,
    palabras_clave = EXCLUDED.palabras_clave,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tema_datos (nombre_tema, descripcion, palabras_clave, estado, observaciones)
VALUES ('Patrimonio', 'Datos relacionados con bienes o destinos con reconocimiento patrimonial nacional o internacional.', 'patrimonio, UNESCO, cultural, natural, intangible, reconocimiento', 'ACTIVO', 'Tema utilizado para ubicar objetos de datos y decidir si un nuevo conjunto de datos ya encaja en el modelo.')
ON CONFLICT (nombre_tema) DO UPDATE SET
    descripcion = EXCLUDED.descripcion,
    palabras_clave = EXCLUDED.palabras_clave,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tema_datos (nombre_tema, descripcion, palabras_clave, estado, observaciones)
VALUES ('Geografía', 'Datos territoriales base del proyecto.', 'país, departamento, municipio, pcode, territorio, ubicación', 'ACTIVO', 'Tema utilizado para ubicar objetos de datos y decidir si un nuevo conjunto de datos ya encaja en el modelo.')
ON CONFLICT (nombre_tema) DO UPDATE SET
    descripcion = EXCLUDED.descripcion,
    palabras_clave = EXCLUDED.palabras_clave,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tema_datos (nombre_tema, descripcion, palabras_clave, estado, observaciones)
VALUES ('Fuentes', 'Datos relacionados con el origen, respaldo y trazabilidad documental.', 'fuente, URL, institución, consulta, respaldo, trazabilidad', 'ACTIVO', 'Tema utilizado para ubicar objetos de datos y decidir si un nuevo conjunto de datos ya encaja en el modelo.')
ON CONFLICT (nombre_tema) DO UPDATE SET
    descripcion = EXCLUDED.descripcion,
    palabras_clave = EXCLUDED.palabras_clave,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tema_datos (nombre_tema, descripcion, palabras_clave, estado, observaciones)
VALUES ('Regiones turísticas', 'Agrupaciones territoriales usadas para organizar destinos turísticos.', 'región turística, altiplano, petén, pacífico, oriente, verapaces', 'ACTIVO', 'Tema utilizado para ubicar objetos de datos y decidir si un nuevo conjunto de datos ya encaja en el modelo.')
ON CONFLICT (nombre_tema) DO UPDATE SET
    descripcion = EXCLUDED.descripcion,
    palabras_clave = EXCLUDED.palabras_clave,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tema_datos (nombre_tema, descripcion, palabras_clave, estado, observaciones)
VALUES ('Actividades turísticas', 'Actividades que un visitante puede realizar en un destino.', 'senderismo, fotografía, recorrido, observación, visita guiada', 'ACTIVO', 'Tema utilizado para ubicar objetos de datos y decidir si un nuevo conjunto de datos ya encaja en el modelo.')
ON CONFLICT (nombre_tema) DO UPDATE SET
    descripcion = EXCLUDED.descripcion,
    palabras_clave = EXCLUDED.palabras_clave,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tema_datos (nombre_tema, descripcion, palabras_clave, estado, observaciones)
VALUES ('Rutas turísticas', 'Agrupaciones ordenadas de destinos para recorridos turísticos.', 'ruta, recorrido, orden de visita, itinerario', 'ACTIVO', 'Tema utilizado para ubicar objetos de datos y decidir si un nuevo conjunto de datos ya encaja en el modelo.')
ON CONFLICT (nombre_tema) DO UPDATE SET
    descripcion = EXCLUDED.descripcion,
    palabras_clave = EXCLUDED.palabras_clave,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tema_datos (nombre_tema, descripcion, palabras_clave, estado, observaciones)
VALUES ('Festividades', 'Eventos o celebraciones que pueden ser turísticas o culturales según su enfoque.', 'festividad, evento, feria, celebración, semana santa, festival', 'ACTIVO', 'Tema utilizado para ubicar objetos de datos y decidir si un nuevo conjunto de datos ya encaja en el modelo.')
ON CONFLICT (nombre_tema) DO UPDATE SET
    descripcion = EXCLUDED.descripcion,
    palabras_clave = EXCLUDED.palabras_clave,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tema_datos (nombre_tema, descripcion, palabras_clave, estado, observaciones)
VALUES ('Deportes', 'Actividades deportivas competitivas o recreativas que podrían requerir un esquema propio.', 'deporte, fútbol, torneo, liga, estadio, competencia, atletismo', 'ACTIVO', 'Tema utilizado para ubicar objetos de datos y decidir si un nuevo conjunto de datos ya encaja en el modelo.')
ON CONFLICT (nombre_tema) DO UPDATE SET
    descripcion = EXCLUDED.descripcion,
    palabras_clave = EXCLUDED.palabras_clave,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.tema_datos (nombre_tema, descripcion, palabras_clave, estado, observaciones)
VALUES ('Cultura', 'Datos relacionados con tradiciones, manifestaciones, museos y expresiones culturales.', 'cultura, tradición, museo, religión, manifestación cultural', 'ACTIVO', 'Tema utilizado para ubicar objetos de datos y decidir si un nuevo conjunto de datos ya encaja en el modelo.')
ON CONFLICT (nombre_tema) DO UPDATE SET
    descripcion = EXCLUDED.descripcion,
    palabras_clave = EXCLUDED.palabras_clave,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


-- ============================================================
-- 9. Relación entre temas y objetos
-- ============================================================


INSERT INTO meta.objeto_tema (
    id_tema, nivel_objeto, id_esquema, id_tabla, id_columna,
    relevancia, justificacion, ejemplo_relacion
)
SELECT
    tm.id_tema,
    'ESQUEMA',
    e.id_esquema,
    NULL,
    NULL,
    'ALTA',
    'El esquema turismo concentra destinos, regiones, rutas, actividades, patrimonio y recomendaciones turísticas.',
    'Buscar turismo muestra el esquema turismo.'
FROM meta.tema_datos tm
JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'


WHERE tm.nombre_tema = 'Turismo'
  AND NOT EXISTS (
      SELECT 1 FROM meta.objeto_tema ot
      WHERE ot.id_tema = tm.id_tema
        AND ot.nivel_objeto = 'ESQUEMA'
        AND COALESCE(ot.id_esquema, -1) = COALESCE(e.id_esquema, -1)
        AND COALESCE(ot.id_tabla, -1) = COALESCE(NULL, -1)
        AND COALESCE(ot.id_columna, -1) = COALESCE(NULL, -1)
  );


INSERT INTO meta.objeto_tema (
    id_tema, nivel_objeto, id_esquema, id_tabla, id_columna,
    relevancia, justificacion, ejemplo_relacion
)
SELECT
    tm.id_tema,
    'ESQUEMA',
    e.id_esquema,
    NULL,
    NULL,
    'ALTA',
    'Geografía es base territorial para ubicar datos de turismo y otros módulos.',
    'Turismo referencia departamentos y municipios de geografía.'
FROM meta.tema_datos tm
JOIN meta.esquema_datos e ON e.nombre_esquema = 'geografia'


WHERE tm.nombre_tema = 'Geografía'
  AND NOT EXISTS (
      SELECT 1 FROM meta.objeto_tema ot
      WHERE ot.id_tema = tm.id_tema
        AND ot.nivel_objeto = 'ESQUEMA'
        AND COALESCE(ot.id_esquema, -1) = COALESCE(e.id_esquema, -1)
        AND COALESCE(ot.id_tabla, -1) = COALESCE(NULL, -1)
        AND COALESCE(ot.id_columna, -1) = COALESCE(NULL, -1)
  );


INSERT INTO meta.objeto_tema (
    id_tema, nivel_objeto, id_esquema, id_tabla, id_columna,
    relevancia, justificacion, ejemplo_relacion
)
SELECT
    tm.id_tema,
    'TABLA',
    e.id_esquema,
    td.id_tabla,
    NULL,
    'ALTA',
    'Tabla central del módulo Turismo; almacena destinos turísticos específicos.',
    'Antigua Guatemala se ubica aquí como destino.'
FROM meta.tema_datos tm
JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'
JOIN meta.tabla_datos td ON td.id_esquema = e.id_esquema AND td.nombre_tabla = 'destino_turistico'

WHERE tm.nombre_tema = 'Turismo'
  AND NOT EXISTS (
      SELECT 1 FROM meta.objeto_tema ot
      WHERE ot.id_tema = tm.id_tema
        AND ot.nivel_objeto = 'TABLA'
        AND COALESCE(ot.id_esquema, -1) = COALESCE(e.id_esquema, -1)
        AND COALESCE(ot.id_tabla, -1) = COALESCE(td.id_tabla, -1)
        AND COALESCE(ot.id_columna, -1) = COALESCE(NULL, -1)
  );


INSERT INTO meta.objeto_tema (
    id_tema, nivel_objeto, id_esquema, id_tabla, id_columna,
    relevancia, justificacion, ejemplo_relacion
)
SELECT
    tm.id_tema,
    'TABLA',
    e.id_esquema,
    td.id_tabla,
    NULL,
    'ALTA',
    'Tabla que registra reconocimientos patrimoniales relacionados con turismo.',
    'UNESCO_TIKAL.'
FROM meta.tema_datos tm
JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'
JOIN meta.tabla_datos td ON td.id_esquema = e.id_esquema AND td.nombre_tabla = 'patrimonio_turistico'

WHERE tm.nombre_tema = 'Patrimonio'
  AND NOT EXISTS (
      SELECT 1 FROM meta.objeto_tema ot
      WHERE ot.id_tema = tm.id_tema
        AND ot.nivel_objeto = 'TABLA'
        AND COALESCE(ot.id_esquema, -1) = COALESCE(e.id_esquema, -1)
        AND COALESCE(ot.id_tabla, -1) = COALESCE(td.id_tabla, -1)
        AND COALESCE(ot.id_columna, -1) = COALESCE(NULL, -1)
  );


INSERT INTO meta.objeto_tema (
    id_tema, nivel_objeto, id_esquema, id_tabla, id_columna,
    relevancia, justificacion, ejemplo_relacion
)
SELECT
    tm.id_tema,
    'TABLA',
    e.id_esquema,
    td.id_tabla,
    NULL,
    'ALTA',
    'Relaciona destinos con reconocimientos patrimoniales.',
    'Antigua Guatemala con Patrimonio Mundial.'
FROM meta.tema_datos tm
JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'
JOIN meta.tabla_datos td ON td.id_esquema = e.id_esquema AND td.nombre_tabla = 'destino_patrimonio'

WHERE tm.nombre_tema = 'Patrimonio'
  AND NOT EXISTS (
      SELECT 1 FROM meta.objeto_tema ot
      WHERE ot.id_tema = tm.id_tema
        AND ot.nivel_objeto = 'TABLA'
        AND COALESCE(ot.id_esquema, -1) = COALESCE(e.id_esquema, -1)
        AND COALESCE(ot.id_tabla, -1) = COALESCE(td.id_tabla, -1)
        AND COALESCE(ot.id_columna, -1) = COALESCE(NULL, -1)
  );


INSERT INTO meta.objeto_tema (
    id_tema, nivel_objeto, id_esquema, id_tabla, id_columna,
    relevancia, justificacion, ejemplo_relacion
)
SELECT
    tm.id_tema,
    'TABLA',
    e.id_esquema,
    td.id_tabla,
    NULL,
    'ALTA',
    'Registra fuentes documentales usadas por turismo.',
    'UNESCO, CONAP, GCB.'
FROM meta.tema_datos tm
JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'
JOIN meta.tabla_datos td ON td.id_esquema = e.id_esquema AND td.nombre_tabla = 'fuente_turistica'

WHERE tm.nombre_tema = 'Fuentes'
  AND NOT EXISTS (
      SELECT 1 FROM meta.objeto_tema ot
      WHERE ot.id_tema = tm.id_tema
        AND ot.nivel_objeto = 'TABLA'
        AND COALESCE(ot.id_esquema, -1) = COALESCE(e.id_esquema, -1)
        AND COALESCE(ot.id_tabla, -1) = COALESCE(td.id_tabla, -1)
        AND COALESCE(ot.id_columna, -1) = COALESCE(NULL, -1)
  );


INSERT INTO meta.objeto_tema (
    id_tema, nivel_objeto, id_esquema, id_tabla, id_columna,
    relevancia, justificacion, ejemplo_relacion
)
SELECT
    tm.id_tema,
    'TABLA',
    e.id_esquema,
    td.id_tabla,
    NULL,
    'ALTA',
    'Relaciona destinos con fuentes de respaldo.',
    'Tikal con UNESCO y SICultura.'
FROM meta.tema_datos tm
JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'
JOIN meta.tabla_datos td ON td.id_esquema = e.id_esquema AND td.nombre_tabla = 'destino_fuente'

WHERE tm.nombre_tema = 'Fuentes'
  AND NOT EXISTS (
      SELECT 1 FROM meta.objeto_tema ot
      WHERE ot.id_tema = tm.id_tema
        AND ot.nivel_objeto = 'TABLA'
        AND COALESCE(ot.id_esquema, -1) = COALESCE(e.id_esquema, -1)
        AND COALESCE(ot.id_tabla, -1) = COALESCE(td.id_tabla, -1)
        AND COALESCE(ot.id_columna, -1) = COALESCE(NULL, -1)
  );


INSERT INTO meta.objeto_tema (
    id_tema, nivel_objeto, id_esquema, id_tabla, id_columna,
    relevancia, justificacion, ejemplo_relacion
)
SELECT
    tm.id_tema,
    'TABLA',
    e.id_esquema,
    td.id_tabla,
    NULL,
    'ALTA',
    'Agrupa destinos por región turística.',
    'Petén Aventura en el Mundo Maya.'
FROM meta.tema_datos tm
JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'
JOIN meta.tabla_datos td ON td.id_esquema = e.id_esquema AND td.nombre_tabla = 'region_turistica'

WHERE tm.nombre_tema = 'Regiones turísticas'
  AND NOT EXISTS (
      SELECT 1 FROM meta.objeto_tema ot
      WHERE ot.id_tema = tm.id_tema
        AND ot.nivel_objeto = 'TABLA'
        AND COALESCE(ot.id_esquema, -1) = COALESCE(e.id_esquema, -1)
        AND COALESCE(ot.id_tabla, -1) = COALESCE(td.id_tabla, -1)
        AND COALESCE(ot.id_columna, -1) = COALESCE(NULL, -1)
  );


INSERT INTO meta.objeto_tema (
    id_tema, nivel_objeto, id_esquema, id_tabla, id_columna,
    relevancia, justificacion, ejemplo_relacion
)
SELECT
    tm.id_tema,
    'TABLA',
    e.id_esquema,
    td.id_tabla,
    NULL,
    'ALTA',
    'Catálogo de actividades que puede realizar un visitante.',
    'Senderismo, fotografía.'
FROM meta.tema_datos tm
JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'
JOIN meta.tabla_datos td ON td.id_esquema = e.id_esquema AND td.nombre_tabla = 'actividad_turistica'

WHERE tm.nombre_tema = 'Actividades turísticas'
  AND NOT EXISTS (
      SELECT 1 FROM meta.objeto_tema ot
      WHERE ot.id_tema = tm.id_tema
        AND ot.nivel_objeto = 'TABLA'
        AND COALESCE(ot.id_esquema, -1) = COALESCE(e.id_esquema, -1)
        AND COALESCE(ot.id_tabla, -1) = COALESCE(td.id_tabla, -1)
        AND COALESCE(ot.id_columna, -1) = COALESCE(NULL, -1)
  );


INSERT INTO meta.objeto_tema (
    id_tema, nivel_objeto, id_esquema, id_tabla, id_columna,
    relevancia, justificacion, ejemplo_relacion
)
SELECT
    tm.id_tema,
    'TABLA',
    e.id_esquema,
    td.id_tabla,
    NULL,
    'ALTA',
    'Relaciona actividades con destinos.',
    'Pacaya con senderismo.'
FROM meta.tema_datos tm
JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'
JOIN meta.tabla_datos td ON td.id_esquema = e.id_esquema AND td.nombre_tabla = 'destino_actividad'

WHERE tm.nombre_tema = 'Actividades turísticas'
  AND NOT EXISTS (
      SELECT 1 FROM meta.objeto_tema ot
      WHERE ot.id_tema = tm.id_tema
        AND ot.nivel_objeto = 'TABLA'
        AND COALESCE(ot.id_esquema, -1) = COALESCE(e.id_esquema, -1)
        AND COALESCE(ot.id_tabla, -1) = COALESCE(td.id_tabla, -1)
        AND COALESCE(ot.id_columna, -1) = COALESCE(NULL, -1)
  );


INSERT INTO meta.objeto_tema (
    id_tema, nivel_objeto, id_esquema, id_tabla, id_columna,
    relevancia, justificacion, ejemplo_relacion
)
SELECT
    tm.id_tema,
    'TABLA',
    e.id_esquema,
    td.id_tabla,
    NULL,
    'ALTA',
    'Define rutas turísticas sugeridas.',
    'Ruta Patrimonio UNESCO.'
FROM meta.tema_datos tm
JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'
JOIN meta.tabla_datos td ON td.id_esquema = e.id_esquema AND td.nombre_tabla = 'ruta_turistica'

WHERE tm.nombre_tema = 'Rutas turísticas'
  AND NOT EXISTS (
      SELECT 1 FROM meta.objeto_tema ot
      WHERE ot.id_tema = tm.id_tema
        AND ot.nivel_objeto = 'TABLA'
        AND COALESCE(ot.id_esquema, -1) = COALESCE(e.id_esquema, -1)
        AND COALESCE(ot.id_tabla, -1) = COALESCE(td.id_tabla, -1)
        AND COALESCE(ot.id_columna, -1) = COALESCE(NULL, -1)
  );


INSERT INTO meta.objeto_tema (
    id_tema, nivel_objeto, id_esquema, id_tabla, id_columna,
    relevancia, justificacion, ejemplo_relacion
)
SELECT
    tm.id_tema,
    'TABLA',
    e.id_esquema,
    td.id_tabla,
    NULL,
    'ALTA',
    'Define destinos incluidos en una ruta y su orden de visita.',
    'Tikal dentro de ruta UNESCO.'
FROM meta.tema_datos tm
JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'
JOIN meta.tabla_datos td ON td.id_esquema = e.id_esquema AND td.nombre_tabla = 'ruta_destino'

WHERE tm.nombre_tema = 'Rutas turísticas'
  AND NOT EXISTS (
      SELECT 1 FROM meta.objeto_tema ot
      WHERE ot.id_tema = tm.id_tema
        AND ot.nivel_objeto = 'TABLA'
        AND COALESCE(ot.id_esquema, -1) = COALESCE(e.id_esquema, -1)
        AND COALESCE(ot.id_tabla, -1) = COALESCE(td.id_tabla, -1)
        AND COALESCE(ot.id_columna, -1) = COALESCE(NULL, -1)
  );


INSERT INTO meta.objeto_tema (
    id_tema, nivel_objeto, id_esquema, id_tabla, id_columna,
    relevancia, justificacion, ejemplo_relacion
)
SELECT
    tm.id_tema,
    'ESQUEMA',
    e.id_esquema,
    NULL,
    NULL,
    'BAJA',
    'Turismo no almacena festividades como regla general; solo podrían incorporarse si se modelan como evento turístico futuro.',
    'Semana Santa como atractivo turístico requeriría una tabla evento_turistico.'
FROM meta.tema_datos tm
JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'


WHERE tm.nombre_tema = 'Festividades'
  AND NOT EXISTS (
      SELECT 1 FROM meta.objeto_tema ot
      WHERE ot.id_tema = tm.id_tema
        AND ot.nivel_objeto = 'ESQUEMA'
        AND COALESCE(ot.id_esquema, -1) = COALESCE(e.id_esquema, -1)
        AND COALESCE(ot.id_tabla, -1) = COALESCE(NULL, -1)
        AND COALESCE(ot.id_columna, -1) = COALESCE(NULL, -1)
  );


INSERT INTO meta.objeto_tema (
    id_tema, nivel_objeto, id_esquema, id_tabla, id_columna,
    relevancia, justificacion, ejemplo_relacion
)
SELECT
    tm.id_tema,
    'ESQUEMA',
    e.id_esquema,
    NULL,
    NULL,
    'BAJA',
    'El esquema turismo no cubre deportes competitivos; solo actividades turísticas como senderismo o montañismo.',
    'Fútbol o ligas deportivas deberían ir en un esquema deportes.'
FROM meta.tema_datos tm
JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'


WHERE tm.nombre_tema = 'Deportes'
  AND NOT EXISTS (
      SELECT 1 FROM meta.objeto_tema ot
      WHERE ot.id_tema = tm.id_tema
        AND ot.nivel_objeto = 'ESQUEMA'
        AND COALESCE(ot.id_esquema, -1) = COALESCE(e.id_esquema, -1)
        AND COALESCE(ot.id_tabla, -1) = COALESCE(NULL, -1)
        AND COALESCE(ot.id_columna, -1) = COALESCE(NULL, -1)
  );


INSERT INTO meta.objeto_tema (
    id_tema, nivel_objeto, id_esquema, id_tabla, id_columna,
    relevancia, justificacion, ejemplo_relacion
)
SELECT
    tm.id_tema,
    'TABLA',
    e.id_esquema,
    td.id_tabla,
    NULL,
    'MEDIA',
    'Algunas categorías turísticas pueden tener enfoque cultural, pero no reemplazan un esquema cultural completo.',
    'Categoría cultural o arqueológica.'
FROM meta.tema_datos tm
JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'
JOIN meta.tabla_datos td ON td.id_esquema = e.id_esquema AND td.nombre_tabla = 'categoria_destino'

WHERE tm.nombre_tema = 'Cultura'
  AND NOT EXISTS (
      SELECT 1 FROM meta.objeto_tema ot
      WHERE ot.id_tema = tm.id_tema
        AND ot.nivel_objeto = 'TABLA'
        AND COALESCE(ot.id_esquema, -1) = COALESCE(e.id_esquema, -1)
        AND COALESCE(ot.id_tabla, -1) = COALESCE(td.id_tabla, -1)
        AND COALESCE(ot.id_columna, -1) = COALESCE(NULL, -1)
  );


INSERT INTO meta.objeto_tema (
    id_tema, nivel_objeto, id_esquema, id_tabla, id_columna,
    relevancia, justificacion, ejemplo_relacion
)
SELECT
    tm.id_tema,
    'TABLA',
    e.id_esquema,
    td.id_tabla,
    NULL,
    'ALTA',
    'Los departamentos se usan como referencia territorial oficial para turismo.',
    'destino_turistico.departamento_id.'
FROM meta.tema_datos tm
JOIN meta.esquema_datos e ON e.nombre_esquema = 'geografia'
JOIN meta.tabla_datos td ON td.id_esquema = e.id_esquema AND td.nombre_tabla = 'departamento'

WHERE tm.nombre_tema = 'Geografía'
  AND NOT EXISTS (
      SELECT 1 FROM meta.objeto_tema ot
      WHERE ot.id_tema = tm.id_tema
        AND ot.nivel_objeto = 'TABLA'
        AND COALESCE(ot.id_esquema, -1) = COALESCE(e.id_esquema, -1)
        AND COALESCE(ot.id_tabla, -1) = COALESCE(td.id_tabla, -1)
        AND COALESCE(ot.id_columna, -1) = COALESCE(NULL, -1)
  );


INSERT INTO meta.objeto_tema (
    id_tema, nivel_objeto, id_esquema, id_tabla, id_columna,
    relevancia, justificacion, ejemplo_relacion
)
SELECT
    tm.id_tema,
    'TABLA',
    e.id_esquema,
    td.id_tabla,
    NULL,
    'ALTA',
    'Los municipios se usan para ubicar destinos turísticos sin duplicar geografía.',
    'destino_turistico.municipio_id.'
FROM meta.tema_datos tm
JOIN meta.esquema_datos e ON e.nombre_esquema = 'geografia'
JOIN meta.tabla_datos td ON td.id_esquema = e.id_esquema AND td.nombre_tabla = 'municipio'

WHERE tm.nombre_tema = 'Geografía'
  AND NOT EXISTS (
      SELECT 1 FROM meta.objeto_tema ot
      WHERE ot.id_tema = tm.id_tema
        AND ot.nivel_objeto = 'TABLA'
        AND COALESCE(ot.id_esquema, -1) = COALESCE(e.id_esquema, -1)
        AND COALESCE(ot.id_tabla, -1) = COALESCE(td.id_tabla, -1)
        AND COALESCE(ot.id_columna, -1) = COALESCE(NULL, -1)
  );


-- ============================================================
-- 10. Fuentes generales del proyecto
-- ============================================================


INSERT INTO meta.fuente_datos (
    codigo_fuente, nombre_fuente, institucion, tipo_fuente, url,
    fecha_consulta, descripcion, confiabilidad, cobertura_geografica,
    licencia_uso, estado, observaciones
)
VALUES (
    'GCB_REGIONES_GT', 'Guatemala Convention Bureau - Regiones de Guatemala', 'Guatemala Convention Bureau', 'INSTITUCIONAL', 'https://guatemalacvb.com/regiones-de-guatemala/',
    CURRENT_DATE, 'Fuente base para documentar las siete regiones turísticas de Guatemala.', 'ALTA', 'Guatemala',
    'Uso informativo institucional.', 'ACTIVA',
    'Fuente registrada para trazabilidad del módulo Turismo y Patrimonio.'
)
ON CONFLICT (codigo_fuente) DO UPDATE SET
    nombre_fuente = EXCLUDED.nombre_fuente,
    institucion = EXCLUDED.institucion,
    tipo_fuente = EXCLUDED.tipo_fuente,
    url = EXCLUDED.url,
    fecha_consulta = EXCLUDED.fecha_consulta,
    descripcion = EXCLUDED.descripcion,
    confiabilidad = EXCLUDED.confiabilidad,
    cobertura_geografica = EXCLUDED.cobertura_geografica,
    licencia_uso = EXCLUDED.licencia_uso,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.fuente_datos (
    codigo_fuente, nombre_fuente, institucion, tipo_fuente, url,
    fecha_consulta, descripcion, confiabilidad, cobertura_geografica,
    licencia_uso, estado, observaciones
)
VALUES (
    'INGUAT_GENERAL', 'Instituto Guatemalteco de Turismo - INGUAT', 'INGUAT', 'INSTITUCIONAL', 'https://inguat.gob.gt/',
    CURRENT_DATE, 'Fuente institucional general del turismo en Guatemala.', 'MEDIA', 'Guatemala',
    'Verificar disponibilidad de páginas específicas.', 'ACTIVA',
    'Fuente registrada para trazabilidad del módulo Turismo y Patrimonio.'
)
ON CONFLICT (codigo_fuente) DO UPDATE SET
    nombre_fuente = EXCLUDED.nombre_fuente,
    institucion = EXCLUDED.institucion,
    tipo_fuente = EXCLUDED.tipo_fuente,
    url = EXCLUDED.url,
    fecha_consulta = EXCLUDED.fecha_consulta,
    descripcion = EXCLUDED.descripcion,
    confiabilidad = EXCLUDED.confiabilidad,
    cobertura_geografica = EXCLUDED.cobertura_geografica,
    licencia_uso = EXCLUDED.licencia_uso,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.fuente_datos (
    codigo_fuente, nombre_fuente, institucion, tipo_fuente, url,
    fecha_consulta, descripcion, confiabilidad, cobertura_geografica,
    licencia_uso, estado, observaciones
)
VALUES (
    'UNESCO_GUATEMALA', 'UNESCO World Heritage Centre - Guatemala', 'UNESCO', 'INTERNACIONAL', 'https://whc.unesco.org/en/statesparties/gt',
    CURRENT_DATE, 'Página general de Guatemala en UNESCO World Heritage Centre.', 'ALTA', 'Guatemala',
    'Uso de datos patrimoniales oficiales.', 'ACTIVA',
    'Fuente registrada para trazabilidad del módulo Turismo y Patrimonio.'
)
ON CONFLICT (codigo_fuente) DO UPDATE SET
    nombre_fuente = EXCLUDED.nombre_fuente,
    institucion = EXCLUDED.institucion,
    tipo_fuente = EXCLUDED.tipo_fuente,
    url = EXCLUDED.url,
    fecha_consulta = EXCLUDED.fecha_consulta,
    descripcion = EXCLUDED.descripcion,
    confiabilidad = EXCLUDED.confiabilidad,
    cobertura_geografica = EXCLUDED.cobertura_geografica,
    licencia_uso = EXCLUDED.licencia_uso,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.fuente_datos (
    codigo_fuente, nombre_fuente, institucion, tipo_fuente, url,
    fecha_consulta, descripcion, confiabilidad, cobertura_geografica,
    licencia_uso, estado, observaciones
)
VALUES (
    'UNESCO_TIKAL', 'UNESCO World Heritage Centre - Tikal National Park', 'UNESCO', 'INTERNACIONAL', 'https://whc.unesco.org/en/list/64/',
    CURRENT_DATE, 'Fuente oficial para Parque Nacional Tikal como Patrimonio Mundial.', 'ALTA', 'Petén, Guatemala',
    'Uso de datos patrimoniales oficiales.', 'ACTIVA',
    'Fuente registrada para trazabilidad del módulo Turismo y Patrimonio.'
)
ON CONFLICT (codigo_fuente) DO UPDATE SET
    nombre_fuente = EXCLUDED.nombre_fuente,
    institucion = EXCLUDED.institucion,
    tipo_fuente = EXCLUDED.tipo_fuente,
    url = EXCLUDED.url,
    fecha_consulta = EXCLUDED.fecha_consulta,
    descripcion = EXCLUDED.descripcion,
    confiabilidad = EXCLUDED.confiabilidad,
    cobertura_geografica = EXCLUDED.cobertura_geografica,
    licencia_uso = EXCLUDED.licencia_uso,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.fuente_datos (
    codigo_fuente, nombre_fuente, institucion, tipo_fuente, url,
    fecha_consulta, descripcion, confiabilidad, cobertura_geografica,
    licencia_uso, estado, observaciones
)
VALUES (
    'UNESCO_ANTIGUA', 'UNESCO World Heritage Centre - Antigua Guatemala', 'UNESCO', 'INTERNACIONAL', 'https://whc.unesco.org/en/list/65/',
    CURRENT_DATE, 'Fuente oficial para Antigua Guatemala como Patrimonio Mundial.', 'ALTA', 'Sacatepéquez, Guatemala',
    'Uso de datos patrimoniales oficiales.', 'ACTIVA',
    'Fuente registrada para trazabilidad del módulo Turismo y Patrimonio.'
)
ON CONFLICT (codigo_fuente) DO UPDATE SET
    nombre_fuente = EXCLUDED.nombre_fuente,
    institucion = EXCLUDED.institucion,
    tipo_fuente = EXCLUDED.tipo_fuente,
    url = EXCLUDED.url,
    fecha_consulta = EXCLUDED.fecha_consulta,
    descripcion = EXCLUDED.descripcion,
    confiabilidad = EXCLUDED.confiabilidad,
    cobertura_geografica = EXCLUDED.cobertura_geografica,
    licencia_uso = EXCLUDED.licencia_uso,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.fuente_datos (
    codigo_fuente, nombre_fuente, institucion, tipo_fuente, url,
    fecha_consulta, descripcion, confiabilidad, cobertura_geografica,
    licencia_uso, estado, observaciones
)
VALUES (
    'UNESCO_QUIRIGUA', 'UNESCO World Heritage Centre - Archaeological Park and Ruins of Quirigua', 'UNESCO', 'INTERNACIONAL', 'https://whc.unesco.org/en/list/149/',
    CURRENT_DATE, 'Fuente oficial para Quiriguá como Patrimonio Mundial.', 'ALTA', 'Izabal, Guatemala',
    'Uso de datos patrimoniales oficiales.', 'ACTIVA',
    'Fuente registrada para trazabilidad del módulo Turismo y Patrimonio.'
)
ON CONFLICT (codigo_fuente) DO UPDATE SET
    nombre_fuente = EXCLUDED.nombre_fuente,
    institucion = EXCLUDED.institucion,
    tipo_fuente = EXCLUDED.tipo_fuente,
    url = EXCLUDED.url,
    fecha_consulta = EXCLUDED.fecha_consulta,
    descripcion = EXCLUDED.descripcion,
    confiabilidad = EXCLUDED.confiabilidad,
    cobertura_geografica = EXCLUDED.cobertura_geografica,
    licencia_uso = EXCLUDED.licencia_uso,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.fuente_datos (
    codigo_fuente, nombre_fuente, institucion, tipo_fuente, url,
    fecha_consulta, descripcion, confiabilidad, cobertura_geografica,
    licencia_uso, estado, observaciones
)
VALUES (
    'UNESCO_TAKALIK_ABAJ', 'UNESCO World Heritage Centre - National Archaeological Park Tak’alik Ab’aj', 'UNESCO', 'INTERNACIONAL', 'https://whc.unesco.org/en/list/1663/',
    CURRENT_DATE, 'Fuente oficial para Tak’alik Ab’aj como Patrimonio Mundial.', 'ALTA', 'Retalhuleu, Guatemala',
    'Uso de datos patrimoniales oficiales.', 'ACTIVA',
    'Fuente registrada para trazabilidad del módulo Turismo y Patrimonio.'
)
ON CONFLICT (codigo_fuente) DO UPDATE SET
    nombre_fuente = EXCLUDED.nombre_fuente,
    institucion = EXCLUDED.institucion,
    tipo_fuente = EXCLUDED.tipo_fuente,
    url = EXCLUDED.url,
    fecha_consulta = EXCLUDED.fecha_consulta,
    descripcion = EXCLUDED.descripcion,
    confiabilidad = EXCLUDED.confiabilidad,
    cobertura_geografica = EXCLUDED.cobertura_geografica,
    licencia_uso = EXCLUDED.licencia_uso,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.fuente_datos (
    codigo_fuente, nombre_fuente, institucion, tipo_fuente, url,
    fecha_consulta, descripcion, confiabilidad, cobertura_geografica,
    licencia_uso, estado, observaciones
)
VALUES (
    'CONAP_GENERAL', 'Consejo Nacional de Areas Protegidas - CONAP', 'CONAP', 'INSTITUCIONAL', 'https://conap.gob.gt/',
    CURRENT_DATE, 'Fuente institucional general sobre áreas protegidas de Guatemala.', 'ALTA', 'Guatemala',
    'Información pública institucional.', 'ACTIVA',
    'Fuente registrada para trazabilidad del módulo Turismo y Patrimonio.'
)
ON CONFLICT (codigo_fuente) DO UPDATE SET
    nombre_fuente = EXCLUDED.nombre_fuente,
    institucion = EXCLUDED.institucion,
    tipo_fuente = EXCLUDED.tipo_fuente,
    url = EXCLUDED.url,
    fecha_consulta = EXCLUDED.fecha_consulta,
    descripcion = EXCLUDED.descripcion,
    confiabilidad = EXCLUDED.confiabilidad,
    cobertura_geografica = EXCLUDED.cobertura_geografica,
    licencia_uso = EXCLUDED.licencia_uso,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.fuente_datos (
    codigo_fuente, nombre_fuente, institucion, tipo_fuente, url,
    fecha_consulta, descripcion, confiabilidad, cobertura_geografica,
    licencia_uso, estado, observaciones
)
VALUES (
    'CONAP_SIGAP_GENERAL', 'CONAP/SIGAP Turismo', 'CONAP', 'INSTITUCIONAL', 'https://turismo-sigap.conap.gob.gt/',
    CURRENT_DATE, 'Portal turístico SIGAP para áreas protegidas y rutas asociadas.', 'ALTA', 'Guatemala',
    'Información turística de áreas protegidas.', 'ACTIVA',
    'Fuente registrada para trazabilidad del módulo Turismo y Patrimonio.'
)
ON CONFLICT (codigo_fuente) DO UPDATE SET
    nombre_fuente = EXCLUDED.nombre_fuente,
    institucion = EXCLUDED.institucion,
    tipo_fuente = EXCLUDED.tipo_fuente,
    url = EXCLUDED.url,
    fecha_consulta = EXCLUDED.fecha_consulta,
    descripcion = EXCLUDED.descripcion,
    confiabilidad = EXCLUDED.confiabilidad,
    cobertura_geografica = EXCLUDED.cobertura_geografica,
    licencia_uso = EXCLUDED.licencia_uso,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.fuente_datos (
    codigo_fuente, nombre_fuente, institucion, tipo_fuente, url,
    fecha_consulta, descripcion, confiabilidad, cobertura_geografica,
    licencia_uso, estado, observaciones
)
VALUES (
    'SICULTURA_GENERAL', 'SICultura - Sistema de Información Cultural', 'Ministerio de Cultura y Deportes', 'INSTITUCIONAL', 'https://www.sicultura.gob.gt/',
    CURRENT_DATE, 'Directorio cultural y patrimonial de Guatemala.', 'ALTA', 'Guatemala',
    'Información cultural institucional.', 'ACTIVA',
    'Fuente registrada para trazabilidad del módulo Turismo y Patrimonio.'
)
ON CONFLICT (codigo_fuente) DO UPDATE SET
    nombre_fuente = EXCLUDED.nombre_fuente,
    institucion = EXCLUDED.institucion,
    tipo_fuente = EXCLUDED.tipo_fuente,
    url = EXCLUDED.url,
    fecha_consulta = EXCLUDED.fecha_consulta,
    descripcion = EXCLUDED.descripcion,
    confiabilidad = EXCLUDED.confiabilidad,
    cobertura_geografica = EXCLUDED.cobertura_geografica,
    licencia_uso = EXCLUDED.licencia_uso,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


INSERT INTO meta.fuente_datos (
    codigo_fuente, nombre_fuente, institucion, tipo_fuente, url,
    fecha_consulta, descripcion, confiabilidad, cobertura_geografica,
    licencia_uso, estado, observaciones
)
VALUES (
    'SIC_TIKAL', 'SICultura - Parque Nacional Tikal Corazón del Mundo Maya', 'Ministerio de Cultura y Deportes', 'INSTITUCIONAL', 'https://www.sicultura.gob.gt/directory-directorio_c/listing/parque-nacional-tikal-corazon-del-mundo-maya/',
    CURRENT_DATE, 'Información complementaria sobre Tikal.', 'ALTA', 'Petén, Guatemala',
    'Información cultural y turística institucional.', 'ACTIVA',
    'Fuente registrada para trazabilidad del módulo Turismo y Patrimonio.'
)
ON CONFLICT (codigo_fuente) DO UPDATE SET
    nombre_fuente = EXCLUDED.nombre_fuente,
    institucion = EXCLUDED.institucion,
    tipo_fuente = EXCLUDED.tipo_fuente,
    url = EXCLUDED.url,
    fecha_consulta = EXCLUDED.fecha_consulta,
    descripcion = EXCLUDED.descripcion,
    confiabilidad = EXCLUDED.confiabilidad,
    cobertura_geografica = EXCLUDED.cobertura_geografica,
    licencia_uso = EXCLUDED.licencia_uso,
    estado = EXCLUDED.estado,
    observaciones = EXCLUDED.observaciones;


-- ============================================================
-- Relación fuentes-tablas
-- ============================================================


INSERT INTO meta.tabla_fuente (
    id_fuente, nivel_respaldo, id_esquema, id_tabla, id_columna,
    uso_fuente, campos_respalda, observaciones
)
SELECT
    f.id_fuente,
    'TABLA',
    e.id_esquema,
    t.id_tabla,
    NULL,
    'Respalda la clasificación de regiones turísticas de Guatemala.',
    'codigo, nombre, descripcion',
    'Usada para documentar las siete regiones turísticas.'
FROM meta.fuente_datos f
JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'
JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'region_turistica'
WHERE f.codigo_fuente = 'GCB_REGIONES_GT'
  AND NOT EXISTS (
      SELECT 1
      FROM meta.tabla_fuente tf
      WHERE tf.id_fuente = f.id_fuente
        AND tf.nivel_respaldo = 'TABLA'
        AND tf.id_tabla = t.id_tabla
        AND tf.uso_fuente = 'Respalda la clasificación de regiones turísticas de Guatemala.'
  );


INSERT INTO meta.tabla_fuente (
    id_fuente, nivel_respaldo, id_esquema, id_tabla, id_columna,
    uso_fuente, campos_respalda, observaciones
)
SELECT
    f.id_fuente,
    'TABLA',
    e.id_esquema,
    t.id_tabla,
    NULL,
    'Respalda la relación general entre departamentos y regiones turísticas.',
    'region_turistica_id, departamento_id',
    'Relación territorial turística.'
FROM meta.fuente_datos f
JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'
JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'departamento_region_turistica'
WHERE f.codigo_fuente = 'GCB_REGIONES_GT'
  AND NOT EXISTS (
      SELECT 1
      FROM meta.tabla_fuente tf
      WHERE tf.id_fuente = f.id_fuente
        AND tf.nivel_respaldo = 'TABLA'
        AND tf.id_tabla = t.id_tabla
        AND tf.uso_fuente = 'Respalda la relación general entre departamentos y regiones turísticas.'
  );


INSERT INTO meta.tabla_fuente (
    id_fuente, nivel_respaldo, id_esquema, id_tabla, id_columna,
    uso_fuente, campos_respalda, observaciones
)
SELECT
    f.id_fuente,
    'TABLA',
    e.id_esquema,
    t.id_tabla,
    NULL,
    'Respalda el catálogo general de patrimonios mundiales de Guatemala.',
    'codigo, nombre, tipo, organismo, anio_inscripcion',
    'Fuente general UNESCO.'
FROM meta.fuente_datos f
JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'
JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'patrimonio_turistico'
WHERE f.codigo_fuente = 'UNESCO_GUATEMALA'
  AND NOT EXISTS (
      SELECT 1
      FROM meta.tabla_fuente tf
      WHERE tf.id_fuente = f.id_fuente
        AND tf.nivel_respaldo = 'TABLA'
        AND tf.id_tabla = t.id_tabla
        AND tf.uso_fuente = 'Respalda el catálogo general de patrimonios mundiales de Guatemala.'
  );


INSERT INTO meta.tabla_fuente (
    id_fuente, nivel_respaldo, id_esquema, id_tabla, id_columna,
    uso_fuente, campos_respalda, observaciones
)
SELECT
    f.id_fuente,
    'REGISTRO',
    e.id_esquema,
    t.id_tabla,
    NULL,
    'Respalda el reconocimiento patrimonial del Parque Nacional Tikal.',
    'nombre, tipo, organismo, anio_inscripcion',
    'Patrimonio Mundial UNESCO.'
FROM meta.fuente_datos f
JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'
JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'patrimonio_turistico'
WHERE f.codigo_fuente = 'UNESCO_TIKAL'
  AND NOT EXISTS (
      SELECT 1
      FROM meta.tabla_fuente tf
      WHERE tf.id_fuente = f.id_fuente
        AND tf.nivel_respaldo = 'REGISTRO'
        AND tf.id_tabla = t.id_tabla
        AND tf.uso_fuente = 'Respalda el reconocimiento patrimonial del Parque Nacional Tikal.'
  );


INSERT INTO meta.tabla_fuente (
    id_fuente, nivel_respaldo, id_esquema, id_tabla, id_columna,
    uso_fuente, campos_respalda, observaciones
)
SELECT
    f.id_fuente,
    'REGISTRO',
    e.id_esquema,
    t.id_tabla,
    NULL,
    'Respalda el reconocimiento patrimonial de Antigua Guatemala.',
    'nombre, tipo, organismo, anio_inscripcion',
    'Patrimonio Mundial UNESCO.'
FROM meta.fuente_datos f
JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'
JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'patrimonio_turistico'
WHERE f.codigo_fuente = 'UNESCO_ANTIGUA'
  AND NOT EXISTS (
      SELECT 1
      FROM meta.tabla_fuente tf
      WHERE tf.id_fuente = f.id_fuente
        AND tf.nivel_respaldo = 'REGISTRO'
        AND tf.id_tabla = t.id_tabla
        AND tf.uso_fuente = 'Respalda el reconocimiento patrimonial de Antigua Guatemala.'
  );


INSERT INTO meta.tabla_fuente (
    id_fuente, nivel_respaldo, id_esquema, id_tabla, id_columna,
    uso_fuente, campos_respalda, observaciones
)
SELECT
    f.id_fuente,
    'REGISTRO',
    e.id_esquema,
    t.id_tabla,
    NULL,
    'Respalda el reconocimiento patrimonial de Quiriguá.',
    'nombre, tipo, organismo, anio_inscripcion',
    'Patrimonio Mundial UNESCO.'
FROM meta.fuente_datos f
JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'
JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'patrimonio_turistico'
WHERE f.codigo_fuente = 'UNESCO_QUIRIGUA'
  AND NOT EXISTS (
      SELECT 1
      FROM meta.tabla_fuente tf
      WHERE tf.id_fuente = f.id_fuente
        AND tf.nivel_respaldo = 'REGISTRO'
        AND tf.id_tabla = t.id_tabla
        AND tf.uso_fuente = 'Respalda el reconocimiento patrimonial de Quiriguá.'
  );


INSERT INTO meta.tabla_fuente (
    id_fuente, nivel_respaldo, id_esquema, id_tabla, id_columna,
    uso_fuente, campos_respalda, observaciones
)
SELECT
    f.id_fuente,
    'REGISTRO',
    e.id_esquema,
    t.id_tabla,
    NULL,
    'Respalda el reconocimiento patrimonial de Tak’alik Ab’aj.',
    'nombre, tipo, organismo, anio_inscripcion',
    'Patrimonio Mundial UNESCO.'
FROM meta.fuente_datos f
JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'
JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'patrimonio_turistico'
WHERE f.codigo_fuente = 'UNESCO_TAKALIK_ABAJ'
  AND NOT EXISTS (
      SELECT 1
      FROM meta.tabla_fuente tf
      WHERE tf.id_fuente = f.id_fuente
        AND tf.nivel_respaldo = 'REGISTRO'
        AND tf.id_tabla = t.id_tabla
        AND tf.uso_fuente = 'Respalda el reconocimiento patrimonial de Tak’alik Ab’aj.'
  );


INSERT INTO meta.tabla_fuente (
    id_fuente, nivel_respaldo, id_esquema, id_tabla, id_columna,
    uso_fuente, campos_respalda, observaciones
)
SELECT
    f.id_fuente,
    'TABLA',
    e.id_esquema,
    t.id_tabla,
    NULL,
    'Respalda datos generales de áreas protegidas y destinos naturales.',
    'es_area_protegida, descripcion',
    'Aplica a destinos naturales y áreas protegidas.'
FROM meta.fuente_datos f
JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'
JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'destino_turistico'
WHERE f.codigo_fuente = 'CONAP_GENERAL'
  AND NOT EXISTS (
      SELECT 1
      FROM meta.tabla_fuente tf
      WHERE tf.id_fuente = f.id_fuente
        AND tf.nivel_respaldo = 'TABLA'
        AND tf.id_tabla = t.id_tabla
        AND tf.uso_fuente = 'Respalda datos generales de áreas protegidas y destinos naturales.'
  );


INSERT INTO meta.tabla_fuente (
    id_fuente, nivel_respaldo, id_esquema, id_tabla, id_columna,
    uso_fuente, campos_respalda, observaciones
)
SELECT
    f.id_fuente,
    'TABLA',
    e.id_esquema,
    t.id_tabla,
    NULL,
    'Respalda información turística de áreas protegidas disponibles en SIGAP.',
    'descripcion, horario, recomendaciones',
    'Aplica a áreas protegidas turísticas.'
FROM meta.fuente_datos f
JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'
JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'destino_turistico'
WHERE f.codigo_fuente = 'CONAP_SIGAP_GENERAL'
  AND NOT EXISTS (
      SELECT 1
      FROM meta.tabla_fuente tf
      WHERE tf.id_fuente = f.id_fuente
        AND tf.nivel_respaldo = 'TABLA'
        AND tf.id_tabla = t.id_tabla
        AND tf.uso_fuente = 'Respalda información turística de áreas protegidas disponibles en SIGAP.'
  );


INSERT INTO meta.tabla_fuente (
    id_fuente, nivel_respaldo, id_esquema, id_tabla, id_columna,
    uso_fuente, campos_respalda, observaciones
)
SELECT
    f.id_fuente,
    'TABLA',
    e.id_esquema,
    t.id_tabla,
    NULL,
    'Respalda datos culturales y patrimoniales de destinos.',
    'descripcion, categoria, patrimonio',
    'Aplica a sitios culturales, arqueológicos o museos.'
FROM meta.fuente_datos f
JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'
JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'destino_turistico'
WHERE f.codigo_fuente = 'SICULTURA_GENERAL'
  AND NOT EXISTS (
      SELECT 1
      FROM meta.tabla_fuente tf
      WHERE tf.id_fuente = f.id_fuente
        AND tf.nivel_respaldo = 'TABLA'
        AND tf.id_tabla = t.id_tabla
        AND tf.uso_fuente = 'Respalda datos culturales y patrimoniales de destinos.'
  );


INSERT INTO meta.tabla_fuente (
    id_fuente, nivel_respaldo, id_esquema, id_tabla, id_columna,
    uso_fuente, campos_respalda, observaciones
)
SELECT
    f.id_fuente,
    'TABLA',
    e.id_esquema,
    t.id_tabla,
    NULL,
    'Respalda información general de promoción turística y rutas.',
    'nombre, descripcion, duracion_dias',
    'Fuente institucional general de turismo.'
FROM meta.fuente_datos f
JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'
JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'ruta_turistica'
WHERE f.codigo_fuente = 'INGUAT_GENERAL'
  AND NOT EXISTS (
      SELECT 1
      FROM meta.tabla_fuente tf
      WHERE tf.id_fuente = f.id_fuente
        AND tf.nivel_respaldo = 'TABLA'
        AND tf.id_tabla = t.id_tabla
        AND tf.uso_fuente = 'Respalda información general de promoción turística y rutas.'
  );


INSERT INTO meta.regla_calidad (
    id_tabla, id_columna, nombre_regla, descripcion, tipo_regla,
    severidad, expresion_validacion, accion_si_falla, estado,
    id_version_desde
)
SELECT
    t.id_tabla,
    c.id_columna,
    'Departamento debe pertenecer a un país',
    'Todo departamento debe referenciar un país existente.',
    'REFERENCIAL',
    'ALTA',
    'pais_id IS NOT NULL AND EXISTS (SELECT 1 FROM geografia.pais p WHERE p.id = pais_id)',
    'No aprobar el registro hasta corregir la relación con país.',
    'ACTIVA',
    v.id_version
FROM meta.esquema_datos e
JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'departamento'
LEFT JOIN meta.columna_datos c ON c.id_tabla = t.id_tabla AND c.nombre_columna = 'pais_id'
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'geografia'
  AND NOT EXISTS (
      SELECT 1
      FROM meta.regla_calidad r
      WHERE r.id_tabla = t.id_tabla
        AND r.nombre_regla = 'Departamento debe pertenecer a un país'
        AND COALESCE(r.id_columna, -1) = COALESCE(c.id_columna, -1)
  );


INSERT INTO meta.regla_calidad (
    id_tabla, id_columna, nombre_regla, descripcion, tipo_regla,
    severidad, expresion_validacion, accion_si_falla, estado,
    id_version_desde
)
SELECT
    t.id_tabla,
    c.id_columna,
    'Municipio debe pertenecer a un departamento',
    'Todo municipio debe referenciar un departamento existente.',
    'REFERENCIAL',
    'ALTA',
    'departamento_id IS NOT NULL AND EXISTS (SELECT 1 FROM geografia.departamento d WHERE d.id = departamento_id)',
    'No aprobar el registro hasta corregir el departamento.',
    'ACTIVA',
    v.id_version
FROM meta.esquema_datos e
JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'municipio'
LEFT JOIN meta.columna_datos c ON c.id_tabla = t.id_tabla AND c.nombre_columna = 'departamento_id'
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'geografia'
  AND NOT EXISTS (
      SELECT 1
      FROM meta.regla_calidad r
      WHERE r.id_tabla = t.id_tabla
        AND r.nombre_regla = 'Municipio debe pertenecer a un departamento'
        AND COALESCE(r.id_columna, -1) = COALESCE(c.id_columna, -1)
  );


INSERT INTO meta.regla_calidad (
    id_tabla, id_columna, nombre_regla, descripcion, tipo_regla,
    severidad, expresion_validacion, accion_si_falla, estado,
    id_version_desde
)
SELECT
    t.id_tabla,
    c.id_columna,
    'Fuente debe tener URL verificable',
    'Toda fuente turística debe registrar una URL o enlace institucional para trazabilidad.',
    'FUENTE',
    'ALTA',
    'url IS NOT NULL AND trim(url) <> ''''',
    'No usar la fuente hasta completar URL verificable.',
    'ACTIVA',
    v.id_version
FROM meta.esquema_datos e
JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'fuente_turistica'
LEFT JOIN meta.columna_datos c ON c.id_tabla = t.id_tabla AND c.nombre_columna = 'url'
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND NOT EXISTS (
      SELECT 1
      FROM meta.regla_calidad r
      WHERE r.id_tabla = t.id_tabla
        AND r.nombre_regla = 'Fuente debe tener URL verificable'
        AND COALESCE(r.id_columna, -1) = COALESCE(c.id_columna, -1)
  );


INSERT INTO meta.regla_calidad (
    id_tabla, id_columna, nombre_regla, descripcion, tipo_regla,
    severidad, expresion_validacion, accion_si_falla, estado,
    id_version_desde
)
SELECT
    t.id_tabla,
    c.id_columna,
    'Destino debe tener departamento oficial',
    'Todo destino debe asociarse a un departamento existente del esquema geografia.',
    'REFERENCIAL',
    'ALTA',
    'departamento_id IS NOT NULL AND EXISTS (SELECT 1 FROM geografia.departamento d WHERE d.id = departamento_id)',
    'No aprobar el destino hasta corregir su ubicación departamental.',
    'ACTIVA',
    v.id_version
FROM meta.esquema_datos e
JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'destino_turistico'
LEFT JOIN meta.columna_datos c ON c.id_tabla = t.id_tabla AND c.nombre_columna = 'departamento_id'
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND NOT EXISTS (
      SELECT 1
      FROM meta.regla_calidad r
      WHERE r.id_tabla = t.id_tabla
        AND r.nombre_regla = 'Destino debe tener departamento oficial'
        AND COALESCE(r.id_columna, -1) = COALESCE(c.id_columna, -1)
  );


INSERT INTO meta.regla_calidad (
    id_tabla, id_columna, nombre_regla, descripcion, tipo_regla,
    severidad, expresion_validacion, accion_si_falla, estado,
    id_version_desde
)
SELECT
    t.id_tabla,
    c.id_columna,
    'Municipio debe corresponder al departamento del destino',
    'Si el destino tiene municipio, ese municipio debe pertenecer al departamento indicado.',
    'COHERENCIA',
    'ALTA',
    'municipio_id IS NULL OR EXISTS (SELECT 1 FROM geografia.municipio m WHERE m.id = municipio_id AND m.departamento_id = departamento_id)',
    'Corregir municipio o departamento antes de aprobar.',
    'ACTIVA',
    v.id_version
FROM meta.esquema_datos e
JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'destino_turistico'
LEFT JOIN meta.columna_datos c ON c.id_tabla = t.id_tabla AND c.nombre_columna = 'municipio_id'
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND NOT EXISTS (
      SELECT 1
      FROM meta.regla_calidad r
      WHERE r.id_tabla = t.id_tabla
        AND r.nombre_regla = 'Municipio debe corresponder al departamento del destino'
        AND COALESCE(r.id_columna, -1) = COALESCE(c.id_columna, -1)
  );


INSERT INTO meta.regla_calidad (
    id_tabla, id_columna, nombre_regla, descripcion, tipo_regla,
    severidad, expresion_validacion, accion_si_falla, estado,
    id_version_desde
)
SELECT
    t.id_tabla,
    c.id_columna,
    'Destino debe tener fuente principal',
    'Todo destino turístico debe contar con una fuente principal verificable.',
    'FUENTE',
    'ALTA',
    'fuente_principal_id IS NOT NULL',
    'Asignar fuente principal antes de aprobar el registro.',
    'ACTIVA',
    v.id_version
FROM meta.esquema_datos e
JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'destino_turistico'
LEFT JOIN meta.columna_datos c ON c.id_tabla = t.id_tabla AND c.nombre_columna = 'fuente_principal_id'
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND NOT EXISTS (
      SELECT 1
      FROM meta.regla_calidad r
      WHERE r.id_tabla = t.id_tabla
        AND r.nombre_regla = 'Destino debe tener fuente principal'
        AND COALESCE(r.id_columna, -1) = COALESCE(c.id_columna, -1)
  );


INSERT INTO meta.regla_calidad (
    id_tabla, id_columna, nombre_regla, descripcion, tipo_regla,
    severidad, expresion_validacion, accion_si_falla, estado,
    id_version_desde
)
SELECT
    t.id_tabla,
    NULL,
    'Destino debe tener al menos una categoría',
    'Todo destino turístico publicado debe estar clasificado en al menos una categoría.',
    'CATALOGO',
    'MEDIA',
    'EXISTS (SELECT 1 FROM turismo.destino_categoria dc WHERE dc.destino_id = destino_id)',
    'Revisar clasificación del destino.',
    'ACTIVA',
    v.id_version
FROM meta.esquema_datos e
JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'destino_categoria'
LEFT JOIN meta.columna_datos c ON FALSE
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND NOT EXISTS (
      SELECT 1
      FROM meta.regla_calidad r
      WHERE r.id_tabla = t.id_tabla
        AND r.nombre_regla = 'Destino debe tener al menos una categoría'
        AND COALESCE(r.id_columna, -1) = COALESCE(NULL, -1)
  );


INSERT INTO meta.regla_calidad (
    id_tabla, id_columna, nombre_regla, descripcion, tipo_regla,
    severidad, expresion_validacion, accion_si_falla, estado,
    id_version_desde
)
SELECT
    t.id_tabla,
    NULL,
    'Destino debe tener trazabilidad documental',
    'Cada destino debe contar con al menos una fuente asociada en destino_fuente.',
    'FUENTE',
    'ALTA',
    'EXISTS (SELECT 1 FROM turismo.destino_fuente df WHERE df.destino_id = destino_id)',
    'Agregar una fuente de respaldo.',
    'ACTIVA',
    v.id_version
FROM meta.esquema_datos e
JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'destino_fuente'
LEFT JOIN meta.columna_datos c ON FALSE
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND NOT EXISTS (
      SELECT 1
      FROM meta.regla_calidad r
      WHERE r.id_tabla = t.id_tabla
        AND r.nombre_regla = 'Destino debe tener trazabilidad documental'
        AND COALESCE(r.id_columna, -1) = COALESCE(NULL, -1)
  );


INSERT INTO meta.regla_calidad (
    id_tabla, id_columna, nombre_regla, descripcion, tipo_regla,
    severidad, expresion_validacion, accion_si_falla, estado,
    id_version_desde
)
SELECT
    t.id_tabla,
    c.id_columna,
    'Orden de visita no debe repetirse en la misma ruta',
    'Dentro de una ruta, el orden de visita debe ser único.',
    'UNICIDAD',
    'MEDIA',
    'UNIQUE (ruta_id, orden_visita)',
    'Corregir el orden de visita duplicado.',
    'ACTIVA',
    v.id_version
FROM meta.esquema_datos e
JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'ruta_destino'
LEFT JOIN meta.columna_datos c ON c.id_tabla = t.id_tabla AND c.nombre_columna = 'orden_visita'
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND NOT EXISTS (
      SELECT 1
      FROM meta.regla_calidad r
      WHERE r.id_tabla = t.id_tabla
        AND r.nombre_regla = 'Orden de visita no debe repetirse en la misma ruta'
        AND COALESCE(r.id_columna, -1) = COALESCE(c.id_columna, -1)
  );


INSERT INTO meta.regla_calidad (
    id_tabla, id_columna, nombre_regla, descripcion, tipo_regla,
    severidad, expresion_validacion, accion_si_falla, estado,
    id_version_desde
)
SELECT
    t.id_tabla,
    c.id_columna,
    'Año de inscripción patrimonial debe ser razonable',
    'El año de inscripción, si existe, debe ser coherente con reconocimientos patrimoniales modernos.',
    'RANGO',
    'MEDIA',
    'anio_inscripcion IS NULL OR anio_inscripcion BETWEEN 1900 AND EXTRACT(YEAR FROM CURRENT_DATE)',
    'Verificar año contra la fuente oficial.',
    'ACTIVA',
    v.id_version
FROM meta.esquema_datos e
JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'patrimonio_turistico'
LEFT JOIN meta.columna_datos c ON c.id_tabla = t.id_tabla AND c.nombre_columna = 'anio_inscripcion'
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
WHERE e.nombre_esquema = 'turismo'
  AND NOT EXISTS (
      SELECT 1
      FROM meta.regla_calidad r
      WHERE r.id_tabla = t.id_tabla
        AND r.nombre_regla = 'Año de inscripción patrimonial debe ser razonable'
        AND COALESCE(r.id_columna, -1) = COALESCE(c.id_columna, -1)
  );


-- ============================================================
-- 13. Revisión por pares
-- ============================================================


INSERT INTO meta.revision_pares (
    nivel_revision, id_esquema, id_tabla, id_columna, id_regla,
    tipo_revision, descripcion_revision,
    revisor_1, estado_revisor_1, fecha_revisor_1, comentario_revisor_1,
    revisor_2, estado_revisor_2, fecha_revisor_2, comentario_revisor_2,
    estado_final, observaciones
)
SELECT
    'ESQUEMA',
    e.id_esquema,
    NULL,
    NULL,
    NULL,
    'MODELO',
    'Revisión del alcance general del esquema turismo y sus límites frente a cultura, deportes y geografía.',
    'Bryan Santiago',
    'APROBADO',
    CURRENT_DATE,
    'Revisión inicial del modelo y documentación del módulo turismo.',
    'Integrante revisor 2',
    'PENDIENTE',
    NULL,
    'Reemplazar por el nombre real del segundo revisor y actualizar estado antes de la entrega final.',
    'PENDIENTE',
    'Debe completarse con la aprobación formal del segundo revisor.'
FROM meta.esquema_datos e
LEFT JOIN meta.tabla_datos t ON FALSE
LEFT JOIN meta.columna_datos c ON FALSE
WHERE e.nombre_esquema = 'turismo'
  AND NOT EXISTS (
      SELECT 1 FROM meta.revision_pares rp
      WHERE rp.nivel_revision = 'ESQUEMA'
        AND rp.tipo_revision = 'MODELO'
        AND COALESCE(rp.id_esquema, -1) = COALESCE(e.id_esquema, -1)
        AND COALESCE(rp.id_tabla, -1) = COALESCE(NULL, -1)
        AND COALESCE(rp.id_columna, -1) = COALESCE(NULL, -1)
  );


INSERT INTO meta.revision_pares (
    nivel_revision, id_esquema, id_tabla, id_columna, id_regla,
    tipo_revision, descripcion_revision,
    revisor_1, estado_revisor_1, fecha_revisor_1, comentario_revisor_1,
    revisor_2, estado_revisor_2, fecha_revisor_2, comentario_revisor_2,
    estado_final, observaciones
)
SELECT
    'TABLA',
    e.id_esquema,
    t.id_tabla,
    NULL,
    NULL,
    'MODELO',
    'Revisión de la tabla central de destinos turísticos, criterios de inclusión, exclusión y relación con geografía.',
    'Bryan Santiago',
    'APROBADO',
    CURRENT_DATE,
    'Revisión inicial del modelo y documentación del módulo turismo.',
    'Integrante revisor 2',
    'PENDIENTE',
    NULL,
    'Reemplazar por el nombre real del segundo revisor y actualizar estado antes de la entrega final.',
    'PENDIENTE',
    'Tabla crítica del módulo.'
FROM meta.esquema_datos e
LEFT JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'destino_turistico'
LEFT JOIN meta.columna_datos c ON FALSE
WHERE e.nombre_esquema = 'turismo'
  AND NOT EXISTS (
      SELECT 1 FROM meta.revision_pares rp
      WHERE rp.nivel_revision = 'TABLA'
        AND rp.tipo_revision = 'MODELO'
        AND COALESCE(rp.id_esquema, -1) = COALESCE(e.id_esquema, -1)
        AND COALESCE(rp.id_tabla, -1) = COALESCE(t.id_tabla, -1)
        AND COALESCE(rp.id_columna, -1) = COALESCE(NULL, -1)
  );


INSERT INTO meta.revision_pares (
    nivel_revision, id_esquema, id_tabla, id_columna, id_regla,
    tipo_revision, descripcion_revision,
    revisor_1, estado_revisor_1, fecha_revisor_1, comentario_revisor_1,
    revisor_2, estado_revisor_2, fecha_revisor_2, comentario_revisor_2,
    estado_final, observaciones
)
SELECT
    'TABLA',
    e.id_esquema,
    t.id_tabla,
    NULL,
    NULL,
    'FUENTE',
    'Revisión de la tabla de fuentes turísticas y sus campos mínimos de trazabilidad.',
    'Bryan Santiago',
    'APROBADO',
    CURRENT_DATE,
    'Revisión inicial del modelo y documentación del módulo turismo.',
    'Integrante revisor 2',
    'PENDIENTE',
    NULL,
    'Reemplazar por el nombre real del segundo revisor y actualizar estado antes de la entrega final.',
    'PENDIENTE',
    'Debe validarse que las fuentes sean verificables.'
FROM meta.esquema_datos e
LEFT JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'fuente_turistica'
LEFT JOIN meta.columna_datos c ON FALSE
WHERE e.nombre_esquema = 'turismo'
  AND NOT EXISTS (
      SELECT 1 FROM meta.revision_pares rp
      WHERE rp.nivel_revision = 'TABLA'
        AND rp.tipo_revision = 'FUENTE'
        AND COALESCE(rp.id_esquema, -1) = COALESCE(e.id_esquema, -1)
        AND COALESCE(rp.id_tabla, -1) = COALESCE(t.id_tabla, -1)
        AND COALESCE(rp.id_columna, -1) = COALESCE(NULL, -1)
  );


INSERT INTO meta.revision_pares (
    nivel_revision, id_esquema, id_tabla, id_columna, id_regla,
    tipo_revision, descripcion_revision,
    revisor_1, estado_revisor_1, fecha_revisor_1, comentario_revisor_1,
    revisor_2, estado_revisor_2, fecha_revisor_2, comentario_revisor_2,
    estado_final, observaciones
)
SELECT
    'TABLA',
    e.id_esquema,
    t.id_tabla,
    NULL,
    NULL,
    'FUENTE',
    'Revisión de patrimonio turístico y uso de fuentes UNESCO o institucionales.',
    'Bryan Santiago',
    'APROBADO',
    CURRENT_DATE,
    'Revisión inicial del modelo y documentación del módulo turismo.',
    'Integrante revisor 2',
    'PENDIENTE',
    NULL,
    'Reemplazar por el nombre real del segundo revisor y actualizar estado antes de la entrega final.',
    'PENDIENTE',
    'Tabla sensible por requerir respaldo oficial.'
FROM meta.esquema_datos e
LEFT JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'patrimonio_turistico'
LEFT JOIN meta.columna_datos c ON FALSE
WHERE e.nombre_esquema = 'turismo'
  AND NOT EXISTS (
      SELECT 1 FROM meta.revision_pares rp
      WHERE rp.nivel_revision = 'TABLA'
        AND rp.tipo_revision = 'FUENTE'
        AND COALESCE(rp.id_esquema, -1) = COALESCE(e.id_esquema, -1)
        AND COALESCE(rp.id_tabla, -1) = COALESCE(t.id_tabla, -1)
        AND COALESCE(rp.id_columna, -1) = COALESCE(NULL, -1)
  );


INSERT INTO meta.revision_pares (
    nivel_revision, id_esquema, id_tabla, id_columna, id_regla,
    tipo_revision, descripcion_revision,
    revisor_1, estado_revisor_1, fecha_revisor_1, comentario_revisor_1,
    revisor_2, estado_revisor_2, fecha_revisor_2, comentario_revisor_2,
    estado_final, observaciones
)
SELECT
    'ESQUEMA',
    e.id_esquema,
    NULL,
    NULL,
    NULL,
    'MODELO',
    'Revisión del uso de geografía como fuente territorial única para otros esquemas.',
    'Bryan Santiago',
    'APROBADO',
    CURRENT_DATE,
    'Revisión inicial del modelo y documentación del módulo turismo.',
    'Integrante revisor 2',
    'PENDIENTE',
    NULL,
    'Reemplazar por el nombre real del segundo revisor y actualizar estado antes de la entrega final.',
    'PENDIENTE',
    'Evita duplicidad de departamentos y municipios.'
FROM meta.esquema_datos e
LEFT JOIN meta.tabla_datos t ON FALSE
LEFT JOIN meta.columna_datos c ON FALSE
WHERE e.nombre_esquema = 'geografia'
  AND NOT EXISTS (
      SELECT 1 FROM meta.revision_pares rp
      WHERE rp.nivel_revision = 'ESQUEMA'
        AND rp.tipo_revision = 'MODELO'
        AND COALESCE(rp.id_esquema, -1) = COALESCE(e.id_esquema, -1)
        AND COALESCE(rp.id_tabla, -1) = COALESCE(NULL, -1)
        AND COALESCE(rp.id_columna, -1) = COALESCE(NULL, -1)
  );


-- ============================================================
-- 14. Decisiones de modelado
-- ============================================================


INSERT INTO meta.decision_modelado (
    id_tema, tema, pregunta, decision, justificacion, ejemplo,
    id_esquema_recomendado, id_tabla_recomendada, alternativa,
    responsable, fecha_decision, id_version_desde, estado, observaciones
)
SELECT
    tm.id_tema,
    'Uso de geografía oficial',
    '¿Turismo debe crear sus propias tablas de departamentos y municipios?',
    'No. Turismo debe referenciar geografia.departamento y geografia.municipio.',
    'La división territorial debe existir una sola vez para evitar inconsistencias y facilitar cruces entre módulos.',
    'Un destino turístico en Antigua Guatemala referencia geografia.departamento y geografia.municipio.',
    e.id_esquema,
    t.id_tabla,
    'Duplicar departamentos en turismo generaría inconsistencias.',
    'Equipo SS2-CONOSE-OCCIDENTE',
    CURRENT_DATE,
    v.id_version,
    'VIGENTE',
    'Decisión documentada para orientar el crecimiento del modelo de datos.'
FROM meta.tema_datos tm
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
LEFT JOIN meta.esquema_datos e ON e.nombre_esquema = 'geografia'
LEFT JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'departamento'
WHERE tm.nombre_tema = 'Geografía'
  AND NOT EXISTS (
      SELECT 1 FROM meta.decision_modelado d
      WHERE d.tema = 'Uso de geografía oficial'
        AND d.pregunta = '¿Turismo debe crear sus propias tablas de departamentos y municipios?'
  );


INSERT INTO meta.decision_modelado (
    id_tema, tema, pregunta, decision, justificacion, ejemplo,
    id_esquema_recomendado, id_tabla_recomendada, alternativa,
    responsable, fecha_decision, id_version_desde, estado, observaciones
)
SELECT
    tm.id_tema,
    'Festividades y eventos',
    '¿Las festividades van en el esquema turismo?',
    'Solo si se modelan desde el enfoque turístico. En la versión 1.0 no se crea una tabla de festividades; si se requiere, se recomienda una tabla futura turismo.evento_turistico o un esquema cultura.',
    'Una festividad puede ser atractiva para visitantes, pero también puede ser una manifestación cultural o religiosa. La ubicación depende del enfoque del análisis.',
    'Semana Santa en Antigua puede ser turismo si se analiza como atractivo turístico; puede ser cultura si se analiza como manifestación religiosa.',
    e.id_esquema,
    NULL,
    'Crear cultura.festividad si el proyecto decide estudiar tradiciones y expresiones culturales de forma independiente.',
    'Equipo SS2-CONOSE-OCCIDENTE',
    CURRENT_DATE,
    v.id_version,
    'VIGENTE',
    'Decisión documentada para orientar el crecimiento del modelo de datos.'
FROM meta.tema_datos tm
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
LEFT JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'
LEFT JOIN meta.tabla_datos t ON FALSE
WHERE tm.nombre_tema = 'Festividades'
  AND NOT EXISTS (
      SELECT 1 FROM meta.decision_modelado d
      WHERE d.tema = 'Festividades y eventos'
        AND d.pregunta = '¿Las festividades van en el esquema turismo?'
  );


INSERT INTO meta.decision_modelado (
    id_tema, tema, pregunta, decision, justificacion, ejemplo,
    id_esquema_recomendado, id_tabla_recomendada, alternativa,
    responsable, fecha_decision, id_version_desde, estado, observaciones
)
SELECT
    tm.id_tema,
    'Datos deportivos',
    '¿La información deportiva pertenece a turismo?',
    'No como regla general. Los deportes competitivos, ligas, resultados, torneos o equipos deberían ir en un esquema deportes si el proyecto los incorpora.',
    'Turismo solo registra actividades turísticas como senderismo o montañismo; no estadísticas deportivas.',
    'Un partido de fútbol no va en turismo; una actividad de senderismo en un volcán puede ir en turismo.actividad_turistica.',
    e.id_esquema,
    t.id_tabla,
    'Crear un esquema deportes para competencias, equipos, torneos, estadios y resultados.',
    'Equipo SS2-CONOSE-OCCIDENTE',
    CURRENT_DATE,
    v.id_version,
    'VIGENTE',
    'Decisión documentada para orientar el crecimiento del modelo de datos.'
FROM meta.tema_datos tm
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
LEFT JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'
LEFT JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'actividad_turistica'
WHERE tm.nombre_tema = 'Deportes'
  AND NOT EXISTS (
      SELECT 1 FROM meta.decision_modelado d
      WHERE d.tema = 'Datos deportivos'
        AND d.pregunta = '¿La información deportiva pertenece a turismo?'
  );


INSERT INTO meta.decision_modelado (
    id_tema, tema, pregunta, decision, justificacion, ejemplo,
    id_esquema_recomendado, id_tabla_recomendada, alternativa,
    responsable, fecha_decision, id_version_desde, estado, observaciones
)
SELECT
    tm.id_tema,
    'Patrimonio turístico',
    '¿Patrimonio debe ir en turismo o en un esquema patrimonio/cultura?',
    'En esta versión, turismo registra patrimonio cuando está relacionado con destinos turísticos. Si el proyecto requiere inventario patrimonial completo, se recomienda un esquema patrimonio o cultura especializado.',
    'El enfoque de esta tabla es turístico, no inventario nacional completo de bienes culturales.',
    'Tikal se registra por su relación con turismo y UNESCO.',
    e.id_esquema,
    t.id_tabla,
    'Crear un esquema cultura/patrimonio si se amplía el alcance patrimonial.',
    'Equipo SS2-CONOSE-OCCIDENTE',
    CURRENT_DATE,
    v.id_version,
    'VIGENTE',
    'Decisión documentada para orientar el crecimiento del modelo de datos.'
FROM meta.tema_datos tm
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
LEFT JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'
LEFT JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'patrimonio_turistico'
WHERE tm.nombre_tema = 'Patrimonio'
  AND NOT EXISTS (
      SELECT 1 FROM meta.decision_modelado d
      WHERE d.tema = 'Patrimonio turístico'
        AND d.pregunta = '¿Patrimonio debe ir en turismo o en un esquema patrimonio/cultura?'
  );


INSERT INTO meta.decision_modelado (
    id_tema, tema, pregunta, decision, justificacion, ejemplo,
    id_esquema_recomendado, id_tabla_recomendada, alternativa,
    responsable, fecha_decision, id_version_desde, estado, observaciones
)
SELECT
    tm.id_tema,
    'Trazabilidad de fuentes',
    '¿Cada dato turístico debe tener fuente?',
    'Sí. Los destinos, patrimonios, rutas o regiones deben relacionarse con fuentes verificables.',
    'La trazabilidad permite corroborar datos y cumplir calidad académica.',
    'Un destino puede relacionarse con UNESCO, SICultura o CONAP mediante destino_fuente.',
    e.id_esquema,
    t.id_tabla,
    'Los datos sin fuente deben quedar pendientes de aprobación.',
    'Equipo SS2-CONOSE-OCCIDENTE',
    CURRENT_DATE,
    v.id_version,
    'VIGENTE',
    'Decisión documentada para orientar el crecimiento del modelo de datos.'
FROM meta.tema_datos tm
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
LEFT JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'
LEFT JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'destino_fuente'
WHERE tm.nombre_tema = 'Fuentes'
  AND NOT EXISTS (
      SELECT 1 FROM meta.decision_modelado d
      WHERE d.tema = 'Trazabilidad de fuentes'
        AND d.pregunta = '¿Cada dato turístico debe tener fuente?'
  );


INSERT INTO meta.decision_modelado (
    id_tema, tema, pregunta, decision, justificacion, ejemplo,
    id_esquema_recomendado, id_tabla_recomendada, alternativa,
    responsable, fecha_decision, id_version_desde, estado, observaciones
)
SELECT
    tm.id_tema,
    'Alcance de destinos turísticos',
    '¿Qué tipo de dato entra en destino_turistico?',
    'Solo lugares físicos o territoriales que funcionen como atractivos turísticos.',
    'La tabla destino_turistico representa lugares; eventos, personas, instituciones o estadísticas no deben mezclarse allí.',
    'Antigua Guatemala sí entra; Semana Santa como evento no entra directamente.',
    e.id_esquema,
    t.id_tabla,
    'Usar tablas especializadas para eventos, festividades o estadísticas si se agregan en futuras versiones.',
    'Equipo SS2-CONOSE-OCCIDENTE',
    CURRENT_DATE,
    v.id_version,
    'VIGENTE',
    'Decisión documentada para orientar el crecimiento del modelo de datos.'
FROM meta.tema_datos tm
JOIN meta.version_proyecto v ON v.numero_version = '1.0'
LEFT JOIN meta.esquema_datos e ON e.nombre_esquema = 'turismo'
LEFT JOIN meta.tabla_datos t ON t.id_esquema = e.id_esquema AND t.nombre_tabla = 'destino_turistico'
WHERE tm.nombre_tema = 'Turismo'
  AND NOT EXISTS (
      SELECT 1 FROM meta.decision_modelado d
      WHERE d.tema = 'Alcance de destinos turísticos'
        AND d.pregunta = '¿Qué tipo de dato entra en destino_turistico?'
  );


COMMIT;
-- ============================================================
-- insertar catalogo real de turismo
-- ============================================================
-- ============================================================

INSERT INTO turismo.fuente_turistica (codigo, nombre, institucion, tipo, url, fecha_consulta, descripcion) VALUES
('GUATEMALA_CVB_REGIONES', 'Regiones de Guatemala', 'Buró de Convenciones de Guatemala', 'turismo', 'https://guatemalacvb.com/regiones-de-guatemala/', '2026-07-06'::date, 'Fuente base para las siete regiones turísticas de Guatemala, sus departamentos asociados y descripciones generales de atractivos por región.')
ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, institucion=EXCLUDED.institucion, tipo=EXCLUDED.tipo, url=EXCLUDED.url, fecha_consulta=EXCLUDED.fecha_consulta, descripcion=EXCLUDED.descripcion;

INSERT INTO turismo.fuente_turistica (codigo, nombre, institucion, tipo, url, fecha_consulta, descripcion) VALUES
('UNESCO_GUATEMALA', 'Guatemala - World Heritage', 'UNESCO World Heritage Centre', 'internacional', 'https://whc.unesco.org/en/statesparties/gt', '2026-07-06'::date, 'Página general de Guatemala en UNESCO World Heritage Centre; lista las propiedades inscritas del país.')
ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, institucion=EXCLUDED.institucion, tipo=EXCLUDED.tipo, url=EXCLUDED.url, fecha_consulta=EXCLUDED.fecha_consulta, descripcion=EXCLUDED.descripcion;

INSERT INTO turismo.fuente_turistica (codigo, nombre, institucion, tipo, url, fecha_consulta, descripcion) VALUES
('UNESCO_ANTIGUA', 'Antigua Guatemala', 'UNESCO World Heritage Centre', 'internacional', 'https://whc.unesco.org/en/list/65/', '2026-07-06'::date, 'Ficha oficial UNESCO del sitio Antigua Guatemala, inscrito como Patrimonio Mundial cultural.')
ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, institucion=EXCLUDED.institucion, tipo=EXCLUDED.tipo, url=EXCLUDED.url, fecha_consulta=EXCLUDED.fecha_consulta, descripcion=EXCLUDED.descripcion;

INSERT INTO turismo.fuente_turistica (codigo, nombre, institucion, tipo, url, fecha_consulta, descripcion) VALUES
('UNESCO_TIKAL', 'Tikal National Park', 'UNESCO World Heritage Centre', 'internacional', 'https://whc.unesco.org/en/list/64/', '2026-07-06'::date, 'Ficha oficial UNESCO del Parque Nacional Tikal, propiedad de Patrimonio Mundial mixto cultural y natural.')
ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, institucion=EXCLUDED.institucion, tipo=EXCLUDED.tipo, url=EXCLUDED.url, fecha_consulta=EXCLUDED.fecha_consulta, descripcion=EXCLUDED.descripcion;

INSERT INTO turismo.fuente_turistica (codigo, nombre, institucion, tipo, url, fecha_consulta, descripcion) VALUES
('UNESCO_QUIRIGUA', 'Archaeological Park and Ruins of Quirigua', 'UNESCO World Heritage Centre', 'internacional', 'https://whc.unesco.org/en/list/149/', '2026-07-06'::date, 'Ficha oficial UNESCO del Parque Arqueológico y Ruinas de Quiriguá, Patrimonio Mundial cultural.')
ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, institucion=EXCLUDED.institucion, tipo=EXCLUDED.tipo, url=EXCLUDED.url, fecha_consulta=EXCLUDED.fecha_consulta, descripcion=EXCLUDED.descripcion;

INSERT INTO turismo.fuente_turistica (codigo, nombre, institucion, tipo, url, fecha_consulta, descripcion) VALUES
('UNESCO_TAKALIK_ABAJ', 'National Archaeological Park Tak’alik Ab’aj', 'UNESCO World Heritage Centre', 'internacional', 'https://whc.unesco.org/en/list/1663/', '2026-07-06'::date, 'Ficha oficial UNESCO del Parque Arqueológico Nacional Tak’alik Ab’aj, inscrito como Patrimonio Mundial cultural en 2023.')
ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, institucion=EXCLUDED.institucion, tipo=EXCLUDED.tipo, url=EXCLUDED.url, fecha_consulta=EXCLUDED.fecha_consulta, descripcion=EXCLUDED.descripcion;

INSERT INTO turismo.fuente_turistica (codigo, nombre, institucion, tipo, url, fecha_consulta, descripcion) VALUES
('UNESCO_RABINAL_ACHI', 'Rabinal Achí dance drama tradition', 'UNESCO Intangible Cultural Heritage', 'internacional', 'https://ich.unesco.org/en/RL/rabinal-achi-dance-drama-tradition-00144', '2026-07-06'::date, 'Ficha UNESCO de Patrimonio Cultural Inmaterial relacionada con la tradición Rabinal Achí.')
ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, institucion=EXCLUDED.institucion, tipo=EXCLUDED.tipo, url=EXCLUDED.url, fecha_consulta=EXCLUDED.fecha_consulta, descripcion=EXCLUDED.descripcion;

INSERT INTO turismo.fuente_turistica (codigo, nombre, institucion, tipo, url, fecha_consulta, descripcion) VALUES
('CONAP_GENERAL', 'Consejo Nacional de Áreas Protegidas - CONAP', 'Consejo Nacional de Áreas Protegidas', 'conservacion', 'https://conap.gob.gt/', '2026-07-06'::date, 'Fuente institucional general sobre áreas protegidas, conservación y SIGAP en Guatemala.')
ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, institucion=EXCLUDED.institucion, tipo=EXCLUDED.tipo, url=EXCLUDED.url, fecha_consulta=EXCLUDED.fecha_consulta, descripcion=EXCLUDED.descripcion;

INSERT INTO turismo.fuente_turistica (codigo, nombre, institucion, tipo, url, fecha_consulta, descripcion) VALUES
('CONAP_SIGAP_GENERAL', 'Turismo SIGAP', 'Consejo Nacional de Áreas Protegidas', 'conservacion', 'https://turismo-sigap.conap.gob.gt/', '2026-07-06'::date, 'Portal turístico del SIGAP utilizado como referencia general para áreas protegidas con uso turístico.')
ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, institucion=EXCLUDED.institucion, tipo=EXCLUDED.tipo, url=EXCLUDED.url, fecha_consulta=EXCLUDED.fecha_consulta, descripcion=EXCLUDED.descripcion;

INSERT INTO turismo.fuente_turistica (codigo, nombre, institucion, tipo, url, fecha_consulta, descripcion) VALUES
('CONAP_SIGAP_PACAYA', 'Parque Nacional Volcán Pacaya y Laguna de Calderas', 'Consejo Nacional de Áreas Protegidas / Turismo SIGAP', 'conservacion', 'https://turismo-sigap.conap.gob.gt/en/rutas-turisticas/ruta-de-montanas-y-playas-boca-costa-pacifico/parque-nacional-volcan-pacaya-y-laguna-de-calderas/', '2026-07-06'::date, 'Ficha específica de Turismo SIGAP para el Parque Nacional Volcán Pacaya y Laguna de Calderas.')
ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, institucion=EXCLUDED.institucion, tipo=EXCLUDED.tipo, url=EXCLUDED.url, fecha_consulta=EXCLUDED.fecha_consulta, descripcion=EXCLUDED.descripcion;

INSERT INTO turismo.fuente_turistica (codigo, nombre, institucion, tipo, url, fecha_consulta, descripcion) VALUES
('SIC_GENERAL', 'Sistema de Información Cultural de Guatemala', 'Ministerio de Cultura y Deportes', 'cultural', 'https://www.sicultura.gob.gt/', '2026-07-06'::date, 'Directorio cultural utilizado como fuente general para sitios culturales, museos y patrimonio.')
ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, institucion=EXCLUDED.institucion, tipo=EXCLUDED.tipo, url=EXCLUDED.url, fecha_consulta=EXCLUDED.fecha_consulta, descripcion=EXCLUDED.descripcion;

INSERT INTO turismo.fuente_turistica (codigo, nombre, institucion, tipo, url, fecha_consulta, descripcion) VALUES
('SIC_TIKAL', 'Parque Nacional Tikal, Corazón del Mundo Maya', 'Sistema de Información Cultural / Ministerio de Cultura y Deportes', 'cultural', 'https://www.sicultura.gob.gt/directory-directorio_c/listing/parque-nacional-tikal-corazon-del-mundo-maya/', '2026-07-06'::date, 'Ficha específica de SICultura para Parque Nacional Tikal; utilizada como fuente complementaria de descripción, ubicación, horarios y tarifas.')
ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, institucion=EXCLUDED.institucion, tipo=EXCLUDED.tipo, url=EXCLUDED.url, fecha_consulta=EXCLUDED.fecha_consulta, descripcion=EXCLUDED.descripcion;

INSERT INTO turismo.fuente_turistica (codigo, nombre, institucion, tipo, url, fecha_consulta, descripcion) VALUES
('MUNIGUATE_TURISMO', 'Turismo MuniGuate', 'Municipalidad de Guatemala', 'municipal', 'https://turismo.muniguate.com/', '2026-07-06'::date, 'Portal municipal utilizado para atractivos urbanos de la Ciudad de Guatemala.')
ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, institucion=EXCLUDED.institucion, tipo=EXCLUDED.tipo, url=EXCLUDED.url, fecha_consulta=EXCLUDED.fecha_consulta, descripcion=EXCLUDED.descripcion;

INSERT INTO turismo.fuente_turistica (codigo, nombre, institucion, tipo, url, fecha_consulta, descripcion) VALUES
('INGUAT_GENERAL', 'Instituto Guatemalteco de Turismo - INGUAT', 'Instituto Guatemalteco de Turismo', 'turismo', 'https://inguat.gob.gt/', '2026-07-06'::date, 'Fuente institucional general de turismo; no se usa como fuente principal masiva de destinos por posibles restricciones de acceso.')
ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, institucion=EXCLUDED.institucion, tipo=EXCLUDED.tipo, url=EXCLUDED.url, fecha_consulta=EXCLUDED.fecha_consulta, descripcion=EXCLUDED.descripcion;

INSERT INTO turismo.fuente_turistica (codigo, nombre, institucion, tipo, url, fecha_consulta, descripcion) VALUES
('IRTRA_GENERAL', 'Instituto de Recreación de los Trabajadores - IRTRA', 'IRTRA', 'recreativo', 'https://irtra.org.gt/', '2026-07-06'::date, 'Fuente institucional para parques recreativos IRTRA, incluyendo Xetulul y Xocomil como parte de su oferta de parques.')
ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, institucion=EXCLUDED.institucion, tipo=EXCLUDED.tipo, url=EXCLUDED.url, fecha_consulta=EXCLUDED.fecha_consulta, descripcion=EXCLUDED.descripcion;

INSERT INTO turismo.fuente_turistica (codigo, nombre, institucion, tipo, url, fecha_consulta, descripcion) VALUES
('ZOO_LA_AURORA_OFICIAL', 'Zoológico La Aurora', 'Zoológico La Aurora', 'recreativo', 'https://www.aurorazoo.org.gt/', '2026-07-06'::date, 'Sitio oficial del Zoológico La Aurora; fuente para destino recreativo urbano y servicios de visita.')
ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, institucion=EXCLUDED.institucion, tipo=EXCLUDED.tipo, url=EXCLUDED.url, fecha_consulta=EXCLUDED.fecha_consulta, descripcion=EXCLUDED.descripcion;

INSERT INTO turismo.fuente_turistica (codigo, nombre, institucion, tipo, url, fecha_consulta, descripcion) VALUES
('MUSEO_MIRAFLORES_OFICIAL', 'Museo Miraflores Guatemala', 'Museo Miraflores', 'cultural', 'https://www.museomiraflores.org.gt/', '2026-07-06'::date, 'Sitio oficial del Museo Miraflores; fuente para el destino cultural vinculado con Kaminaljuyú.')
ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, institucion=EXCLUDED.institucion, tipo=EXCLUDED.tipo, url=EXCLUDED.url, fecha_consulta=EXCLUDED.fecha_consulta, descripcion=EXCLUDED.descripcion;

INSERT INTO turismo.fuente_turistica (codigo, nombre, institucion, tipo, url, fecha_consulta, descripcion) VALUES
('HOBBITENANGO_OFICIAL', 'Hobbitenango', 'Hobbitenango', 'recreativo', 'https://hobbitenango.com/', '2026-07-06'::date, 'Sitio del operador turístico Hobbitenango; se usa únicamente para identificar el atractivo recreativo privado.')
ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, institucion=EXCLUDED.institucion, tipo=EXCLUDED.tipo, url=EXCLUDED.url, fecha_consulta=EXCLUDED.fecha_consulta, descripcion=EXCLUDED.descripcion;

INSERT INTO turismo.region_turistica (id_region, codigo, nombre, descripcion, fuente_id) VALUES (1, 'GUATEMALA_MODERNA_COLONIAL', 'GUATEMALA, Moderna y Colonial', 'Región turística integrada principalmente por Guatemala y Sacatepéquez; destaca la Ciudad de Guatemala, Antigua Guatemala, servicios urbanos, patrimonio colonial, eventos y turismo cultural.', (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES')) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion, fuente_id=EXCLUDED.fuente_id;
INSERT INTO turismo.region_turistica (id_region, codigo, nombre, descripcion, fuente_id) VALUES (2, 'ALTIPLANO_CULTURA_MAYA_VIVA', 'ALTIPLANO, Cultura Maya Viva', 'Región del altiplano con cultura maya viva, mercados, pueblos, volcanes, lagos, artesanías, turismo comunitario y paisaje montañoso.', (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES')) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion, fuente_id=EXCLUDED.fuente_id;
INSERT INTO turismo.region_turistica (id_region, codigo, nombre, descripcion, fuente_id) VALUES (3, 'PETEN_MUNDO_MAYA', 'PETÉN, Aventura en el Mundo Maya', 'Región asociada con la selva maya, sitios arqueológicos monumentales, aventura, ecoturismo, observación de aves y reservas naturales.', (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES')) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion, fuente_id=EXCLUDED.fuente_id;
INSERT INTO turismo.region_turistica (id_region, codigo, nombre, descripcion, fuente_id) VALUES (4, 'IZABAL_CARIBE_VERDE', 'IZABAL, Un Caribe Verde', 'Región caribeña vinculada con Río Dulce, Lago de Izabal, Livingston, Castillo de San Felipe y Quiriguá.', (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES')) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion, fuente_id=EXCLUDED.fuente_id;
INSERT INTO turismo.region_turistica (id_region, codigo, nombre, descripcion, fuente_id) VALUES (5, 'VERAPACES_PARAISO_NATURAL', 'LAS VERAPACES, Paraíso Natural', 'Región de Alta Verapaz y Baja Verapaz con bosques nubosos, cuevas, ríos, Semuc Champey, Biotopo del Quetzal y cultura local.', (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES')) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion, fuente_id=EXCLUDED.fuente_id;
INSERT INTO turismo.region_turistica (id_region, codigo, nombre, descripcion, fuente_id) VALUES (6, 'PACIFICO_MAGICO_DIVERSO', 'PACÍFICO, Mágico y Diverso', 'Región de costa, playas de arena volcánica, manglares, pesca deportiva, parques recreativos, volcanes y sitios arqueológicos del sur.', (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES')) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion, fuente_id=EXCLUDED.fuente_id;
INSERT INTO turismo.region_turistica (id_region, codigo, nombre, descripcion, fuente_id) VALUES (7, 'ORIENTE_MISTICO_NATURAL', 'ORIENTE, Místico y Natural', 'Región cálida de peregrinaje, paleontología, montañas, Sierra de las Minas, volcanes, lagunas y tradición religiosa.', (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES')) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion, fuente_id=EXCLUDED.fuente_id;

INSERT INTO turismo.departamento_region_turistica (region_turistica_id, departamento_id, observacion) VALUES (1, turismo.fn_departamento_id('Guatemala'), 'Departamento incluido por la fuente en la región Guatemala, Moderna y Colonial.') ON CONFLICT (region_turistica_id, departamento_id) DO UPDATE SET observacion=EXCLUDED.observacion;
INSERT INTO turismo.departamento_region_turistica (region_turistica_id, departamento_id, observacion) VALUES (1, turismo.fn_departamento_id('Sacatepéquez'), 'Departamento incluido por la fuente en la región Guatemala, Moderna y Colonial.') ON CONFLICT (region_turistica_id, departamento_id) DO UPDATE SET observacion=EXCLUDED.observacion;
INSERT INTO turismo.departamento_region_turistica (region_turistica_id, departamento_id, observacion) VALUES (2, turismo.fn_departamento_id('Huehuetenango'), 'Departamento incluido por la fuente en Altiplano, Cultura Maya Viva.') ON CONFLICT (region_turistica_id, departamento_id) DO UPDATE SET observacion=EXCLUDED.observacion;
INSERT INTO turismo.departamento_region_turistica (region_turistica_id, departamento_id, observacion) VALUES (2, turismo.fn_departamento_id('Quiché'), 'Departamento incluido por la fuente en Altiplano, Cultura Maya Viva.') ON CONFLICT (region_turistica_id, departamento_id) DO UPDATE SET observacion=EXCLUDED.observacion;
INSERT INTO turismo.departamento_region_turistica (region_turistica_id, departamento_id, observacion) VALUES (2, turismo.fn_departamento_id('Chimaltenango'), 'Departamento incluido por la fuente en Altiplano, Cultura Maya Viva.') ON CONFLICT (region_turistica_id, departamento_id) DO UPDATE SET observacion=EXCLUDED.observacion;
INSERT INTO turismo.departamento_region_turistica (region_turistica_id, departamento_id, observacion) VALUES (2, turismo.fn_departamento_id('Totonicapán'), 'Departamento incluido por la fuente en Altiplano, Cultura Maya Viva.') ON CONFLICT (region_turistica_id, departamento_id) DO UPDATE SET observacion=EXCLUDED.observacion;
INSERT INTO turismo.departamento_region_turistica (region_turistica_id, departamento_id, observacion) VALUES (2, turismo.fn_departamento_id('Sololá'), 'Departamento incluido por la fuente en Altiplano, Cultura Maya Viva.') ON CONFLICT (region_turistica_id, departamento_id) DO UPDATE SET observacion=EXCLUDED.observacion;
INSERT INTO turismo.departamento_region_turistica (region_turistica_id, departamento_id, observacion) VALUES (2, turismo.fn_departamento_id('San Marcos'), 'La fuente ubica la parte norte de San Marcos en Altiplano; también se asocia parcialmente con Pacífico.') ON CONFLICT (region_turistica_id, departamento_id) DO UPDATE SET observacion=EXCLUDED.observacion;
INSERT INTO turismo.departamento_region_turistica (region_turistica_id, departamento_id, observacion) VALUES (3, turismo.fn_departamento_id('Petén'), 'Departamento asociado a la región Petén, Aventura en el Mundo Maya.') ON CONFLICT (region_turistica_id, departamento_id) DO UPDATE SET observacion=EXCLUDED.observacion;
INSERT INTO turismo.departamento_region_turistica (region_turistica_id, departamento_id, observacion) VALUES (4, turismo.fn_departamento_id('Izabal'), 'Departamento asociado a la región Izabal, Un Caribe Verde.') ON CONFLICT (region_turistica_id, departamento_id) DO UPDATE SET observacion=EXCLUDED.observacion;
INSERT INTO turismo.departamento_region_turistica (region_turistica_id, departamento_id, observacion) VALUES (5, turismo.fn_departamento_id('Alta Verapaz'), 'Departamento asociado a Las Verapaces.') ON CONFLICT (region_turistica_id, departamento_id) DO UPDATE SET observacion=EXCLUDED.observacion;
INSERT INTO turismo.departamento_region_turistica (region_turistica_id, departamento_id, observacion) VALUES (5, turismo.fn_departamento_id('Baja Verapaz'), 'Departamento asociado a Las Verapaces.') ON CONFLICT (region_turistica_id, departamento_id) DO UPDATE SET observacion=EXCLUDED.observacion;
INSERT INTO turismo.departamento_region_turistica (region_turistica_id, departamento_id, observacion) VALUES (6, turismo.fn_departamento_id('San Marcos'), 'La fuente asocia la parte sur de San Marcos con Pacífico; por eso aparece también en Altiplano.') ON CONFLICT (region_turistica_id, departamento_id) DO UPDATE SET observacion=EXCLUDED.observacion;
INSERT INTO turismo.departamento_region_turistica (region_turistica_id, departamento_id, observacion) VALUES (6, turismo.fn_departamento_id('Retalhuleu'), 'Departamento asociado a Pacífico, Mágico y Diverso.') ON CONFLICT (region_turistica_id, departamento_id) DO UPDATE SET observacion=EXCLUDED.observacion;
INSERT INTO turismo.departamento_region_turistica (region_turistica_id, departamento_id, observacion) VALUES (6, turismo.fn_departamento_id('Suchitepéquez'), 'Departamento asociado a Pacífico, Mágico y Diverso.') ON CONFLICT (region_turistica_id, departamento_id) DO UPDATE SET observacion=EXCLUDED.observacion;
INSERT INTO turismo.departamento_region_turistica (region_turistica_id, departamento_id, observacion) VALUES (6, turismo.fn_departamento_id('Escuintla'), 'Departamento asociado a Pacífico, Mágico y Diverso.') ON CONFLICT (region_turistica_id, departamento_id) DO UPDATE SET observacion=EXCLUDED.observacion;
INSERT INTO turismo.departamento_region_turistica (region_turistica_id, departamento_id, observacion) VALUES (6, turismo.fn_departamento_id('Santa Rosa'), 'Departamento asociado a Pacífico, Mágico y Diverso.') ON CONFLICT (region_turistica_id, departamento_id) DO UPDATE SET observacion=EXCLUDED.observacion;
INSERT INTO turismo.departamento_region_turistica (region_turistica_id, departamento_id, observacion) VALUES (6, turismo.fn_departamento_id('Jutiapa'), 'La fuente asocia la parte sur de Jutiapa con Pacífico; también aparece parcialmente en Oriente.') ON CONFLICT (region_turistica_id, departamento_id) DO UPDATE SET observacion=EXCLUDED.observacion;
INSERT INTO turismo.departamento_region_turistica (region_turistica_id, departamento_id, observacion) VALUES (7, turismo.fn_departamento_id('El Progreso'), 'Departamento asociado a Oriente, Místico y Natural.') ON CONFLICT (region_turistica_id, departamento_id) DO UPDATE SET observacion=EXCLUDED.observacion;
INSERT INTO turismo.departamento_region_turistica (region_turistica_id, departamento_id, observacion) VALUES (7, turismo.fn_departamento_id('Chiquimula'), 'Departamento asociado a Oriente, Místico y Natural.') ON CONFLICT (region_turistica_id, departamento_id) DO UPDATE SET observacion=EXCLUDED.observacion;
INSERT INTO turismo.departamento_region_turistica (region_turistica_id, departamento_id, observacion) VALUES (7, turismo.fn_departamento_id('Jalapa'), 'Departamento asociado a Oriente, Místico y Natural.') ON CONFLICT (region_turistica_id, departamento_id) DO UPDATE SET observacion=EXCLUDED.observacion;
INSERT INTO turismo.departamento_region_turistica (region_turistica_id, departamento_id, observacion) VALUES (7, turismo.fn_departamento_id('Zacapa'), 'Departamento asociado a Oriente, Místico y Natural.') ON CONFLICT (region_turistica_id, departamento_id) DO UPDATE SET observacion=EXCLUDED.observacion;
INSERT INTO turismo.departamento_region_turistica (region_turistica_id, departamento_id, observacion) VALUES (7, turismo.fn_departamento_id('Jutiapa'), 'La fuente asocia la parte norte de Jutiapa con Oriente; también aparece parcialmente en Pacífico.') ON CONFLICT (region_turistica_id, departamento_id) DO UPDATE SET observacion=EXCLUDED.observacion;

INSERT INTO turismo.categoria_destino (id_categoria, codigo, nombre, descripcion) VALUES (1, 'ARQUEOLOGIA', 'Arqueología', 'Sitios arqueológicos prehispánicos, parques arqueológicos, estelas, acrópolis y ciudades mayas.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.categoria_destino (id_categoria, codigo, nombre, descripcion) VALUES (2, 'PATRIMONIO_UNESCO', 'Patrimonio UNESCO', 'Destinos o expresiones vinculadas con listas de Patrimonio Mundial o Patrimonio Cultural Inmaterial.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.categoria_destino (id_categoria, codigo, nombre, descripcion) VALUES (3, 'COLONIAL', 'Arquitectura colonial', 'Ciudades, templos, conventos, plazas y conjuntos urbanos coloniales.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.categoria_destino (id_categoria, codigo, nombre, descripcion) VALUES (4, 'NATURALEZA', 'Naturaleza', 'Atractivos naturales como lagos, ríos, bosques, montañas, cascadas, cuevas y paisajes.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.categoria_destino (id_categoria, codigo, nombre, descripcion) VALUES (5, 'AREA_PROTEGIDA', 'Área protegida', 'Destinos dentro o vinculados al Sistema Guatemalteco de Áreas Protegidas.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.categoria_destino (id_categoria, codigo, nombre, descripcion) VALUES (6, 'AVENTURA', 'Aventura', 'Destinos que permiten senderismo, ascenso, exploración, canopy, navegación u otras actividades de aventura.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.categoria_destino (id_categoria, codigo, nombre, descripcion) VALUES (7, 'PLAYA', 'Playa y costa', 'Playas, costas, manglares, litoral del Pacífico o Caribe y actividades marinas.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.categoria_destino (id_categoria, codigo, nombre, descripcion) VALUES (8, 'VOLCAN', 'Volcanes', 'Volcanes activos o inactivos, miradores volcánicos y rutas de ascenso.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.categoria_destino (id_categoria, codigo, nombre, descripcion) VALUES (9, 'LAGO_RIO', 'Lagos y ríos', 'Lagos, lagunas, ríos navegables, pozas y cuerpos de agua con valor turístico.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.categoria_destino (id_categoria, codigo, nombre, descripcion) VALUES (10, 'TURISMO_COMUNITARIO', 'Turismo comunitario', 'Destinos donde destaca convivencia comunitaria, cultura local, textiles, talleres o experiencias rurales.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.categoria_destino (id_categoria, codigo, nombre, descripcion) VALUES (11, 'RELIGIOSO', 'Turismo religioso', 'Basílicas, templos, peregrinajes, celebraciones religiosas y tradición espiritual.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.categoria_destino (id_categoria, codigo, nombre, descripcion) VALUES (12, 'URBANO', 'Turismo urbano', 'Centros históricos, museos, plazas, zoológicos, servicios, gastronomía y oferta urbana.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.categoria_destino (id_categoria, codigo, nombre, descripcion) VALUES (13, 'MUSEO', 'Museos', 'Museos, centros de interpretación y espacios de exhibición patrimonial.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.categoria_destino (id_categoria, codigo, nombre, descripcion) VALUES (14, 'GASTRONOMIA', 'Gastronomía', 'Destinos donde la comida local o mercados tienen valor turístico.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.categoria_destino (id_categoria, codigo, nombre, descripcion) VALUES (15, 'ARTESANIA', 'Artesanía', 'Mercados, textiles, cerámica, talleres, productos artesanales y cultura material.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.categoria_destino (id_categoria, codigo, nombre, descripcion) VALUES (16, 'OBSERVACION_AVES', 'Observación de aves', 'Destinos apropiados para observación de aves o biodiversidad.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.categoria_destino (id_categoria, codigo, nombre, descripcion) VALUES (17, 'FAMILIAR', 'Turismo familiar', 'Parques recreativos, zoológicos, museos y destinos de visita familiar.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.categoria_destino (id_categoria, codigo, nombre, descripcion) VALUES (18, 'CULTURA_VIVA', 'Cultura viva', 'Manifestaciones culturales, pueblos vivos, trajes, idiomas, tradiciones y fiestas.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;

INSERT INTO turismo.actividad_turistica (id_actividad, codigo, nombre, descripcion) VALUES (1, 'CAMINATA', 'Caminata', 'Recorridos a pie en áreas urbanas, naturales o culturales.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.actividad_turistica (id_actividad, codigo, nombre, descripcion) VALUES (2, 'SENDERISMO', 'Senderismo', 'Caminatas de mayor esfuerzo en volcanes, montañas, bosques o senderos.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.actividad_turistica (id_actividad, codigo, nombre, descripcion) VALUES (3, 'FOTOGRAFIA', 'Fotografía', 'Registro visual de arquitectura, paisaje, naturaleza, cultura o patrimonio.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.actividad_turistica (id_actividad, codigo, nombre, descripcion) VALUES (4, 'OBSERVACION_AVES', 'Observación de aves', 'Actividad de observación de avifauna en áreas naturales o protegidas.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.actividad_turistica (id_actividad, codigo, nombre, descripcion) VALUES (5, 'NAVEGACION', 'Navegación', 'Paseos en lancha, recorrido en río, lago o costa.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.actividad_turistica (id_actividad, codigo, nombre, descripcion) VALUES (6, 'NATACION', 'Natación', 'Uso recreativo de pozas, playas o cuerpos de agua donde sea permitido.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.actividad_turistica (id_actividad, codigo, nombre, descripcion) VALUES (7, 'ARQUEOLOGIA', 'Recorrido arqueológico', 'Visita guiada o interpretativa a sitios arqueológicos.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.actividad_turistica (id_actividad, codigo, nombre, descripcion) VALUES (8, 'MUSEOS', 'Visita a museos', 'Visita a museos y centros de interpretación.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.actividad_turistica (id_actividad, codigo, nombre, descripcion) VALUES (9, 'COMPRAS_ARTESANIA', 'Compra de artesanías', 'Compra o apreciación de textiles, cerámica, madera, joyería u otros productos locales.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.actividad_turistica (id_actividad, codigo, nombre, descripcion) VALUES (10, 'GASTRONOMIA', 'Gastronomía local', 'Degustación de comida local, mercados o restaurantes tradicionales.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.actividad_turistica (id_actividad, codigo, nombre, descripcion) VALUES (11, 'PEREGRINAJE', 'Peregrinaje', 'Visita religiosa o devocional.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.actividad_turistica (id_actividad, codigo, nombre, descripcion) VALUES (12, 'CAMPING', 'Camping', 'Pernocta en áreas naturales o rutas de montaña donde esté permitido.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.actividad_turistica (id_actividad, codigo, nombre, descripcion) VALUES (13, 'ASCENSO_VOLCAN', 'Ascenso a volcán', 'Ascenso a volcanes o miradores volcánicos.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.actividad_turistica (id_actividad, codigo, nombre, descripcion) VALUES (14, 'SURF', 'Surf', 'Actividad en playas aptas para surf.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.actividad_turistica (id_actividad, codigo, nombre, descripcion) VALUES (15, 'PESCA_DEPORTIVA', 'Pesca deportiva', 'Actividad recreativa vinculada a pesca deportiva.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.actividad_turistica (id_actividad, codigo, nombre, descripcion) VALUES (16, 'TURISMO_COMUNITARIO', 'Turismo comunitario', 'Participación en experiencias comunitarias y rurales.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.actividad_turistica (id_actividad, codigo, nombre, descripcion) VALUES (17, 'RELAX_TERMAL', 'Aguas termales', 'Visita a aguas termales o espacios de relajación.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.actividad_turistica (id_actividad, codigo, nombre, descripcion) VALUES (18, 'EDUCACION_AMBIENTAL', 'Educación ambiental', 'Actividades de aprendizaje sobre conservación, biodiversidad o áreas protegidas.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.actividad_turistica (id_actividad, codigo, nombre, descripcion) VALUES (19, 'CULTURA_VIVA', 'Cultura viva', 'Participación o apreciación de tradiciones, mercados, idiomas, trajes y prácticas culturales.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.actividad_turistica (id_actividad, codigo, nombre, descripcion) VALUES (20, 'AVENTURA_EXTREMA', 'Aventura extrema', 'Actividades de mayor riesgo o esfuerzo físico como exploración, canopy o trekking largo.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, descripcion=EXCLUDED.descripcion;

INSERT INTO turismo.temporada_turistica (id_temporada, codigo, nombre, meses, descripcion) VALUES (1, 'SECA', 'Temporada seca', 'noviembre-abril', 'Periodo generalmente más favorable para caminatas, volcanes, arqueología y recorridos por carretera.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, meses=EXCLUDED.meses, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.temporada_turistica (id_temporada, codigo, nombre, meses, descripcion) VALUES (2, 'LLUVIOSA', 'Temporada lluviosa', 'mayo-octubre', 'Periodo con paisajes verdes y mayor caudal de ríos, pero requiere prever lluvia y estado de caminos.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, meses=EXCLUDED.meses, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.temporada_turistica (id_temporada, codigo, nombre, meses, descripcion) VALUES (3, 'SEMANA_SANTA', 'Semana Santa', 'marzo-abril', 'Periodo de alta afluencia turística y tradición religiosa, especialmente en Antigua Guatemala y centros históricos.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, meses=EXCLUDED.meses, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.temporada_turistica (id_temporada, codigo, nombre, meses, descripcion) VALUES (4, 'FIN_DE_ANIO', 'Fin de año', 'noviembre-enero', 'Periodo de vacaciones, festividades, clima fresco en altiplano y mayor demanda de hospedaje.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, meses=EXCLUDED.meses, descripcion=EXCLUDED.descripcion;
INSERT INTO turismo.temporada_turistica (id_temporada, codigo, nombre, meses, descripcion) VALUES (5, 'TODO_EL_ANIO', 'Todo el año', 'enero-diciembre', 'Destino visitable durante todo el año, sujeto a condiciones locales y clima.') ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, meses=EXCLUDED.meses, descripcion=EXCLUDED.descripcion;

-- Destinos turisticos
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (1, 'ANTIGUA_GUATEMALA', 'Antigua Guatemala', 'CULTURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Sacatepéquez'), turismo.fn_municipio_id('Sacatepéquez', 'Antigua Guatemala', FALSE), 'Ciudad colonial ubicada en el valle de Panchoy, reconocida por su arquitectura, ruinas, iglesias, plazas, tradiciones religiosas y valor patrimonial.', 'Centro histórico de Antigua Guatemala', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, '1 a 2 días', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='UNESCO_ANTIGUA'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (2, 'PARQUE_NACIONAL_TIKAL', 'Parque Nacional Tikal', 'MIXTO'::turismo.tipo_destino, turismo.fn_departamento_id('Petén'), turismo.fn_municipio_id('Petén', 'Flores', FALSE), 'Uno de los principales sitios de la civilización maya, rodeado de selva y reconocido por templos, plazas ceremoniales, biodiversidad y patrimonio mixto UNESCO.', 'Parque Nacional Tikal, Reserva de la Biosfera Maya', NULL, NULL, NULL, 'MEDIA'::turismo.dificultad_destino, '1 día completo', NULL, NULL, NULL, TRUE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='UNESCO_TIKAL'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (3, 'YAXHA', 'Parque Nacional Yaxhá-Nakum-Naranjo', 'ARQUEOLOGICO'::turismo.tipo_destino, turismo.fn_departamento_id('Petén'), turismo.fn_municipio_id('Petén', 'Flores', FALSE), 'Conjunto arqueológico maya rodeado por lagunas y bosque tropical, importante para arqueología, naturaleza y observación de aves.', 'Área protegida Yaxhá-Nakum-Naranjo', NULL, NULL, NULL, 'MEDIA'::turismo.dificultad_destino, '1 día', NULL, NULL, NULL, TRUE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='CONAP_GENERAL'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (4, 'EL_MIRADOR', 'Sitio arqueológico El Mirador', 'ARQUEOLOGICO'::turismo.tipo_destino, turismo.fn_departamento_id('Petén'), turismo.fn_municipio_id('Petén', 'San Andrés', FALSE), 'Ciudad maya preclásica en la selva de Petén, visitada mediante expediciones de varios días por su localización remota.', 'Reserva de la Biosfera Maya, norte de Petén', NULL, NULL, NULL, 'ALTA'::turismo.dificultad_destino, '5 a 6 días', NULL, NULL, NULL, TRUE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='CONAP_GENERAL'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (5, 'UAXACTUN', 'Uaxactún', 'ARQUEOLOGICO'::turismo.tipo_destino, turismo.fn_departamento_id('Petén'), turismo.fn_municipio_id('Petén', 'Flores', FALSE), 'Sitio arqueológico y comunidad vinculada con astronomía maya, bosque y cultura local en Petén.', 'Comunidad de Uaxactún, Petén', NULL, NULL, NULL, 'MEDIA'::turismo.dificultad_destino, 'medio día a 1 día', NULL, NULL, NULL, TRUE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (6, 'LAGO_ATITLAN', 'Lago de Atitlán', 'NATURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Sololá'), turismo.fn_municipio_id('Sololá', 'Panajachel', FALSE), 'Lago rodeado por volcanes y pueblos mayas, reconocido por su paisaje, navegación, cultura viva, artesanías y turismo comunitario.', 'Cuenca del Lago de Atitlán', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, '1 a 3 días', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (7, 'PANAJACHEL', 'Panajachel', 'URBANO'::turismo.tipo_destino, turismo.fn_departamento_id('Sololá'), turismo.fn_municipio_id('Sololá', 'Panajachel', FALSE), 'Principal punto de acceso turístico al Lago de Atitlán, con embarcaderos, comercio, hospedaje, gastronomía y vistas panorámicas.', 'Ribera norte del Lago de Atitlán', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, 'medio día a 1 día', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (8, 'SAN_JUAN_LA_LAGUNA', 'San Juan La Laguna', 'CULTURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Sololá'), turismo.fn_municipio_id('Sololá', 'San Juan La Laguna', FALSE), 'Pueblo del Lago de Atitlán reconocido por murales, cooperativas textiles, arte local, turismo comunitario y cultura tz’utujil.', 'Ribera occidental del Lago de Atitlán', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, 'medio día', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (9, 'CHICHICASTENANGO', 'Chichicastenango', 'CULTURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Quiché'), turismo.fn_municipio_id('Quiché', 'Chichicastenango', FALSE), 'Municipio conocido por su mercado, iglesia de Santo Tomás, tradiciones mayas, textiles, artesanías y sincretismo religioso.', 'Centro de Chichicastenango', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, 'medio día a 1 día', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (10, 'IXIMCHE', 'Iximché', 'ARQUEOLOGICO'::turismo.tipo_destino, turismo.fn_departamento_id('Chimaltenango'), turismo.fn_municipio_id('Chimaltenango', 'Tecpán Guatemala', FALSE), 'Sitio arqueológico kaqchikel con plazas, estructuras ceremoniales y valor histórico en el altiplano guatemalteco.', 'Tecpán Guatemala, Chimaltenango', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, 'medio día', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='SIC_GENERAL'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (11, 'QUIRIGUA', 'Parque Arqueológico Quiriguá', 'ARQUEOLOGICO'::turismo.tipo_destino, turismo.fn_departamento_id('Izabal'), turismo.fn_municipio_id('Izabal', 'Los Amates', FALSE), 'Parque arqueológico maya reconocido por sus estelas monumentales y esculturas, inscrito como Patrimonio Mundial UNESCO.', 'Los Amates, Izabal', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, 'medio día', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='UNESCO_QUIRIGUA'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (12, 'RIO_DULCE', 'Río Dulce', 'NATURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Izabal'), turismo.fn_municipio_id('Izabal', 'Livingston', FALSE), 'Corredor fluvial y lacustre que conecta el Lago de Izabal con el Caribe, usado para navegación, naturaleza y conexión hacia Livingston.', 'Río Dulce - Lago de Izabal - Livingston', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, '1 día', NULL, NULL, NULL, TRUE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (13, 'CASTILLO_SAN_FELIPE', 'Castillo de San Felipe de Lara', 'CULTURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Izabal'), turismo.fn_municipio_id('Izabal', 'Livingston', FALSE), 'Fortaleza histórica ubicada en la entrada del Río Dulce, asociada con la defensa colonial y turismo familiar.', 'Entrada del Río Dulce, Izabal', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, '2 a 3 horas', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (14, 'LIVINGSTON', 'Livingston', 'CULTURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Izabal'), turismo.fn_municipio_id('Izabal', 'Livingston', FALSE), 'Población caribeña con cultura garífuna, gastronomía, acceso marítimo, playa, río y diversidad cultural.', 'Costa Caribe de Izabal', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, '1 a 2 días', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (15, 'SEMUC_CHAMPEY', 'Semuc Champey', 'NATURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Alta Verapaz'), turismo.fn_municipio_id('Alta Verapaz', 'Lanquín', FALSE), 'Monumento natural de pozas escalonadas de agua turquesa sobre un puente natural de piedra caliza, rodeado de bosque tropical.', 'Lanquín, Alta Verapaz', NULL, NULL, NULL, 'MEDIA'::turismo.dificultad_destino, '1 día', NULL, NULL, NULL, TRUE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='CONAP_GENERAL'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (16, 'CUEVAS_CANDELARIA_AV', 'Cuevas de Candelaria', 'NATURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Alta Verapaz'), turismo.fn_municipio_id('Alta Verapaz', 'Chisec', FALSE), 'Sistema de cuevas y ríos subterráneos asociado con naturaleza, aventura y valor cultural en Alta Verapaz.', 'Chisec, Alta Verapaz', NULL, NULL, NULL, 'MEDIA'::turismo.dificultad_destino, 'medio día a 1 día', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (17, 'BIOTOPO_QUETZAL', 'Biotopo del Quetzal Mario Dary Rivera', 'NATURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Baja Verapaz'), turismo.fn_municipio_id('Baja Verapaz', 'Purulhá', FALSE), 'Área protegida de bosque nuboso creada para conservación del quetzal y biodiversidad, con senderos y educación ambiental.', 'Purulhá, Baja Verapaz', NULL, NULL, NULL, 'MEDIA'::turismo.dificultad_destino, 'medio día', NULL, NULL, NULL, TRUE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='CONAP_GENERAL'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (18, 'COBAN', 'Cobán', 'URBANO'::turismo.tipo_destino, turismo.fn_departamento_id('Alta Verapaz'), turismo.fn_municipio_id('Alta Verapaz', 'Cobán', FALSE), 'Centro urbano de Alta Verapaz, punto base para visitar cuevas, orquídeas, café, bosques y atractivos naturales cercanos.', 'Cabecera departamental de Alta Verapaz', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, 'medio día a 1 día', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (19, 'ESQUIPULAS', 'Esquipulas', 'RELIGIOSO'::turismo.tipo_destino, turismo.fn_departamento_id('Chiquimula'), turismo.fn_municipio_id('Chiquimula', 'Esquipulas', FALSE), 'Municipio reconocido por peregrinación religiosa, servicios turísticos y la Basílica del Cristo Negro.', 'Esquipulas, Chiquimula', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, '1 día', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (20, 'BASILICA_ESQUIPULAS', 'Basílica del Cristo Negro de Esquipulas', 'RELIGIOSO'::turismo.tipo_destino, turismo.fn_departamento_id('Chiquimula'), turismo.fn_municipio_id('Chiquimula', 'Esquipulas', FALSE), 'Templo de peregrinación católica de relevancia regional, asociado al Cristo Negro de Esquipulas.', 'Centro de Esquipulas', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, '2 a 4 horas', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (21, 'VOLCAN_PACAYA', 'Volcán de Pacaya', 'NATURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Escuintla'), turismo.fn_municipio_id('Escuintla', 'San Vicente Pacaya', FALSE), 'Volcán activo y parque nacional cercano a la ciudad, popular para senderismo, paisajes volcánicos y observación geológica.', 'San Vicente Pacaya, Escuintla', NULL, NULL, NULL, 'MEDIA'::turismo.dificultad_destino, 'medio día', NULL, NULL, NULL, TRUE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='CONAP_SIGAP_PACAYA'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (22, 'MONTERRICO', 'Monterrico', 'NATURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Santa Rosa'), turismo.fn_municipio_id('Santa Rosa', 'Taxisco', FALSE), 'Playa del Pacífico con arena volcánica, manglares cercanos y actividades vinculadas a descanso, naturaleza y tortugarios.', 'Costa del Pacífico, Taxisco', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, '1 a 2 días', NULL, NULL, NULL, TRUE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (23, 'SIPACATE_NARANJO', 'Parque Nacional Sipacate-Naranjo', 'NATURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Escuintla'), turismo.fn_municipio_id('Escuintla', 'Sipacate', FALSE), 'Área costera de manglar, playa y humedales del Pacífico con importancia para conservación y recreación.', 'Sipacate, Escuintla', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, '1 día', NULL, NULL, NULL, TRUE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='CONAP_GENERAL'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (24, 'TAKALIK_ABAJ', 'Parque Arqueológico Nacional Tak’alik Ab’aj', 'ARQUEOLOGICO'::turismo.tipo_destino, turismo.fn_departamento_id('Retalhuleu'), turismo.fn_municipio_id('Retalhuleu', 'El Asintal', FALSE), 'Sitio arqueológico con larga ocupación y transición olmeca-maya, inscrito como Patrimonio Mundial UNESCO en 2023.', 'El Asintal, Retalhuleu', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, 'medio día', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='UNESCO_TAKALIK_ABAJ'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (25, 'XETULUL_XOCOMIL', 'Parques Xetulul y Xocomil', 'RECREATIVO'::turismo.tipo_destino, turismo.fn_departamento_id('Retalhuleu'), turismo.fn_municipio_id('Retalhuleu', 'San Martín Zapotitlán', FALSE), 'Complejo recreativo y familiar con parque temático, juegos mecánicos y parque acuático en Retalhuleu.', 'San Martín Zapotitlán, Retalhuleu', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, '1 día', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='IRTRA_GENERAL'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (26, 'PUERTO_SAN_JOSE', 'Puerto San José', 'NATURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Escuintla'), turismo.fn_municipio_id('Escuintla', 'San José', FALSE), 'Destino costero del Pacífico asociado con playa, pesca, descanso y conectividad hacia otros atractivos del litoral.', 'Costa del Pacífico, Escuintla', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, '1 día', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (27, 'PLAYA_TILAPA', 'Playa Tilapa', 'NATURAL'::turismo.tipo_destino, turismo.fn_departamento_id('San Marcos'), turismo.fn_municipio_id('San Marcos', 'Ocós', FALSE), 'Playa y comunidad costera del Pacífico en San Marcos, vinculada con descanso, pesca y paisaje costero.', 'Ocós, San Marcos', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, '1 día', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (28, 'FUENTES_GEORGINAS', 'Fuentes Georginas', 'NATURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Quetzaltenango'), turismo.fn_municipio_id('Quetzaltenango', 'Zunil', FALSE), 'Aguas termales ubicadas entre montañas y bosque nuboso, visitadas por relajación y paisaje natural.', 'Zunil, Quetzaltenango', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, 'medio día', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (29, 'QUETZALTENANGO_CENTRO', 'Centro Histórico de Quetzaltenango', 'URBANO'::turismo.tipo_destino, turismo.fn_departamento_id('Quetzaltenango'), turismo.fn_municipio_id('Quetzaltenango', 'Quetzaltenango', FALSE), 'Centro urbano del occidente con arquitectura, parques, museos, gastronomía, cultura y servicios turísticos.', 'Centro de Quetzaltenango', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, 'medio día a 1 día', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (30, 'VOLCAN_TAJUMULCO', 'Volcán Tajumulco', 'NATURAL'::turismo.tipo_destino, turismo.fn_departamento_id('San Marcos'), turismo.fn_municipio_id('San Marcos', 'Tajumulco', FALSE), 'Volcán más alto de Guatemala y Centroamérica, destino de montañismo y senderismo de alta montaña.', 'Tajumulco, San Marcos', NULL, NULL, NULL, 'ALTA'::turismo.dificultad_destino, '1 a 2 días', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (31, 'LAGUNA_BRAVA', 'Laguna Brava', 'NATURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Huehuetenango'), turismo.fn_municipio_id('Huehuetenango', 'Nentón', FALSE), 'Laguna de color turquesa en Huehuetenango, visitada por naturaleza, caminata, fotografía y paisaje.', 'Nentón, Huehuetenango', NULL, NULL, NULL, 'MEDIA'::turismo.dificultad_destino, '1 día', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (32, 'CENOTES_CANDELARIA_HUEHUE', 'Cenotes de Candelaria', 'NATURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Huehuetenango'), turismo.fn_municipio_id('Huehuetenango', 'Nentón', FALSE), 'Conjunto de cenotes de agua azul en Nentón, asociados con paisaje kárstico y turismo natural.', 'Nentón, Huehuetenango', NULL, NULL, NULL, 'MEDIA'::turismo.dificultad_destino, '1 día', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (33, 'TODOS_SANTOS_CUCHUMATAN', 'Todos Santos Cuchumatán', 'CULTURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Huehuetenango'), turismo.fn_municipio_id('Huehuetenango', 'Todos Santos Cuchumatán', FALSE), 'Municipio de los Cuchumatanes reconocido por cultura mam, trajes tradicionales, mercado y tradiciones locales.', 'Sierra de los Cuchumatanes', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, '1 día', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (34, 'NEBAJ', 'Nebaj', 'CULTURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Quiché'), turismo.fn_municipio_id('Quiché', 'Nebaj', FALSE), 'Pueblo del área ixil con cultura viva, textiles, paisaje montañoso y rutas de turismo comunitario.', 'Área Ixil, Quiché', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, '1 día', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (35, 'MUNAE', 'Museo Nacional de Arqueología y Etnología', 'CULTURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Guatemala'), turismo.fn_municipio_id('Guatemala', 'Guatemala', FALSE), 'Museo de referencia para colecciones arqueológicas y etnológicas de Guatemala, ubicado en la zona 13 de la Ciudad de Guatemala.', 'Zona 13, Ciudad de Guatemala', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, '2 a 3 horas', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='SIC_GENERAL'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (36, 'KAMINALJUYU', 'Kaminaljuyú', 'ARQUEOLOGICO'::turismo.tipo_destino, turismo.fn_departamento_id('Guatemala'), turismo.fn_municipio_id('Guatemala', 'Guatemala', FALSE), 'Sitio arqueológico prehispánico ubicado dentro del área metropolitana de Guatemala, vinculado con la historia maya del altiplano central.', 'Zona 7, Ciudad de Guatemala', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, '1 a 2 horas', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='SIC_GENERAL'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (37, 'ZOO_LA_AURORA', 'Zoológico La Aurora', 'RECREATIVO'::turismo.tipo_destino, turismo.fn_departamento_id('Guatemala'), turismo.fn_municipio_id('Guatemala', 'Guatemala', FALSE), 'Zoológico urbano de la Ciudad de Guatemala, destino familiar y educativo con colecciones de fauna.', 'Zona 13, Ciudad de Guatemala', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, 'medio día', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='ZOO_LA_AURORA_OFICIAL'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (38, 'CENTRO_HISTORICO_GUATEMALA', 'Centro Histórico de la Ciudad de Guatemala', 'URBANO'::turismo.tipo_destino, turismo.fn_departamento_id('Guatemala'), turismo.fn_municipio_id('Guatemala', 'Guatemala', FALSE), 'Centro urbano con plazas, edificios históricos, Catedral, Palacio Nacional, mercados y actividades culturales.', 'Zona 1, Ciudad de Guatemala', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, 'medio día', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='MUNIGUATE_TURISMO'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (39, 'MIXCO_VIEJO', 'Mixco Viejo', 'ARQUEOLOGICO'::turismo.tipo_destino, turismo.fn_departamento_id('Chimaltenango'), turismo.fn_municipio_id('Chimaltenango', 'San Martín Jilotepeque', FALSE), 'Sitio arqueológico fortificado asociado al periodo posclásico, con vistas y estructuras ceremoniales.', 'San Martín Jilotepeque, Chimaltenango', NULL, NULL, NULL, 'MEDIA'::turismo.dificultad_destino, 'medio día', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='SIC_GENERAL'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (40, 'VOLCAN_ACATENANGO', 'Volcán Acatenango', 'NATURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Chimaltenango'), turismo.fn_municipio_id('Chimaltenango', 'Acatenango', FALSE), 'Volcán de alta montaña visitado por senderismo y campamento, con vistas al Volcán de Fuego.', 'Acatenango, Chimaltenango', NULL, NULL, NULL, 'ALTA'::turismo.dificultad_destino, '1 a 2 días', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (41, 'VOLCAN_AGUA', 'Volcán de Agua', 'NATURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Sacatepéquez'), turismo.fn_municipio_id('Sacatepéquez', 'Santa María de Jesús', FALSE), 'Volcán emblemático cercano a Antigua Guatemala, visible desde el valle de Panchoy y asociado a rutas de ascenso.', 'Santa María de Jesús, Sacatepéquez', NULL, NULL, NULL, 'ALTA'::turismo.dificultad_destino, '1 día', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (42, 'HOBBITENANGO', 'Hobbitenango', 'RECREATIVO'::turismo.tipo_destino, turismo.fn_departamento_id('Sacatepéquez'), turismo.fn_municipio_id('Sacatepéquez', 'Antigua Guatemala', FALSE), 'Parque temático y mirador en las montañas de Antigua Guatemala, popular por fotografía, vistas y actividades familiares.', 'Aldea El Hato, Antigua Guatemala', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, 'medio día', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='HOBBITENANGO_OFICIAL'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (43, 'MUSEO_MIRAFLORES', 'Museo Miraflores', 'CULTURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Guatemala'), turismo.fn_municipio_id('Guatemala', 'Guatemala', FALSE), 'Museo y centro cultural dedicado al patrimonio arqueológico de Kaminaljuyú y la historia prehispánica del valle de Guatemala.', 'Zona 11, Ciudad de Guatemala', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, '2 horas', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='MUSEO_MIRAFLORES_OFICIAL'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (44, 'SIERRA_MINAS', 'Reserva de Biosfera Sierra de las Minas', 'NATURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Zacapa'), turismo.fn_municipio_id('Zacapa', 'Río Hondo', FALSE), 'Área montañosa de alto valor ecológico compartida por varios departamentos, importante para conservación, biodiversidad y recursos hídricos.', 'Sierra de las Minas, oriente de Guatemala', NULL, NULL, NULL, 'ALTA'::turismo.dificultad_destino, '1 a 2 días', NULL, NULL, NULL, TRUE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (45, 'MUSEO_PALEONTOLOGIA_ESTANZUELA', 'Museo de Paleontología y Arqueología de Estanzuela', 'CULTURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Zacapa'), turismo.fn_municipio_id('Zacapa', 'Estanzuela', FALSE), 'Museo reconocido por fósiles, piezas paleontológicas y arqueológicas del oriente de Guatemala.', 'Estanzuela, Zacapa', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, '1 a 2 horas', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (46, 'VOLCAN_LAGUNA_IPALA', 'Volcán y Laguna de Ipala', 'NATURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Chiquimula'), turismo.fn_municipio_id('Chiquimula', 'Ipala', FALSE), 'Volcán con laguna en el cráter, atractivo para senderismo, naturaleza, fotografía y recreación.', 'Ipala, Chiquimula', NULL, NULL, NULL, 'MEDIA'::turismo.dificultad_destino, 'medio día a 1 día', NULL, NULL, NULL, TRUE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='CONAP_GENERAL'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (47, 'LAGO_GUIJA', 'Lago de Güija', 'NATURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Jutiapa'), turismo.fn_municipio_id('Jutiapa', 'Asunción Mita', FALSE), 'Lago fronterizo compartido con El Salvador, asociado con paisaje, pesca, naturaleza y patrimonio regional.', 'Asunción Mita, Jutiapa', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, 'medio día', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (48, 'VOLCAN_SUCHITAN', 'Volcán Suchitán', 'NATURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Jutiapa'), turismo.fn_municipio_id('Jutiapa', 'Santa Catarina Mita', FALSE), 'Volcán del oriente de Guatemala con rutas de senderismo, naturaleza y vistas panorámicas.', 'Santa Catarina Mita, Jutiapa', NULL, NULL, NULL, 'MEDIA'::turismo.dificultad_destino, 'medio día a 1 día', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (49, 'PLAYA_BLANCA_IZABAL', 'Playa Blanca', 'NATURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Izabal'), turismo.fn_municipio_id('Izabal', 'Livingston', FALSE), 'Playa de arena clara del Caribe guatemalteco, accesible principalmente por vía acuática desde Livingston o Río Dulce.', 'Costa Caribe de Izabal', NULL, NULL, NULL, 'BAJA'::turismo.dificultad_destino, 'medio día', NULL, NULL, NULL, FALSE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;
INSERT INTO turismo.destino_turistico (id_destino, codigo, nombre, tipo, departamento_id, municipio_id, descripcion, direccion_referencia, latitud, longitud, altitud_msnm, dificultad, tiempo_recomendado, costo_aprox_nacional_q, costo_aprox_extranjero_q, horario, es_area_protegida, fuente_principal_id, activo) VALUES (50, 'LAGUNA_LACHUA', 'Laguna Lachuá', 'NATURAL'::turismo.tipo_destino, turismo.fn_departamento_id('Alta Verapaz'), turismo.fn_municipio_id('Alta Verapaz', 'Cobán', FALSE), 'Laguna circular de aguas claras ubicada dentro del Parque Nacional Laguna Lachuá, área protegida de alto valor natural.', 'Parque Nacional Laguna Lachuá, Cobán', NULL, NULL, NULL, 'MEDIA'::turismo.dificultad_destino, '1 día', NULL, NULL, NULL, TRUE, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='CONAP_GENERAL'), TRUE) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, tipo=EXCLUDED.tipo, departamento_id=EXCLUDED.departamento_id, municipio_id=EXCLUDED.municipio_id, descripcion=EXCLUDED.descripcion, direccion_referencia=EXCLUDED.direccion_referencia, latitud=EXCLUDED.latitud, longitud=EXCLUDED.longitud, altitud_msnm=EXCLUDED.altitud_msnm, dificultad=EXCLUDED.dificultad, tiempo_recomendado=EXCLUDED.tiempo_recomendado, costo_aprox_nacional_q=EXCLUDED.costo_aprox_nacional_q, costo_aprox_extranjero_q=EXCLUDED.costo_aprox_extranjero_q, horario=EXCLUDED.horario, es_area_protegida=EXCLUDED.es_area_protegida, fuente_principal_id=EXCLUDED.fuente_principal_id, activo=EXCLUDED.activo;

-- Region turistica principal por destino; evita duplicidad en departamentos compartidos entre regiones turisticas.
UPDATE turismo.destino_turistico SET region_turistica_id = 1 WHERE codigo IN ('ANTIGUA_GUATEMALA','MUNAE','KAMINALJUYU','ZOO_LA_AURORA','CENTRO_HISTORICO_GUATEMALA','HOBBITENANGO','MUSEO_MIRAFLORES','VOLCAN_AGUA');
UPDATE turismo.destino_turistico SET region_turistica_id = 2 WHERE codigo IN ('LAGO_ATITLAN','PANAJACHEL','SAN_JUAN_LA_LAGUNA','CHICHICASTENANGO','IXIMCHE','FUENTES_GEORGINAS','QUETZALTENANGO_CENTRO','VOLCAN_TAJUMULCO','LAGUNA_BRAVA','CENOTES_CANDELARIA_HUEHUE','TODOS_SANTOS_CUCHUMATAN','NEBAJ','MIXCO_VIEJO','VOLCAN_ACATENANGO');
UPDATE turismo.destino_turistico SET region_turistica_id = 3 WHERE codigo IN ('PARQUE_NACIONAL_TIKAL','YAXHA','EL_MIRADOR','UAXACTUN');
UPDATE turismo.destino_turistico SET region_turistica_id = 4 WHERE codigo IN ('QUIRIGUA','RIO_DULCE','CASTILLO_SAN_FELIPE','LIVINGSTON','PLAYA_BLANCA_IZABAL');
UPDATE turismo.destino_turistico SET region_turistica_id = 5 WHERE codigo IN ('SEMUC_CHAMPEY','CUEVAS_CANDELARIA_AV','BIOTOPO_QUETZAL','COBAN','LAGUNA_LACHUA');
UPDATE turismo.destino_turistico SET region_turistica_id = 6 WHERE codigo IN ('VOLCAN_PACAYA','MONTERRICO','SIPACATE_NARANJO','TAKALIK_ABAJ','XETULUL_XOCOMIL','PUERTO_SAN_JOSE','PLAYA_TILAPA');
UPDATE turismo.destino_turistico SET region_turistica_id = 7 WHERE codigo IN ('ESQUIPULAS','BASILICA_ESQUIPULAS','SIERRA_MINAS','MUSEO_PALEONTOLOGIA_ESTANZUELA','VOLCAN_LAGUNA_IPALA','LAGO_GUIJA','VOLCAN_SUCHITAN');

-- Relaciones destino-categoria
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='ANTIGUA_GUATEMALA' AND c.codigo='PATRIMONIO_UNESCO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='ANTIGUA_GUATEMALA' AND c.codigo='COLONIAL' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='ANTIGUA_GUATEMALA' AND c.codigo='CULTURA_VIVA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='ANTIGUA_GUATEMALA' AND c.codigo='URBANO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='PARQUE_NACIONAL_TIKAL' AND c.codigo='PATRIMONIO_UNESCO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='PARQUE_NACIONAL_TIKAL' AND c.codigo='ARQUEOLOGIA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='PARQUE_NACIONAL_TIKAL' AND c.codigo='AREA_PROTEGIDA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='PARQUE_NACIONAL_TIKAL' AND c.codigo='NATURALEZA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='PARQUE_NACIONAL_TIKAL' AND c.codigo='OBSERVACION_AVES' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='YAXHA' AND c.codigo='ARQUEOLOGIA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='YAXHA' AND c.codigo='AREA_PROTEGIDA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='YAXHA' AND c.codigo='NATURALEZA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='YAXHA' AND c.codigo='OBSERVACION_AVES' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='EL_MIRADOR' AND c.codigo='ARQUEOLOGIA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='EL_MIRADOR' AND c.codigo='AREA_PROTEGIDA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='EL_MIRADOR' AND c.codigo='AVENTURA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='EL_MIRADOR' AND c.codigo='NATURALEZA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='UAXACTUN' AND c.codigo='ARQUEOLOGIA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='UAXACTUN' AND c.codigo='NATURALEZA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='UAXACTUN' AND c.codigo='TURISMO_COMUNITARIO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='LAGO_ATITLAN' AND c.codigo='NATURALEZA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='LAGO_ATITLAN' AND c.codigo='LAGO_RIO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='LAGO_ATITLAN' AND c.codigo='CULTURA_VIVA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='LAGO_ATITLAN' AND c.codigo='TURISMO_COMUNITARIO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='PANAJACHEL' AND c.codigo='LAGO_RIO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='PANAJACHEL' AND c.codigo='URBANO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='PANAJACHEL' AND c.codigo='GASTRONOMIA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='PANAJACHEL' AND c.codigo='ARTESANIA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='SAN_JUAN_LA_LAGUNA' AND c.codigo='CULTURA_VIVA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='SAN_JUAN_LA_LAGUNA' AND c.codigo='ARTESANIA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='SAN_JUAN_LA_LAGUNA' AND c.codigo='TURISMO_COMUNITARIO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='SAN_JUAN_LA_LAGUNA' AND c.codigo='LAGO_RIO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='CHICHICASTENANGO' AND c.codigo='CULTURA_VIVA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='CHICHICASTENANGO' AND c.codigo='ARTESANIA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='CHICHICASTENANGO' AND c.codigo='RELIGIOSO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='CHICHICASTENANGO' AND c.codigo='GASTRONOMIA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='IXIMCHE' AND c.codigo='ARQUEOLOGIA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='IXIMCHE' AND c.codigo='CULTURA_VIVA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='QUIRIGUA' AND c.codigo='PATRIMONIO_UNESCO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='QUIRIGUA' AND c.codigo='ARQUEOLOGIA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='RIO_DULCE' AND c.codigo='NATURALEZA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='RIO_DULCE' AND c.codigo='LAGO_RIO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='RIO_DULCE' AND c.codigo='AREA_PROTEGIDA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='CASTILLO_SAN_FELIPE' AND c.codigo='COLONIAL' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='CASTILLO_SAN_FELIPE' AND c.codigo='CULTURA_VIVA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='CASTILLO_SAN_FELIPE' AND c.codigo='FAMILIAR' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='LIVINGSTON' AND c.codigo='CULTURA_VIVA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='LIVINGSTON' AND c.codigo='PLAYA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='LIVINGSTON' AND c.codigo='GASTRONOMIA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='SEMUC_CHAMPEY' AND c.codigo='NATURALEZA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='SEMUC_CHAMPEY' AND c.codigo='AREA_PROTEGIDA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='SEMUC_CHAMPEY' AND c.codigo='LAGO_RIO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='SEMUC_CHAMPEY' AND c.codigo='AVENTURA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='CUEVAS_CANDELARIA_AV' AND c.codigo='NATURALEZA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='CUEVAS_CANDELARIA_AV' AND c.codigo='AVENTURA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='BIOTOPO_QUETZAL' AND c.codigo='AREA_PROTEGIDA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='BIOTOPO_QUETZAL' AND c.codigo='NATURALEZA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='BIOTOPO_QUETZAL' AND c.codigo='OBSERVACION_AVES' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='COBAN' AND c.codigo='URBANO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='COBAN' AND c.codigo='GASTRONOMIA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='COBAN' AND c.codigo='CULTURA_VIVA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='ESQUIPULAS' AND c.codigo='RELIGIOSO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='ESQUIPULAS' AND c.codigo='URBANO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='BASILICA_ESQUIPULAS' AND c.codigo='RELIGIOSO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='BASILICA_ESQUIPULAS' AND c.codigo='CULTURA_VIVA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='VOLCAN_PACAYA' AND c.codigo='VOLCAN' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='VOLCAN_PACAYA' AND c.codigo='AREA_PROTEGIDA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='VOLCAN_PACAYA' AND c.codigo='AVENTURA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='VOLCAN_PACAYA' AND c.codigo='NATURALEZA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='MONTERRICO' AND c.codigo='PLAYA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='MONTERRICO' AND c.codigo='AREA_PROTEGIDA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='MONTERRICO' AND c.codigo='NATURALEZA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='SIPACATE_NARANJO' AND c.codigo='PLAYA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='SIPACATE_NARANJO' AND c.codigo='AREA_PROTEGIDA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='SIPACATE_NARANJO' AND c.codigo='NATURALEZA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='TAKALIK_ABAJ' AND c.codigo='PATRIMONIO_UNESCO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='TAKALIK_ABAJ' AND c.codigo='ARQUEOLOGIA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='XETULUL_XOCOMIL' AND c.codigo='FAMILIAR' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='XETULUL_XOCOMIL' AND c.codigo='AVENTURA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='PUERTO_SAN_JOSE' AND c.codigo='PLAYA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='PUERTO_SAN_JOSE' AND c.codigo='GASTRONOMIA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='PLAYA_TILAPA' AND c.codigo='PLAYA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='PLAYA_TILAPA' AND c.codigo='NATURALEZA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='FUENTES_GEORGINAS' AND c.codigo='NATURALEZA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='FUENTES_GEORGINAS' AND c.codigo='LAGO_RIO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='QUETZALTENANGO_CENTRO' AND c.codigo='URBANO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='QUETZALTENANGO_CENTRO' AND c.codigo='GASTRONOMIA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='QUETZALTENANGO_CENTRO' AND c.codigo='CULTURA_VIVA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='VOLCAN_TAJUMULCO' AND c.codigo='VOLCAN' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='VOLCAN_TAJUMULCO' AND c.codigo='AVENTURA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='VOLCAN_TAJUMULCO' AND c.codigo='NATURALEZA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='LAGUNA_BRAVA' AND c.codigo='NATURALEZA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='LAGUNA_BRAVA' AND c.codigo='LAGO_RIO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='LAGUNA_BRAVA' AND c.codigo='AVENTURA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='CENOTES_CANDELARIA_HUEHUE' AND c.codigo='NATURALEZA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='CENOTES_CANDELARIA_HUEHUE' AND c.codigo='LAGO_RIO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='CENOTES_CANDELARIA_HUEHUE' AND c.codigo='AVENTURA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='TODOS_SANTOS_CUCHUMATAN' AND c.codigo='CULTURA_VIVA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='TODOS_SANTOS_CUCHUMATAN' AND c.codigo='ARTESANIA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='TODOS_SANTOS_CUCHUMATAN' AND c.codigo='TURISMO_COMUNITARIO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='NEBAJ' AND c.codigo='CULTURA_VIVA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='NEBAJ' AND c.codigo='TURISMO_COMUNITARIO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='NEBAJ' AND c.codigo='ARTESANIA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='MUNAE' AND c.codigo='MUSEO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='MUNAE' AND c.codigo='ARQUEOLOGIA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='MUNAE' AND c.codigo='URBANO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='KAMINALJUYU' AND c.codigo='ARQUEOLOGIA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='KAMINALJUYU' AND c.codigo='URBANO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='ZOO_LA_AURORA' AND c.codigo='FAMILIAR' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='ZOO_LA_AURORA' AND c.codigo='URBANO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='ZOO_LA_AURORA' AND c.codigo='NATURALEZA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='CENTRO_HISTORICO_GUATEMALA' AND c.codigo='URBANO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='CENTRO_HISTORICO_GUATEMALA' AND c.codigo='COLONIAL' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='CENTRO_HISTORICO_GUATEMALA' AND c.codigo='GASTRONOMIA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='MIXCO_VIEJO' AND c.codigo='ARQUEOLOGIA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='MIXCO_VIEJO' AND c.codigo='AVENTURA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='VOLCAN_ACATENANGO' AND c.codigo='VOLCAN' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='VOLCAN_ACATENANGO' AND c.codigo='AVENTURA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='VOLCAN_ACATENANGO' AND c.codigo='NATURALEZA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='VOLCAN_AGUA' AND c.codigo='VOLCAN' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='VOLCAN_AGUA' AND c.codigo='AVENTURA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='VOLCAN_AGUA' AND c.codigo='NATURALEZA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='HOBBITENANGO' AND c.codigo='FAMILIAR' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='HOBBITENANGO' AND c.codigo='NATURALEZA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='HOBBITENANGO' AND c.codigo='GASTRONOMIA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='MUSEO_MIRAFLORES' AND c.codigo='MUSEO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='MUSEO_MIRAFLORES' AND c.codigo='ARQUEOLOGIA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='MUSEO_MIRAFLORES' AND c.codigo='URBANO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='SIERRA_MINAS' AND c.codigo='AREA_PROTEGIDA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='SIERRA_MINAS' AND c.codigo='NATURALEZA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='SIERRA_MINAS' AND c.codigo='OBSERVACION_AVES' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='MUSEO_PALEONTOLOGIA_ESTANZUELA' AND c.codigo='MUSEO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='MUSEO_PALEONTOLOGIA_ESTANZUELA' AND c.codigo='URBANO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='VOLCAN_LAGUNA_IPALA' AND c.codigo='VOLCAN' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='VOLCAN_LAGUNA_IPALA' AND c.codigo='LAGO_RIO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='VOLCAN_LAGUNA_IPALA' AND c.codigo='AREA_PROTEGIDA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='VOLCAN_LAGUNA_IPALA' AND c.codigo='NATURALEZA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='LAGO_GUIJA' AND c.codigo='LAGO_RIO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='LAGO_GUIJA' AND c.codigo='NATURALEZA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='VOLCAN_SUCHITAN' AND c.codigo='VOLCAN' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='VOLCAN_SUCHITAN' AND c.codigo='AVENTURA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='VOLCAN_SUCHITAN' AND c.codigo='NATURALEZA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='PLAYA_BLANCA_IZABAL' AND c.codigo='PLAYA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='PLAYA_BLANCA_IZABAL' AND c.codigo='NATURALEZA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='LAGUNA_LACHUA' AND c.codigo='AREA_PROTEGIDA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='LAGUNA_LACHUA' AND c.codigo='NATURALEZA' ON CONFLICT (destino_id, categoria_id) DO NOTHING;
INSERT INTO turismo.destino_categoria (destino_id, categoria_id) SELECT d.id_destino, c.id_categoria FROM turismo.destino_turistico d CROSS JOIN turismo.categoria_destino c WHERE d.codigo='LAGUNA_LACHUA' AND c.codigo='LAGO_RIO' ON CONFLICT (destino_id, categoria_id) DO NOTHING;

-- Relaciones destino-actividad
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='ANTIGUA_GUATEMALA' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='ANTIGUA_GUATEMALA' AND a.codigo='CAMINATA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='ANTIGUA_GUATEMALA' AND a.codigo='CULTURA_VIVA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='ANTIGUA_GUATEMALA' AND a.codigo='GASTRONOMIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='PARQUE_NACIONAL_TIKAL' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='PARQUE_NACIONAL_TIKAL' AND a.codigo='CAMINATA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='PARQUE_NACIONAL_TIKAL' AND a.codigo='ARQUEOLOGIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='PARQUE_NACIONAL_TIKAL' AND a.codigo='EDUCACION_AMBIENTAL' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='PARQUE_NACIONAL_TIKAL' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='PARQUE_NACIONAL_TIKAL' AND a.codigo='OBSERVACION_AVES' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='YAXHA' AND a.codigo='ARQUEOLOGIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='YAXHA' AND a.codigo='CAMINATA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='YAXHA' AND a.codigo='EDUCACION_AMBIENTAL' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='YAXHA' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='YAXHA' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='YAXHA' AND a.codigo='OBSERVACION_AVES' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='EL_MIRADOR' AND a.codigo='ARQUEOLOGIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='EL_MIRADOR' AND a.codigo='CAMINATA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='EL_MIRADOR' AND a.codigo='EDUCACION_AMBIENTAL' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='EL_MIRADOR' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='EL_MIRADOR' AND a.codigo='AVENTURA_EXTREMA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='EL_MIRADOR' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='UAXACTUN' AND a.codigo='ARQUEOLOGIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='UAXACTUN' AND a.codigo='CAMINATA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='UAXACTUN' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='UAXACTUN' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='UAXACTUN' AND a.codigo='EDUCACION_AMBIENTAL' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='UAXACTUN' AND a.codigo='TURISMO_COMUNITARIO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='LAGO_ATITLAN' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='LAGO_ATITLAN' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='LAGO_ATITLAN' AND a.codigo='EDUCACION_AMBIENTAL' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='LAGO_ATITLAN' AND a.codigo='NAVEGACION' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='LAGO_ATITLAN' AND a.codigo='CULTURA_VIVA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='LAGO_ATITLAN' AND a.codigo='TURISMO_COMUNITARIO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='PANAJACHEL' AND a.codigo='NAVEGACION' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='PANAJACHEL' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='PANAJACHEL' AND a.codigo='CAMINATA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='PANAJACHEL' AND a.codigo='GASTRONOMIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='PANAJACHEL' AND a.codigo='COMPRAS_ARTESANIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='SAN_JUAN_LA_LAGUNA' AND a.codigo='CULTURA_VIVA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='SAN_JUAN_LA_LAGUNA' AND a.codigo='COMPRAS_ARTESANIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='SAN_JUAN_LA_LAGUNA' AND a.codigo='TURISMO_COMUNITARIO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='SAN_JUAN_LA_LAGUNA' AND a.codigo='NAVEGACION' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='SAN_JUAN_LA_LAGUNA' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='CHICHICASTENANGO' AND a.codigo='CULTURA_VIVA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='CHICHICASTENANGO' AND a.codigo='COMPRAS_ARTESANIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='CHICHICASTENANGO' AND a.codigo='PEREGRINAJE' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='CHICHICASTENANGO' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='CHICHICASTENANGO' AND a.codigo='GASTRONOMIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='IXIMCHE' AND a.codigo='ARQUEOLOGIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='IXIMCHE' AND a.codigo='CAMINATA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='IXIMCHE' AND a.codigo='CULTURA_VIVA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='QUIRIGUA' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='QUIRIGUA' AND a.codigo='CAMINATA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='QUIRIGUA' AND a.codigo='ARQUEOLOGIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='RIO_DULCE' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='RIO_DULCE' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='RIO_DULCE' AND a.codigo='EDUCACION_AMBIENTAL' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='RIO_DULCE' AND a.codigo='NAVEGACION' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='CASTILLO_SAN_FELIPE' AND a.codigo='CAMINATA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='CASTILLO_SAN_FELIPE' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='CASTILLO_SAN_FELIPE' AND a.codigo='CULTURA_VIVA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='LIVINGSTON' AND a.codigo='CULTURA_VIVA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='LIVINGSTON' AND a.codigo='NATACION' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='LIVINGSTON' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='LIVINGSTON' AND a.codigo='GASTRONOMIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='SEMUC_CHAMPEY' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='SEMUC_CHAMPEY' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='SEMUC_CHAMPEY' AND a.codigo='EDUCACION_AMBIENTAL' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='SEMUC_CHAMPEY' AND a.codigo='NAVEGACION' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='SEMUC_CHAMPEY' AND a.codigo='AVENTURA_EXTREMA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='CUEVAS_CANDELARIA_AV' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='CUEVAS_CANDELARIA_AV' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='CUEVAS_CANDELARIA_AV' AND a.codigo='EDUCACION_AMBIENTAL' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='CUEVAS_CANDELARIA_AV' AND a.codigo='AVENTURA_EXTREMA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='BIOTOPO_QUETZAL' AND a.codigo='EDUCACION_AMBIENTAL' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='BIOTOPO_QUETZAL' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='BIOTOPO_QUETZAL' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='BIOTOPO_QUETZAL' AND a.codigo='OBSERVACION_AVES' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='COBAN' AND a.codigo='CAMINATA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='COBAN' AND a.codigo='GASTRONOMIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='COBAN' AND a.codigo='CULTURA_VIVA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='ESQUIPULAS' AND a.codigo='PEREGRINAJE' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='ESQUIPULAS' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='ESQUIPULAS' AND a.codigo='CAMINATA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='ESQUIPULAS' AND a.codigo='GASTRONOMIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='BASILICA_ESQUIPULAS' AND a.codigo='PEREGRINAJE' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='BASILICA_ESQUIPULAS' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='BASILICA_ESQUIPULAS' AND a.codigo='CULTURA_VIVA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_PACAYA' AND a.codigo='ASCENSO_VOLCAN' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_PACAYA' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_PACAYA' AND a.codigo='EDUCACION_AMBIENTAL' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_PACAYA' AND a.codigo='AVENTURA_EXTREMA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_PACAYA' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='MONTERRICO' AND a.codigo='NATACION' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='MONTERRICO' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='MONTERRICO' AND a.codigo='EDUCACION_AMBIENTAL' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='MONTERRICO' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='SIPACATE_NARANJO' AND a.codigo='NATACION' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='SIPACATE_NARANJO' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='SIPACATE_NARANJO' AND a.codigo='EDUCACION_AMBIENTAL' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='SIPACATE_NARANJO' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='TAKALIK_ABAJ' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='TAKALIK_ABAJ' AND a.codigo='CAMINATA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='TAKALIK_ABAJ' AND a.codigo='ARQUEOLOGIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='XETULUL_XOCOMIL' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='XETULUL_XOCOMIL' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='XETULUL_XOCOMIL' AND a.codigo='AVENTURA_EXTREMA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='PUERTO_SAN_JOSE' AND a.codigo='NATACION' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='PUERTO_SAN_JOSE' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='PUERTO_SAN_JOSE' AND a.codigo='GASTRONOMIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='PLAYA_TILAPA' AND a.codigo='NATACION' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='PLAYA_TILAPA' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='PLAYA_TILAPA' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='PLAYA_TILAPA' AND a.codigo='EDUCACION_AMBIENTAL' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='FUENTES_GEORGINAS' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='FUENTES_GEORGINAS' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='FUENTES_GEORGINAS' AND a.codigo='EDUCACION_AMBIENTAL' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='FUENTES_GEORGINAS' AND a.codigo='NAVEGACION' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='QUETZALTENANGO_CENTRO' AND a.codigo='CAMINATA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='QUETZALTENANGO_CENTRO' AND a.codigo='GASTRONOMIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='QUETZALTENANGO_CENTRO' AND a.codigo='CULTURA_VIVA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_TAJUMULCO' AND a.codigo='ASCENSO_VOLCAN' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_TAJUMULCO' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_TAJUMULCO' AND a.codigo='AVENTURA_EXTREMA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_TAJUMULCO' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_TAJUMULCO' AND a.codigo='EDUCACION_AMBIENTAL' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='LAGUNA_BRAVA' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='LAGUNA_BRAVA' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='LAGUNA_BRAVA' AND a.codigo='EDUCACION_AMBIENTAL' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='LAGUNA_BRAVA' AND a.codigo='NAVEGACION' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='LAGUNA_BRAVA' AND a.codigo='AVENTURA_EXTREMA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='CENOTES_CANDELARIA_HUEHUE' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='CENOTES_CANDELARIA_HUEHUE' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='CENOTES_CANDELARIA_HUEHUE' AND a.codigo='EDUCACION_AMBIENTAL' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='CENOTES_CANDELARIA_HUEHUE' AND a.codigo='NAVEGACION' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='CENOTES_CANDELARIA_HUEHUE' AND a.codigo='AVENTURA_EXTREMA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='TODOS_SANTOS_CUCHUMATAN' AND a.codigo='CULTURA_VIVA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='TODOS_SANTOS_CUCHUMATAN' AND a.codigo='COMPRAS_ARTESANIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='TODOS_SANTOS_CUCHUMATAN' AND a.codigo='TURISMO_COMUNITARIO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='NEBAJ' AND a.codigo='CULTURA_VIVA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='NEBAJ' AND a.codigo='TURISMO_COMUNITARIO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='NEBAJ' AND a.codigo='COMPRAS_ARTESANIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='MUNAE' AND a.codigo='MUSEOS' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='MUNAE' AND a.codigo='ARQUEOLOGIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='MUNAE' AND a.codigo='CAMINATA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='MUNAE' AND a.codigo='GASTRONOMIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='KAMINALJUYU' AND a.codigo='ARQUEOLOGIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='KAMINALJUYU' AND a.codigo='CAMINATA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='KAMINALJUYU' AND a.codigo='GASTRONOMIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='ZOO_LA_AURORA' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='ZOO_LA_AURORA' AND a.codigo='CAMINATA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='ZOO_LA_AURORA' AND a.codigo='GASTRONOMIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='ZOO_LA_AURORA' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='ZOO_LA_AURORA' AND a.codigo='EDUCACION_AMBIENTAL' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='CENTRO_HISTORICO_GUATEMALA' AND a.codigo='CAMINATA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='CENTRO_HISTORICO_GUATEMALA' AND a.codigo='GASTRONOMIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='CENTRO_HISTORICO_GUATEMALA' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='MIXCO_VIEJO' AND a.codigo='ARQUEOLOGIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='MIXCO_VIEJO' AND a.codigo='CAMINATA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='MIXCO_VIEJO' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='MIXCO_VIEJO' AND a.codigo='AVENTURA_EXTREMA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_ACATENANGO' AND a.codigo='ASCENSO_VOLCAN' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_ACATENANGO' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_ACATENANGO' AND a.codigo='AVENTURA_EXTREMA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_ACATENANGO' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_ACATENANGO' AND a.codigo='EDUCACION_AMBIENTAL' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_AGUA' AND a.codigo='ASCENSO_VOLCAN' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_AGUA' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_AGUA' AND a.codigo='AVENTURA_EXTREMA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_AGUA' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_AGUA' AND a.codigo='EDUCACION_AMBIENTAL' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='HOBBITENANGO' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='HOBBITENANGO' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='HOBBITENANGO' AND a.codigo='EDUCACION_AMBIENTAL' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='HOBBITENANGO' AND a.codigo='GASTRONOMIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='MUSEO_MIRAFLORES' AND a.codigo='MUSEOS' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='MUSEO_MIRAFLORES' AND a.codigo='ARQUEOLOGIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='MUSEO_MIRAFLORES' AND a.codigo='CAMINATA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='MUSEO_MIRAFLORES' AND a.codigo='GASTRONOMIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='SIERRA_MINAS' AND a.codigo='EDUCACION_AMBIENTAL' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='SIERRA_MINAS' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='SIERRA_MINAS' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='SIERRA_MINAS' AND a.codigo='OBSERVACION_AVES' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='MUSEO_PALEONTOLOGIA_ESTANZUELA' AND a.codigo='MUSEOS' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='MUSEO_PALEONTOLOGIA_ESTANZUELA' AND a.codigo='CAMINATA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='MUSEO_PALEONTOLOGIA_ESTANZUELA' AND a.codigo='GASTRONOMIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_LAGUNA_IPALA' AND a.codigo='ASCENSO_VOLCAN' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_LAGUNA_IPALA' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_LAGUNA_IPALA' AND a.codigo='NAVEGACION' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_LAGUNA_IPALA' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_LAGUNA_IPALA' AND a.codigo='EDUCACION_AMBIENTAL' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='LAGO_GUIJA' AND a.codigo='NAVEGACION' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='LAGO_GUIJA' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='LAGO_GUIJA' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='LAGO_GUIJA' AND a.codigo='EDUCACION_AMBIENTAL' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_SUCHITAN' AND a.codigo='ASCENSO_VOLCAN' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_SUCHITAN' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_SUCHITAN' AND a.codigo='AVENTURA_EXTREMA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_SUCHITAN' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='VOLCAN_SUCHITAN' AND a.codigo='EDUCACION_AMBIENTAL' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='PLAYA_BLANCA_IZABAL' AND a.codigo='NATACION' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='PLAYA_BLANCA_IZABAL' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='PLAYA_BLANCA_IZABAL' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='PLAYA_BLANCA_IZABAL' AND a.codigo='EDUCACION_AMBIENTAL' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='LAGUNA_LACHUA' AND a.codigo='EDUCACION_AMBIENTAL' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='LAGUNA_LACHUA' AND a.codigo='SENDERISMO' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='LAGUNA_LACHUA' AND a.codigo='FOTOGRAFIA' ON CONFLICT (destino_id, actividad_id) DO NOTHING;
INSERT INTO turismo.destino_actividad (destino_id, actividad_id, notas) SELECT d.id_destino, a.id_actividad, 'Actividad recomendada para el destino según su clasificación turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.actividad_turistica a WHERE d.codigo='LAGUNA_LACHUA' AND a.codigo='NAVEGACION' ON CONFLICT (destino_id, actividad_id) DO NOTHING;

-- Temporadas
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='ANTIGUA_GUATEMALA' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='PARQUE_NACIONAL_TIKAL' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='YAXHA' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='EL_MIRADOR' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='UAXACTUN' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='LAGO_ATITLAN' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='PANAJACHEL' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='SAN_JUAN_LA_LAGUNA' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='CHICHICASTENANGO' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='IXIMCHE' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='QUIRIGUA' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='RIO_DULCE' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='CASTILLO_SAN_FELIPE' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='LIVINGSTON' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='SEMUC_CHAMPEY' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='CUEVAS_CANDELARIA_AV' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='BIOTOPO_QUETZAL' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='COBAN' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='ESQUIPULAS' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='BASILICA_ESQUIPULAS' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='VOLCAN_PACAYA' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='MONTERRICO' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='SIPACATE_NARANJO' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='TAKALIK_ABAJ' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='XETULUL_XOCOMIL' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='PUERTO_SAN_JOSE' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='PLAYA_TILAPA' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='FUENTES_GEORGINAS' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='QUETZALTENANGO_CENTRO' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='VOLCAN_TAJUMULCO' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='LAGUNA_BRAVA' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='CENOTES_CANDELARIA_HUEHUE' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='TODOS_SANTOS_CUCHUMATAN' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='NEBAJ' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='MUNAE' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='KAMINALJUYU' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='ZOO_LA_AURORA' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='CENTRO_HISTORICO_GUATEMALA' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='MIXCO_VIEJO' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='VOLCAN_ACATENANGO' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='VOLCAN_AGUA' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='HOBBITENANGO' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='MUSEO_MIRAFLORES' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='SIERRA_MINAS' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='MUSEO_PALEONTOLOGIA_ESTANZUELA' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='VOLCAN_LAGUNA_IPALA' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='LAGO_GUIJA' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='VOLCAN_SUCHITAN' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='PLAYA_BLANCA_IZABAL' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Destino visitable durante todo el año; validar clima, horarios y condiciones locales antes del viaje.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='LAGUNA_LACHUA' AND t.codigo='TODO_EL_ANIO' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'La temporada seca suele ser preferible para senderismo y ascenso por estabilidad de caminos y visibilidad.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='VOLCAN_ACATENANGO' AND t.codigo='SECA' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'La temporada seca suele ser preferible para senderismo y ascenso por estabilidad de caminos y visibilidad.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='VOLCAN_AGUA' AND t.codigo='SECA' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'La temporada seca suele ser preferible para senderismo y ascenso por estabilidad de caminos y visibilidad.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='VOLCAN_PACAYA' AND t.codigo='SECA' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'La temporada seca suele ser preferible para senderismo y ascenso por estabilidad de caminos y visibilidad.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='VOLCAN_TAJUMULCO' AND t.codigo='SECA' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'La temporada seca suele ser preferible para senderismo y ascenso por estabilidad de caminos y visibilidad.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='VOLCAN_LAGUNA_IPALA' AND t.codigo='SECA' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'La temporada seca suele ser preferible para senderismo y ascenso por estabilidad de caminos y visibilidad.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='VOLCAN_SUCHITAN' AND t.codigo='SECA' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Alta afluencia por actividades religiosas y culturales; reservar hospedaje y transporte con anticipación.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='ANTIGUA_GUATEMALA' AND t.codigo='SEMANA_SANTA' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Alta afluencia por actividades religiosas y culturales; reservar hospedaje y transporte con anticipación.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='CENTRO_HISTORICO_GUATEMALA' AND t.codigo='SEMANA_SANTA' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Alta afluencia por actividades religiosas y culturales; reservar hospedaje y transporte con anticipación.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='BASILICA_ESQUIPULAS' AND t.codigo='SEMANA_SANTA' ON CONFLICT (destino_id, temporada_id) DO NOTHING;
INSERT INTO turismo.destino_temporada (destino_id, temporada_id, recomendacion) SELECT d.id_destino, t.id_temporada, 'Alta afluencia por actividades religiosas y culturales; reservar hospedaje y transporte con anticipación.' FROM turismo.destino_turistico d CROSS JOIN turismo.temporada_turistica t WHERE d.codigo='ESQUIPULAS' AND t.codigo='SEMANA_SANTA' ON CONFLICT (destino_id, temporada_id) DO NOTHING;

-- Fuentes por destino
-- Se relaciona cada destino con fuentes por codigo para evitar depender de IDs físicos.
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente oficial UNESCO utilizada para respaldar el reconocimiento patrimonial del destino.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='ANTIGUA_GUATEMALA' AND f.codigo='UNESCO_ANTIGUA' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria para clasificación por región turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='ANTIGUA_GUATEMALA' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente oficial UNESCO utilizada para respaldar el reconocimiento patrimonial del destino.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='PARQUE_NACIONAL_TIKAL' AND f.codigo='UNESCO_TIKAL' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria para clasificación por región turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='PARQUE_NACIONAL_TIKAL' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente institucional de CONAP/SIGAP utilizada para respaldar la condicion natural o de area protegida.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='YAXHA' AND f.codigo='CONAP_GENERAL' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria para clasificación por región turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='YAXHA' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente institucional de CONAP/SIGAP utilizada para respaldar la condicion natural o de area protegida.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='EL_MIRADOR' AND f.codigo='CONAP_GENERAL' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria para clasificación por región turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='EL_MIRADOR' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='UAXACTUN' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='LAGO_ATITLAN' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='PANAJACHEL' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='SAN_JUAN_LA_LAGUNA' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='CHICHICASTENANGO' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente cultural utilizada para respaldar la naturaleza cultural, arqueologica o museistica del destino.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='IXIMCHE' AND f.codigo='SIC_GENERAL' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria para clasificación por región turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='IXIMCHE' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente oficial UNESCO utilizada para respaldar el reconocimiento patrimonial del destino.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='QUIRIGUA' AND f.codigo='UNESCO_QUIRIGUA' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria para clasificación por región turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='QUIRIGUA' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='RIO_DULCE' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='CASTILLO_SAN_FELIPE' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='LIVINGSTON' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente institucional de CONAP/SIGAP utilizada para respaldar la condicion natural o de area protegida.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='SEMUC_CHAMPEY' AND f.codigo='CONAP_GENERAL' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria para clasificación por región turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='SEMUC_CHAMPEY' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='CUEVAS_CANDELARIA_AV' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente institucional de CONAP/SIGAP utilizada para respaldar la condicion natural o de area protegida.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='BIOTOPO_QUETZAL' AND f.codigo='CONAP_GENERAL' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria para clasificación por región turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='BIOTOPO_QUETZAL' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='COBAN' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='ESQUIPULAS' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='BASILICA_ESQUIPULAS' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente institucional de CONAP/SIGAP utilizada para respaldar la condicion natural o de area protegida.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='VOLCAN_PACAYA' AND f.codigo='CONAP_SIGAP_PACAYA' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria para clasificación por región turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='VOLCAN_PACAYA' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='MONTERRICO' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente institucional de CONAP/SIGAP utilizada para respaldar la condicion natural o de area protegida.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='SIPACATE_NARANJO' AND f.codigo='CONAP_GENERAL' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria para clasificación por región turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='SIPACATE_NARANJO' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente oficial UNESCO utilizada para respaldar el reconocimiento patrimonial del destino.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='TAKALIK_ABAJ' AND f.codigo='UNESCO_TAKALIK_ABAJ' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria para clasificación por región turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='TAKALIK_ABAJ' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente especifica del operador o institucion utilizada para identificar el atractivo turistico.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='XETULUL_XOCOMIL' AND f.codigo='IRTRA_GENERAL' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria para clasificación por región turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='XETULUL_XOCOMIL' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='PUERTO_SAN_JOSE' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='PLAYA_TILAPA' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='FUENTES_GEORGINAS' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='QUETZALTENANGO_CENTRO' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='VOLCAN_TAJUMULCO' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='LAGUNA_BRAVA' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='CENOTES_CANDELARIA_HUEHUE' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='TODOS_SANTOS_CUCHUMATAN' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='NEBAJ' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente cultural utilizada para respaldar la naturaleza cultural, arqueologica o museistica del destino.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='MUNAE' AND f.codigo='SIC_GENERAL' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria para clasificación por región turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='MUNAE' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente cultural utilizada para respaldar la naturaleza cultural, arqueologica o museistica del destino.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='KAMINALJUYU' AND f.codigo='SIC_GENERAL' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria para clasificación por región turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='KAMINALJUYU' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente especifica del operador o institucion utilizada para identificar el atractivo turistico.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='ZOO_LA_AURORA' AND f.codigo='ZOO_LA_AURORA_OFICIAL' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria para clasificación por región turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='ZOO_LA_AURORA' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente especifica del operador o institucion utilizada para identificar el atractivo turistico.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='CENTRO_HISTORICO_GUATEMALA' AND f.codigo='MUNIGUATE_TURISMO' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria para clasificación por región turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='CENTRO_HISTORICO_GUATEMALA' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente cultural utilizada para respaldar la naturaleza cultural, arqueologica o museistica del destino.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='MIXCO_VIEJO' AND f.codigo='SIC_GENERAL' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria para clasificación por región turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='MIXCO_VIEJO' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='VOLCAN_ACATENANGO' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='VOLCAN_AGUA' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente especifica del operador o institucion utilizada para identificar el atractivo turistico.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='HOBBITENANGO' AND f.codigo='HOBBITENANGO_OFICIAL' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria para clasificación por región turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='HOBBITENANGO' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente especifica del operador o institucion utilizada para identificar el atractivo turistico.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='MUSEO_MIRAFLORES' AND f.codigo='MUSEO_MIRAFLORES_OFICIAL' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria para clasificación por región turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='MUSEO_MIRAFLORES' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='SIERRA_MINAS' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='MUSEO_PALEONTOLOGIA_ESTANZUELA' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente institucional de CONAP/SIGAP utilizada para respaldar la condicion natural o de area protegida.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='VOLCAN_LAGUNA_IPALA' AND f.codigo='CONAP_GENERAL' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria para clasificación por región turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='VOLCAN_LAGUNA_IPALA' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='LAGO_GUIJA' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='VOLCAN_SUCHITAN' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente regional utilizada para clasificar el destino dentro de las regiones turisticas de Guatemala.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='PLAYA_BLANCA_IZABAL' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente institucional de CONAP/SIGAP utilizada para respaldar la condicion natural o de area protegida.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='LAGUNA_LACHUA' AND f.codigo='CONAP_GENERAL' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria para clasificación por región turística.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='LAGUNA_LACHUA' AND f.codigo='GUATEMALA_CVB_REGIONES' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria de respaldo documental.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='PARQUE_NACIONAL_TIKAL' AND f.codigo='SIC_TIKAL' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria de respaldo documental.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='PARQUE_NACIONAL_TIKAL' AND f.codigo='UNESCO_GUATEMALA' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria de respaldo documental.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='ANTIGUA_GUATEMALA' AND f.codigo='UNESCO_GUATEMALA' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria de respaldo documental.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='QUIRIGUA' AND f.codigo='UNESCO_GUATEMALA' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria de respaldo documental.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='TAKALIK_ABAJ' AND f.codigo='UNESCO_GUATEMALA' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria de respaldo documental.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='VOLCAN_PACAYA' AND f.codigo='CONAP_SIGAP_GENERAL' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria de respaldo documental.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='YAXHA' AND f.codigo='CONAP_SIGAP_GENERAL' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria de respaldo documental.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='EL_MIRADOR' AND f.codigo='CONAP_SIGAP_GENERAL' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria de respaldo documental.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='SEMUC_CHAMPEY' AND f.codigo='CONAP_SIGAP_GENERAL' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria de respaldo documental.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='BIOTOPO_QUETZAL' AND f.codigo='CONAP_SIGAP_GENERAL' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria de respaldo documental.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='SIPACATE_NARANJO' AND f.codigo='CONAP_SIGAP_GENERAL' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria de respaldo documental.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='VOLCAN_LAGUNA_IPALA' AND f.codigo='CONAP_SIGAP_GENERAL' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;
INSERT INTO turismo.destino_fuente (destino_id, fuente_id, detalle) SELECT d.id_destino, f.id_fuente, 'Fuente complementaria de respaldo documental.' FROM turismo.destino_turistico d CROSS JOIN turismo.fuente_turistica f WHERE d.codigo='LAGUNA_LACHUA' AND f.codigo='CONAP_SIGAP_GENERAL' ON CONFLICT (destino_id, fuente_id) DO UPDATE SET detalle=EXCLUDED.detalle;

-- Patrimonio
INSERT INTO turismo.patrimonio_turistico (id_patrimonio, codigo, tipo, nombre, organismo, anio_inscripcion, descripcion, fuente_id) VALUES (1, 'UNESCO_ANTIGUA', 'UNESCO_CULTURAL'::turismo.tipo_patrimonio, 'Antigua Guatemala', 'UNESCO', 1979, 'Ciudad colonial inscrita como Patrimonio Mundial por su valor urbano, histórico y arquitectónico.', (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='UNESCO_ANTIGUA')) ON CONFLICT (codigo) DO UPDATE SET tipo=EXCLUDED.tipo, nombre=EXCLUDED.nombre, organismo=EXCLUDED.organismo, anio_inscripcion=EXCLUDED.anio_inscripcion, descripcion=EXCLUDED.descripcion, fuente_id=EXCLUDED.fuente_id;
INSERT INTO turismo.patrimonio_turistico (id_patrimonio, codigo, tipo, nombre, organismo, anio_inscripcion, descripcion, fuente_id) VALUES (2, 'UNESCO_TIKAL', 'UNESCO_MIXTO'::turismo.tipo_patrimonio, 'Parque Nacional Tikal', 'UNESCO', 1979, 'Sitio de patrimonio mixto por sus valores culturales mayas y naturales de selva tropical.', (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='UNESCO_TIKAL')) ON CONFLICT (codigo) DO UPDATE SET tipo=EXCLUDED.tipo, nombre=EXCLUDED.nombre, organismo=EXCLUDED.organismo, anio_inscripcion=EXCLUDED.anio_inscripcion, descripcion=EXCLUDED.descripcion, fuente_id=EXCLUDED.fuente_id;
INSERT INTO turismo.patrimonio_turistico (id_patrimonio, codigo, tipo, nombre, organismo, anio_inscripcion, descripcion, fuente_id) VALUES (3, 'UNESCO_QUIRIGUA', 'UNESCO_CULTURAL'::turismo.tipo_patrimonio, 'Parque Arqueológico y Ruinas de Quiriguá', 'UNESCO', 1981, 'Sitio arqueológico maya reconocido por estelas y monumentos tallados.', (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='UNESCO_QUIRIGUA')) ON CONFLICT (codigo) DO UPDATE SET tipo=EXCLUDED.tipo, nombre=EXCLUDED.nombre, organismo=EXCLUDED.organismo, anio_inscripcion=EXCLUDED.anio_inscripcion, descripcion=EXCLUDED.descripcion, fuente_id=EXCLUDED.fuente_id;
INSERT INTO turismo.patrimonio_turistico (id_patrimonio, codigo, tipo, nombre, organismo, anio_inscripcion, descripcion, fuente_id) VALUES (4, 'UNESCO_TAKALIK_ABAJ', 'UNESCO_CULTURAL'::turismo.tipo_patrimonio, 'Parque Arqueológico Nacional Tak’alik Ab’aj', 'UNESCO', 2023, 'Sitio arqueológico vinculado con la transición olmeca-maya e inscrito como Patrimonio Mundial.', (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='UNESCO_TAKALIK_ABAJ')) ON CONFLICT (codigo) DO UPDATE SET tipo=EXCLUDED.tipo, nombre=EXCLUDED.nombre, organismo=EXCLUDED.organismo, anio_inscripcion=EXCLUDED.anio_inscripcion, descripcion=EXCLUDED.descripcion, fuente_id=EXCLUDED.fuente_id;
INSERT INTO turismo.patrimonio_turistico (id_patrimonio, codigo, tipo, nombre, organismo, anio_inscripcion, descripcion, fuente_id) VALUES (5, 'UNESCO_RABINAL_ACHI', 'UNESCO_INTANGIBLE'::turismo.tipo_patrimonio, 'Tradición del teatro bailado Rabinal Achí', 'UNESCO', 2008, 'Patrimonio Cultural Inmaterial asociado con la tradición maya de Rabinal Achí.', (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='UNESCO_RABINAL_ACHI')) ON CONFLICT (codigo) DO UPDATE SET tipo=EXCLUDED.tipo, nombre=EXCLUDED.nombre, organismo=EXCLUDED.organismo, anio_inscripcion=EXCLUDED.anio_inscripcion, descripcion=EXCLUDED.descripcion, fuente_id=EXCLUDED.fuente_id;
INSERT INTO turismo.destino_patrimonio (destino_id, patrimonio_id, observacion) SELECT d.id_destino, p.id_patrimonio, 'Destino asociado directamente con el reconocimiento patrimonial.' FROM turismo.destino_turistico d CROSS JOIN turismo.patrimonio_turistico p WHERE d.codigo='ANTIGUA_GUATEMALA' AND p.codigo='UNESCO_ANTIGUA' ON CONFLICT (destino_id, patrimonio_id) DO NOTHING;
INSERT INTO turismo.destino_patrimonio (destino_id, patrimonio_id, observacion) SELECT d.id_destino, p.id_patrimonio, 'Destino asociado directamente con el reconocimiento patrimonial.' FROM turismo.destino_turistico d CROSS JOIN turismo.patrimonio_turistico p WHERE d.codigo='PARQUE_NACIONAL_TIKAL' AND p.codigo='UNESCO_TIKAL' ON CONFLICT (destino_id, patrimonio_id) DO NOTHING;
INSERT INTO turismo.destino_patrimonio (destino_id, patrimonio_id, observacion) SELECT d.id_destino, p.id_patrimonio, 'Destino asociado directamente con el reconocimiento patrimonial.' FROM turismo.destino_turistico d CROSS JOIN turismo.patrimonio_turistico p WHERE d.codigo='QUIRIGUA' AND p.codigo='UNESCO_QUIRIGUA' ON CONFLICT (destino_id, patrimonio_id) DO NOTHING;
INSERT INTO turismo.destino_patrimonio (destino_id, patrimonio_id, observacion) SELECT d.id_destino, p.id_patrimonio, 'Destino asociado directamente con el reconocimiento patrimonial.' FROM turismo.destino_turistico d CROSS JOIN turismo.patrimonio_turistico p WHERE d.codigo='TAKALIK_ABAJ' AND p.codigo='UNESCO_TAKALIK_ABAJ' ON CONFLICT (destino_id, patrimonio_id) DO NOTHING;

-- Rutas
INSERT INTO turismo.ruta_turistica (id_ruta, codigo, nombre, region_id, descripcion, duracion_dias, fuente_id) VALUES (1, 'RUTA_GUATEMALA_COLONIAL', 'Ruta Guatemala Moderna y Colonial', 1, 'Recorrido urbano y colonial por Ciudad de Guatemala, Antigua Guatemala y miradores cercanos.', 3, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES')) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, region_id=EXCLUDED.region_id, descripcion=EXCLUDED.descripcion, duracion_dias=EXCLUDED.duracion_dias, fuente_id=EXCLUDED.fuente_id;
INSERT INTO turismo.ruta_turistica (id_ruta, codigo, nombre, region_id, descripcion, duracion_dias, fuente_id) VALUES (2, 'RUTA_ALTIPLANO_ATITLAN', 'Ruta Altiplano y Lago de Atitlán', 2, 'Ruta cultural y natural por Chichicastenango, Lago de Atitlán y pueblos mayas vivos.', 4, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES')) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, region_id=EXCLUDED.region_id, descripcion=EXCLUDED.descripcion, duracion_dias=EXCLUDED.duracion_dias, fuente_id=EXCLUDED.fuente_id;
INSERT INTO turismo.ruta_turistica (id_ruta, codigo, nombre, region_id, descripcion, duracion_dias, fuente_id) VALUES (3, 'RUTA_MUNDO_MAYA_PETEN', 'Ruta Mundo Maya en Petén', 3, 'Ruta arqueológica y natural por Tikal, Yaxhá, Uaxactún y otros sitios de Petén.', 4, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES')) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, region_id=EXCLUDED.region_id, descripcion=EXCLUDED.descripcion, duracion_dias=EXCLUDED.duracion_dias, fuente_id=EXCLUDED.fuente_id;
INSERT INTO turismo.ruta_turistica (id_ruta, codigo, nombre, region_id, descripcion, duracion_dias, fuente_id) VALUES (4, 'RUTA_CARIBE_VERDE', 'Ruta Caribe Verde', 4, 'Ruta por Río Dulce, Castillo de San Felipe, Livingston, Playa Blanca y Quiriguá.', 4, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES')) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, region_id=EXCLUDED.region_id, descripcion=EXCLUDED.descripcion, duracion_dias=EXCLUDED.duracion_dias, fuente_id=EXCLUDED.fuente_id;
INSERT INTO turismo.ruta_turistica (id_ruta, codigo, nombre, region_id, descripcion, duracion_dias, fuente_id) VALUES (5, 'RUTA_VERAPACES_NATURAL', 'Ruta Paraíso Natural Verapaces', 5, 'Ruta de naturaleza por Semuc Champey, cuevas, Cobán, Biotopo del Quetzal y Laguna Lachuá.', 4, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES')) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, region_id=EXCLUDED.region_id, descripcion=EXCLUDED.descripcion, duracion_dias=EXCLUDED.duracion_dias, fuente_id=EXCLUDED.fuente_id;
INSERT INTO turismo.ruta_turistica (id_ruta, codigo, nombre, region_id, descripcion, duracion_dias, fuente_id) VALUES (6, 'RUTA_PACIFICO_AVENTURA', 'Ruta Pacífico Mágico y Diverso', 6, 'Ruta de costa, arqueología, parques recreativos y playas del Pacífico.', 4, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES')) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, region_id=EXCLUDED.region_id, descripcion=EXCLUDED.descripcion, duracion_dias=EXCLUDED.duracion_dias, fuente_id=EXCLUDED.fuente_id;
INSERT INTO turismo.ruta_turistica (id_ruta, codigo, nombre, region_id, descripcion, duracion_dias, fuente_id) VALUES (7, 'RUTA_ORIENTE_MISTICO', 'Ruta Oriente Místico y Natural', 7, 'Ruta de peregrinaje, paleontología, montañas, lagunas y naturaleza del oriente.', 3, (SELECT id_fuente FROM turismo.fuente_turistica WHERE codigo='GUATEMALA_CVB_REGIONES')) ON CONFLICT (codigo) DO UPDATE SET nombre=EXCLUDED.nombre, region_id=EXCLUDED.region_id, descripcion=EXCLUDED.descripcion, duracion_dias=EXCLUDED.duracion_dias, fuente_id=EXCLUDED.fuente_id;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 1, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=1 AND d.codigo='CENTRO_HISTORICO_GUATEMALA' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 2, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=1 AND d.codigo='MUNAE' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 3, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=1 AND d.codigo='KAMINALJUYU' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 4, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=1 AND d.codigo='ANTIGUA_GUATEMALA' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 5, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=1 AND d.codigo='HOBBITENANGO' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 1, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=2 AND d.codigo='CHICHICASTENANGO' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 2, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=2 AND d.codigo='LAGO_ATITLAN' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 3, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=2 AND d.codigo='PANAJACHEL' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 4, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=2 AND d.codigo='SAN_JUAN_LA_LAGUNA' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 5, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=2 AND d.codigo='IXIMCHE' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 1, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=3 AND d.codigo='PARQUE_NACIONAL_TIKAL' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 2, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=3 AND d.codigo='UAXACTUN' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 3, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=3 AND d.codigo='YAXHA' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 4, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=3 AND d.codigo='EL_MIRADOR' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 1, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=4 AND d.codigo='RIO_DULCE' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 2, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=4 AND d.codigo='CASTILLO_SAN_FELIPE' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 3, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=4 AND d.codigo='LIVINGSTON' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 4, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=4 AND d.codigo='PLAYA_BLANCA_IZABAL' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 5, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=4 AND d.codigo='QUIRIGUA' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 1, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=5 AND d.codigo='COBAN' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 2, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=5 AND d.codigo='SEMUC_CHAMPEY' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 3, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=5 AND d.codigo='CUEVAS_CANDELARIA_AV' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 4, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=5 AND d.codigo='BIOTOPO_QUETZAL' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 5, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=5 AND d.codigo='LAGUNA_LACHUA' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 1, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=6 AND d.codigo='TAKALIK_ABAJ' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 2, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=6 AND d.codigo='XETULUL_XOCOMIL' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 3, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=6 AND d.codigo='MONTERRICO' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 4, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=6 AND d.codigo='SIPACATE_NARANJO' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 5, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=6 AND d.codigo='PUERTO_SAN_JOSE' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 1, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=7 AND d.codigo='ESQUIPULAS' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 2, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=7 AND d.codigo='BASILICA_ESQUIPULAS' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 3, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=7 AND d.codigo='MUSEO_PALEONTOLOGIA_ESTANZUELA' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 4, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=7 AND d.codigo='VOLCAN_LAGUNA_IPALA' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;
INSERT INTO turismo.ruta_destino (ruta_id, destino_id, orden_visita, tiempo_sugerido) SELECT r.id_ruta, d.id_destino, 5, 'medio día a 1 día' FROM turismo.ruta_turistica r CROSS JOIN turismo.destino_turistico d WHERE r.id_ruta=7 AND d.codigo='LAGO_GUIJA' ON CONFLICT (ruta_id, destino_id) DO UPDATE SET orden_visita=EXCLUDED.orden_visita, tiempo_sugerido=EXCLUDED.tiempo_sugerido;

-- Recomendaciones
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='ANTIGUA_GUATEMALA';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='PARQUE_NACIONAL_TIKAL';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='YAXHA';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='EL_MIRADOR';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='UAXACTUN';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='LAGO_ATITLAN';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='PANAJACHEL';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='SAN_JUAN_LA_LAGUNA';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='CHICHICASTENANGO';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='IXIMCHE';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='QUIRIGUA';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='RIO_DULCE';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='CASTILLO_SAN_FELIPE';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='LIVINGSTON';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='SEMUC_CHAMPEY';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='CUEVAS_CANDELARIA_AV';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='BIOTOPO_QUETZAL';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='COBAN';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='ESQUIPULAS';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='BASILICA_ESQUIPULAS';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='VOLCAN_PACAYA';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='MONTERRICO';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='SIPACATE_NARANJO';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='TAKALIK_ABAJ';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='XETULUL_XOCOMIL';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='PUERTO_SAN_JOSE';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='PLAYA_TILAPA';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='FUENTES_GEORGINAS';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='QUETZALTENANGO_CENTRO';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='VOLCAN_TAJUMULCO';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='LAGUNA_BRAVA';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='CENOTES_CANDELARIA_HUEHUE';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='TODOS_SANTOS_CUCHUMATAN';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='NEBAJ';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='MUNAE';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='KAMINALJUYU';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='ZOO_LA_AURORA';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='CENTRO_HISTORICO_GUATEMALA';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='MIXCO_VIEJO';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='VOLCAN_ACATENANGO';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='VOLCAN_AGUA';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='HOBBITENANGO';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='MUSEO_MIRAFLORES';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='SIERRA_MINAS';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='MUSEO_PALEONTOLOGIA_ESTANZUELA';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='VOLCAN_LAGUNA_IPALA';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='LAGO_GUIJA';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='VOLCAN_SUCHITAN';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='PLAYA_BLANCA_IZABAL';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'LOGISTICA'::turismo.tipo_recomendacion, 'Verificar horarios, condiciones de acceso, clima, disponibilidad de guías y transporte local antes de la visita.' FROM turismo.destino_turistico WHERE codigo='LAGUNA_LACHUA';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'AMBIENTAL'::turismo.tipo_recomendacion, 'Respetar senderos, normas del área protegida, no extraer flora o fauna y reducir residuos durante la visita.' FROM turismo.destino_turistico WHERE codigo='PARQUE_NACIONAL_TIKAL';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'AMBIENTAL'::turismo.tipo_recomendacion, 'Respetar senderos, normas del área protegida, no extraer flora o fauna y reducir residuos durante la visita.' FROM turismo.destino_turistico WHERE codigo='YAXHA';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'AMBIENTAL'::turismo.tipo_recomendacion, 'Respetar senderos, normas del área protegida, no extraer flora o fauna y reducir residuos durante la visita.' FROM turismo.destino_turistico WHERE codigo='EL_MIRADOR';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'AMBIENTAL'::turismo.tipo_recomendacion, 'Respetar senderos, normas del área protegida, no extraer flora o fauna y reducir residuos durante la visita.' FROM turismo.destino_turistico WHERE codigo='SEMUC_CHAMPEY';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'AMBIENTAL'::turismo.tipo_recomendacion, 'Respetar senderos, normas del área protegida, no extraer flora o fauna y reducir residuos durante la visita.' FROM turismo.destino_turistico WHERE codigo='BIOTOPO_QUETZAL';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'AMBIENTAL'::turismo.tipo_recomendacion, 'Respetar senderos, normas del área protegida, no extraer flora o fauna y reducir residuos durante la visita.' FROM turismo.destino_turistico WHERE codigo='VOLCAN_PACAYA';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'AMBIENTAL'::turismo.tipo_recomendacion, 'Respetar senderos, normas del área protegida, no extraer flora o fauna y reducir residuos durante la visita.' FROM turismo.destino_turistico WHERE codigo='MONTERRICO';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'AMBIENTAL'::turismo.tipo_recomendacion, 'Respetar senderos, normas del área protegida, no extraer flora o fauna y reducir residuos durante la visita.' FROM turismo.destino_turistico WHERE codigo='SIPACATE_NARANJO';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'AMBIENTAL'::turismo.tipo_recomendacion, 'Respetar senderos, normas del área protegida, no extraer flora o fauna y reducir residuos durante la visita.' FROM turismo.destino_turistico WHERE codigo='SIERRA_MINAS';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'AMBIENTAL'::turismo.tipo_recomendacion, 'Respetar senderos, normas del área protegida, no extraer flora o fauna y reducir residuos durante la visita.' FROM turismo.destino_turistico WHERE codigo='VOLCAN_LAGUNA_IPALA';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'AMBIENTAL'::turismo.tipo_recomendacion, 'Respetar senderos, normas del área protegida, no extraer flora o fauna y reducir residuos durante la visita.' FROM turismo.destino_turistico WHERE codigo='LAGUNA_LACHUA';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'CULTURAL'::turismo.tipo_recomendacion, 'Solicitar permiso antes de fotografiar personas o ceremonias, y respetar normas comunitarias y religiosas locales.' FROM turismo.destino_turistico WHERE codigo='CHICHICASTENANGO';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'CULTURAL'::turismo.tipo_recomendacion, 'Solicitar permiso antes de fotografiar personas o ceremonias, y respetar normas comunitarias y religiosas locales.' FROM turismo.destino_turistico WHERE codigo='SAN_JUAN_LA_LAGUNA';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'CULTURAL'::turismo.tipo_recomendacion, 'Solicitar permiso antes de fotografiar personas o ceremonias, y respetar normas comunitarias y religiosas locales.' FROM turismo.destino_turistico WHERE codigo='TODOS_SANTOS_CUCHUMATAN';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'CULTURAL'::turismo.tipo_recomendacion, 'Solicitar permiso antes de fotografiar personas o ceremonias, y respetar normas comunitarias y religiosas locales.' FROM turismo.destino_turistico WHERE codigo='NEBAJ';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'CULTURAL'::turismo.tipo_recomendacion, 'Solicitar permiso antes de fotografiar personas o ceremonias, y respetar normas comunitarias y religiosas locales.' FROM turismo.destino_turistico WHERE codigo='LIVINGSTON';
INSERT INTO turismo.recomendacion_destino (destino_id, tipo, recomendacion) SELECT id_destino, 'CULTURAL'::turismo.tipo_recomendacion, 'Solicitar permiso antes de fotografiar personas o ceremonias, y respetar normas comunitarias y religiosas locales.' FROM turismo.destino_turistico WHERE codigo='ANTIGUA_GUATEMALA';
SELECT setval(pg_get_serial_sequence('turismo.fuente_turistica', 'id_fuente'), COALESCE((SELECT MAX(id_fuente) FROM turismo.fuente_turistica), 1));
SELECT setval(pg_get_serial_sequence('turismo.region_turistica', 'id_region'), COALESCE((SELECT MAX(id_region) FROM turismo.region_turistica), 1));
SELECT setval(pg_get_serial_sequence('turismo.categoria_destino', 'id_categoria'), COALESCE((SELECT MAX(id_categoria) FROM turismo.categoria_destino), 1));
SELECT setval(pg_get_serial_sequence('turismo.actividad_turistica', 'id_actividad'), COALESCE((SELECT MAX(id_actividad) FROM turismo.actividad_turistica), 1));
SELECT setval(pg_get_serial_sequence('turismo.temporada_turistica', 'id_temporada'), COALESCE((SELECT MAX(id_temporada) FROM turismo.temporada_turistica), 1));
SELECT setval(pg_get_serial_sequence('turismo.destino_turistico', 'id_destino'), COALESCE((SELECT MAX(id_destino) FROM turismo.destino_turistico), 1));
SELECT setval(pg_get_serial_sequence('turismo.patrimonio_turistico', 'id_patrimonio'), COALESCE((SELECT MAX(id_patrimonio) FROM turismo.patrimonio_turistico), 1));
SELECT setval(pg_get_serial_sequence('turismo.ruta_turistica', 'id_ruta'), COALESCE((SELECT MAX(id_ruta) FROM turismo.ruta_turistica), 1));
-- **********************************************************************
-- Fin schema TURISMO
-- **********************************************************************