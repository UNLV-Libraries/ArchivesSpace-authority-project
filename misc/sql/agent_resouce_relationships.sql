/**
 * Queries to export a table of Agents with their relationship to resources.
 */

SELECT ap.id AS agent_id, np.sort_name AS name, ev.value as relationship, linked_agents_rlshp.resource_id, r.title, REPLACE(REPLACE(REPLACE(r.identifier, '","','-'),'["',''),'",null,null]','') AS coll_id 
FROM agent_person AS ap
INNER JOIN name_person AS np on ap.id = np.agent_person_id
INNER JOIN linked_agents_rlshp ON ap.id = linked_agents_rlshp.agent_person_id
INNER JOIN resource AS r ON linked_agents_rlshp.resource_id = r.id
LEFT JOIN enumeration_value AS ev ON linked_agents_rlshp.role_id = ev.id
WHERE resource_id IS NOT NULL
AND np.is_display_name IS TRUE
ORDER BY name, relationship;

SELECT ac.id AS agent_id, nc.sort_name AS name, ev.value AS relationship, linked_agents_rlshp.resource_id, r.title, REPLACE(REPLACE(REPLACE(r.identifier, '","','-'),'["',''),'",null,null]','') AS coll_id 
FROM agent_corporate_entity AS ac
INNER JOIN name_corporate_entity AS nc on ac.id = nc.agent_corporate_entity_id
INNER JOIN linked_agents_rlshp ON ac.id = linked_agents_rlshp.agent_corporate_entity_id
INNER JOIN resource AS r ON linked_agents_rlshp.resource_id = r.id
LEFT JOIN enumeration_value AS ev ON linked_agents_rlshp.role_id = ev.id
WHERE resource_id IS NOT NULL
AND nc.is_display_name IS TRUE
ORDER BY name, relationship;

SELECT a.id AS agent_id, n.sort_name AS name, ev.value AS relationship, linked_agents_rlshp.resource_id, r.title, REPLACE(REPLACE(REPLACE(r.identifier, '","','-'),'["',''),'",null,null]','') AS coll_id 
FROM agent_family AS a
INNER JOIN name_family AS n on a.id = n.agent_family_id
INNER JOIN linked_agents_rlshp ON a.id = linked_agents_rlshp.agent_family_id
INNER JOIN resource AS r ON linked_agents_rlshp.resource_id = r.id
LEFT JOIN enumeration_value AS ev ON linked_agents_rlshp.role_id = ev.id
WHERE resource_id IS NOT NULL
AND n.is_display_name IS TRUE
ORDER BY name, relationship;