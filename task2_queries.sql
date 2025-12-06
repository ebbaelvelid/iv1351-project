-- QUERY 1
SELECT
    cl.course_code AS "Course Code",
    ci.instance_id AS "Course Instance ID",
    cl.hp AS "HP",
    sp.study_period AS "Period",
    ci.num_students AS "# Students",

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
             THEN pa.planned_hours + ta.factor * ci.num_students + 2 * cl.hp
             ELSE 0 END) AS "Admin",

    SUM(CASE WHEN ta.activity_name = 'Examination'
             THEN pa.planned_hours + ta.factor * ci.num_students
             ELSE 0 END) AS "Exam",
    
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
    ) AS "Total Hours"

FROM course_instance ci
JOIN course_layout cl ON ci.id_layout = cl.id
JOIN study_period_ENUM sp ON ci.study_period_id = sp.study_period_id
JOIN planned_activity pa ON ci.instance_id = pa.instance_id
JOIN teaching_activity ta ON pa.id_teaching = ta.id
WHERE ci.study_year = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY
    cl.course_code,
    ci.instance_id,
    cl.hp,
    sp.study_period,
    ci.num_students
ORDER BY
    cl.course_code,
    ci.instance_id;

--QUERY 2
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

--QUERY 3 
SELECT
    cl.course_code AS "Course Code",
    ci.instance_id AS "Course Instance ID",
    cl.hp AS "HP",
    sp.study_period AS "Period",
    (p.first_name || ' ' || p.last_name) AS "Teacher's Name",

    SUM(CASE WHEN ta.activity_name = 'Lecture' THEN pa.planned_hours * ta.factor ELSE 0 END) AS "Lecture Hours",
    SUM(CASE WHEN ta.activity_name = 'Tutorial' THEN pa.planned_hours * ta.factor ELSE 0 END) AS "Tutorial Hours",
    SUM(CASE WHEN ta.activity_name = 'Lab' THEN pa.planned_hours * ta.factor ELSE 0 END) AS "Lab Hours",
    SUM(CASE WHEN ta.activity_name = 'Seminar' THEN pa.planned_hours * ta.factor ELSE 0 END) AS "Seminar Hours",
    SUM(CASE WHEN ta.activity_name = 'Others' THEN pa.planned_hours * ta.factor ELSE 0 END) AS "Other Overhead Hours",
    SUM(CASE WHEN ta.activity_name = 'Administration' THEN pa.planned_hours + ta.factor * ci.num_students + 2 * cl.hp ELSE 0 END) AS "Admin",
    SUM(CASE WHEN ta.activity_name = 'Examination' THEN pa.planned_hours + ta.factor * ci.num_students ELSE 0 END) AS "Exam",

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
JOIN planned_activity pa ON a.id_teaching = pa.id_teaching AND a.instance_id = pa.instance_id
JOIN teaching_activity ta ON pa.id_teaching = ta.id
JOIN course_instance ci ON a.instance_id = ci.instance_id
JOIN course_layout cl ON ci.id_layout = cl.id
JOIN study_period_ENUM sp ON ci.study_period_id = sp.study_period_id

WHERE ci.study_year = EXTRACT(YEAR FROM CURRENT_DATE)
AND e.employment_id = 'CS-1002'   -- we pick one teacher

GROUP BY
    cl.course_code,
    ci.instance_id,
    cl.hp,
    sp.study_period,
    "Teacher's Name"

ORDER BY "Teacher's Name", ci.instance_id;

 --QUERY 4
SELECT
    e.employment_id AS "Employment ID",
    (p.first_name || ' ' || p.last_name) AS "Teacher's Name",
    sp.study_period AS "Period",
    COUNT(DISTINCT ci.instance_id) AS "No of courses"
FROM allocations a 
JOIN employee e ON a.id_person = e.id_person 
JOIN person p ON e.id_person = p.id  
JOIN course_instance ci ON a.instance_id  = ci.instance_id  
JOIN study_period_ENUM sp ON ci.study_period_id = sp.study_period_id 
WHERE ci.study_year = EXTRACT(YEAR FROM CURRENT_DATE)
  AND sp.study_period = 'P1'      -- for current period, we choose P1 as the current period
GROUP BY
    e.employment_id, 
    "Teacher's Name",
    sp.study_period
HAVING COUNT(DISTINCT ci.instance_id) > 1    -- here we choose N as 1
ORDER BY "No of courses" ASC, "Teacher's Name";
