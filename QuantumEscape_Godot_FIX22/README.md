# Quantum Escape FIX15

Corrección de flujo:

- Al terminar el Nivel 3 ahora aparece una ventana de transición al Nivel 4.
- ENTER inicia el Nivel 4 de Entrelazamiento Cuántico.
- El Nivel 4 conserva la mecánica de dos qubits, estaciones E, colores y receptor.

Controles principales:

- WASD: moverte
- ESPACIO en niveles 2 y 3: activar/desactivar superposición
- ESPACIO en nivel 4: cambiar qubit controlado antes del entrelazamiento
- ENTER: aceptar cuadros


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
- ENTER reinicia el Nivel 3.
- Este caso cuenta como intento del Nivel 3 y al tercer fallo aparece fin del juego.


## FIX22
- En Nivel 3, las compuertas M solo provocan colapso si todavia estas en superposicion.
- Si ya colapsaste antes, tocar otra medicion no reinicia el nivel.
- El aviso de colapso dentro de pared se acorto para evitar que se encime.
