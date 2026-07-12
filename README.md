# CONOCE-GUATEMALA

Conoce Guate es una plataforma de integración y análisis de datos abiertos sobre Guatemala, 
como proyecto académico colaborativo en el Centro Universitario de Occidente (CUNOC) de la Universidad de San Carlos de Guatemala. 
Su propósito es centralizar información dispersa proveniente de múltiples instituciones públicas, organizarla bajo criterios de calidad y gobierno de datos, y ponerla a disposición de cualquier persona que quiera entender mejor la realidad del país: turistas, investigadores, estudiantes, analistas, periodistas o ciudadanos interesados.

Es una base de datos relacional que toma a Guatemala como eje central, y reune en un solo lugar, información relevante de multiples áreas de interés (justicia, salud, educación, turismo, clima, geografía, demografía, entre otras).

Los datos se recopilan de fuentes oficiales, se normalizan por dominio y se cargan con sus respectivos metadatos, de modo que a futuro se puedan hacer extracciones y análisis específicos con datos de calidad.

El proyecto nació de una pregunta simple: ¿Qué necesitaría saber alguien que quiere conocer Guatemala de verdad? 
No solo dónde está el lago Atitlán o cuál es la ruta al Tikal. También:

- ¿Qué tan seguro es viajar a ese departamento?
- ¿Qué tan bien pagan a quienes trabajan en las instituciones del Estado?
- ¿Qué condiciones climáticas hay en esa zona del país?
- ¿Qué transporte existe?
- ¿Qué pueblos, mercados o festividades hay en esa región?
La respuesta a todas esas preguntas existe en datos públicos dispersos. Lo que falta es integración, estructura y acceso.

## Objetivo General.
Integrar información pública sobre Guatemala en una base de datos organizada por módulos temáticos, documentada mediante metadatos, fuentes, reglas de calidad y criterios de modelado, para facilitar su consulta, análisis y reutilización.

## Alcance del proyecto
Conoce Guate está organizado en módulos temáticos, cada uno desarrollado por un sub-equipo del proyecto. 
Todos comparten una misma base de datos y un esquema geográfico común (departamentos, municipios, regiones), 
lo que permite cruzar información entre módulos y construir análisis más completos.

## Consulta y exploración de datos.
El proyecto cuenta con un esquema especial llamado `meta`, cuyo objetivo es documentar la estructura de la base de datos 
y facilitar la búsqueda de información para nuevos integrantes, docentes o personas interesadas. 

A través del esquema `meta` se puede consultar:

- Qué esquemas existen en el proyecto
- Qué información contiene cada esquema
- Qué tablas pertenecen a cada módulo
- Qué columnas tiene cada tabla
- qué significa cada columna
- Qué fuentes respaldan los datos
- Qué reglas de calidad aplican
- Qué decisiones de modelado se tomaron
- Qué cargas de datos se realizaron

Esto permite que una persona no tenga que revisar todo el código SQL para entender la base de datos, 
sino que pueda consultar directamente el catálogo de metadatos. 
Para facilitar esta exploración se incluye el archivo: `consultas_metadatos.sql`. 
Este archivo contiene consultas preparadas para buscar información por esquema, tabla, columna, tema, fuente o decisión de modelado. 

Por ejemplo, permite responder preguntas como:

- ¿Qué contiene el esquema turismo?
- ¿Qué tablas existen sobre geografía?
- ¿Qué fuente respalda una tabla?
- ¿Dónde se documentan los datos relacionados con festividades?

Si se desea agregar información de algún tema, ¿ya existe un lugar donde colocarla o debe proponerse un nuevo esquema?

---

## Requisitos

### PostgreSQL

La base de datos se levanta en PostgreSQL, los scripts están en el dialecto de PostgreSQL, se recomienda **versión 17 o superior.

Se optó por PostgreSQL, ya que es un motor robusto y muy completo, las principales características consideradas son:
- Alta tolerancia a fallos
- Estricta integridad y consistencia de datos
- Soporta tipos de datos como JSONB lo que permite almacenar datos semiestructurados
- Alta extensibilidad por medio de creación de funciones u extensiones fácilmente integrables
- Comunidad y código abierto

#### Instalación:

**En Linux:**

- Distribuciones basadas en **Debian/Ubuntu**:
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
```
- Distribuciones basadas en **Arch**:
```bash
sudo pacman -Syu postgresql
sudo -u postgres initdb -D /var/lib/postgres/data
```
- Distribuciones basadas en **Red Hat**:
```bash
# Desactiva el módulo predeterminado para no instalar una versión antigua y agregar el repositorio oficial 
sudo dnf module disable postgresql
sudo dnf install -y https://postgresql.org(rpm -E %rhel)-x86_64/pgdg-redhat-repo-latest.noarch.rpm

# Instalar el servidor de la versión deseada
sudo dnf install -y postgresql17-server

# Inicializar el servidor y la base de datos
sudo /usr/pgsql-17/bin/postgresql-17-setup initdb
sudo systemctl start postgresql-17
sudo systemctl enable postgresql-17
```
- Verificar estado, iniciar servicio y habilitar en arranque:
```bash
sudo systemctl status postgresql
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

**En Mac:**
Instalar con `brew install postgresql`

**En Windows:**
- Descargar instalador oficial desde https://www.postgresql.org/download/windows/
- Ejecutar y seguir los pasos del instalador

**Con Docker:**
Levantar un contenedor con la imagen oficial de PostgreSQL:
```bash
docker run --name postgres \
-e POSTGRES_PASSWORD=contraseña_segura \
-p 5432:5432 \
-v /ruta/en/tu/pc/datos:/var/lib/postgresql/data \
-d postgres
```
Conectarse desde terminal:
```bash
docker exec -it mi-postgres psql -U postgres`
```

## Enlaces externos

- [Wiki SR_LABS](https://srlabs.a2hosted.com/rs-humhub/index.php?r=content%2Fperma&id=33166)

