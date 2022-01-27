SELECT date.id, resource_id, archival_object_id, ev1.value AS date_type, ev2.value AS label, ev3.value AS certainty, expression  
FROM SpecArc.date 
LEFT JOIN resource ON date.resource_id = resource.id 
LEFT JOIN archival_object ON date.archival_object_id = archival_object.id 
LEFT JOIN enumeration_value AS ev1 ON date.date_type_id = ev1.id 
LEFT JOIN enumeration_value AS ev2 ON date.label_id = ev2.id 
LEFT JOIN enumeration_value AS ev3 ON date.certainty_id = ev3.id 
WHERE (   date.begin IS NULL    AND date.end IS NULL ) 
AND (  resource.publish = TRUE OR archival_object.publish = TRUE ) 
ORDER BY resource_id ASC, archival_object_id ASC
