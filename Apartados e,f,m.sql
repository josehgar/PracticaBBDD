USE hospital_management_system;

-- e) Opcion sin doctores sin procedimientos
-- SELECT p.name, COUNT(p.name) AS number_procedures, SUM(m.cost) AS total_costs, AVG(m.cost) AS average_costs
-- FROM physician p, undergoes u, medical_procedure m
-- WHERE p.employeeid = u.physicianid
-- AND u.procedureid = m.code
-- GROUP BY p.name
-- ORDER BY number_procedures DESC;


-- e)
SELECT p.name AS nombre_doctor, COUNT(u.procedureid) AS numero_procedimientos, IFNULL(SUM(m.cost), 0) AS coste_total, IFNULL(AVG(m.cost), 0) AS coste_promedio
FROM physician p 
LEFT JOIN undergoes u ON p.employeeid = u.physicianid
LEFT JOIN medical_procedure m ON u.procedureid = m.code
GROUP BY p.employeeid, p.name
ORDER BY numero_procedimientos DESC;

-- f)
SELECT p.name AS Doctor_que_cumple_parametros, p.position AS Posicion 
FROM physician p
INNER JOIN undergoes u ON p.employeeid = u.physicianid
INNER JOIN medical_procedure m ON u.procedureid = m.code
GROUP BY p.employeeid, p.name, p.position
HAVING COUNT(*) > 3
AND p.employeeid IN (SELECT u2.physicianid FROM undergoes u2
					 INNER JOIN medical_procedure m2 ON u2.procedureid = m2.code
				 	 WHERE m2.cost > 5000
					 GROUP BY u2.physicianid
					 HAVING COUNT(DISTINCT u2.procedureid) = (SELECT COUNT(*) FROM medical_procedure
															  WHERE cost > 5000)
					)
;

-- m)
DELIMITER $$
CREATE FUNCTION calc_stay_cost(p_stay_id INT)
RETURNS DECIMAL
DETERMINISTIC
BEGIN
    DECLARE v_fecha_inicio VARCHAR(10);
    DECLARE v_fecha_fin VARCHAR(10);
    DECLARE v_tipo_hab VARCHAR(20);
    DECLARE v_dias INT;
    DECLARE v_precio_dia INT;
    DECLARE v_coste_total DECIMAL;

    -- Obtenemos los datos de la estancia y habitación uniéndolas
    SELECT s.start_time, s.end_time, r.roomtype INTO v_fecha_inicio, v_fecha_fin, v_tipo_hab
    FROM stay s
    INNER JOIN room r ON s.roomid = r.roomnumber
    WHERE s.stayid = p_stay_id;

    -- Calculamos los días
    SET v_dias = DATEDIFF(STR_TO_DATE(v_fecha_fin, '%d/%m/%Y'), STR_TO_DATE(v_fecha_inicio, '%d/%m/%Y'));

    -- Si entró y salió el mismo día, cobramos al menos 1 día
    IF v_dias = 0 THEN
        SET v_dias = 1;
    END IF;

    -- Determinamos el precio por día según el tipo
    CASE v_tipo_hab
        WHEN 'ICU' THEN SET v_precio_dia = 500;
        WHEN 'Single' THEN SET v_precio_dia = 300;
        WHEN 'Double' THEN SET v_precio_dia = 150;
        ELSE SET v_precio_dia = 100;
    END CASE;

    -- Calculamos el total
    SET v_coste_total = v_dias * v_precio_dia;

    RETURN v_coste_total;
END$$
DELIMITER ;

-- Probamos la función para todas las estancias
SELECT calc_stay_cost(3215) AS coste_estancia_3215, calc_stay_cost(3216) AS coste_estancia_3216, calc_stay_cost(3217) AS coste_estancia_3217;