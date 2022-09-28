import unittest
import eecs

test "Evenly split a set":
  const ents = {EntityID(0), 1, 2, 3, 4, 5, 6, 7, 8, 9}

  let splitIn3 = ents.evenlyDivide[:3]
  assert EntityID(0) in splitIn3[0]
  assert EntityID(1) in splitIn3[0]
  assert EntityID(2) in splitIn3[0]
  assert EntityID(3) in splitIn3[1]
  assert EntityID(4) in splitIn3[1]
  assert EntityID(5) in splitIn3[1]
  assert EntityID(6) in splitIn3[2]
  assert EntityID(7) in splitIn3[2]
  assert EntityID(8) in splitIn3[2]
  assert EntityID(9) in splitIn3[2] # Remainder goes in last set