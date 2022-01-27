SELECT digital_object.digital_object_id, 
       digital_object.title, 
       file_version.file_uri 
FROM   digital_object 
       LEFT JOIN file_version 
              ON digital_object.id = file_version.digital_object_id
WHERE digital_object.id IN (
	SELECT instance_do_link_rlshp.digital_object_id
	FROM instance_do_link_rlshp
	WHERE instance_do_link_rlshp.instance_id IN (
		SELECT instance.id 
		FROM instance 
		WHERE instance.archival_object_id IN ( 
					SELECT archival_object.id 
					 FROM   archival_object 
					 WHERE  archival_object.root_record_id = 475
			)
	)
)
ORDER BY digital_object.digital_object_id
;