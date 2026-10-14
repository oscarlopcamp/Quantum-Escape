# Quantum Escape 3D

**Videojuego educativo en primera persona sobre computación cuántica.**

Explora un laboratorio futurista, inmoviliza drones con un rayo de coherencia y resuelve desafíos de superposición, medición y entrelazamiento.

## Probar el sistema en línea

**[Visitar la demostración de Quantum Escape](https://oscarlopcamp.github.io/Quantum-Escape/)**

Puedes visitar la página para conocer y probar el funcionamiento del sistema directamente desde tu navegador. La demostración funciona **sin base de datos** y no requiere instalar Godot.

## Versión actual: 3D en primera persona

El proyecto de Godot incluye cuatro niveles, un escenario 3D y una cámara en primera persona. Su escena inicial es `Main3D.tscn` y el menú ofrece **Iniciar en 3D**.

![Laboratorio cuántico en primera persona](QuantumEscape_Godot_FIX22/previews/laberinto.png)

## Características

- Laboratorio con circuitos luminosos, interfaz holográfica y paleta cian/violeta.
- Emisor cuántico, mira y radar.
- Rayo de coherencia que congela drones durante **3,5 segundos**; alcance de 28 metros y recarga de 0,65 segundos.
- Superposición para atravesar muros y escáneres de medición que provocan colapso.
- Dos qubits entrelazados: Q1 recoge el color solicitado y Q2 lo entrega al receptor.
- Música electrónica original y efectos de sonido.
- Controles para mando Xbox, incluido movimiento y apuntado con ambos sticks.

## Los cuatro niveles

1. **Laberinto clásico:** alcanza el portal verde y evita a los drones.
2. **Superposición:** cambia de estado para atravesar los muros.
3. **Medición y colapso:** evita los escáneres M mientras estás en superposición.
4. **Entrelazamiento:** enlaza Q1 y Q2 en sus estaciones E y completa tres entregas de colores.

## Ejecutar el proyecto en Godot

1. Abre [QuantumEscape_Godot_FIX22/project.godot](QuantumEscape_Godot_FIX22/project.godot) con Godot 4.7.
2. Pulsa **Ejecutar proyecto**.
3. Selecciona **Iniciar en 3D**.

| Acción | Control Xbox |
| --- | --- |
| Moverte | Stick izquierdo |
| Mirar y apuntar | Stick derecho |
| Disparar el rayo | RT |
| Superposición o cambiar de qubit | A |
| Volver al menú | B o Menu/Start |
| Reiniciar después de morir | X |
| Activar o silenciar el sonido | Y |

Los pasos de conexión por USB-C en Mac están en el [README del proyecto](QuantumEscape_Godot_FIX22/README.md).

## Tecnologías

- Godot Engine 4.7
- GDScript
- HTML5 / WebAssembly para la demostración web
