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
	# La fonte e' attribuita per personaggio: una singola lista eventi puo' contenere
	# azioni/reazioni di piu' unita'. Non usare l'ultima azione vista per tutte le risorse.
	var source_by_unit: Dictionary = {}
	var source_by_unit_resource: Dictionary = {}
	if phase != "phase_transition":
		# Le tecniche a due emettono sia "act" sia "duo" per lo stesso attore:
		# la seconda etichetta e' piu' specifica e deve prevalere sulla prima.
		var duo_by_unit: Dictionary = {}
		for e in events:
			if str(e.get("t", "")) == "duo":
				var duo_uid: String = str(e.get("unit", ""))
				if duo_uid != "":
					duo_by_unit[duo_uid] = str(e.get("id", "unknown"))
		for e in events:
			var kind: String = str(e.get("t", ""))
			var uid: String = str(e.get("unit", ""))
			if uid == "":
				continue
			if kind == "resource_change":
				var resource_key: String = uid + "|" + str(e.get("resource", ""))
				var resource_source: String = str(e.get("source", phase))
				if source_by_unit_resource.has(resource_key) and str(source_by_unit_resource[resource_key]) != resource_source:
					source_by_unit_resource[resource_key] = "mista"
				else:
					source_by_unit_resource[resource_key] = resource_source
				continue
			var candidate: String = ""
			if kind == "act":
				var move_id: String = str(e.get("move", "unknown"))
				candidate = "duo:" + move_id if str(duo_by_unit.get(uid, "")) == move_id else "azione:" + move_id
			elif kind == "duo":
				candidate = "duo:" + str(e.get("id", "unknown"))
			if candidate == "":
				continue
			if source_by_unit.has(uid) and str(source_by_unit[uid]) != candidate:
				source_by_unit[uid] = "mista"
			else:
				source_by_unit[uid] = candidate
	else:
		# La lista eventi di fine round contiene anche azioni precedenti. In transizione
		# attribuiamo soltanto le mutazioni esplicitamente generate dal cambio fase.
		for e in events:
			if str(e.get("t", "")) != "resource_change" or str(e.get("source", "")) != "phase_change":
				continue
			var resource_key: String = str(e.get("unit", "")) + "|" + str(e.get("resource", ""))
			if resource_key != "|":
				source_by_unit_resource[resource_key] = "phase_change"
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
				"source": str(source_by_unit_resource.get(str(uid) + "|" + resource, source_by_unit.get(str(uid), phase))),
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
