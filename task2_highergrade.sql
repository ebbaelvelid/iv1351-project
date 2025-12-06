CREATE INDEX idx_course_instance_year
ON course_instance(instance_id, study_year);

CREATE INDEX idx_allocations_person_instance
ON allocations(id_person, instance_id);

CREATE INDEX idx_planned_activity_teaching_instance
ON planned_activity(id_teaching, instance_id);

CREATE MATERIALIZED VIEW mv_teacher_allocations AS -- query 2
SELECT
    cl.course_code AS "Course Code",
    ci.instance_id  AS "Course Instance ID",
    cl.hp AS "HP",
    (p.first_name || ' ' || p.last_name) AS "Teacher's Name",
    jt.job_title AS "Designation",

    SUM(CASE WHEN ta.activity_name = 'Lecture'
             THEN pa.planned_hours * ta.factor ELSE 0 END) AS "Lecture Hours",
    SUM(CASE WHEN ta.activity_name = 'Tutorial'
             THEN pa.planned_hours * ta.factor ELSE 0 END) AS "Tutorial Hours",
    SUM(CASE WHEN ta.activity_name = 'Lab'
             THEN pa.planned_hours * ta.factor ELSE 0 END) AS "Lab Hours",
    SUM(CASE WHEN ta.activity_name = 'Seminar'
             THEN pa.planned_hours * ta.factor ELSE 0 END) AS "Seminar Hours",
    SUM(CASE WHEN ta.activity_name = 'Others'
             THEN pa.planned_hours * ta.factor ELSE 0 END) AS "Other Overhead Hours",
    SUM(CASE WHEN ta.activity_name = 'Administration'
             THEN pa.planned_hours + ta.factor * ci.num_students + 2 * cl.hp ELSE 0 END) AS "Admin",
    SUM(CASE WHEN ta.activity_name = 'Examination'
             THEN pa.planned_hours + ta.factor * ci.num_students ELSE 0 END) AS "Exam",

    SUM(
        CASE
            WHEN ta.activity_name IN ('Lecture','Tutorial','Lab','Seminar','Others')
                THEN pa.planned_hours * ta.factor
            WHEN ta.activity_name = 'Administration'
                THEN pa.planned_hours + ta.factor * ci.num_students + 2 * cl.hp
            WHEN ta.activity_name = 'Examination'
                THEN pa.planned_hours + ta.factor * ci.num_students
            ELSE 0
        END
    ) AS "Total"

FROM allocations a
JOIN employee e ON a.id_person = e.id_person
JOIN person p ON e.id_person = p.id
JOIN job_title jt ON e.id_job    = jt.id
JOIN planned_activity pa ON a.id_teaching = pa.id_teaching
                            AND a.instance_id = pa.instance_id
JOIN teaching_activity ta ON pa.id_teaching = ta.id
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


/* RESULTS EXPLAIN ANALYZE BEFORE

QUERY 2
                                                                                                  QUERY PLAN                                                                                                  
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=29.92..30.08 rows=1 width=338) (actual time=2.271..2.431 rows=64.00 loops=1)
   Group Key: cl.course_code, ci.instance_id, ((((p.first_name)::text || ' '::text) || (p.last_name)::text)), jt.job_title
   Buffers: shared hit=1007
   ->  Sort  (cost=29.92..29.93 rows=1 width=368) (actual time=2.249..2.260 rows=70.00 loops=1)
         Sort Key: cl.course_code, ci.instance_id, ((((p.first_name)::text || ' '::text) || (p.last_name)::text)), jt.job_title
         Sort Method: quicksort  Memory: 32kB
         Buffers: shared hit=1007
         ->  Nested Loop  (cost=1.20..29.91 rows=1 width=368) (actual time=1.220..2.173 rows=70.00 loops=1)
               Buffers: shared hit=1007
               ->  Nested Loop  (cost=1.05..23.06 rows=1 width=496) (actual time=0.215..1.056 rows=70.00 loops=1)
                     Buffers: shared hit=867
                     ->  Nested Loop  (cost=0.90..16.20 rows=1 width=414) (actual time=0.201..0.926 rows=70.00 loops=1)
                           Join Filter: (a.id_teaching = ta.id)
                           Buffers: shared hit=727
                           ->  Nested Loop  (cost=0.75..15.53 rows=1 width=336) (actual time=0.180..0.801 rows=70.00 loops=1)
                                 Buffers: shared hit=587
                                 ->  Nested Loop  (cost=0.60..15.23 rows=1 width=342) (actual time=0.160..0.630 rows=70.00 loops=1)
                                       Buffers: shared hit=447
                                       ->  Nested Loop  (cost=0.45..14.94 rows=1 width=268) (actual time=0.142..0.515 rows=70.00 loops=1)
                                             Join Filter: (a.id_person = p.id)
                                             Buffers: shared hit=307
                                             ->  Nested Loop  (cost=0.31..14.64 rows=1 width=120) (actual time=0.131..0.392 rows=70.00 loops=1)
                                                   Buffers: shared hit=167
                                                   ->  Nested Loop  (cost=0.16..13.95 rows=1 width=112) (actual time=0.099..0.245 rows=70.00 loops=1)
                                                         Buffers: shared hit=27
                                                         ->  Seq Scan on allocations a  (cost=0.00..1.91 rows=91 width=22) (actual time=0.042..0.053 rows=91.00 loops=1)
                                                               Buffers: shared hit=1
                                                         ->  Memoize  (cost=0.16..0.71 rows=1 width=90) (actual time=0.002..0.002 rows=0.77 loops=91)
                                                               Cache Key: a.instance_id
                                                               Cache Mode: logical
                                                               Hits: 78  Misses: 13  Evictions: 0  Overflows: 0  Memory Usage: 2kB
                                                               Buffers: shared hit=26
                                                               ->  Index Scan using pk_course_instance on course_instance ci  (cost=0.15..0.70 rows=1 width=90) (actual time=0.007..0.007 rows=0.77 loops=13)
                                                                     Index Cond: ((instance_id)::text = (a.instance_id)::text)
                                                                     Filter: ((study_year)::numeric = EXTRACT(year FROM CURRENT_DATE))
                                                                     Rows Removed by Filter: 0
                                                                     Index Searches: 13
                                                                     Buffers: shared hit=26
                                                   ->  Index Scan using pk_employee on employee e  (cost=0.15..0.69 rows=1 width=8) (actual time=0.001..0.001 rows=1.00 loops=70)
                                                         Index Cond: (id_person = a.id_person)
                                                         Index Searches: 70
                                                         Buffers: shared hit=140
                                             ->  Index Scan using pk_person on person p  (cost=0.15..0.29 rows=1 width=160) (actual time=0.001..0.001 rows=1.00 loops=70)
                                                   Index Cond: (id = e.id_person)
                                                   Index Searches: 70
                                                   Buffers: shared hit=140
                                       ->  Index Scan using pk_job_title on job_title jt  (cost=0.15..0.29 rows=1 width=82) (actual time=0.001..0.001 rows=1.00 loops=70)
                                             Index Cond: (id = e.id_job)
                                             Index Searches: 70
                                             Buffers: shared hit=140
                                 ->  Index Scan using pk_planned_activity on planned_activity pa  (cost=0.14..0.29 rows=1 width=22) (actual time=0.002..0.002 rows=1.00 loops=70)
                                       Index Cond: ((id_teaching = a.id_teaching) AND ((instance_id)::text = (a.instance_id)::text))
                                       Index Searches: 70
                                       Buffers: shared hit=140
                           ->  Index Scan using pk_teaching_activity on teaching_activity ta  (cost=0.15..0.66 rows=1 width=90) (actual time=0.001..0.001 rows=1.00 loops=70)
                                 Index Cond: (id = pa.id_teaching)
                                 Index Searches: 70
                                 Buffers: shared hit=140
                     ->  Index Scan using pk_course_layout on course_layout cl  (cost=0.15..6.83 rows=1 width=90) (actual time=0.001..0.001 rows=1.00 loops=70)
                           Index Cond: (id = ci.id_layout)
                           Index Searches: 70
                           Buffers: shared hit=140
               ->  Index Only Scan using pk_study_period_enum on study_period_enum sp  (cost=0.15..6.84 rows=1 width=4) (actual time=0.015..0.015 rows=1.00 loops=70)
                     Index Cond: (study_period_id = ci.study_period_id)
                     Heap Fetches: 70
                     Index Searches: 70
                     Buffers: shared hit=140
 Planning:
   Buffers: shared hit=45
 Planning Time: 6.278 ms
 Execution Time: 2.694 ms
(71 rows)

QUERY 3
                                                                                               QUERY PLAN                                                                                               
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=29.63..29.79 rows=1 width=272) (actual time=1.515..1.581 rows=64.00 loops=1)
   Group Key: ((((p.first_name)::text || ' '::text) || (p.last_name)::text)), ci.instance_id, cl.course_code, sp.study_period
   Buffers: shared hit=867
   ->  Sort  (cost=29.63..29.64 rows=1 width=302) (actual time=1.491..1.498 rows=70.00 loops=1)
         Sort Key: ((((p.first_name)::text || ' '::text) || (p.last_name)::text)), ci.instance_id, cl.course_code, sp.study_period
         Sort Method: quicksort  Memory: 31kB
         Buffers: shared hit=867
         ->  Nested Loop  (cost=1.05..29.62 rows=1 width=302) (actual time=0.898..1.423 rows=70.00 loops=1)
               Buffers: shared hit=867
               ->  Nested Loop  (cost=0.89..22.77 rows=1 width=418) (actual time=0.882..1.338 rows=70.00 loops=1)
                     Buffers: shared hit=727
                     ->  Nested Loop  (cost=0.75..15.91 rows=1 width=336) (actual time=0.867..1.256 rows=70.00 loops=1)
                           Join Filter: (a.id_teaching = ta.id)
                           Buffers: shared hit=587
                           ->  Nested Loop  (cost=0.60..15.24 rows=1 width=258) (actual time=0.855..1.179 rows=70.00 loops=1)
                                 Buffers: shared hit=447
                                 ->  Nested Loop  (cost=0.45..14.94 rows=1 width=264) (actual time=0.831..1.057 rows=70.00 loops=1)
                                       Join Filter: (a.id_person = p.id)
                                       Buffers: shared hit=307
                                       ->  Nested Loop  (cost=0.31..14.64 rows=1 width=116) (actual time=0.812..0.966 rows=70.00 loops=1)
                                             Buffers: shared hit=167
                                             ->  Nested Loop  (cost=0.16..13.95 rows=1 width=112) (actual time=0.136..0.222 rows=70.00 loops=1)
                                                   Buffers: shared hit=27
                                                   ->  Seq Scan on allocations a  (cost=0.00..1.91 rows=91 width=22) (actual time=0.075..0.082 rows=91.00 loops=1)
                                                         Buffers: shared hit=1
                                                   ->  Memoize  (cost=0.16..0.71 rows=1 width=90) (actual time=0.001..0.001 rows=0.77 loops=91)
                                                         Cache Key: a.instance_id
                                                         Cache Mode: logical
                                                         Hits: 78  Misses: 13  Evictions: 0  Overflows: 0  Memory Usage: 2kB
                                                         Buffers: shared hit=26
                                                         ->  Index Scan using pk_course_instance on course_instance ci  (cost=0.15..0.70 rows=1 width=90) (actual time=0.005..0.005 rows=0.77 loops=13)
                                                               Index Cond: ((instance_id)::text = (a.instance_id)::text)
                                                               Filter: ((study_year)::numeric = EXTRACT(year FROM CURRENT_DATE))
                                                               Rows Removed by Filter: 0
                                                               Index Searches: 13
                                                               Buffers: shared hit=26
                                             ->  Index Only Scan using pk_employee on employee e  (cost=0.15..0.69 rows=1 width=4) (actual time=0.010..0.010 rows=1.00 loops=70)
                                                   Index Cond: (id_person = a.id_person)
                                                   Heap Fetches: 70
                                                   Index Searches: 70
                                                   Buffers: shared hit=140
                                       ->  Index Scan using pk_person on person p  (cost=0.15..0.29 rows=1 width=160) (actual time=0.001..0.001 rows=1.00 loops=70)
                                             Index Cond: (id = e.id_person)
                                             Index Searches: 70
                                             Buffers: shared hit=140
                                 ->  Index Scan using pk_planned_activity on planned_activity pa  (cost=0.14..0.29 rows=1 width=22) (actual time=0.001..0.001 rows=1.00 loops=70)
                                       Index Cond: ((id_teaching = a.id_teaching) AND ((instance_id)::text = (a.instance_id)::text))
                                       Index Searches: 70
                                       Buffers: shared hit=140
                           ->  Index Scan using pk_teaching_activity on teaching_activity ta  (cost=0.15..0.66 rows=1 width=90) (actual time=0.001..0.001 rows=1.00 loops=70)
                                 Index Cond: (id = pa.id_teaching)
                                 Index Searches: 70
                                 Buffers: shared hit=140
                     ->  Index Scan using pk_course_layout on course_layout cl  (cost=0.15..6.83 rows=1 width=90) (actual time=0.001..0.001 rows=1.00 loops=70)
                           Index Cond: (id = ci.id_layout)
                           Index Searches: 70
                           Buffers: shared hit=140
               ->  Index Scan using pk_study_period_enum on study_period_enum sp  (cost=0.15..6.84 rows=1 width=16) (actual time=0.001..0.001 rows=1.00 loops=70)
                     Index Cond: (study_period_id = ci.study_period_id)
                     Index Searches: 70
                     Buffers: shared hit=140
 Planning Time: 9.935 ms
 Execution Time: 1.840 ms
(63 rows)

QUERY 4
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

RESULTS EXPLAIN ANALYZE AFTER

QUERY 2 After:

iv1351=# EXPLAIN ANALYZE
iv1351-# SELECT *
iv1351-# FROM mv_teacher_allocations;
                                                      QUERY PLAN                                                       
-----------------------------------------------------------------------------------------------------------------------
 Seq Scan on mv_teacher_allocations  (cost=0.00..2.64 rows=64 width=126) (actual time=0.029..0.067 rows=64.00 loops=1)
   Buffers: shared hit=2
 Planning:
   Buffers: shared hit=44
 Planning Time: 0.473 ms
 Execution Time: 0.097 ms
(6 rows)

QUERY 1 After:
                                                                           QUERY PLAN                                                                            
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=7.29..8.33 rows=7 width=244) (actual time=0.392..0.509 rows=11.00 loops=1)
   Group Key: cl.course_code, ci.instance_id, sp.study_period
   Buffers: shared hit=15
   ->  Sort  (cost=7.29..7.30 rows=7 width=270) (actual time=0.352..0.365 rows=77.00 loops=1)
         Sort Key: cl.course_code, ci.instance_id, sp.study_period
         Sort Method: quicksort  Memory: 30kB
         Buffers: shared hit=15
         ->  Hash Join  (cost=4.74..7.19 rows=7 width=270) (actual time=0.167..0.273 rows=77.00 loops=1)
               Hash Cond: (pa.id_teaching = ta.id)
               Buffers: shared hit=15
               ->  Hash Join  (cost=3.58..6.00 rows=7 width=188) (actual time=0.119..0.188 rows=77.00 loops=1)
                     Hash Cond: ((pa.instance_id)::text = (ci.instance_id)::text)
                     Buffers: shared hit=14
                     ->  Seq Scan on planned_activity pa  (cost=0.00..1.98 rows=98 width=22) (actual time=0.009..0.022 rows=98.00 loops=1)
                           Buffers: shared hit=1
                     ->  Hash  (cost=3.57..3.57 rows=1 width=180) (actual time=0.102..0.105 rows=11.00 loops=1)
                           Buckets: 1024  Batches: 1  Memory Usage: 9kB
                           Buffers: shared hit=13
                           ->  Nested Loop  (cost=1.29..3.57 rows=1 width=180) (actual time=0.055..0.095 rows=11.00 loops=1)
                                 Join Filter: (sp.study_period_id = ci.study_period_id)
                                 Rows Removed by Join Filter: 8
                                 Buffers: shared hit=13
                                 ->  Hash Join  (cost=1.29..2.48 rows=1 width=172) (actual time=0.045..0.057 rows=11.00 loops=1)
                                       Hash Cond: (cl.id = ci.id_layout)
                                       Buffers: shared hit=2
                                       ->  Seq Scan on course_layout cl  (cost=0.00..1.13 rows=13 width=90) (actual time=0.009..0.011 rows=13.00 loops=1)
                                             Buffers: shared hit=1
                                       ->  Hash  (cost=1.28..1.28 rows=1 width=90) (actual time=0.027..0.028 rows=11.00 loops=1)
                                             Buckets: 1024  Batches: 1  Memory Usage: 9kB
                                             Buffers: shared hit=1
                                             ->  Seq Scan on course_instance ci  (cost=0.00..1.28 rows=1 width=90) (actual time=0.013..0.022 rows=11.00 loops=1)
                                                   Filter: ((study_year)::numeric = EXTRACT(year FROM CURRENT_DATE))
                                                   Rows Removed by Filter: 3
                                                   Buffers: shared hit=1
                                 ->  Seq Scan on study_period_enum sp  (cost=0.00..1.04 rows=4 width=16) (actual time=0.001..0.001 rows=1.73 loops=11)
                                       Buffers: shared hit=11
               ->  Hash  (cost=1.07..1.07 rows=7 width=90) (actual time=0.040..0.040 rows=7.00 loops=1)
                     Buckets: 1024  Batches: 1  Memory Usage: 9kB
                     Buffers: shared hit=1
                     ->  Seq Scan on teaching_activity ta  (cost=0.00..1.07 rows=7 width=90) (actual time=0.029..0.032 rows=7.00 loops=1)
                           Buffers: shared hit=1
 Planning Time: 1.120 ms
 Execution Time: 0.631 ms
(43 rows)


QUERY 3 After: 
                                                                                       QUERY PLAN                                                                                        
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=14.90..15.84 rows=6 width=272) (actual time=0.772..0.891 rows=64.00 loops=1)
   Group Key: ((((p.first_name)::text || ' '::text) || (p.last_name)::text)), ci.instance_id, cl.course_code, sp.study_period
   Buffers: shared hit=435
   ->  Sort  (cost=14.90..14.91 rows=6 width=302) (actual time=0.744..0.756 rows=70.00 loops=1)
         Sort Key: ((((p.first_name)::text || ' '::text) || (p.last_name)::text)), ci.instance_id, cl.course_code, sp.study_period
         Sort Method: quicksort  Memory: 31kB
         Buffers: shared hit=435
         ->  Hash Join  (cost=5.18..14.82 rows=6 width=302) (actual time=0.195..0.684 rows=70.00 loops=1)
               Hash Cond: (a.id_teaching = ta.id)
               Buffers: shared hit=435
               ->  Nested Loop  (cost=4.02..13.61 rows=6 width=348) (actual time=0.160..0.609 rows=70.00 loops=1)
                     Buffers: shared hit=434
                     ->  Nested Loop  (cost=3.88..11.84 rows=6 width=354) (actual time=0.142..0.428 rows=70.00 loops=1)
                           Join Filter: (a.id_person = p.id)
                           Buffers: shared hit=294
                           ->  Nested Loop  (cost=3.73..10.05 rows=6 width=206) (actual time=0.124..0.289 rows=70.00 loops=1)
                                 Buffers: shared hit=154
                                 ->  Hash Join  (cost=3.58..5.90 rows=6 width=202) (actual time=0.098..0.153 rows=70.00 loops=1)
                                       Hash Cond: ((a.instance_id)::text = (ci.instance_id)::text)
                                       Buffers: shared hit=14
                                       ->  Seq Scan on allocations a  (cost=0.00..1.91 rows=91 width=22) (actual time=0.008..0.019 rows=91.00 loops=1)
                                             Buffers: shared hit=1
                                       ->  Hash  (cost=3.57..3.57 rows=1 width=180) (actual time=0.085..0.088 rows=11.00 loops=1)
                                             Buckets: 1024  Batches: 1  Memory Usage: 9kB
                                             Buffers: shared hit=13
                                             ->  Nested Loop  (cost=1.29..3.57 rows=1 width=180) (actual time=0.052..0.082 rows=11.00 loops=1)
                                                   Join Filter: (sp.study_period_id = ci.study_period_id)
                                                   Rows Removed by Join Filter: 8
                                                   Buffers: shared hit=13
                                                   ->  Hash Join  (cost=1.29..2.48 rows=1 width=172) (actual time=0.042..0.052 rows=11.00 loops=1)
                                                         Hash Cond: (cl.id = ci.id_layout)
                                                         Buffers: shared hit=2
                                                         ->  Seq Scan on course_layout cl  (cost=0.00..1.13 rows=13 width=90) (actual time=0.012..0.014 rows=13.00 loops=1)
                                                               Buffers: shared hit=1
                                                         ->  Hash  (cost=1.28..1.28 rows=1 width=90) (actual time=0.019..0.020 rows=11.00 loops=1)
                                                               Buckets: 1024  Batches: 1  Memory Usage: 9kB
                                                               Buffers: shared hit=1
                                                               ->  Seq Scan on course_instance ci  (cost=0.00..1.28 rows=1 width=90) (actual time=0.011..0.016 rows=11.00 loops=1)
                                                                     Filter: ((study_year)::numeric = EXTRACT(year FROM CURRENT_DATE))
                                                                     Rows Removed by Filter: 3
                                                                     Buffers: shared hit=1
                                                   ->  Seq Scan on study_period_enum sp  (cost=0.00..1.04 rows=4 width=16) (actual time=0.001..0.001 rows=1.73 loops=11)
                                                         Buffers: shared hit=11
                                 ->  Index Only Scan using pk_employee on employee e  (cost=0.15..0.69 rows=1 width=4) (actual time=0.001..0.001 rows=1.00 loops=70)
                                       Index Cond: (id_person = a.id_person)
                                       Heap Fetches: 70
                                       Index Searches: 70
                                       Buffers: shared hit=140
                           ->  Index Scan using pk_person on person p  (cost=0.15..0.29 rows=1 width=160) (actual time=0.001..0.001 rows=1.00 loops=70)
                                 Index Cond: (id = e.id_person)
                                 Index Searches: 70
                                 Buffers: shared hit=140
                     ->  Index Scan using idx_planned_activity_teaching_instance on planned_activity pa  (cost=0.14..0.29 rows=1 width=22) (actual time=0.002..0.002 rows=1.00 loops=70)
                           Index Cond: ((id_teaching = a.id_teaching) AND ((instance_id)::text = (a.instance_id)::text))
                           Index Searches: 70
                           Buffers: shared hit=140
               ->  Hash  (cost=1.07..1.07 rows=7 width=90) (actual time=0.028..0.029 rows=7.00 loops=1)
                     Buckets: 1024  Batches: 1  Memory Usage: 9kB
                     Buffers: shared hit=1
                     ->  Seq Scan on teaching_activity ta  (cost=0.00..1.07 rows=7 width=90) (actual time=0.021..0.023 rows=7.00 loops=1)
                           Buffers: shared hit=1
 Planning Time: 9.672 ms
 Execution Time: 1.022 ms
(63 rows)

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

iv1351=# 
iv1351=#  */
