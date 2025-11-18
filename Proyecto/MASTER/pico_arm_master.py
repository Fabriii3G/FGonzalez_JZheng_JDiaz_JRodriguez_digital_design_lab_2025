from machine import Pin, SPI
import time

# ============================================================================
# Configuración SPI
# ============================================================================
cs = Pin(17, Pin.OUT)
spi = SPI(0, baudrate=1_000_000, polarity=0, phase=0, bits=8, firstbit=SPI.MSB,
          sck=Pin(18), mosi=Pin(19), miso=Pin(16))
cs.value(1)

HANDSHAKE_SEND = 0xA5
HANDSHAKE_EXPECT = 0x5A

def spi_transfer(tx_byte):
    tx = bytes([tx_byte])
    rx = bytearray(1)
    cs.value(0)
    time.sleep_us(50)
    spi.write_readinto(tx, rx)
    time.sleep_us(50)
    cs.value(1)
    time.sleep_us(100)
    return rx[0]

def flush(n=2):
    last = 0
    for _ in range(n):
        last = spi_transfer(0x00)
    return last

def do_handshake():
    print("Handshake...")
    resp = spi_transfer(HANDSHAKE_SEND)
    flush(2)
    final = flush(1)
    if final == HANDSHAKE_EXPECT:
        print("✓ OK")
        return True
    print("✗ FAIL")
    return False

def send_a(value):
    value &= 0x0F
    cmd = 0x10 | value
    print(f"\nA: {value} (0x{value:X})")
    
    # Limpiar buffer antes de enviar
    flush(1)
    time.sleep_us(100)
    
    spi_transfer(cmd)
    spi_transfer(0x00)
    ack = spi_transfer(0x00)
    expected_ack = 0xA0 | value
    if ack == expected_ack:
        print(f"  ✓ ACK: 0x{ack:02X}")
    else:
        print(f"  ⚠ ACK: 0x{ack:02X} (esperado: 0x{expected_ack:02X})")
    time.sleep(0.15)

def send_b(value):
    value &= 0x0F
    cmd = 0x20 | value
    print(f"B: {value} (0x{value:X})")
    
    # Limpiar buffer antes de enviar
    flush(1)
    time.sleep_us(100)
    
    spi_transfer(cmd)
    spi_transfer(0x00)
    ack = spi_transfer(0x00)
    expected_ack = 0xB0 | value
    if ack == expected_ack:
        print(f"  ✓ ACK: 0x{ack:02X}")
    else:
        print(f"  ⚠ ACK: 0x{ack:02X} (esperado: 0x{expected_ack:02X})")
    time.sleep(0.15)

def read_result():
    print("\nResultado:")
    
    # Limpiar buffer antes de leer
    flush(1)
    time.sleep_us(100)
    
    spi_transfer(0x30)
    spi_transfer(0x00)
    result_byte = spi_transfer(0x00)
    result = result_byte & 0x0F
    print(f"  {result} (0x{result:X}, 0b{result:04b})")
    return result

def test_suma(a, b, descripcion="", max_reintentos=2):
    expected = (a + b) & 0x0F
    suma_real = a + b
    tiene_overflow = suma_real > 15
    
    print("\n" + "=" * 60)
    if descripcion:
        print(f"{descripcion}")
    print(f"Test: {a} + {b} = {suma_real}", end="")
    if tiene_overflow:
        print(f" → {expected} (OVERFLOW)")
    else:
        print(f" = {expected}")
    print("=" * 60)
    
    for intento in range(max_reintentos):
        send_a(a)
        time.sleep(0.25)
        send_b(b)
        time.sleep(0.3)  # Dar tiempo a que la ALU procese
        
        result = read_result()
        
        print("-" * 60)
        if result == expected:
            print(f"✓ PASS: {a} + {b} = {result}", end="")
            if tiene_overflow:
                print(f" (overflow: {suma_real} → {expected})")
            else:
                print()
            if intento > 0:
                print(f"  (correcto en intento {intento + 1})")
            print("-" * 60)
            return True
        else:
            if intento < max_reintentos - 1:
                print(f"⚠ Resultado incorrecto: {result} (esperado: {expected})")
                print(f"  Reintentando... ({intento + 2}/{max_reintentos})")
                print("-" * 60)
                time.sleep(0.2)
            else:
                print(f"✗ FAIL: {a} + {b} = {result} (esperado: {expected})")
                print(f"  Después de {max_reintentos} intentos")
                print("-" * 60)
    
    return False

# ============================================================================
# MODO MANUAL - Bucle continuo de valores personalizados
# ============================================================================
def modo_manual():
    print("\n" + "=" * 60)
    print("  MODO MANUAL - Valores personalizados")
    print("  Rango válido: 0-15 (4 bits)")
    print("  Presiona Ctrl+C para salir")
    print("=" * 60)
    
    try:
        while True:
            print("\n" + "─" * 60)
            try:
                # Leer y validar A
                a_input = input("A (0-15): ").strip()
                a = int(a_input)
                if a < 0 or a > 15:
                    print(f"✗ Error: {a} está fuera del rango [0-15]")
                    continue
                
                # Leer y validar B
                b_input = input("B (0-15): ").strip()
                b = int(b_input)
                if b < 0 or b > 15:
                    print(f"✗ Error: {b} está fuera del rango [0-15]")
                    continue
                
                # Ejecutar suma
                test_suma(a, b, "Manual")
                
            except ValueError:
                print("✗ Valores inválidos, debe ser un número entero")
            except KeyboardInterrupt:
                break
            
            time.sleep(0.3)
    
    except KeyboardInterrupt:
        pass
    
    print("\n✓ Saliendo del modo manual...")

# ============================================================================
# PROGRAMA PRINCIPAL
# ============================================================================
def main():
    print("\n" + "=" * 60)
    print("  TEST ARM + SPI")
    print("=" * 60)
    
    # Handshake una sola vez
    time.sleep(0.5)
    if not do_handshake():
        print("\n✗ Error: No hay comunicación")
        return
    
    print("✓ Comunicación OK\n")
    flush(3)
    time.sleep(0.1)
    
    print("=" * 60)
    print("Presiona Ctrl+C para detener")
    print("=" * 60)
    
    try:
        while True:
            # Mostrar menú simple
            print("\n" + "─" * 60)
            print("OPCIONES:")
            print("  1. Prueba simple: 3 + 5 = 8")
            print("  2. Prueba overflow: 15 + 3 = 18 → 2")
            print("  3. Valores manuales (bucle continuo)")
            print("  4. Salir")
            print("─" * 60)
            
            try:
                opcion = input("\nSelecciona (1-4): ").strip()
                
                if opcion == '1':
                    # Test simple 3 + 5
                    test_suma(3, 5, "Prueba simple")
                    
                elif opcion == '2':
                    # Test overflow 15 + 3
                    test_suma(15, 3, "Prueba overflow")
                    
                elif opcion == '3':
                    # Entrar al modo manual (bucle continuo)
                    modo_manual()
                    
                elif opcion == '4':
                    print("\n✓ Saliendo...")
                    break
                else:
                    print("✗ Opción inválida")
                    
            except ValueError:
                print("✗ Entrada inválida")
            except KeyboardInterrupt:
                break
            
            time.sleep(0.3)
            
    except KeyboardInterrupt:
        print("\n\n✓ Detenido por usuario")
    
    print("\n✓ Programa terminado")
    flush(2)

# Ejecutar
if __name__ == "__main__":
    main()