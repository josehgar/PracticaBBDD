USE hospital_management_system;

-- 3.1)
CREATE VIEW vista_medicamentos_prescritos AS
SELECT m.code AS codigo_medicamento, m.name AS nombre_medicamento, m.brand AS marca_medicamento,
	   p.name AS nombre_paciente, pr.date AS fecha_prescripcion, doc.name AS nombre_doctor
FROM prescribes pr
INNER JOIN medication m ON pr.medicationid = m.code
INNER JOIN patient p ON pr.patientid = p.ssn
INNER JOIN physician doc ON pr.physicianid = doc.employeeid;

-- Para comprobar que funciona
SELECT * FROM vista_medicamentos_prescritos;

-- 3.2)
CREATE USER 'becario' IDENTIFIED BY 'contrasena123';
GRANT SELECT ON hospital_management_system.vista_medicamentos_prescritos TO 'becario';
FLUSH PRIVILEGES;

-- Para comprobar que funciona
SHOW GRANTS FOR 'becario';