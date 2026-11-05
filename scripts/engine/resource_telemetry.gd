class_name ResourceTelemetry
extends RefCounted

# Osservazione delle risorse V3. Non modifica mai le regole o i valori del combattimento.
# Snapshot = delta netto per azione; gain/spend = mutazioni con richiesto, effettivo e spreco.

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


static func gain_unit(u: Dictionary, resource: String, requested: int, cap: int, events: Array, source: String) -> void:
	if u.is_empty() or requested <= 0:
		return
	var before: int = int(u.get(resource, 0))
	var after: int = mini(cap, before + requested)
	var effective: int = after - before
	u[resource] = after
	events.append({"t": "resource_change", "resource": resource, "unit": str(u.get("id", "")), "requested": requested, "effective": effective, "delta": effective, "wasted": requested - effective, "before": before, "after": after, "source": source})


static func spend_unit(u: Dictionary, resource: String, requested: int, events: Array, source: String) -> void:
	if u.is_empty() or requested <= 0:
		return
	var before: int = int(u.get(resource, 0))
	var after: int = maxi(0, before - requested)
	var effective: int = before - after
	u[resource] = after
	events.append({"t": "resource_change", "resource": resource, "unit": str(u.get("id", "")), "requested": requested, "effective": effective, "delta": -effective, "wasted": requested - effective, "before": before, "after": after, "source": source})
