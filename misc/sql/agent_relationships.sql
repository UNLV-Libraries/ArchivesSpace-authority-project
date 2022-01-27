SELECT 
  CONCAT(relationship_target_record_type, '/', relationship_target_id) AS target, 
  CONCAT(np0.sort_name, ' (agent_person/', agent_person_id_0, ')') AS person_1, 
  CONCAT(np1.sort_name, ' (agent_person/', agent_person_id_1, ')') AS person_2, 
  CONCAT(nc0.sort_name, ' (agent_corporate_entity/', agent_corporate_entity_id_0, ')') AS corp_1, 
  CONCAT(nc1.sort_name, ' (agent_corporate_entity/', agent_corporate_entity_id_1, ')') AS corp_2, 
  CONCAT(nf0.sort_name, ' (agent_family/', agent_family_id_0, ')') AS family_1, 
  CONCAT(nf1.sort_name, ' (agent_family/', agent_family_id_1, ')') AS family_2, 
  relator, 
  description,
  rar.user_mtime AS last_modified
FROM related_agents_rlshp AS rar
LEFT JOIN name_person AS np0 ON np0.agent_person_id = rar.agent_person_id_0 AND np0.is_display_name IS TRUE
LEFT JOIN name_person AS np1 ON np1.agent_person_id = rar.agent_person_id_1 AND np1.is_display_name IS TRUE
LEFT JOIN name_corporate_entity AS nc0 ON nc0.agent_corporate_entity_id = rar.agent_corporate_entity_id_0 AND nc0.is_display_name IS TRUE
LEFT JOIN name_corporate_entity AS nc1 ON nc1.agent_corporate_entity_id = rar.agent_corporate_entity_id_1 AND nc1.is_display_name IS TRUE
LEFT JOIN name_family AS nf0 ON nf0.agent_family_id = rar.agent_family_id_0 AND nf0.is_display_name IS TRUE
LEFT JOIN name_family AS nf1 ON nf1.agent_family_id = rar.agent_family_id_1 AND nf1.is_display_name IS TRUE
ORDER BY last_modified DESC;