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

QUERY 1 After:
                                                                                     QUERY PLAN                                                                                     
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=24.79..25.84 rows=7 width=244) (actual time=0.672..0.793 rows=11.00 loops=1)
   Group Key: cl.course_code, ci.instance_id, sp.study_period
   Buffers: shared hit=200
   ->  Sort  (cost=24.79..24.81 rows=7 width=270) (actual time=0.619..0.634 rows=77.00 loops=1)
         Sort Key: cl.course_code, ci.instance_id, sp.study_period
         Sort Method: quicksort  Memory: 30kB
         Buffers: shared hit=200
         ->  Nested Loop  (cost=17.83..24.70 rows=7 width=270) (actual time=0.314..0.525 rows=77.00 loops=1)
               Buffers: shared hit=200
               ->  Hash Join  (cost=17.68..20.09 rows=7 width=188) (actual time=0.298..0.371 rows=77.00 loops=1)
                     Hash Cond: ((pa.instance_id)::text = (ci.instance_id)::text)
                     Buffers: shared hit=46
                     ->  Seq Scan on planned_activity pa  (cost=0.00..1.98 rows=98 width=22) (actual time=0.055..0.069 rows=98.00 loops=1)
                           Buffers: shared hit=1
                     ->  Hash  (cost=17.66..17.66 rows=1 width=180) (actual time=0.214..0.216 rows=11.00 loops=1)
                           Buckets: 1024  Batches: 1  Memory Usage: 9kB
                           Buffers: shared hit=45
                           ->  Nested Loop  (cost=0.30..17.66 rows=1 width=180) (actual time=0.089..0.149 rows=11.00 loops=1)
                                 Buffers: shared hit=45
                                 ->  Nested Loop  (cost=0.15..9.48 rows=1 width=172) (actual time=0.051..0.091 rows=11.00 loops=1)
                                       Buffers: shared hit=23
                                       ->  Seq Scan on course_instance ci  (cost=0.00..1.28 rows=1 width=90) (actual time=0.023..0.036 rows=11.00 loops=1)
                                             Filter: ((study_year)::numeric = EXTRACT(year FROM CURRENT_DATE))
                                             Rows Removed by Filter: 3
                                             Buffers: shared hit=1
                                       ->  Index Scan using pk_course_layout on course_layout cl  (cost=0.15..8.17 rows=1 width=90) (actual time=0.003..0.003 rows=1.00 loops=11)
                                             Index Cond: (id = ci.id_layout)
                                             Index Searches: 11
                                             Buffers: shared hit=22
                                 ->  Index Scan using pk_study_period_enum on study_period_enum sp  (cost=0.15..8.17 rows=1 width=16) (actual time=0.004..0.004 rows=1.00 loops=11)
                                       Index Cond: (study_period_id = ci.study_period_id)
                                       Index Searches: 11
                                       Buffers: shared hit=22
               ->  Index Scan using pk_teaching_activity on teaching_activity ta  (cost=0.15..0.66 rows=1 width=90) (actual time=0.001..0.001 rows=1.00 loops=77)
                     Index Cond: (id = pa.id_teaching)
                     Index Searches: 77
                     Buffers: shared hit=154
 Planning:
   Buffers: shared hit=24 dirtied=1
 Planning Time: 1.580 ms
 Execution Time: 0.925 ms
(41 rows)

QUERY 2 Before: 
                                                                                               QUERY PLAN                                                                                               
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=29.65..29.76 rows=1 width=386) (actual time=1.633..1.925 rows=64.00 loops=1)
   Group Key: cl.course_code, ci.instance_id, ((((p.first_name)::text || ' '::text) || (p.last_name)::text)), jt.job_title
   Buffers: shared hit=867
   ->  Sort  (cost=29.65..29.65 rows=1 width=365) (actual time=1.595..1.611 rows=70.00 loops=1)
         Sort Key: cl.course_code, ci.instance_id, ((((p.first_name)::text || ' '::text) || (p.last_name)::text)), jt.job_title
         Sort Method: quicksort  Memory: 32kB
         Buffers: shared hit=867
         ->  Nested Loop  (cost=1.05..29.64 rows=1 width=365) (actual time=0.258..1.476 rows=70.00 loops=1)
               Buffers: shared hit=867
               ->  Nested Loop  (cost=0.90..22.79 rows=1 width=493) (actual time=0.150..1.186 rows=70.00 loops=1)
                     Buffers: shared hit=727
                     ->  Nested Loop  (cost=0.76..15.93 rows=1 width=411) (actual time=0.133..0.997 rows=70.00 loops=1)
                           Buffers: shared hit=587
                           ->  Nested Loop  (cost=0.60..15.23 rows=1 width=329) (actual time=0.119..0.816 rows=70.00 loops=1)
                                 Buffers: shared hit=447
                                 ->  Nested Loop  (cost=0.45..14.94 rows=1 width=255) (actual time=0.104..0.642 rows=70.00 loops=1)
                                       Join Filter: (a.id_person = p.id)
                                       Buffers: shared hit=307
                                       ->  Nested Loop  (cost=0.31..14.64 rows=1 width=107) (actual time=0.085..0.438 rows=70.00 loops=1)
                                             Buffers: shared hit=167
                                             ->  Nested Loop  (cost=0.16..13.95 rows=1 width=99) (actual time=0.065..0.230 rows=70.00 loops=1)
                                                   Buffers: shared hit=27
                                                   ->  Seq Scan on allocations a  (cost=0.00..1.91 rows=91 width=27) (actual time=0.024..0.041 rows=91.00 loops=1)
                                                         Buffers: shared hit=1
                                                   ->  Memoize  (cost=0.16..0.71 rows=1 width=86) (actual time=0.001..0.001 rows=0.77 loops=91)
                                                         Cache Key: a.instance_id
                                                         Cache Mode: logical
                                                         Hits: 78  Misses: 13  Evictions: 0  Overflows: 0  Memory Usage: 2kB
                                                         Buffers: shared hit=26
                                                         ->  Index Scan using pk_course_instance on course_instance ci  (cost=0.15..0.70 rows=1 width=86) (actual time=0.005..0.005 rows=0.77 loops=13)
                                                               Index Cond: ((instance_id)::text = (a.instance_id)::text)
                                                               Filter: ((study_year)::numeric = EXTRACT(year FROM CURRENT_DATE))
                                                               Rows Removed by Filter: 0
                                                               Index Searches: 13
                                                               Buffers: shared hit=26
                                             ->  Index Scan using pk_employee on employee e  (cost=0.15..0.69 rows=1 width=8) (actual time=0.002..0.002 rows=1.00 loops=70)
                                                   Index Cond: (id_person = a.id_person)
                                                   Index Searches: 70
                                                   Buffers: shared hit=140
                                       ->  Index Scan using pk_person on person p  (cost=0.15..0.29 rows=1 width=160) (actual time=0.002..0.002 rows=1.00 loops=70)
                                             Index Cond: (id = e.id_person)
                                             Index Searches: 70
                                             Buffers: shared hit=140
                                 ->  Index Scan using pk_job_title on job_title jt  (cost=0.15..0.29 rows=1 width=82) (actual time=0.002..0.002 rows=1.00 loops=70)
                                       Index Cond: (id = e.id_job)
                                       Index Searches: 70
                                       Buffers: shared hit=140
                           ->  Index Scan using pk_teaching_activity on teaching_activity ta  (cost=0.15..0.69 rows=1 width=90) (actual time=0.002..0.002 rows=1.00 loops=70)
                                 Index Cond: (id = a.id_teaching)
                                 Index Searches: 70
                                 Buffers: shared hit=140
                     ->  Index Scan using pk_course_layout on course_layout cl  (cost=0.15..6.83 rows=1 width=90) (actual time=0.002..0.002 rows=1.00 loops=70)
                           Index Cond: (id = ci.id_layout)
                           Index Searches: 70
                           Buffers: shared hit=140
               ->  Index Only Scan using pk_study_period_enum on study_period_enum sp  (cost=0.15..6.84 rows=1 width=4) (actual time=0.003..0.003 rows=1.00 loops=70)
                     Index Cond: (study_period_id = ci.study_period_id)
                     Heap Fetches: 70
                     Index Searches: 70
                     Buffers: shared hit=140
 Planning:
   Buffers: shared hit=86
 Planning Time: 5.035 ms
 Execution Time: 2.148 ms
(64 rows)

QUERY 2 After (using MV):
                                                         QUERY PLAN                                                          
-----------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=4.56..4.72 rows=64 width=116) (actual time=0.045..0.049 rows=64.00 loops=1)
   Sort Key: "Course Code", "Course Instance ID", "Teacher's Name"
   Sort Method: quicksort  Memory: 33kB
   Buffers: shared hit=2
   ->  Seq Scan on mv_teacher_allocations  (cost=0.00..2.64 rows=64 width=116) (actual time=0.015..0.020 rows=64.00 loops=1)
         Buffers: shared hit=2
 Planning:
   Buffers: shared hit=44 dirtied=5
 Planning Time: 0.455 ms
 Execution Time: 0.070 ms
(10 rows)

QUERY 2 After (using index):
                                                                                                QUERY PLAN                                                                                                
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=31.93..32.60 rows=6 width=386) (actual time=1.101..1.324 rows=64.00 loops=1)
   Group Key: cl.course_code, ci.instance_id, ((((p.first_name)::text || ' '::text) || (p.last_name)::text)), jt.job_title
   Buffers: shared hit=606
   ->  Sort  (cost=31.93..31.95 rows=6 width=365) (actual time=1.066..1.079 rows=70.00 loops=1)
         Sort Key: cl.course_code, ci.instance_id, ((((p.first_name)::text || ' '::text) || (p.last_name)::text)), jt.job_title
         Sort Method: quicksort  Memory: 32kB
         Buffers: shared hit=606
         ->  Nested Loop  (cost=18.27..31.86 rows=6 width=365) (actual time=0.263..0.953 rows=70.00 loops=1)
               Buffers: shared hit=606
               ->  Nested Loop  (cost=18.12..27.66 rows=6 width=407) (actual time=0.250..0.782 rows=70.00 loops=1)
                     Buffers: shared hit=466
                     ->  Nested Loop  (cost=17.97..25.93 rows=6 width=333) (actual time=0.237..0.629 rows=70.00 loops=1)
                           Join Filter: (a.id_person = p.id)
                           Buffers: shared hit=326
                           ->  Nested Loop  (cost=17.82..24.14 rows=6 width=185) (actual time=0.225..0.456 rows=70.00 loops=1)
                                 Buffers: shared hit=186
                                 ->  Hash Join  (cost=17.68..19.99 rows=6 width=177) (actual time=0.210..0.281 rows=70.00 loops=1)
                                       Hash Cond: ((a.instance_id)::text = (ci.instance_id)::text)
                                       Buffers: shared hit=46
                                       ->  Seq Scan on allocations a  (cost=0.00..1.91 rows=91 width=27) (actual time=0.033..0.047 rows=91.00 loops=1)
                                             Buffers: shared hit=1
                                       ->  Hash  (cost=17.66..17.66 rows=1 width=164) (actual time=0.164..0.165 rows=11.00 loops=1)
                                             Buckets: 1024  Batches: 1  Memory Usage: 9kB
                                             Buffers: shared hit=45
                                             ->  Nested Loop  (cost=0.30..17.66 rows=1 width=164) (actual time=0.067..0.124 rows=11.00 loops=1)
                                                   Buffers: shared hit=45
                                                   ->  Nested Loop  (cost=0.15..9.48 rows=1 width=168) (actual time=0.048..0.084 rows=11.00 loops=1)
                                                         Buffers: shared hit=23
                                                         ->  Seq Scan on course_instance ci  (cost=0.00..1.28 rows=1 width=86) (actual time=0.015..0.025 rows=11.00 loops=1)
                                                               Filter: ((study_year)::numeric = EXTRACT(year FROM CURRENT_DATE))
                                                               Rows Removed by Filter: 3
                                                               Buffers: shared hit=1
                                                         ->  Index Scan using pk_course_layout on course_layout cl  (cost=0.15..8.17 rows=1 width=90) (actual time=0.004..0.004 rows=1.00 loops=11)
                                                               Index Cond: (id = ci.id_layout)
                                                               Index Searches: 11
                                                               Buffers: shared hit=22
                                                   ->  Index Only Scan using pk_study_period_enum on study_period_enum sp  (cost=0.15..8.17 rows=1 width=4) (actual time=0.003..0.003 rows=1.00 loops=11)
                                                         Index Cond: (study_period_id = ci.study_period_id)
                                                         Heap Fetches: 11
                                                         Index Searches: 11
                                                         Buffers: shared hit=22
                                 ->  Index Scan using pk_employee on employee e  (cost=0.15..0.69 rows=1 width=8) (actual time=0.002..0.002 rows=1.00 loops=70)
                                       Index Cond: (id_person = a.id_person)
                                       Index Searches: 70
                                       Buffers: shared hit=140
                           ->  Index Scan using pk_person on person p  (cost=0.15..0.29 rows=1 width=160) (actual time=0.002..0.002 rows=1.00 loops=70)
                                 Index Cond: (id = e.id_person)
                                 Index Searches: 70
                                 Buffers: shared hit=140
                     ->  Index Scan using pk_job_title on job_title jt  (cost=0.15..0.29 rows=1 width=82) (actual time=0.001..0.001 rows=1.00 loops=70)
                           Index Cond: (id = e.id_job)
                           Index Searches: 70
                           Buffers: shared hit=140
               ->  Index Scan using pk_teaching_activity on teaching_activity ta  (cost=0.15..0.69 rows=1 width=90) (actual time=0.001..0.001 rows=1.00 loops=70)
                     Index Cond: (id = a.id_teaching)
                     Index Searches: 70
                     Buffers: shared hit=140
 Planning Time: 4.354 ms
 Execution Time: 1.497 ms
(59 rows)

QUERY 3 Before:
                                                                                           QUERY PLAN                                                                                           
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=26.43..26.54 rows=1 width=320) (actual time=0.365..0.383 rows=3.00 loops=1)
   Group Key: ((((p.first_name)::text || ' '::text) || (p.last_name)::text)), ci.instance_id, cl.course_code, sp.study_period
   Buffers: shared hit=42
   ->  Sort  (cost=26.43..26.43 rows=1 width=299) (actual time=0.304..0.313 rows=3.00 loops=1)
         Sort Key: ((((p.first_name)::text || ' '::text) || (p.last_name)::text)), ci.instance_id, cl.course_code, sp.study_period
         Sort Method: quicksort  Memory: 25kB
         Buffers: shared hit=42
         ->  Nested Loop  (cost=8.93..26.42 rows=1 width=299) (actual time=0.158..0.261 rows=3.00 loops=1)
               Buffers: shared hit=39
               ->  Nested Loop  (cost=8.77..19.57 rows=1 width=415) (actual time=0.140..0.236 rows=3.00 loops=1)
                     Buffers: shared hit=33
                     ->  Nested Loop  (cost=8.63..12.70 rows=1 width=333) (actual time=0.124..0.190 rows=3.00 loops=1)
                           Buffers: shared hit=27
                           ->  Nested Loop  (cost=8.48..11.72 rows=1 width=261) (actual time=0.099..0.152 rows=4.00 loops=1)
                                 Buffers: shared hit=19
                                 ->  Nested Loop  (cost=8.33..11.02 rows=1 width=179) (actual time=0.081..0.125 rows=4.00 loops=1)
                                       Buffers: shared hit=11
                                       ->  Hash Join  (cost=8.18..10.33 rows=1 width=31) (actual time=0.066..0.100 rows=4.00 loops=1)
                                             Hash Cond: (a.id_person = e.id_person)
                                             Buffers: shared hit=3
                                             ->  Seq Scan on allocations a  (cost=0.00..1.91 rows=91 width=27) (actual time=0.022..0.037 rows=91.00 loops=1)
                                                   Buffers: shared hit=1
                                             ->  Hash  (cost=8.17..8.17 rows=1 width=4) (actual time=0.024..0.025 rows=1.00 loops=1)
                                                   Buckets: 1024  Batches: 1  Memory Usage: 9kB
                                                   Buffers: shared hit=2
                                                   ->  Index Scan using employee_employment_id_key on employee e  (cost=0.15..8.17 rows=1 width=4) (actual time=0.013..0.014 rows=1.00 loops=1)
                                                         Index Cond: ((employment_id)::text = 'CS-1002'::text)
                                                         Index Searches: 1
                                                         Buffers: shared hit=2
                                       ->  Index Scan using pk_person on person p  (cost=0.15..0.69 rows=1 width=160) (actual time=0.004..0.004 rows=1.00 loops=4)
                                             Index Cond: (id = a.id_person)
                                             Index Searches: 4
                                             Buffers: shared hit=8
                                 ->  Index Scan using pk_teaching_activity on teaching_activity ta  (cost=0.15..0.69 rows=1 width=90) (actual time=0.005..0.005 rows=1.00 loops=4)
                                       Index Cond: (id = a.id_teaching)
                                       Index Searches: 4
                                       Buffers: shared hit=8
                           ->  Index Scan using pk_course_instance on course_instance ci  (cost=0.15..0.70 rows=1 width=86) (actual time=0.008..0.008 rows=0.75 loops=4)
                                 Index Cond: ((instance_id)::text = (a.instance_id)::text)
                                 Filter: ((study_year)::numeric = EXTRACT(year FROM CURRENT_DATE))
                                 Rows Removed by Filter: 0
                                 Index Searches: 4
                                 Buffers: shared hit=8
                     ->  Index Scan using pk_course_layout on course_layout cl  (cost=0.15..6.83 rows=1 width=90) (actual time=0.006..0.006 rows=1.00 loops=3)
                           Index Cond: (id = ci.id_layout)
                           Index Searches: 3
                           Buffers: shared hit=6
               ->  Index Scan using pk_study_period_enum on study_period_enum sp  (cost=0.15..6.84 rows=1 width=16) (actual time=0.006..0.006 rows=1.00 loops=3)
                     Index Cond: (study_period_id = ci.study_period_id)
                     Index Searches: 3
                     Buffers: shared hit=6
 Planning:
   Buffers: shared hit=12
 Planning Time: 2.717 ms
 Execution Time: 0.713 ms
(55 rows)

QUERY 3 After:
                                                                             QUERY PLAN                                                                                  
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=25.61..25.73 rows=1 width=320) (actual time=0.324..0.332 rows=3.00 loops=1)
   Group Key: ((((p.first_name)::text || ' '::text) || (p.last_name)::text)), ci.instance_id, cl.course_code, sp.study_period
   Buffers: shared hit=82
   ->  Sort  (cost=25.61..25.62 rows=1 width=299) (actual time=0.298..0.302 rows=3.00 loops=1)
         Sort Key: ((((p.first_name)::text || ' '::text) || (p.last_name)::text)), ci.instance_id, cl.course_code, sp.study_period
         Sort Method: quicksort  Memory: 25kB
         Buffers: shared hit=82
         ->  Nested Loop  (cost=2.05..25.60 rows=1 width=299) (actual time=0.147..0.253 rows=3.00 loops=1)
               Buffers: shared hit=82
               ->  Nested Loop  (cost=1.89..17.42 rows=1 width=415) (actual time=0.138..0.240 rows=3.00 loops=1)
                     Buffers: shared hit=76
                     ->  Nested Loop  (cost=1.75..9.22 rows=1 width=333) (actual time=0.130..0.228 rows=3.00 loops=1)
                           Buffers: shared hit=70
                           ->  Nested Loop  (cost=1.60..8.52 rows=1 width=251) (actual time=0.122..0.216 rows=3.00 loops=1)
                                 Buffers: shared hit=64
                                 ->  Nested Loop  (cost=1.45..7.82 rows=1 width=103) (actual time=0.114..0.204 rows=3.00 loops=1)
                                       Buffers: shared hit=58
                                       ->  Hash Join  (cost=1.29..3.51 rows=6 width=99) (actual time=0.067..0.101 rows=70.00 loops=1)
                                             Hash Cond: ((a.instance_id)::text = (ci.instance_id)::text)
                                             Buffers: shared hit=2
                                             ->  Seq Scan on allocations a  (cost=0.00..1.91 rows=91 width=27) (actual time=0.031..0.038 rows=91.00 loops=1)
                                                   Buffers: shared hit=1
                                             ->  Hash  (cost=1.28..1.28 rows=1 width=86) (actual time=0.027..0.027 rows=11.00 loops=1)
                                                   Buckets: 1024  Batches: 1  Memory Usage: 9kB
                                                   Buffers: shared hit=1
                                                   ->  Seq Scan on course_instance ci  (cost=0.00..1.28 rows=1 width=86) (actual time=0.015..0.020 rows=11.00 loops=1)
                                                         Filter: ((study_year)::numeric = EXTRACT(year FROM CURRENT_DATE))
                                                         Rows Removed by Filter: 3
                                                         Buffers: shared hit=1
                                       ->  Memoize  (cost=0.16..0.70 rows=1 width=4) (actual time=0.001..0.001 rows=0.04 loops=70)
                                             Cache Key: a.id_person
                                             Cache Mode: logical
                                             Hits: 42  Misses: 28  Evictions: 0  Overflows: 0  Memory Usage: 2kB
                                             Buffers: shared hit=56
                                             ->  Index Scan using pk_employee on employee e  (cost=0.15..0.69 rows=1 width=4) (actual time=0.002..0.002 rows=0.04 loops=28)
                                                   Index Cond: (id_person = a.id_person)
                                                   Filter: ((employment_id)::text = 'CS-1002'::text)
                                                   Rows Removed by Filter: 1
                                                   Index Searches: 28
                                                   Buffers: shared hit=56
                                 ->  Index Scan using pk_person on person p  (cost=0.15..0.69 rows=1 width=160) (actual time=0.003..0.003 rows=1.00 loops=3)
                                       Index Cond: (id = a.id_person)
                                       Index Searches: 3
                                       Buffers: shared hit=6
                           ->  Index Scan using pk_teaching_activity on teaching_activity ta  (cost=0.15..0.69 rows=1 width=90) (actual time=0.003..0.003 rows=1.00 loops=3)
                                 Index Cond: (id = a.id_teaching)
                                 Index Searches: 3
                                 Buffers: shared hit=6
                     ->  Index Scan using pk_course_layout on course_layout cl  (cost=0.15..8.17 rows=1 width=90) (actual time=0.003..0.003 rows=1.00 loops=3)
                           Index Cond: (id = ci.id_layout)
                           Index Searches: 3
                           Buffers: shared hit=6
               ->  Index Scan using pk_study_period_enum on study_period_enum sp  (cost=0.15..8.17 rows=1 width=16) (actual time=0.003..0.003 rows=1.00 loops=3)
                     Index Cond: (study_period_id = ci.study_period_id)
                     Index Searches: 3
                     Buffers: shared hit=6
 Planning Time: 3.374 ms
 Execution Time: 0.447 ms
(58 rows)


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
