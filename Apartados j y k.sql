USE hospital_management_system;

-- APARTADO J)
DROP TRIGGER IF EXISTS intervenciones_medicas;
DROP TRIGGER IF EXISTS check_delete_patient;
DELIMITER $$

CREATE TRIGGER intervenciones_medicas
BEFORE INSERT ON undergoes
FOR EACH ROW
BEGIN
    DECLARE fecha_validez VARCHAR(10);
    
    -- Buscamos el certificado más reciente
    SELECT certificationexpires INTO fecha_validez
    FROM trained_in
    WHERE physicianid = NEW.physicianid  
      AND treatmentid = NEW.procedureid     
    ORDER BY certificationexpires DESC        
    LIMIT 1;

    -- Validaciones
    IF fecha_validez IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: El doctor no tiene certificación requerida';
    ELSEIF fecha_validez < NEW.date THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: Certificado caducado para la fecha del procedimiento';
    END IF;
END$$

DELIMITER ;

-- APARTADO K)
-- 1. Consulta los nombres 
SELECT TABLE_NAME, CONSTRAINT_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE REFERENCED_TABLE_NAME = 'patient'
  AND TABLE_SCHEMA = 'hospital_management_system';

--  2. Modificar tablas para permitir el borrado de pacientes

ALTER TABLE appointments DROP FOREIGN KEY appointments_ibfk_1;
ALTER TABLE appointments
ADD CONSTRAINT fk_appointments_patient_cascade
FOREIGN KEY (patientid) REFERENCES patient(ssn) ON DELETE CASCADE;

ALTER TABLE prescribes DROP FOREIGN KEY prescribes_ibfk_2;
ALTER TABLE prescribes
ADD CONSTRAINT fk_prescribes_patient_cascade
FOREIGN KEY (patientid) REFERENCES patient(ssn) ON DELETE CASCADE;

ALTER TABLE stay DROP FOREIGN KEY stay_ibfk_1;
ALTER TABLE stay
ADD CONSTRAINT fk_stay_patient_cascade
FOREIGN KEY (patientid) REFERENCES patient(ssn) ON DELETE CASCADE;

ALTER TABLE undergoes DROP FOREIGN KEY undergoes_ibfk_1;
ALTER TABLE undergoes
ADD CONSTRAINT fk_undergoes_patient_cascade
FOREIGN KEY (patientid) REFERENCES patient(ssn) ON DELETE CASCADE;

-- Limpiar
DELETE FROM patient WHERE ssn = 999999999;

-- 3. Trigger de control de borrado
DROP TRIGGER IF EXISTS check_delete_patient;
DELIMITER $$
CREATE TRIGGER check_delete_patient
BEFORE DELETE ON patient
FOR EACH ROW
BEGIN
    -- Comprobar citas futuras
    IF (SELECT COUNT(*) FROM appointments 
        WHERE patientid = OLD.ssn 
        AND STR_TO_DATE(start_dt_time, '%Y-%m-%d') > NOW()) > 0 THEN
        
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: No se puede borrar. El paciente tiene citas programadas en el futuro.';
    END IF;

    -- Comprobar procedimientos futuros
    IF (SELECT COUNT(*) FROM undergoes 
        WHERE patientid = OLD.ssn 
        AND STR_TO_DATE(date, '%Y-%m-%d') > NOW()) > 0 THEN
        
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: No se puede borrar. El paciente tiene procedimientos médicos pendientes.';
    END IF;

    -- Comprobar citas recientes (3 años)
    IF (SELECT COUNT(*) FROM appointments 
        WHERE patientid = OLD.ssn 
        AND STR_TO_DATE(start_dt_time, '%Y-%m-%d') BETWEEN DATE_SUB(NOW(), INTERVAL 3 YEAR) AND NOW()) > 0 THEN
        
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: Actividad reciente. El paciente ha tenido citas en los últimos 3 años.';
    END IF;

    -- Comprobar procedimientos recientes (3 años)
    IF (SELECT COUNT(*) FROM undergoes 
        WHERE patientid = OLD.ssn 
        AND STR_TO_DATE(date, '%Y-%m-%d') BETWEEN DATE_SUB(NOW(), INTERVAL 3 YEAR) AND NOW()) > 0 THEN
        
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: Actividad reciente. El paciente se ha sometido a procedimientos en los últimos 3 años.';
    END IF;

    -- Historial de recetas recientes (3 años)
    IF (SELECT COUNT(*) FROM prescribes 
        WHERE patientid = OLD.ssn 
        AND STR_TO_DATE(date, '%Y-%m-%d') BETWEEN DATE_SUB(NOW(), INTERVAL 3 YEAR) AND NOW()) > 0 THEN
        
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: Actividad reciente. Al paciente se le han recetado medicamentos en los últimos 3 años.';
    END IF;

    -- Comprobar estancias recientes (3 años)
    IF (SELECT COUNT(*) FROM stay 
        WHERE patientid = OLD.ssn 
        AND STR_TO_DATE(start_time, '%Y-%m-%d') BETWEEN DATE_SUB(NOW(), INTERVAL 3 YEAR) AND NOW()) > 0 THEN
        
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: Actividad reciente. El paciente ha estado ingresado en los últimos 3 años.';
    END IF;

END$$

DELIMITER ;

-- 4. Pruebas
--  Insertar paciente base (ID 999999999)
INSERT IGNORE INTO physician(employeeid, name, position, ssn) VALUES (1, 'Dr Test', 'Jefe', 111);
INSERT IGNORE INTO nurse(employeeid, name, position, registered, ssn) VALUES (101, 'Enf Test', 'Jefe', '1', 222);
INSERT IGNORE INTO medication(code, name, brand, description) VALUES (1, 'Med Test', 'Brand', 'Desc');

INSERT INTO patient(ssn, name, address, phonenum, insuranceid, pcpid)
VALUES (999999999, 'Test Patient', 'Calle Falsa 123', '555-0000', 9999, 1);

-- PRUEBA 1: Cita futura (Debe fallar)
INSERT INTO appointments(appointmentid, patientid, prepnurseid, physicianid, start_dt_time, end_dt_time, examinationroom)
VALUES (999999, 999999999, 101, 1, '2030-01-01', '2030-01-01', 'A');

-- Intentamos borrar - fallo
DELETE FROM patient WHERE ssn = 999999999;

-- Limpiamos
DELETE FROM appointments WHERE appointmentid = 999999;
DELETE FROM appointments WHERE appointmentid = 888888;
DELETE FROM patient WHERE ssn = 999999999;


-- PRUEBA 2: Actividad reciente (Debe fallar)
/* IMPORTANTE: Volvemos a crear al paciente porque lo borramos en la limpieza anterior */
INSERT INTO patient(ssn, name, address, phonenum, insuranceid, pcpid)
VALUES (999999999, 'Test Patient', 'Calle Falsa 123', '555-0000', 9999, 1);

-- Insertamos cita para poder recetar
INSERT INTO appointments(appointmentid, patientid, prepnurseid, physicianid, start_dt_time, end_dt_time, examinationroom)
VALUES (888888, 999999999, 101, 1, '2023-01-01', '2023-01-01', 'C');

-- Insertamos receta reciente
INSERT INTO prescribes(physicianid, patientid, medicationid, date, appointmentid, dose)
VALUES (1, 999999999, 1, DATE_FORMAT(NOW() - INTERVAL 1 MONTH, '%Y-%m-%d'), 888888, 5); 

-- Intentamos borrar - fallo(correcto)
DELETE FROM patient WHERE ssn = 999999999;

-- Limpiamos datos asociados
DELETE FROM prescribes WHERE patientid = 999999999;
DELETE FROM appointments WHERE appointmentid = 888888;

-- PRUEBA 3: Borrado Exitoso
DELETE FROM patient WHERE ssn = 999999999;

-- Sale vacío
SELECT * FROM patient WHERE ssn = 999999999;
