class_name PlayerIntent
extends RefCounted

# Cosa vuole fare il giocatore in un fotogramma di fisica.
# Non sa nulla di tastiera, touch o rete: chi comanda il personaggio
# (input locale, test automatici, in futuro la rete) riempie questi campi.

var move: Vector3 = Vector3.ZERO    # direzione nel mondo, y = 0, lunghezza da 0 a 1
var jump_pressed: bool = false      # premuto proprio in questo fotogramma
var jump_held: bool = false         # tenuto premuto: salto piu' alto
var dodge_pressed: bool = false
