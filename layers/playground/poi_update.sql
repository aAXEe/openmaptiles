DROP TRIGGER IF EXISTS trigger_flag ON osm_playground_polygon;
DROP TRIGGER IF EXISTS trigger_refresh ON playground_poi.updates;

-- etldoc:  osm_playground_polygon ->  osm_playground_polygon

CREATE OR REPLACE FUNCTION convert_point() RETURNS VOID AS $$
BEGIN
  UPDATE osm_playground_polygon SET geometry=ST_PointOnSurface(geometry) WHERE ST_GeometryType(geometry) <> 'ST_Point';
  ANALYZE osm_playground_polygon;
END;
$$ LANGUAGE plpgsql;

SELECT convert_point();

-- Handle updates

CREATE SCHEMA IF NOT EXISTS playground_poi;

CREATE TABLE IF NOT EXISTS playground_poi.updates(id serial primary key, t text, unique (t));
CREATE OR REPLACE FUNCTION playground_poi.flag() RETURNS trigger AS $$
BEGIN
    INSERT INTO playground_poi.updates(t) VALUES ('y')  ON CONFLICT(t) DO NOTHING;
    RETURN null;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION playground_poi.refresh() RETURNS trigger AS
  $BODY$
  BEGIN
    RAISE LOG 'Refresh poi';
    PERFORM convert_point();
    DELETE FROM playground_poi.updates;
    RETURN null;
  END;
  $BODY$
language plpgsql;

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE ON osm_playground_polygon
    FOR EACH STATEMENT
    EXECUTE PROCEDURE playground_poi.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT ON playground_poi.updates
    INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE PROCEDURE playground_poi.refresh();

-- etldoc:  osm_playground_polygon ->  osm_playground_polygon
UPDATE osm_playground_polygon SET geometry=topoint(geometry)
WHERE ST_GeometryType(geometry) <> 'ST_Point';

ANALYZE osm_playground_polygon;
