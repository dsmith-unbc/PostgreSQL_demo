


CREATE EXTENSION IF NOT EXISTS postgis;

DROP SCHEMA IF EXISTS functions CASCADE;
CREATE SCHEMA functions;

CREATE OR REPLACE FUNCTION functions.create_geom_points()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
  DECLARE
BEGIN

IF NEW.lon IS NOT NULL AND NEW.lat IS NOT NULL THEN
NEW.geom = ST_SetSRID(ST_MakePoint(NEW.lon, NEW.lat),4326);
END IF;

RETURN NEW;
END;$function$
;

CREATE OR REPLACE FUNCTION functions.station_spatial_ops()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
  DECLARE
BEGIN

IF NEW.lon IS NOT NULL AND NEW.lat IS NOT NULL THEN
NEW.geom = ST_SetSRID(ST_MakePoint(NEW.lon, NEW.lat),4326);
NEW.env_zone := (SELECT
  z.zone
FROM spatial.flow_zone AS z
WHERE ST_Intersects(z.geom, ST_Transform(NEW.geom, 26911)));
END IF;

RETURN NEW;
END;$function$;

DROP SCHEMA IF EXISTS telemetry CASCADE;
CREATE SCHEMA telemetry;

DROP TABLE IF EXISTS telemetry.deployment CASCADE;
CREATE TABLE telemetry.deployment (
  station_id varchar,
  date_deployment date,
  receiver varchar,
  activity varchar,
  download bool,
  missing bool,
  moved bool,
  battery_dead bool,
  comment varchar,
  added_to_database timestamp with time zone DEFAULT now(),
  id integer);

COMMENT ON TABLE telemetry.deployment IS 'Table that stores information on receiver visits. Each observation corresponds to a single activity (i.e., deployment, redeployment, or removal).';
COMMENT ON COLUMN telemetry.deployment.station_id IS 'Code for identifying receiver station';
COMMENT ON COLUMN telemetry.deployment.date_deployment IS 'Date of visit';
COMMENT ON COLUMN telemetry.deployment.receiver IS 'Receiver identification numnber';
COMMENT ON COLUMN telemetry.deployment.activity IS 'Receiver visit activity. Must be one of deploy, redeploy or remove. If receiver is missing, then activity is remove.';
COMMENT ON COLUMN telemetry.deployment.missing IS 'Whether receiver was missing on visit';
COMMENT ON COLUMN telemetry.deployment.moved IS 'Wheter receiver moved since last visit';
COMMENT ON COLUMN telemetry.deployment.battery_dead IS 'Whether receiver battery was dead on visit';

DROP SCHEMA IF EXISTS lookup CASCADE;
CREATE SCHEMA lookup;

DROP TABLE IF EXISTS lookup.lab_supervisor;
CREATE TABLE lookup.lab_supervisor (
  lab varchar,
  supervisor varchar
);

COMMENT ON TABLE lookup.lab_supervisor IS 'Relational table to join labs to supervisors';
COMMENT ON COLUMN lookup.lab_supervisor.lab IS 'Lab name individual is associated with';
COMMENT ON COLUMN lookup.lab_supervisor.supervisor IS 'Supervisor of Lab';


DROP TABLE IF EXISTS lookup.sex CASCADE;
CREATE TABLE lookup.sex (
  sex_id varchar PRIMARY KEY,
  sex varchar);

COMMENT ON TABLE lookup.sex IS 'Table to hold identification information about fish';
COMMENT ON COLUMN lookup.sex.sex_id IS 'Unique identifier for sex';
COMMENT ON COLUMN lookup.sex.sex IS 'Sex categories';

INSERT INTO lookup.sex 
VALUES ('M', 'Male'),
('F', 'Female'),
('Unk', 'Unknown');

DROP TABLE IF EXISTS telemetry.detections CASCADE;
CREATE TABLE telemetry.detections (
  datetime_utc timestamp without time zone,
  receiver varchar,
  transmitter varchar,
  transmitter_name varchar,
  transmitter_serial integer,
  sensor_value varchar,
  sensor_unit varchar,
  station_name varchar,
  lat double precision,
  lon double precision,
  transmitter_type varchar,
  sensor_precision varchar,
  file varchar,
  geom geometry(POINT, 4326),
  added_to_database timestamp with time zone DEFAULT now(),
  PRIMARY KEY (datetime_utc,receiver,transmitter));

COMMENT ON COLUMN telemetry.detections.datetime_utc IS 'Timestamp in UTC';
COMMENT ON COLUMN telemetry.detections.receiver IS 'Receiver ID number';
COMMENT ON COLUMN telemetry.detections.transmitter IS 'Transmitter ID number';

CREATE trigger detection_trigger_points before
INSERT
    ON
    telemetry.detections for each row execute function functions.create_geom_points();

DROP SCHEMA IF EXISTS demo CASCADE;
CREATE SCHEMA demo;

DROP TABLE IF EXISTS demo.demo_table CASCADE;
CREATE TABLE demo.demo_table(
  name varchar PRIMARY KEY,
  lab varchar,
  gradstudent bool,
  datetime timestamp without time zone,
  id_num integer,
  random_val double precision,
  sex varchar,
  added_to_database timestamp with time zone DEFAULT now()
);

COMMENT ON COLUMN demo.demo_table.name IS 'Name of individual';
COMMENT ON COLUMN demo.demo_table.lab IS 'Lab name individual is associated with';
COMMENT ON COLUMN demo.demo_table.gradstudent IS 'Is the individual a grad student or not? (boolean)';
COMMENT ON COLUMN demo.demo_table.datetime IS 'A random date and time without timezone';
COMMENT ON COLUMN demo.demo_table.id_num IS 'A random integer as an example';
COMMENT ON COLUMN demo.demo_table.random_val IS 'A random value to show how double precision works';
COMMENT ON COLUMN demo.demo_table.sex IS 'Sex of individual';
COMMENT ON COLUMN demo.demo_table.added_to_database IS 'Timestamp of when data was added to database';



