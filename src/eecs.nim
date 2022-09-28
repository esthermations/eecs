import std/tables
import std/sets

#
# Entity
#

type
  EntityID* = uint16
  EntitySet* = set[EntityID]

#
# Queryable
#

type
  ComponentID* = uint8
  ComponentSet* = set[ComponentID]

  Queryable* = ref object of RootObj
    id*: ComponentID
    ents: EntitySet

method has*(c: Queryable, e: EntityID): bool {.base.} = c.ents.contains(e)
method getEnts*(c: Queryable): EntitySet {.base.} = c.ents

### Convenience - lets you write `entity.has component`
func has*(e: EntityID, c: Queryable): bool = c.has(e)

#
# Component
#

type Component*[DataT] = ref object of Queryable
  data: array[EntityID, DataT] # Worst-case memory usage, Table works here too

func get*[T](c: Component[T], e: EntityID): T = c.data[e]
proc set*[T](c: var Component[T], e: EntityID, value: T) =
  c.ents.incl e
  c.data[e] = value

proc remove*[T](c: var Component[T], e: EntityID) =
  c.ents.excl e

func query*(comps: varargs[Queryable]): EntitySet =
  if comps.len == 0: return {}
  if comps.len == 1: return comps[0].getEnts
  result = comps[0].getEnts
  for c in comps[1 ..< len(comps)]:
    result = result * c.getEnts # Intersection

#
# ECS (manager)
#

type
  SystemKernel* = proc(ents: EntitySet) {.closure.}
  SystemID      = uint8

  ECS* = ref object
    kernels : array[SystemID, SystemKernel]
    compSets: array[SystemID, ComponentSet]
    comps   : array[ComponentID, Queryable]

    nextComponent: ComponentID
    nextEntity   : EntityID
    nextSystem   : SystemID

proc returnAndIncr[T: Ordinal](val: var T): T =
  result = val
  val.inc

proc newEntity*(ecs: var ECS): EntityID =
  returnAndIncr ecs.nextEntity

proc newComponent*[T](ecs: var ECS): Component[T] =
  result = new Component[T]
  result.id = returnAndIncr ecs.nextComponent
  ecs.comps[result.id] = result

proc getEntsForSystem(ecs: ECS, s: SystemID): EntitySet =
  var queryables: seq[Queryable]
  for c in ecs.compSets[s]:
    queryables.add ecs.comps[c]
  return query(queryables)

proc getExtantSystems(ecs : ECS): HSlice[SystemID, SystemID] =
  SystemID(0) ..< ecs.nextSystem

proc addSystem*(
  ecs   : var ECS,
  kernel: SystemKernel,
  comps : seq[Queryable]
) =
  let k = returnAndIncr ecs.nextSystem
  ecs.kernels[k] = kernel
  ecs.compSets[k] = block:
    var compSet: ComponentSet
    for q in comps:
      compSet.incl q.id
    compSet

func evenlyDivide*[denom: static[Positive]](ents: EntitySet): array[denom, EntitySet] =
  let splitLen = ents.len div denom

  var i = 0
  for e in ents:
    let outputSet = min(i div splitLen, denom - 1)
    result[outputSet].incl e
    i.inc

proc runSystems*(ecs : ECS) =
  for k in ecs.getExtantSystems:
    ecs.kernels[k](ecs.getEntsForSystem k)
