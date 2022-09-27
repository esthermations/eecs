import pkg/benchy

import eecs

timeIt "Init 1000 components":
  const ents = EntityID(1) .. EntityID(1000)
  var c = new Component[int]
  for e in ents: c.set(e, int(e))
  for e in ents: c.remove(e)
  keep(c)

timeIt "Make a whole bunch of queries":
  const
    allEnts = EntityID(1) .. EntityID(10_000)

  type
    Health = range[0 .. 100]
    Damage = range[0 .. 10]
    Size   = range[1 .. 5]

  var
    health = new Component[Health]
    damage = new Component[Damage]
    size   = new Component[Size]

  for e in allEnts:
    if e mod 2 == 0: health.set e, 100
    if e mod 3 == 0: damage.set e, 5
    if e mod 4 == 0:   size.set e, 3

  let queryEnts = query(health, damage, size)
  keep(queryEnts)

var
  ecs = new ECS
  acc = newComponent[int] ecs
  vel = newComponent[int] ecs
  pos = newComponent[int] ecs

proc kAccelerate(ents: EntitySet) =
  for e in ents: vel.set e, (vel.get e) + (acc.get e)

proc kMove(ents: EntitySet) =
  for e in ents: pos.set e, (pos.get e) + (vel.get e)

ecs.addSystem kAccelerate, @[Queryable(vel), acc]
ecs.addSystem kMove, @[Queryable(pos), vel]

let manyManyEntities = EntityID(0) .. EntityID(65_535)
for e in manyManyEntities:
  acc.set e, 1
  vel.set e, 0
  pos.set e, 0

timeIt "Do a whole bunch of acceleration and velocity updates":
  ecs.runSystems()
