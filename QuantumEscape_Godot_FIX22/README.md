# Quantum Escape FIX22

## Diseño del laboratorio cuántico

- Menú holográfico, circuitos luminosos y paleta cian/violeta.
- El personaje es un qubit animado inspirado en la esfera de Bloch; la superposición muestra dos estados fantasma.
- Drones rojos, portales verdes y escáneres de medición dorados.
- Qubits del nivel 4 con indicador de selección y enlace animado al entrelazarse.
- Paneles con objetivo, guía de campo y controles de Xbox.

Los gráficos se dibujan dentro de Godot y se animan automáticamente. Para ver el diseño, abre `project.godot` y pulsa **F5**.

Capturas: [menú](previews/menu.png), [laberinto](previews/laberinto.png), [entrelazamiento](previews/entrelazamiento.png).

## Ambiente sonoro

La música electrónica empieza automáticamente al abrir el juego. Combina sintetizadores y un arpegio espacial con un ritmo que gana presencia en los niveles cuánticos; baja suavemente durante los diálogos. Las dos pistas forman un bucle de 40 segundos y continúan al cambiar de nivel.

La superposición, las mediciones, el cambio de qubit, las entregas y la victoria tienen efectos propios. Pulsa **Y** en el mando o el botón **Sonido** para silenciar o activar la música y los efectos.

La composición original está en `audio/quantum_ambient.wav` y `audio/quantum_pulse.wav`. Para regenerarla, usa `python3 tools/generate_quantum_audio.py` con NumPy disponible; el juego reproduce los WAV y no necesita Python.

## Jugar con un control de Xbox por USB-C en Mac

1. Usa macOS Sequoia 15 o posterior y Godot 4.5 o posterior. Este proyecto ya está configurado para Godot 4.7.
2. Conecta el control a la Mac con un cable USB-C que transfiera **datos**. Un cable que solo carga no sirve. Si aparece el aviso de acceso al accesorio, pulsa **Permitir**.
3. Revisa que macOS lo reconozca en **Configuración del Sistema → Controles de videojuegos**.
4. Abre `project.godot` con Godot y ejecuta con **F5**. Da foco a la ventana del juego. En el menú aparecerá **Mando detectado** junto al nombre del control.
5. Selecciona **Iniciar experimento** con el stick izquierdo o la cruceta y pulsa **A**.

| Acción | Xbox |
| --- | --- |
| Moverte o elegir una opción | Stick izquierdo o cruceta |
| Aceptar un cuadro o la opción seleccionada | A |
| Activar/desactivar superposición, niveles 2 y 3 | A |
| Cambiar el qubit controlado, nivel 4 | A |
| Volver al menú desde el juego o un cuadro | B o botón Menu/Start (≡) |
| Reiniciar después de morir | X, o A con Reiniciar seleccionado |
| Salir desde el menú principal | B, o A con Salir seleccionado |
| Activar o silenciar el sonido | Y |

El stick permite moverte despacio o a velocidad completa según cuánto lo inclines. Tiene una zona muerta del 20 % para evitar movimiento involuntario. El control se puede conectar o desconectar con el juego abierto; el indicador del menú se actualiza automáticamente.

**Si no se detecta:** prueba otro cable de datos y otro puerto, conecta directamente a la Mac y acepta el permiso del accesorio. Si tampoco aparece en la configuración de macOS, actualiza el firmware del control desde una Xbox o la app Accesorios de Xbox en Windows. La compatibilidad depende del modelo concreto; los mandos de terceros pueden requerir soporte adicional del sistema.

Referencias: [conexión y ajustes de controles en Apple](https://support.apple.com/es-mx/111099), [permisos USB en macOS](https://support.apple.com/es-mx/guide/mac-help/mchlf779ae93/mac), [soporte Xbox por cable desde macOS 15 en SDL](https://discourse.libsdl.org/t/sdl-added-support-for-wired-xbox-controllers-on-macos-15-0-sequoia/54802), [mandos en Godot](https://docs.godotengine.org/en/4.7/tutorials/inputs/controllers_gamepads_joysticks.html).

## Historial

Corrección de flujo:

- Al terminar el Nivel 3 ahora aparece una ventana de transición al Nivel 4.
- Aceptar el cuadro inicia el Nivel 4 de Entrelazamiento Cuántico.
- El Nivel 4 conserva la mecánica de dos qubits, estaciones E, colores y receptor.

FIX18:
- Ajusta HUD del nivel 4 para que el titulo no se encime.
- Centra las etiquetas Qubit 1 y Qubit 2 sobre cada qubit.
- El receptor cambia de letra y color segun el color esperado.


FIX19:
- Limpia HUD inferior del nivel 4.
- Quita texto repetido de entregas cerca del receptor.
- Quita mensaje inferior de acercar ambos al centro.
- Mantiene el contador arriba en el HUD.


## FIX20
- Mensaje final simplificado: "Has escapado del mundo clásico."


## FIX21
- En el Nivel 3, si colapsas dentro de una compuerta de medicion en una pared, aparece un cuadro explicando que quedaste atrapado.
- Aceptar el cuadro reinicia el Nivel 3.
- Este caso cuenta como intento del Nivel 3 y al tercer fallo aparece fin del juego.


## FIX22
- En Nivel 3, las compuertas M solo provocan colapso si todavia estas en superposicion.
- Si ya colapsaste antes, tocar otra medicion no reinicia el nivel.
- El aviso de colapso dentro de pared se acorto para evitar que se encime.
