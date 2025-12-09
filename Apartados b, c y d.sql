-- queries

-- apartado b)
SELECT physician.name AS Doctor, medication.name AS Medicacion, prescribes.date AS Prescripcion FROM physician INNER JOIN prescribes ON physician.employeeid = prescribes.physicianid
INNER JOIN affiliated_with ON physician.employeeid = affiliated_with.physicianid INNER JOIN department ON affiliated_with.departmentid = department.departmentid 
INNER JOIN medication ON prescribes.medicationId = medication.code
WHERE department.name = 'General Medicine' AND (prescribes.date LIKE '%2023' OR prescribes.date LIKE '%2024');

-- apartado c)
(
SELECT patient.name AS nombre, room.roomnumber AS numero_habitacion, block.blockcodeid as bloque, block.blockfloorid as piso, MAX(str_to_date(stay.end_time, '%d/%m/%Y') - str_to_date(stay.start_time, '%d/%m/%Y')) AS max_ingreso
FROM patient INNER JOIN stay ON patient.ssn = stay.patientid INNER JOIN room ON stay.roomid = room.roomnumber INNER JOIN block ON room.blockcodeid = block.blockcodeid
GROUP BY patient.name, room.roomnumber, block.blockcodeid, block.blockfloorid, patient.ssn
ORDER BY max_ingreso DESC LIMIT 1
)

UNION

(
SELECT patient.name AS nombre, room.roomnumber AS numero_habitacion, block.blockcodeid as bloque, block.blockfloorid as piso, MIN(str_to_date(stay.end_time, '%d/%m/%Y') - str_to_date(stay.start_time, '%d/%m/%Y')) AS max_ingreso
FROM patient INNER JOIN stay ON patient.ssn = stay.patientid INNER JOIN room ON stay.roomid = room.roomnumber INNER JOIN block ON room.blockcodeid = block.blockcodeid
GROUP BY patient.name, room.roomnumber, block.blockcodeid, block.blockfloorid, patient.ssn
ORDER BY max_ingreso ASC LIMIT 1
);

-- apartado d)
UPDATE medication SET description = concat(description, ' (Possible discontinuation)')
WHERE medication.code NOT IN
(SELECT medicationid FROM prescribes
INNER JOIN physician ON prescribes.physicianid = physician.employeeid
INNER JOIN affiliated_with ON physician.employeeid = affiliated_with.physicianid
INNER JOIN department ON affiliated_with.departmentid = department.departmentid
WHERE department.name = 'General Medicine'
AND datediff(curdate(), str_to_date(prescribes.date, '%d/%m/%Y')) <= 730
)
AND medication.description NOT LIKE '%Possible discontinuation%';