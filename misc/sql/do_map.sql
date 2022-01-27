SELECT archival_object.ref_id, 
       file_version.file_uri, 
       Trim('\n' FROM digital_object.digital_object_id) AS digital_object_id 
FROM   instance 
       RIGHT JOIN instance_do_link_rlshp 
               ON instance.id = instance_do_link_rlshp.instance_id 
       INNER JOIN digital_object 
               ON instance_do_link_rlshp.digital_object_id = digital_object.id 
       INNER JOIN file_version 
               ON instance_do_link_rlshp.digital_object_id = 
                  file_version.digital_object_id 
       INNER JOIN archival_object 
               ON instance.archival_object_id = archival_object.id; 