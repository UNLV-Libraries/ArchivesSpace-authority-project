SELECT a.authority_id AS authority_uri, COALESCE(p.sort_name, c.primary_name, f.family_name) AS name 
FROM name_authority_id AS a 
LEFT JOIN name_person AS p ON a.name_person_id = p.id 
LEFT JOIN name_corporate_entity AS c ON a.name_corporate_entity_id = c.id 
LEFT JOIN name_family AS f ON a.name_family_id = f.id 
ORDER BY uri;
