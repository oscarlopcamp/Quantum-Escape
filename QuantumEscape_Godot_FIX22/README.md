# Quantum Escape 3D

Videojuego educativo en primera persona sobre computación cuántica. Explora un laboratorio futurista, inmoviliza drones con un rayo de coherencia y completa desafíos de superposición, medición y entrelazamiento.

## Probar el sistema en línea

Puedes visitar la [demostración de Quantum Escape](https://oscarlopcamp.github.io/Quantum-Escape/) para conocer y probar el funcionamiento del sistema directamente desde tu navegador.

La demostración funciona **sin base de datos** y no requiere instalar Godot.

## Diseño del laboratorio cuántico

- Cuatro niveles en primera persona dentro de un laboratorio 3D, con pasillos, paneles y luces de neón.
- Menú holográfico, circuitos luminosos y paleta cian/violeta.
- Emisor de coherencia con un qubit animado inspirado en la esfera de Bloch, mira y radar del laboratorio.
- Drones rojos, portales verdes y escáneres de medición dorados.
- Qubits del nivel 4 con esfera de Bloch y enlace animado al entrelazarse; cambiar de qubit cambia tu perspectiva.
- Paneles con objetivo, guía de campo y controles de Xbox.

Los gráficos se generan dentro de Godot y se animan automáticamente. Abre `project.godot` y ejecuta el proyecto con el botón **Ejecutar proyecto**. La escena inicial es `Main3D.tscn`; el proyecto aparece como **Quantum Escape 3D** y el menú ofrece **Iniciar en 3D**.

Capturas: [menú](previews/menu.png), [laberinto 3D](previews/laberinto.png), [rayo cuántico](previews/rayo.png), [superposición](previews/superposicion.png), [entrelazamiento](previews/entrelazamiento.png).

## Rayo y niveles

Apunta con el stick derecho y pulsa **RT** para disparar. El rayo alcanza 28 metros y congela al dron durante **3,5 segundos**: cambia de rojo a cian y muestra el tiempo restante. El emisor se recarga en 0,65 segundos. Las paredes bloquean el disparo, incluso durante la superposición.

1. **Laberinto clásico:** encuentra el portal verde y usa el rayo para abrirte paso entre los drones.
2. **Superposición:** pulsa A para cambiar de estado y atravesar los muros. Sal del muro antes de volver al estado clásico.
3. **Medición y colapso:** evita los escáneres M mientras estás en superposición; una medición puede bloquear esa habilidad o atraparte dentro de una pared.
4. **Entrelazamiento:** lleva Q1 y Q2 a sus estaciones E. Después Q1 toma el color solicitado y Q2 lo lleva al receptor; completa tres entregas.

Los drones vuelven a perseguirte cuando termina la congelación. El rayo los detiene temporalmente; los portales y las mecánicas cuánticas siguen siendo el objetivo de cada nivel.

## Ambiente sonoro

La música electrónica empieza automáticamente al abrir el juego. Combina sintetizadores y un arpegio espacial con un ritmo que gana presencia en los niveles cuánticos; baja suavemente durante los diálogos. Las dos pistas forman un bucle de 40 segundos y continúan al cambiar de nivel.

El rayo, la congelación, la superposición, las mediciones, el cambio de qubit, las entregas y la victoria tienen efectos propios. Pulsa **Y** en el mando o el botón **Sonido** para silenciar o activar la música y los efectos.

La composición original está en `audio/quantum_ambient.wav` y `audio/quantum_pulse.wav`. Para regenerarla, usa `python3 tools/generate_quantum_audio.py` con NumPy disponible; el juego reproduce los WAV y no necesita Python.

## Jugar con un control de Xbox por USB-C en Mac

1. Usa macOS Sequoia 15 o posterior y Godot 4.5 o posterior. Este proyecto ya está configurado para Godot 4.7.
2. Conecta el control a la Mac con un cable USB-C que transfiera **datos**. Un cable que solo carga no sirve. Si aparece el aviso de acceso al accesorio, pulsa **Permitir**.
3. Revisa que macOS lo reconozca en **Configuración del Sistema → Controles de videojuegos**.
4. Abre `project.godot` con Godot y pulsa **Ejecutar proyecto**. Da foco a la ventana del juego. En el menú aparecerá **Mando detectado** junto al nombre del control.
5. Selecciona **Iniciar en 3D** con el stick izquierdo o la cruceta y pulsa **A**.

| Acción | Xbox |
| --- | --- |
| Moverte o elegir una opción | Stick izquierdo o cruceta |
| Mirar y apuntar | Stick derecho |
| Disparar el rayo de coherencia | RT |
| Aceptar un cuadro o la opción seleccionada | A |
| Activar/desactivar superposición, niveles 2 y 3 | A |
| Cambiar el qubit controlado, nivel 4 | A |
| Volver al menú desde el juego o un cuadro | B o botón Menu/Start (≡) |
| Reiniciar después de morir | X, o A con Reiniciar seleccionado |
| Salir desde el menú principal | B, o A con Salir seleccionado |
| Activar o silenciar el sonido | Y |

El stick izquierdo permite moverte despacio o a velocidad completa según cuánto lo inclines. Su zona muerta es del 20 % y la del stick derecho es del 18 %, para evitar movimiento y giro involuntarios. El control se puede conectar o desconectar con el juego abierto; el indicador del menú se actualiza automáticamente.

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
