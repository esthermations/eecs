import unittest
import eecs

test "Component sanity":
  var e = EntityID(100)
  var c = new Component[int]

  assert not c.has(e)
  c.set(e, 50)
  assert c.has(e)
  assert c.get(e) == 50
  c.remove(e)
  assert not c.has(e)
  assert e.has(c) == c.has(e)

test "Component query sanity":
  const ents = EntityID(1) .. EntityID(1000)

  type
    Health = range[0..100]
    Damage = range[0..10]

  var
    health = new Component[Health]
    damage = new Component[Damage]

  for e in ents:
    health.set(e, 100)
    # Give every third entity damage
    if e mod 3 == 0:
      damage.set(e, 10)

  var entsWithDamageAndHealth = query(health, damage)

  # All members of returned set have the queried components
  for e in entsWithDamageAndHealth:
    assert e.has health
    assert e.has damage

  # No members were excluded
  for e in ents:
    if e.has(health) and e.has(damage):
      assert e in entsWithDamageAndHealth

test "Using ECS":
  var
    ecs = new ECS
    position = newComponent[int] ecs
    velocity = newComponent[int] ecs

  assert position.id != velocity.id

  proc kMove(ents: EntitySet) =
    for e in ents:
      let
        pos = position.get e
        vel = velocity.get e
      position.set e, (pos + vel)

  proc kAccelerate(ents: EntitySet) =
    for e in ents:
      let oldVel = velocity.get e
      velocity.set e, oldVel + 1

  ecs.addSystem(kMove, @[Queryable(position), velocity])
  ecs.addSystem(kAccelerate, @[Queryable(velocity)])

  ecs.runSystems() # Should do nothing, we have no entities

  let
    e1 = ecs.newEntity
    e2 = ecs.newEntity

  position.set e1, 100
  velocity.set e1, 10

  position.set e2, 0
  velocity.set e2, 110

  ecs.runSystems()

  assert position.get(e1) == 110
  assert position.get(e2) == 110


test "System Dependencies":
  var
    ecs = new ECS
    acc = newComponent[int] ecs
    vel = newComponent[int] ecs
    pos = newComponent[int] ecs

  let e = ecs.newEntity

  acc.set e, 1
  vel.set e, 0
  pos.set e, 0

  proc kUpdateVelocity(ents: EntitySet) =
    for e in ents: vel.set e, (vel.get e) + (acc.get e)

  proc kUpdatePosition(ents: EntitySet) =
    for e in ents: pos.set e, (pos.get e) + (vel.get e)

  let posSys = ecs.addSystem(kUpdatePosition, @[Queryable(pos), vel])
  let velSys = ecs.addSystem(kUpdateVelocity, @[Queryable(vel), acc])

  ecs.addDependency(posSys, {velSys})
  ecs.runSystems()

  echo "This test is EXPECTED TO FAIL"

  assert acc.get(e) == 1
  assert vel.get(e) == 1
  assert pos.get(e) == 1

  # I expect this to fail because the systems weren't added in dependency
  # order. There's currently no way to tell the ECS what the dependencies are.
  # @TODO


test "Kernels as actual kernels":
  type
    Position = array[3, float]
    Velocity = array[3, float]

  func kUpdateVelocity(p: Position, v: Velocity): Position =
    static: assert Position.len == Velocity.len
    for i in 0 .. p.len:
      result[i] = p[i] + v[i]

  var
    ecs = new ECS
    pos = ecs.newComponent[:Position]
    vel = ecs.newComponent[:Velocity]

  const ents = {EntityID(0), 1, 100, 50}

  for e in ents:
    pos.set e, [0.0, 0, 0]
    vel.set e, [1.0, 1, 1]

  proc marshal(e: EntityID) =
    pos.set e, kUpdateVelocity(pos.get e, vel.get e)


