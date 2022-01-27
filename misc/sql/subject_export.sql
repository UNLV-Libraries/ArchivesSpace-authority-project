SELECT subject.id, 
       title, 
       value, 
       authority_id, 
       (SELECT Count(subject_term.id) 
        FROM   subject_term 
        WHERE  subject_term.subject_id = subject.id)  AS term_count, 
       (SELECT Count(subject_rlshp.id) 
        FROM   subject_rlshp 
        WHERE  subject_rlshp.subject_id = subject.id) AS use_count 
FROM   subject 
       INNER JOIN enumeration_value 
               ON subject.source_id = enumeration_value.id 
ORDER  BY subject.title
;