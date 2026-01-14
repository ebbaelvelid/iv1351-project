CREATE INDEX idx_course_instance_year
ON course_instance(instance_id, study_year);

CREATE INDEX idx_allocations_person_instance
ON allocations(id_person, instance_id);

CREATE MATERIALIZED VIEW mv_teacher_allocations AS -- query 2
SELECT
    cl.course_code AS "Course Code",
    ci.instance_id  AS "Course Instance ID",
    cl.hp AS "HP",
    (p.first_name || ' ' || p.last_name) AS "Teacher's Name",
    jt.job_title AS "Designation",

    SUM(CASE WHEN ta.activity_name = 'Lecture'
             THEN a.allocated_hours * ta.factor ELSE 0 END) AS "Lecture Hours",
    SUM(CASE WHEN ta.activity_name = 'Tutorial'
             THEN a.allocated_hours * ta.factor ELSE 0 END) AS "Tutorial Hours",
    SUM(CASE WHEN ta.activity_name = 'Lab'
             THEN a.allocated_hours * ta.factor ELSE 0 END) AS "Lab Hours",
    SUM(CASE WHEN ta.activity_name = 'Seminar'
             THEN a.allocated_hours * ta.factor ELSE 0 END) AS "Seminar Hours",
    SUM(CASE WHEN ta.activity_name = 'Others'
             THEN a.allocated_hours * ta.factor ELSE 0 END) AS "Other Overhead Hours",
    SUM(CASE WHEN ta.activity_name = 'Administration'
         THEN a.allocated_hours ELSE 0 END) AS "Admin",
    SUM(CASE WHEN ta.activity_name = 'Examination'
            THEN a.allocated_hours ELSE 0 END) AS "Exam",


    SUM(
        CASE
            WHEN ta.activity_name IN ('Lecture','Tutorial','Lab','Seminar','Others')
                THEN a.allocated_hours * ta.factor
            WHEN ta.activity_name IN ('Administration','Examination')
                THEN a.allocated_hours   
            ELSE 0
        END
    ) AS "Total"

FROM allocations a
JOIN employee e ON a.id_person = e.id_person
JOIN person p ON e.id_person = p.id
JOIN job_title jt ON e.id_job    = jt.id
JOIN teaching_activity ta ON a.id_teaching = ta.id
JOIN course_instance ci ON a.instance_id  = ci.instance_id
JOIN course_layout cl ON ci.id_layout   = cl.id
JOIN study_period_ENUM sp ON ci.study_period_id = sp.study_period_id
WHERE ci.study_year = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY
    cl.course_code,
    ci.instance_id,
    cl.hp,
    "Teacher's Name",
    jt.job_title
ORDER BY
    cl.course_code,
    ci.instance_id,
    "Teacher's Name";


/* RESULTS EXPLAIN ANALYZE (updated)


QUERY 4 Before:
                                                                                         QUERY PLAN                                                                                         
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=21.84..21.85 rows=1 width=130) (actual time=0.804..0.808 rows=18.00 loops=1)
   Sort Key: (count(DISTINCT ci.instance_id)) DESC, ((((p.first_name)::text || ' '::text) || (p.last_name)::text))
   Sort Method: quicksort  Memory: 25kB
   Buffers: shared hit=450
   ->  GroupAggregate  (cost=21.80..21.83 rows=1 width=130) (actual time=0.731..0.764 rows=18.00 loops=1)
         Group Key: e.employment_id, ((((p.first_name)::text || ' '::text) || (p.last_name)::text)), sp.study_period
         Filter: (count(DISTINCT ci.instance_id) > 1)
         Rows Removed by Filter: 20
         Buffers: shared hit=447
         ->  Sort  (cost=21.80..21.81 rows=1 width=200) (actual time=0.716..0.722 rows=70.00 loops=1)
               Sort Key: e.employment_id, ((((p.first_name)::text || ' '::text) || (p.last_name)::text)), sp.study_period, ci.instance_id
               Sort Method: quicksort  Memory: 29kB
               Buffers: shared hit=447
               ->  Nested Loop  (cost=0.61..21.79 rows=1 width=200) (actual time=0.169..0.648 rows=70.00 loops=1)
                     Buffers: shared hit=447
                     ->  Nested Loop  (cost=0.45..14.94 rows=1 width=316) (actual time=0.151..0.527 rows=70.00 loops=1)
                           Join Filter: (a.id_person = p.id)
                           Buffers: shared hit=307
                           ->  Nested Loop  (cost=0.31..14.64 rows=1 width=168) (actual time=0.125..0.394 rows=70.00 loops=1)
                                 Buffers: shared hit=167
                                 ->  Nested Loop  (cost=0.16..13.95 rows=1 width=86) (actual time=0.097..0.261 rows=70.00 loops=1)
                                       Buffers: shared hit=27
                                       ->  Seq Scan on allocations a  (cost=0.00..1.91 rows=91 width=18) (actual time=0.066..0.076 rows=91.00 loops=1)
                                             Buffers: shared hit=1
                                       ->  Memoize  (cost=0.16..0.71 rows=1 width=82) (actual time=0.002..0.002 rows=0.77 loops=91)
                                             Cache Key: a.instance_id
                                             Cache Mode: logical
                                             Hits: 78  Misses: 13  Evictions: 0  Overflows: 0  Memory Usage: 2kB
                                             Buffers: shared hit=26
                                             ->  Index Scan using pk_course_instance on course_instance ci  (cost=0.15..0.70 rows=1 width=82) (actual time=0.008..0.008 rows=0.77 loops=13)
                                                   Index Cond: ((instance_id)::text = (a.instance_id)::text)
                                                   Filter: ((study_year)::numeric = EXTRACT(year FROM CURRENT_DATE))
                                                   Rows Removed by Filter: 0
                                                   Index Searches: 13
                                                   Buffers: shared hit=26
                                 ->  Index Scan using pk_employee on employee e  (cost=0.15..0.69 rows=1 width=82) (actual time=0.001..0.001 rows=1.00 loops=70)
                                       Index Cond: (id_person = a.id_person)
                                       Index Searches: 70
                                       Buffers: shared hit=140
                           ->  Index Scan using pk_person on person p  (cost=0.15..0.29 rows=1 width=160) (actual time=0.001..0.001 rows=1.00 loops=70)
                                 Index Cond: (id = e.id_person)
                                 Index Searches: 70
                                 Buffers: shared hit=140
                     ->  Index Scan using pk_study_period_enum on study_period_enum sp  (cost=0.15..6.84 rows=1 width=16) (actual time=0.001..0.001 rows=1.00 loops=70)
                           Index Cond: (study_period_id = ci.study_period_id)
                           Index Searches: 70
                           Buffers: shared hit=140
 Planning:
   Buffers: shared hit=13
 Planning Time: 0.969 ms
 Execution Time: 0.930 ms
(51 rows)

QUERY 4 After:
                                                                           QUERY PLAN                                                                            
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=10.83..10.84 rows=2 width=130) (actual time=0.792..0.799 rows=18.00 loops=1)
   Sort Key: (count(DISTINCT ci.instance_id)) DESC, ((((p.first_name)::text || ' '::text) || (p.last_name)::text))
   Sort Method: quicksort  Memory: 25kB
   Buffers: shared hit=283
   ->  GroupAggregate  (cost=10.66..10.82 rows=2 width=130) (actual time=0.702..0.765 rows=18.00 loops=1)
         Group Key: e.employment_id, ((((p.first_name)::text || ' '::text) || (p.last_name)::text)), sp.study_period
         Filter: (count(DISTINCT ci.instance_id) > 1)
         Rows Removed by Filter: 20
         Buffers: shared hit=283
         ->  Sort  (cost=10.66..10.68 rows=6 width=200) (actual time=0.683..0.694 rows=70.00 loops=1)
               Sort Key: e.employment_id, ((((p.first_name)::text || ' '::text) || (p.last_name)::text)), sp.study_period, ci.instance_id
               Sort Method: quicksort  Memory: 29kB
               Buffers: shared hit=283
               ->  Hash Join  (cost=2.68..10.59 rows=6 width=200) (actual time=0.204..0.601 rows=70.00 loops=1)
                     Hash Cond: (ci.study_period_id = sp.study_period_id)
                     Buffers: shared hit=283
                     ->  Nested Loop  (cost=1.59..9.45 rows=6 width=316) (actual time=0.130..0.482 rows=70.00 loops=1)
                           Join Filter: (a.id_person = p.id)
                           Buffers: shared hit=282
                           ->  Nested Loop  (cost=1.44..7.67 rows=6 width=168) (actual time=0.093..0.299 rows=70.00 loops=1)
                                 Buffers: shared hit=142
                                 ->  Hash Join  (cost=1.29..3.51 rows=6 width=86) (actual time=0.061..0.123 rows=70.00 loops=1)
                                       Hash Cond: ((a.instance_id)::text = (ci.instance_id)::text)
                                       Buffers: shared hit=2
                                       ->  Seq Scan on allocations a  (cost=0.00..1.91 rows=91 width=18) (actual time=0.008..0.022 rows=91.00 loops=1)
                                             Buffers: shared hit=1
                                       ->  Hash  (cost=1.28..1.28 rows=1 width=82) (actual time=0.036..0.037 rows=11.00 loops=1)
                                             Buckets: 1024  Batches: 1  Memory Usage: 9kB
                                             Buffers: shared hit=1
                                             ->  Seq Scan on course_instance ci  (cost=0.00..1.28 rows=1 width=82) (actual time=0.015..0.023 rows=11.00 loops=1)
                                                   Filter: ((study_year)::numeric = EXTRACT(year FROM CURRENT_DATE))
                                                   Rows Removed by Filter: 3
                                                   Buffers: shared hit=1
                                 ->  Index Scan using pk_employee on employee e  (cost=0.15..0.69 rows=1 width=82) (actual time=0.002..0.002 rows=1.00 loops=70)
                                       Index Cond: (id_person = a.id_person)
                                       Index Searches: 70
                                       Buffers: shared hit=140
                           ->  Index Scan using pk_person on person p  (cost=0.15..0.29 rows=1 width=160) (actual time=0.002..0.002 rows=1.00 loops=70)
                                 Index Cond: (id = e.id_person)
                                 Index Searches: 70
                                 Buffers: shared hit=140
                     ->  Hash  (cost=1.04..1.04 rows=4 width=16) (actual time=0.055..0.055 rows=4.00 loops=1)
                           Buckets: 1024  Batches: 1  Memory Usage: 9kB
                           Buffers: shared hit=1
                           ->  Seq Scan on study_period_enum sp  (cost=0.00..1.04 rows=4 width=16) (actual time=0.044..0.046 rows=4.00 loops=1)
                                 Buffers: shared hit=1
 Planning Time: 1.443 ms
 Execution Time: 0.944 ms
(48 rows)
