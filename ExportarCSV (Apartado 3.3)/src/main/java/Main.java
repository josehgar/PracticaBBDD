import java.sql.*;
import java.io.FileWriter;
import java.io.IOException;

public class Main {
    private static final String VISTA_SQL = "SELECT * FROM ver_todo_de_physician";
    public static void main(String[] args) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver").newInstance();
        } catch (Exception e) {
            System.out.println(e.getMessage());
        }
        Connection c = null;
        Statement s = null;
        ResultSet rs = null;
        try {
            c = DriverManager.getConnection("jdbc:mysql://localhost:3306/hospital_management_system", "root", "");
            s = c.createStatement();
            if (s.execute(VISTA_SQL)) {
                rs = s.getResultSet();
            }
            ResultSetMetaData rsmtdt = rs.getMetaData();
            int columnas = rsmtdt.getColumnCount();
            try (FileWriter fw = new FileWriter("C:/Users/Usuario/OneDrive/Escritorio/vista_csv.csv")){
                for (int i=1; i<=columnas; i++) {
                    fw.append(rsmtdt.getColumnLabel(i));
                    if (i < columnas) {
                        fw.append(",");
                    }
                }
                fw.append("\n");
                while (rs.next()) {
                    for (int i=1; i<=columnas; i++) {
                        String info = rs.getString(i);
                        if (info == null) {
                            info = "NULL";
                        }
                        fw.append(info);
                        if (i < columnas) {
                            fw.append(",");
                        }
                        if (i == columnas) {
                            fw.append("\n");
                        }
                    }
                }
            } catch (IOException e) {
                System.out.println("Error al leer");
            }
        } catch (SQLException e) {
            System.out.println("Error al conectar");
        }
    }
}
