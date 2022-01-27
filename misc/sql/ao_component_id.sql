SELECT archival_object.id, 
       root_record_id, 
       enumeration_value.value AS level, 
       component_id, 
       display_string, 
       archival_object.last_modified_by, 
       archival_object.user_mtime 
FROM   archival_object 
       LEFT JOIN enumeration_value 
              ON level_id = enumeration_value.id 
       LEFT JOIN resource 
              ON archival_object.root_record_id = resource.id 
WHERE  component_id IS NOT NULL 
       AND resource.ead_location LIKE '%ark:%' 
       AND enumeration_value.value IN ( 'file', 'item' ) 
ORDER  BY component_id, 
          root_record_id, 
          archival_object.id; 