class_name ResourceTelemetry
extends RefCounted

# Osservazione delle risorse V3. Non modifica mai lo stato di battaglia.
# I delta sono netti per singola azione: i costi lordi espliciti restano eventi separati.

const UNIT_RESOURCES: Array[String] = ["energy", "gauge", "hype", "ammo"]


static func snapshot(state: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for uid in state.get("units", {}):
		var u: Dictionary = state["units"][uid]
		if str(u.get("side", "")) != "player":
			continue
		var values: Dictionary = {"char": str(u.get("char", ""))}
		for resource in UNIT_RESOURCES:
			values[resource] = int(u.get(resource, 0))
		out[str(uid)] = values
	return out


static func record(state: Dictionary, before: Dictionary, events: Array, phase: String) -> void:
	if before.is_empty():
		return
	var source: String = phase
	if phase != "phase_transition":
		for e in events:
			if str(e.get("t", "")) == "act":
				source = "azione:" + str(e.get("move", "unknown"))
			if str(e.get("t", "")) == "duo":
				source = "duo:" + str(e.get("id", "unknown"))
	for uid in before:
		var old: Dictionary = before[uid]
		var current: Dictionary = state.get("units", {}).get(str(uid), {})
		if current.is_empty():
			continue
		for resource in UNIT_RESOURCES:
			if resource == "ammo":
				continue # Le munizioni hanno già il delta richiesto/effettivo in BattleResolver._change_ammo.
			var was: int = int(old.get(resource, 0))
			var now: int = int(current.get(resource, 0))
			var delta: int = now - was
			if delta == 0:
				continue
			events.append({
				"t": "resource_delta",
				"resource": resource,
				"unit": str(uid),
				"char": str(old.get("char", "")),
				"delta": delta,
				"before": was,
				"after": now,
				"source": source,
				"phase": phase
			})
