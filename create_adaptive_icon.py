#!/usr/bin/env python3
"""
Script para crear un icono adaptativo de Android con padding correcto.

Android adaptive icons necesitan que el contenido principal ocupe solo el 66%
del área central para evitar recortes cuando los launchers aplican diferentes
máscaras (círculo, cuadrado redondeado, etc.).

Este script toma AppIcon.png y crea AppIconForeground.png con el padding adecuado.
"""

from PIL import Image
import sys


def create_adaptive_foreground(input_path, output_path):
    """
    Crea un icono foreground adaptativo con padding correcto.
    
    Args:
        input_path: Ruta del icono original (1024x1024)
        output_path: Ruta donde guardar el foreground con padding
    """
    try:
        # Cargar la imagen original
        print(f"📖 Cargando {input_path}...")
        original = Image.open(input_path)
        
        # Verificar que sea cuadrada
        if original.width != original.height:
            print(f"⚠️  Advertencia: La imagen no es cuadrada ({original.width}x{original.height})")
            print("   Se usará el lado más pequeño como referencia")
        
        # Tamaño del canvas final
        canvas_size = 1024
        
        # El contenido debe ocupar el 66% del centro (área segura)
        safe_area_percentage = 0.66
        icon_size = int(canvas_size * safe_area_percentage)
        
        # Calcular padding (espacio transparente en cada lado)
        padding = (canvas_size - icon_size) // 2
        
        print(f"📐 Configuración:")
        print(f"   Canvas final: {canvas_size}x{canvas_size}px")
        print(f"   Tamaño del icono: {icon_size}x{icon_size}px")
        print(f"   Padding: {padding}px en cada lado")
        
        # Redimensionar el icono original al tamaño seguro
        print(f"🔄 Redimensionando icono a {icon_size}x{icon_size}px...")
        resized_icon = original.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
        
        # Crear un canvas transparente del tamaño final
        print(f"🎨 Creando canvas transparente de {canvas_size}x{canvas_size}px...")
        canvas = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
        
        # Pegar el icono redimensionado en el centro
        position = (padding, padding)
        canvas.paste(resized_icon, position, resized_icon if resized_icon.mode == 'RGBA' else None)
        
        # Guardar el resultado
        print(f"💾 Guardando {output_path}...")
        canvas.save(output_path, 'PNG')
        
        print(f"\n✅ ¡Listo! Se creó {output_path}")
        print(f"\n📱 Área segura para Android adaptive icons:")
        print(f"   • Total: 100% ({canvas_size}x{canvas_size}px)")
        print(f"   • Área segura: 66% (círculo de {icon_size}px de diámetro)")
        print(f"   • Padding: {padding}px transparente en cada lado")
        print(f"\n🚀 Próximos pasos:")
        print(f"   1. Verifica que AppIconForeground.png se vea bien")
        print(f"   2. Ejecuta: flutter pub get")
        print(f"   3. Ejecuta: dart run flutter_launcher_icons")
        print(f"   4. Reinstala la app en tu dispositivo")
        
        return True
        
    except FileNotFoundError:
        print(f"❌ Error: No se encontró el archivo {input_path}")
        print(f"   Asegúrate de que AppIcon.png existe en la raíz del proyecto")
        return False
    except Exception as e:
        print(f"❌ Error inesperado: {e}")
        return False


def main():
    """Función principal del script."""
    print("🎯 Generador de Icono Adaptativo para Android")
    print("=" * 60)
    
    # Rutas de entrada y salida
    input_icon = "AppIcon.png"
    output_icon = "AppIconForeground.png"
    
    # Verificar si Pillow está instalado
    try:
        import PIL
    except ImportError:
        print("❌ Error: Se requiere la librería Pillow")
        print("\n📦 Instálala con:")
        print("   pip install Pillow")
        print("   o")
        print("   pip3 install Pillow")
        sys.exit(1)
    
    # Crear el icono adaptativo
    success = create_adaptive_foreground(input_icon, output_icon)
    
    if not success:
        sys.exit(1)
    
    print("\n" + "=" * 60)
    print("✨ Proceso completado exitosamente")


if __name__ == "__main__":
    main()
