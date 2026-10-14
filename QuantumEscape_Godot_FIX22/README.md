# Quantum Escape 3D

Explora un laboratorio cuántico en primera persona. Usa un rayo para inmovilizar drones y resuelve cuatro desafíos de superposición, medición y entrelazamiento.

[Abrir la demo web](https://oscarlopcamp.github.io/Quantum-Escape/). La demostración funciona sin base de datos y no requiere instalar Godot.

## Empezar

Abre `project.godot` con Godot 4.7 y pulsa **Ejecutar proyecto** o **F5**. En el navegador, espera a que cargue el menú y haz clic en una opción:

- **Iniciar juego:** entra directamente al primer nivel.
- **Tutorial corto:** practica antes de jugar; es opcional.
- **Salir:** cierra la aplicación de escritorio. En la web puedes cerrar la pestaña.

El tutorial tiene cuatro pasos: moverte, mirar con el ratón, congelar un dron y activar la superposición antes de llegar al portal verde. El dron permanece quieto y no te persigue. No hay castigos ni límite de tiempo; atravesar un muro es opcional.

## Controles de PC y navegador

| Acción | Control |
| --- | --- |
| Moverte / elegir opciones | WASD o flechas |
| Mirar y apuntar | Ratón |
| Disparar el rayo | Clic izquierdo |
| Superposición en niveles 2–3 / cambiar de qubit en nivel 4 | Espacio |
| Aceptar una opción o un diálogo | Enter o clic en el botón |
| Reiniciar después de fallar | R |
| Activar o silenciar música y efectos | M |
| Pausar | Esc |

El juego captura el ratón al iniciar. Si cambias de pestaña, pierdes el foco o pulsas **Esc**, la partida se pausa. Pulsa **Enter** o haz clic en **Continuar** para recuperar el control de la cámara. Desde la pausa, otro **Esc** vuelve al menú.

## Objetivo de cada nivel

1. **Laberinto clásico:** encuentra el portal verde y evita a los drones.
2. **Superposición:** usa Espacio para atravesar muros. Sal de la pared antes de volver al estado clásico.
3. **Medición y colapso:** evita los escáneres M mientras estás en superposición; pueden bloquear esa habilidad o atraparte dentro de una pared.
4. **Entrelazamiento:** acerca Q1 y Q2 a sus estaciones E. Q1 toma el color solicitado y Q2 lo entrega al receptor. Completa tres entregas.

El rayo congela a un dron durante **3,5 segundos**. Apunta con la mira; los muros bloquean el disparo incluso durante la superposición. Cuando termina la congelación, el dron vuelve a moverse.

## Diseño y sonido

El laboratorio conserva la paleta cian/violeta, los circuitos de neón y la interfaz holográfica. El emisor lleva un qubit inspirado en la esfera de Bloch; los portales son verdes y los escáneres de medición, dorados.

La música electrónica original acompaña cada nivel, con efectos para el rayo, la congelación y las acciones cuánticas. En el navegador, el audio comienza tras interactuar con el juego. Pulsa **M** o el botón **Sonido** para silenciarlo.

Las pistas están en `audio/quantum_ambient.wav` y `audio/quantum_pulse.wav`. Puedes regenerarlas con `python3 tools/generate_quantum_audio.py` y NumPy; el juego reproduce los WAV sin necesitar Python.

Capturas: [menú](previews/menu.png) · [tutorial](previews/tutorial.png) · [laboratorio 3D](previews/laberinto.png) · [entrelazamiento](previews/entrelazamiento.png).

## Exportar la demo web

El proyecto usa el renderizador **Compatibility**. El preset **Web** de `export_presets.cfg` desactiva los threads y apunta a `../docs/index.html`, la carpeta `docs` del repositorio.

En Godot, instala las plantillas de exportación correspondientes al motor y abre **Proyecto → Exportar → Web**. Exporta el HTML junto con todos los archivos generados; conserva el conjunto completo en `docs` para servirlo por HTTP o GitHub Pages.

Si el navegador muestra un menú antiguo o repite un aviso de configuración, prueba una recarga completa: **Ctrl+Shift+R** en PC o **Cmd+Shift+R** en Mac. Si persiste, borra los datos de ese sitio y abre de nuevo la demo. Recargar reinicia la partida.
