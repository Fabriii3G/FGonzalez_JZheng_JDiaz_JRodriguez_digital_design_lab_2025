import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.util.Scanner;

public class Calculadora extends JFrame implements ActionListener {
    private JLabel etiquetaOperacion;
    private JLabel etiquetaResultado;
    private double num1, num2;
    private static boolean continuar = true;
    private static Scanner entrada = new Scanner(System.in);
    private static Calculadora instancia;

    public Calculadora(double n1, double n2) {
        num1 = n1;
        num2 = n2;

        setTitle("Calculadora GUI + Consola");
        setSize(350, 250);
        setDefaultCloseOperation(EXIT_ON_CLOSE);
        setLayout(new BorderLayout(10, 10));

        // Panel superior: texto
        JPanel panelTexto = new JPanel(new GridLayout(2, 1));
        etiquetaOperacion = new JLabel("Operación: ---", SwingConstants.CENTER);
        etiquetaOperacion.setFont(new Font("Arial", Font.PLAIN, 18));

        etiquetaResultado = new JLabel("Resultado: ---", SwingConstants.CENTER);
        etiquetaResultado.setFont(new Font("Arial", Font.BOLD, 22));

        panelTexto.add(etiquetaOperacion);
        panelTexto.add(etiquetaResultado);
        add(panelTexto, BorderLayout.NORTH);

        // Panel de botones
        JPanel panelBotones = new JPanel(new GridLayout(1, 5, 10, 10));
        String[] operaciones = {"+", "-", "*", "/", "^"};
        for (String op : operaciones) {
            JButton boton = new JButton(op);
            boton.setFont(new Font("Arial", Font.BOLD, 22));
            boton.addActionListener(this);
            panelBotones.add(boton);
        }

        add(panelBotones, BorderLayout.CENTER);
        setVisible(true);
    }

    public void setNumeros(double n1, double n2) {
        num1 = n1;
        num2 = n2;
        etiquetaOperacion.setText("Operación: ---");
        etiquetaResultado.setText("Resultado: ---");
    }

    @Override
    public void actionPerformed(ActionEvent e) {
        String comando = e.getActionCommand();
        double resultado = 0;
        boolean valido = true;

        switch (comando) {
            case "+": resultado = num1 + num2; break;
            case "-": resultado = num1 - num2; break;
            case "*": resultado = num1 * num2; break;
            case "/":
                if (num2 != 0) resultado = num1 / num2;
                else {
                    etiquetaOperacion.setText("Error: división entre 0");
                    etiquetaResultado.setText("Resultado: ---");
                    valido = false;
                }
                break;
            case "^": resultado = Math.pow(num1, num2); break;
        }

        if (valido) {
            etiquetaOperacion.setText("Operación: " + num1 + " " + comando + " " + num2);
            etiquetaResultado.setText("Resultado: " + resultado);
        }
    }

    // --- Método principal ---
    public static void main(String[] args) {
        // Pedir los primeros números
        double[] numeros = pedirNumeros();
        instancia = new Calculadora(numeros[0], numeros[1]);

        // Ciclo de ingreso desde consola
        while (continuar) {
            System.out.print("¿Deseas continuar? (s/n): ");
            char opcion = entrada.next().toLowerCase().charAt(0);

            if (opcion != 's') {
                continuar = false;
                System.out.println("👋 Programa finalizado.");
                instancia.dispose();
                break;
            }

            double[] nuevos = pedirNumeros();
            instancia.setNumeros(nuevos[0], nuevos[1]);
        }

        entrada.close();
    }

    private static double[] pedirNumeros() {
        double n1, n2;

        do {
            System.out.print("Ingresa el primer número (0–15): ");
            n1 = entrada.nextDouble();
            if (n1 < 0 || n1 > 15)
                System.out.println("❌ Número fuera de rango. Intenta de nuevo.");
        } while (n1 < 0 || n1 > 15);

        do {
            System.out.print("Ingresa el segundo número (0–15): ");
            n2 = entrada.nextDouble();
            if (n2 < 0 || n2 > 15)
                System.out.println("❌ Número fuera de rango. Intenta de nuevo.");
        } while (n2 < 0 || n2 > 15);

        System.out.println("✔️ Números actualizados: " + n1 + " y " + n2);
        return new double[]{n1, n2};
    }
}
