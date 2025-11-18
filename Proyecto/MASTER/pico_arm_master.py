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
    spi_transfer(cmd)
    spi_transfer(0x00)
    ack = spi_transfer(0x00)
    expected_ack = 0xA0 | value
    if ack == expected_ack:
        print(f"  ✓ ACK: 0x{ack:02X}")
    else:
        print(f"  ⚠ ACK: 0x{ack:02X} (esperado: 0x{expected_ack:02X})")
    time.sleep(0.1)

def send_b(value):
    value &= 0x0F
    cmd = 0x20 | value
    print(f"B: {value} (0x{value:X}) -> LEDs: {value:04b}")
    spi_transfer(cmd)
    spi_transfer(0x00)
    ack = spi_transfer(0x00)
    expected_ack = 0xB0 | value
    if ack == expected_ack:
        print(f"  ✓ ACK: 0x{ack:02X}")
    else:
        print(f"  ⚠ ACK: 0x{ack:02X} (esperado: 0x{expected_ack:02X})")
    time.sleep(0.1)

def read_result():
    print("\nResultado:")
    spi_transfer(0x30)
    spi_transfer(0x00)
    result_byte = spi_transfer(0x00)
    result = result_byte & 0x0F
    print(f"  {result} (0x{result:X}, 0b{result:04b})")
    return result

def test_suma(a, b, descripcion=""):
    expected = (a + b) & 0x0F
    
    print("\n" + "=" * 60)
    if descripcion:
        print(f"{descripcion}")
    print(f"Test: {a} + {b} = {expected}")
    print("=" * 60)
    
    send_a(a)
    time.sleep(0.2)
    send_b(b)
    time.sleep(0.5)
    
    result = read_result()
    
    print("-" * 60)
    if result == expected:
        print(f"✓ PASS: {a} + {b} = {result}")
    else:
        print(f"✗ FAIL: {a} + {b} = {result} (esperado: {expected})")
    print("-" * 60)
    
    return result == expected

# ============================================================================
# PROGRAMA PRINCIPAL CON BUCLE
# ============================================================================
def main():
    print("\n" + "=" * 60)
    print("  TEST CONTINUO - ARM + SPI")
    print("=" * 60)
    
    # Handshake una sola vez
    time.sleep(0.5)
    if not do_handshake():
        print("\n✗ Error: No hay comunicación")
        return
    
    print("✓ Comunicación OK\n")
    flush(3)
    time.sleep(0.1)
    
    # Tests disponibles
    tests = [
        (3, 5, "Suma simple"),
        (0, 0, "Ceros"),
        (15, 1, "Overflow (15+1=16→0)"),
        (7, 7, "Valores medianos"),
        (10, 5, "Resultado máximo"),
        (1, 2, "Números pequeños"),
    ]
    
    # BUCLE INFINITO
    print("=" * 60)
    print("MODO CONTINUO ACTIVADO")
    print("Presiona Ctrl+C para detener")
    print("=" * 60)
    
    try:
        while True:
            # Mostrar menú
            print("\n" + "─" * 60)
            print("OPCIONES:")
            for i, (a, b, desc) in enumerate(tests, 1):
                print(f"  {i}. {desc}: {a}+{b}={((a+b)&0x0F)}")
            print("  7. Valores manuales")
            print("  8. Salir")
            print("─" * 60)
            
            try:
                opcion = input("\nTest (1-8): ").strip()
                
                if opcion == '8':
                    print("\n✓ Saliendo del bucle...")
                    break
                
                idx = int(opcion) - 1
                
                if 0 <= idx < len(tests):
                    # Test predefinido
                    a, b, desc = tests[idx]
                    test_suma(a, b, desc)
                    
                elif int(opcion) == 7:
                    # Valores manuales
                    print("\n" + "─" * 60)
                    print("VALORES MANUALES")
                    print("─" * 60)
                    try:
                        a = int(input("A (0-15): ").strip()) & 0x0F
                        b = int(input("B (0-15): ").strip()) & 0x0F
                        test_suma(a, b, "Manual")
                    except ValueError:
                        print("✗ Valores inválidos")
                else:
                    print("✗ Opción inválida")
                    
            except ValueError:
                print("✗ Entrada inválida")
            
            # Pequeña pausa antes de mostrar menú de nuevo
            time.sleep(0.3)
            
    except KeyboardInterrupt:
        print("\n\n✓ Detenido por usuario")
    
    print("\n✓ Programa terminado")
    flush(2)

# Ejecutar
if __name__ == "__main__":
    main()