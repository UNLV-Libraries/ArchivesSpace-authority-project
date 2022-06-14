SELECT CONCAT('/subjects/',s.id) AS subject_uri, s.title, COALESCE(s.authority_id, '') AS authority_uri
FROM subject AS s
LEFT JOIN subject_term AS st ON s.id = st.subject_id 
LEFT JOIN term AS t on st.term_id = t.id 
WHERE term_type_id = 1269 -- Find subjects with geographic terms
AND s.title LIKE CONCAT(t.term,'%') -- With the geographic term in the first position
AND (SELECT count(id) FROM subject_rlshp WHERE subject_id = s.id) > 0 -- currently in use
ORDER BY s.id ASC -- Subject AS URI order, could be reversed if you want newest first
