DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

CREATE TABLE address (
 id INT NOT NULL,
 street VARCHAR(30) NOT NULL,
 zip VARCHAR(30) NOT NULL,
 city VARCHAR(30) NOT NULL
);

ALTER TABLE address ADD CONSTRAINT PK_address PRIMARY KEY (id);


CREATE TABLE course_layout (
 id INT NOT NULL,
 course_code   VARCHAR(30) UNIQUE NOT NULL,
 course_name VARCHAR(30) NOT NULL,
 min_students INT NOT NULL,
 max_students INT NOT NULL,
 hp FLOAT NOT NULL
);

ALTER TABLE course_layout ADD CONSTRAINT PK_course_layout PRIMARY KEY (id);


CREATE TABLE department (
 id INT NOT NULL,
 department_name   VARCHAR(30) UNIQUE NOT NULL,
 id_manager INT
);

ALTER TABLE department ADD CONSTRAINT PK_department PRIMARY KEY (id);


CREATE TABLE employee (
 id_person INT NOT NULL,
 employment_id  VARCHAR(30) UNIQUE NOT NULL,
 salary INT NOT NULL,
 manager VARCHAR(30) ,
 id_job INT NOT NULL,
 id_department INT NOT NULL
);

ALTER TABLE employee ADD CONSTRAINT PK_employee PRIMARY KEY (id_person);


CREATE TABLE job_title (
 id INT NOT NULL,
 job_title   VARCHAR(30) UNIQUE NOT NULL
);

ALTER TABLE job_title ADD CONSTRAINT PK_job_title PRIMARY KEY (id);


CREATE TABLE person (
 id INT NOT NULL,
 personal_number  VARCHAR(30) UNIQUE NOT NULL,
 first_name VARCHAR(30) NOT NULL,
 last_name VARCHAR(30) NOT NULL
);

ALTER TABLE person ADD CONSTRAINT PK_person PRIMARY KEY (id);


CREATE TABLE person_address (
 id_person INT NOT NULL,
 id_address INT NOT NULL
);

ALTER TABLE person_address ADD CONSTRAINT PK_person_address PRIMARY KEY (id_person,id_address);


CREATE TABLE phone_number (
 id INT NOT NULL,
 phone_num   VARCHAR(30) UNIQUE NOT NULL,
 num_type VARCHAR(30) NOT NULL
);

ALTER TABLE phone_number ADD CONSTRAINT PK_phone_number PRIMARY KEY (id);


CREATE TABLE skill_set (
 id INT NOT NULL,
 skill  VARCHAR(30) UNIQUE
);

ALTER TABLE skill_set ADD CONSTRAINT PK_skill_set PRIMARY KEY (id);


CREATE TABLE study_period_ENUM (
 study_period_id INT NOT NULL,
 study_period CHAR(2)
);

ALTER TABLE study_period_ENUM ADD CONSTRAINT PK_study_period_ENUM PRIMARY KEY (study_period_id);

CREATE TABLE system_rules (
 rule_name VARCHAR(10) NOT NULL,
 rule_value INT
 

);

	
ALTER TABLE system_rules ADD CONSTRAINT PK_system_rules PRIMARY KEY (rule_name);

CREATE TABLE teaching_activity(
 id INT NOT NULL,
 activity_name VARCHAR(30) UNIQUE NOT NULL,
 factor FLOAT NOT NULL
);

ALTER TABLE teaching_activity ADD CONSTRAINT PK_teaching_activity PRIMARY KEY (id);


CREATE TABLE course_instance (
 instance_id   VARCHAR(30) UNIQUE NOT NULL,
 num_students INT NOT NULL,
 study_year INT NOT NULL,
 id_layout INT NOT NULL,
 study_period_id INT NOT NULL
);

ALTER TABLE course_instance ADD CONSTRAINT PK_course_instance PRIMARY KEY (instance_id );


CREATE TABLE employee_skill (
 id_skill INT NOT NULL,
 id_person INT NOT NULL
);

ALTER TABLE employee_skill ADD CONSTRAINT PK_employee_skill PRIMARY KEY (id_skill,id_person);


CREATE TABLE person_phone (
 id_person INT NOT NULL,
 id_phone INT NOT NULL
);

ALTER TABLE person_phone ADD CONSTRAINT PK_person_phone PRIMARY KEY (id_person,id_phone);


CREATE TABLE planned_activity (
 id_teaching INT NOT NULL,
 instance_id   VARCHAR(30) NOT NULL,
 planned_hours INT NOT NULL
);

ALTER TABLE planned_activity ADD CONSTRAINT PK_planned_activity PRIMARY KEY (id_teaching,instance_id  );


CREATE TABLE allocations (
 id_person INT NOT NULL,
 id_teaching INT NOT NULL,
 instance_id   VARCHAR(30) NOT NULL
);


CREATE OR REPLACE FUNCTION check_teacher_activities()
RETURNS trigger AS $$
DECLARE
    max_limit INT;
    activity_count INT;
BEGIN

    SELECT rule_value INTO max_limit
    FROM system_rules
    WHERE rule_name = 'max';

    SELECT COUNT(*) INTO activity_count
    FROM allocations
    WHERE id_person = NEW.id_person;

    IF activity_count >= max_limit THEN
        RAISE EXCEPTION 'Teacher already has too many activities';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_check_teacher_activities
BEFORE INSERT OR UPDATE ON allocations
FOR EACH ROW
EXECUTE FUNCTION check_teacher_activities();


ALTER TABLE allocations ADD CONSTRAINT PK_allocations PRIMARY KEY (id_person,id_teaching,instance_id );


ALTER TABLE department ADD CONSTRAINT FK_department_0 FOREIGN KEY (id_manager) REFERENCES employee (id_person) ON DELETE RESTRICT;


ALTER TABLE employee ADD CONSTRAINT FK_employee_0 FOREIGN KEY (id_person) REFERENCES person (id)   ON DELETE CASCADE;
ALTER TABLE employee ADD CONSTRAINT FK_employee_1 FOREIGN KEY (id_job) REFERENCES job_title (id)   ON DELETE CASCADE;
ALTER TABLE employee ADD CONSTRAINT FK_employee_2 FOREIGN KEY (id_department) REFERENCES department (id)   ON DELETE CASCADE;


ALTER TABLE person_address ADD CONSTRAINT FK_person_address_0 FOREIGN KEY (id_person) REFERENCES person (id)   ON DELETE CASCADE;
ALTER TABLE person_address ADD CONSTRAINT FK_person_address_1 FOREIGN KEY (id_address) REFERENCES address (id)   ON DELETE CASCADE;


ALTER TABLE course_instance ADD CONSTRAINT FK_course_instance_0 FOREIGN KEY (id_layout) REFERENCES course_layout (id)   ON DELETE CASCADE;
ALTER TABLE course_instance ADD CONSTRAINT FK_course_instance_1 FOREIGN KEY (study_period_id) REFERENCES study_period_ENUM (study_period_id)   ON DELETE CASCADE;


ALTER TABLE employee_skill ADD CONSTRAINT FK_employee_skill_0 FOREIGN KEY (id_skill) REFERENCES skill_set (id)   ON DELETE CASCADE;
ALTER TABLE employee_skill ADD CONSTRAINT FK_employee_skill_1 FOREIGN KEY (id_person) REFERENCES employee (id_person)   ON DELETE CASCADE;


ALTER TABLE person_phone ADD CONSTRAINT FK_person_phone_0 FOREIGN KEY (id_person) REFERENCES person (id)   ON DELETE CASCADE;
ALTER TABLE person_phone ADD CONSTRAINT FK_person_phone_1 FOREIGN KEY (id_phone) REFERENCES phone_number (id)   ON DELETE CASCADE;


ALTER TABLE planned_activity ADD CONSTRAINT FK_planned_activity_0 FOREIGN KEY (id_teaching) REFERENCES teaching_activity(id)   ON DELETE CASCADE;
ALTER TABLE planned_activity ADD CONSTRAINT FK_planned_activity_1 FOREIGN KEY (instance_id  ) REFERENCES course_instance (instance_id  )   ON DELETE CASCADE;


ALTER TABLE allocations ADD CONSTRAINT FK_allocations_0 FOREIGN KEY (id_person) REFERENCES employee (id_person)   ON DELETE CASCADE;
ALTER TABLE allocations ADD CONSTRAINT FK_allocations_1 FOREIGN KEY (id_teaching,instance_id  ) REFERENCES planned_activity (id_teaching,instance_id  )   ON DELETE CASCADE;
