
CREATE OR REPLACE FUNCTION layer_playground_poi(bbox geometry, zoom_level integer, pixel_width numeric)
RETURNS TABLE(osm_id bigint, geometry geometry, name text) AS $$

  SELECT * FROM (
	SELECT osm_id, geometry, name FROM osm_playground_point
        UNION ALL
	SELECT osm_id, geometry, name FROM osm_playground_polygon
  ) AS poi_points
  WHERE geometry && bbox AND zoom_level >= 13;

$$ LANGUAGE SQL IMMUTABLE;
