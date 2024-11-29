// RUN: %target-run-simple-swift(-I %S/Inputs -Xfrontend -enable-experimental-cxx-interop)
// RUN: %target-run-simple-swift(-I %S/Inputs -cxx-interoperability-mode=swift-6)
// RUN: %target-run-simple-swift(-I %S/Inputs -cxx-interoperability-mode=upcoming-swift)
// RUN: %target-run-simple-swift(-I %S/Inputs -cxx-interoperability-mode=upcoming-swift -Xcc -std=c++14)
// RUN: %target-run-simple-swift(-I %S/Inputs -cxx-interoperability-mode=upcoming-swift -Xcc -std=c++17)
// RUN: %target-run-simple-swift(-I %S/Inputs -cxx-interoperability-mode=upcoming-swift -Xcc -std=c++20)

// Also test this with a bridging header instead of the StdSet module.
// RUN: %empty-directory(%t2)
// RUN: cp %S/Inputs/std-set.h %t2/std-set-bridging-header.h
// RUN: %target-run-simple-swift(-D BRIDGING_HEADER -import-objc-header %t2/std-set-bridging-header.h -Xfrontend -enable-experimental-cxx-interop)
// RUN: %target-run-simple-swift(-D BRIDGING_HEADER -import-objc-header %t2/std-set-bridging-header.h -cxx-interoperability-mode=swift-6)
// RUN: %target-run-simple-swift(-D BRIDGING_HEADER -import-objc-header %t2/std-set-bridging-header.h -cxx-interoperability-mode=upcoming-swift)

// REQUIRES: executable_test
//
// Enable this everywhere once we have a solution for modularizing other C++ stdlibs: rdar://87654514
// REQUIRES: OS=macosx || OS=linux-gnu

import StdlibUnittest
#if !BRIDGING_HEADER
import StdSet
#endif
import CxxStdlib
import Cxx

var StdSetTestSuite = TestSuite("StdSet")

StdSetTestSuite.test("iterate over Swift.Array") {
    let s = Array(initSetOfCInt())
    var result = [CInt]()
    for x in s {
        result.append(x)
    }
    expectEqual(result[0], 1)
    expectEqual(result[1], 3)
    expectEqual(result[2], 5)
}

StdSetTestSuite.test("SetOfCInt.contains") {
    // This relies on the `std::set` conformance to `CxxSet` protocol.
    let s = initSetOfCInt()
    expectTrue(s.contains(1))
    expectFalse(s.contains(2))
    expectTrue(s.contains(3))
}

StdSetTestSuite.test("UnorderedSetOfCInt.contains") {
    // This relies on the `std::unordered_set` conformance to `CxxSet` protocol.
    let s = initUnorderedSetOfCInt()
    expectFalse(s.contains(1))
    expectTrue(s.contains(2))
    expectFalse(s.contains(3))
}

StdSetTestSuite.test("MultisetOfCInt.contains") {
    // This relies on the `std::multiset` conformance to `CxxSet` protocol.
    let s = initMultisetOfCInt()
    expectFalse(s.contains(1))
    expectTrue(s.contains(2))
    expectFalse(s.contains(3))
}

StdSetTestSuite.test("SetOfCInt.init()") {
    let s = SetOfCInt([1, 3, 5])
    expectTrue(s.contains(1))
    expectFalse(s.contains(2))
    expectTrue(s.contains(3))
}

StdSetTestSuite.test("UnorderedSetOfCInt.init()") {
    let s = UnorderedSetOfCInt([1, 3, 5])
    expectTrue(s.contains(1))
    expectFalse(s.contains(2))
    expectTrue(s.contains(3))
}

StdSetTestSuite.test("SetOfCInt as ExpressibleByArrayLiteral") {
    let s: SetOfCInt = [1, 3, 5]
    expectTrue(s.contains(1))
    expectFalse(s.contains(2))
    expectTrue(s.contains(3))

    func takesSetOfCInt(_ s: SetOfCInt) {
        expectTrue(s.contains(1))
        expectTrue(s.contains(2))
        expectFalse(s.contains(3))
    }

    takesSetOfCInt([1, 2])
}

StdSetTestSuite.test("UnorderedSetOfCInt as ExpressibleByArrayLiteral") {
    let s: UnorderedSetOfCInt = [1, 3, 5]
    expectTrue(s.contains(1))
    expectFalse(s.contains(2))
    expectTrue(s.contains(3))

    func takesUnorderedSetOfCInt(_ s: UnorderedSetOfCInt) {
        expectTrue(s.contains(1))
        expectTrue(s.contains(2))
        expectFalse(s.contains(3))
    }

    takesUnorderedSetOfCInt([1, 2])
}

StdSetTestSuite.test("MultisetOfCInt as ExpressibleByArrayLiteral") {
    let s: MultisetOfCInt = [1, 1, 3]
    expectTrue(s.contains(1))
    expectFalse(s.contains(2))
    expectTrue(s.contains(3))

    func takesMultisetOfCInt(_ s: MultisetOfCInt) {
        expectTrue(s.contains(1))
        expectTrue(s.contains(2))
        expectFalse(s.contains(3))
    }

    takesMultisetOfCInt([1, 1, 2])
}

StdSetTestSuite.test("SetOfCInt.insert") {
    var s = SetOfCInt()
    expectFalse(s.contains(123))

    let res1 = s.insert(123)
    expectTrue(res1.inserted)
    expectTrue(s.contains(123))

    let res2 = s.insert(123)
    expectFalse(res2.inserted)
    expectTrue(s.contains(123))
}

StdSetTestSuite.test("UnorderedSetOfCInt.insert") {
    var s = UnorderedSetOfCInt()
    expectFalse(s.contains(123))

    let res1 = s.insert(123)
    expectTrue(res1.inserted)
    expectTrue(s.contains(123))

    let res2 = s.insert(123)
    expectFalse(res2.inserted)
    expectTrue(s.contains(123))
}

StdSetTestSuite.test("SetOfCInt.erase") {
    var s = initSetOfCInt()
    expectTrue(s.contains(1))
    s.erase(1)
    expectFalse(s.contains(1))
    s.erase(1)
    expectFalse(s.contains(1))
}

StdSetTestSuite.test("UnorderedSetOfCInt.erase") {
    var s = initUnorderedSetOfCInt()
    expectTrue(s.contains(2))
    s.erase(2)
    expectFalse(s.contains(2))
    s.erase(2)
    expectFalse(s.contains(2))
}

#if !os(Linux)
StdSetTestSuite.test("SetOfCInt.remove") {
    var s = initSetOfCInt()
    expectTrue(s.contains(1))
    expectEqual(s.remove(1), 1)
    expectFalse(s.contains(1))
    expectEqual(s.remove(1), nil)
    expectFalse(s.contains(1))
}

StdSetTestSuite.test("UnorderedSetOfCInt.remove") {
    var s = initUnorderedSetOfCInt()
    expectTrue(s.contains(2))
    expectEqual(s.remove(2), 2)
    expectFalse(s.contains(2))
    expectEqual(s.remove(2), nil)
    expectFalse(s.contains(2))
}
#endif

StdSetTestSuite.test("SetOfCInt.filter") {
    let s1 = initSetOfCInt()
      .filter { $0 % 2 != 0 }
    
    expectTrue(s1.contains(1))
    expectTrue(s1.contains(3))
    expectTrue(s1.contains(5))
    
    let s2 = initSetOfCInt()
        .filter { $0 > 3 }

    expectFalse(s2.contains(1))
    expectFalse(s2.contains(3))
    expectTrue(s2.contains(5))
}

StdSetTestSuite.test("UnorderedSetOfCInt.filter") {
    let s1 = initUnorderedSetOfCInt()
        .filter { $0 % 2 != 0 }

    expectFalse(s1.contains(2))
    expectFalse(s1.contains(4))
    expectFalse(s1.contains(6))

    let s2 = initUnorderedSetOfCInt()
      .filter { $0 > 3 }
    expectFalse(s2.contains(2))
    expectTrue(s2.contains(4))
    expectTrue(s2.contains(6))
}

StdSetTestSuite.test("SetOfCInt.formUnion") {
    var s = initSetOfCInt()

    s.formUnion([2, 4, 6])
    s.formUnion(Set(arrayLiteral: 7, 8, 9))
    s.formUnion(SetOfCInt(arrayLiteral: 10, 11, 12))

    // Test with CxxUniqueSet, which type is not equal to Self.
    s.formUnion(UnorderedSetOfCInt(arrayLiteral: 13, 14, 15))

    for i in CInt(1)...15 {
        expectTrue(s.contains(i))
    }
}

StdSetTestSuite.test("UnorderedSetOfCInt.formUnion") {
    var s = initUnorderedSetOfCInt()

    s.formUnion([1, 3, 5])
    s.formUnion(Set(arrayLiteral: 7, 8, 9))

    // Test with CxxUniqueSet, which type is not equal to Self.
    s.formUnion(SetOfCInt(arrayLiteral: 10, 11, 12))
    s.formUnion(UnorderedSetOfCInt(arrayLiteral: 13, 14, 15))

    for i in CInt(1)...15 {
        expectTrue(s.contains(i))
    }
}

StdSetTestSuite.test("SetOfCInt.intersection(set)") {
    let s = initSetOfCInt()

    let r1 = s.intersection(initSetOfCInt())

    expectTrue(r1.contains(1))
    expectTrue(r1.contains(3))
    expectTrue(r1.contains(5))

    let r2 = s.intersection(initSetOfCInt2())
    expectFalse(r2.contains(1))
    expectTrue(r2.contains(3))
    expectFalse(r2.contains(5))

    // Test with CxxUniqueSet, which type is not equal to Self.
    let r3 = s.intersection(initUnorderedSetOfCInt())
    expectTrue(r3.isEmpty)
}

StdSetTestSuite.test("UnorderedSetOfCInt.intersection(set)") {
    let s = initUnorderedSetOfCInt()

    let r1 = s.intersection(initUnorderedSetOfCInt())
    expectTrue(r1.contains(2))
    expectTrue(r1.contains(4))
    expectTrue(r1.contains(6))  
    
    let r2 = s.intersection(initUnorderedSetOfCInt2())
    expectFalse(r2.contains(2))
    expectTrue(r2.contains(4))
    expectFalse(r2.contains(6))

    // Test with CxxUniqueSet, which type is not equal to Self.
    let r3 = s.intersection(initSetOfCInt())
    expectTrue(r3.isEmpty)
}

StdSetTestSuite.test("SetOfCInt.intersection") {
    let s = initSetOfCInt()

    let r1 = s.intersection([2, 4, 6])
    expectTrue(r1.isEmpty)

    let r2 = s.intersection([1, 5])
    expectTrue(r2.contains(1))
    expectFalse(r2.contains(3))
    expectTrue(r2.contains(5))
}

StdSetTestSuite.test("UnorderedSetOfCInt.intersection") {
    let s = initUnorderedSetOfCInt()

    let r1 = s.intersection([1, 3, 5])
    expectTrue(r1.isEmpty)

    let r2 = s.intersection([2, 6])
    expectTrue(r2.contains(2))
    expectFalse(r2.contains(4))
    expectTrue(r2.contains(6))  
}

// `formIntersection` is implemented with `intersection`, so we can skip this test

StdSetTestSuite.test("SetOfCInt.subtract") {
    var s = initSetOfCInt()

    s.subtract(initUnorderedSetOfCInt())
    expectTrue(s.contains(1))
    expectTrue(s.contains(3))
    expectTrue(s.contains(5))

    s.subtract([1, 3])
    
    expectFalse(s.contains(1))
    expectFalse(s.contains(3))
    expectTrue(s.contains(5))

    s.subtract([5])
    expectFalse(s.contains(5))
    expectTrue(s.isEmpty)
}

StdSetTestSuite.test("UnorderedSetOfCInt.subtract") {
    var s = initUnorderedSetOfCInt()

    s.subtract(initSetOfCInt())
    expectTrue(s.contains(2))
    expectTrue(s.contains(4))
    expectTrue(s.contains(6))

    s.subtract([2, 4])
    
    expectFalse(s.contains(2))
    expectFalse(s.contains(4))
    expectTrue(s.contains(6))

    s.subtract([6])
    expectFalse(s.contains(6))
    expectTrue(s.isEmpty)
}

StdSetTestSuite.test("SetOfCInt.isSubset(set)") {
  let m = initSetOfCInt()
  
  expectFalse(m.isSubset(of: initSetOfCIntEmpty()))
  expectFalse(m.isSubset(of: initSetOfCIntSubset()))
  expectTrue(m.isSubset(of: m))
  expectTrue(m.isSubset(of: initSetOfCIntSuperset()))
  expectFalse(m.isSubset(of: initSetOfCIntHasIntersection()))

  // Test with CxxUniqueSet, which type is not equal to Self.
  expectFalse(m.isSubset(of: initUnorderedSetOfCIntEmpty()))
  expectFalse(m.isSubset(of: initUnorderedSetOfCIntSubset()))
  expectTrue(m.isSubset(of: initUnorderedSetOfCIntCrossVerift()))
  expectTrue(m.isSubset(of: initUnorderedSetOfCIntCrossVeriftStrictSuperset()))
}

StdSetTestSuite.test("UnorderedSetOfCInt.isSubset(set)") {
  let m = initUnorderedSetOfCInt()
  
  expectFalse(m.isSubset(of: initUnorderedSetOfCIntEmpty()))
  expectFalse(m.isSubset(of: initUnorderedSetOfCIntSubset()))
  expectTrue(m.isSubset(of: m))
  expectTrue(m.isSubset(of: initUnorderedSetOfCIntSuperset()))
  expectFalse(m.isSubset(of: initUnorderedSetOfCIntHasIntersection()))

  // Test with CxxUniqueSet, which type is not equal to Self.
  expectFalse(m.isSubset(of: initSetOfCIntEmpty()))
  expectFalse(m.isSubset(of: initSetOfCIntSubset()))
  expectTrue(m.isSubset(of: initSetOfCIntCrossVerift()))
  expectTrue(m.isSubset(of: initSetOfCIntCrossVeriftStrictSuperset()))
}

StdSetTestSuite.test("SetOfCInt.isSubset") {
  let m = initSetOfCInt()
  
  expectFalse(m.isSubset(of: Array<CInt>()))
  expectFalse(m.isSubset(of: [CInt(1)]))
  expectFalse(m.isSubset(of: [CInt(1), 3]))
  expectTrue(m.isSubset(of: [CInt(1), 3, 5]))
  expectTrue(m.isSubset(of: [CInt(1), 3, 5, 7]))
  expectFalse(m.isSubset(of: [CInt(1), 5, 7]))
}

StdSetTestSuite.test("UnorderedSetOfCInt.isSubset") {
  let m = initUnorderedSetOfCInt()
  
  expectFalse(m.isSubset(of: Array<CInt>()))
  expectFalse(m.isSubset(of: [CInt(2)]))
  expectFalse(m.isSubset(of: [CInt(2), 4]))
  expectTrue(m.isSubset(of: [CInt(2), 4, 6]))
  expectTrue(m.isSubset(of: [CInt(2), 4, 6, 8]))
  expectFalse(m.isSubset(of: [CInt(2), 6, 8]))
}

StdSetTestSuite.test("SetOfCInt.isStrictSubset(set)") {
  let m = initSetOfCInt()
  
  expectFalse(m.isStrictSubset(of: initSetOfCIntEmpty()))
  expectFalse(m.isStrictSubset(of: initSetOfCIntSubset()))
  expectFalse(m.isStrictSubset(of: m))
  expectTrue(m.isStrictSubset(of: initSetOfCIntSuperset()))
  expectFalse(m.isStrictSubset(of: initSetOfCIntHasIntersection()))

  // Test with CxxUniqueSet, which type is not equal to Self.
  expectFalse(m.isStrictSubset(of: initUnorderedSetOfCIntEmpty()))
  expectFalse(m.isStrictSubset(of: initUnorderedSetOfCIntSubset()))
  expectFalse(m.isStrictSubset(of: initUnorderedSetOfCIntCrossVerift()))
  expectTrue(m.isStrictSubset(of: initUnorderedSetOfCIntCrossVeriftStrictSuperset()))
}

StdSetTestSuite.test("UnorderedSetOfCInt.isStrictSubset(set)") {
  let m = initUnorderedSetOfCInt()
  
  expectFalse(m.isStrictSubset(of: initUnorderedSetOfCIntEmpty()))
  expectFalse(m.isStrictSubset(of: initUnorderedSetOfCIntSubset()))
  expectFalse(m.isStrictSubset(of: m))
  expectTrue(m.isStrictSubset(of: initUnorderedSetOfCIntSuperset()))
  expectFalse(m.isStrictSubset(of: initUnorderedSetOfCIntHasIntersection()))

  // Test with CxxUniqueSet, which type is not equal to Self.
  expectFalse(m.isStrictSubset(of: initSetOfCIntEmpty()))
  expectFalse(m.isStrictSubset(of: initSetOfCIntSubset()))
  expectFalse(m.isStrictSubset(of: initSetOfCIntCrossVerift()))
  expectTrue(m.isStrictSubset(of: initSetOfCIntCrossVeriftStrictSuperset()))
}

StdSetTestSuite.test("SetOfCInt.isStrictSubset") {
  let m = initSetOfCInt()
  
  expectFalse(m.isStrictSubset(of: Array<CInt>()))
  expectFalse(m.isStrictSubset(of: [CInt(1)]))
  expectFalse(m.isStrictSubset(of: [CInt(1), 3]))
  expectFalse(m.isStrictSubset(of: [CInt(1), 3, 5]))
  expectFalse(m.isStrictSubset(of: [CInt(1), 3, 5, 3]))
  expectTrue(m.isStrictSubset(of: [CInt(1), 3, 5, 7]))
  expectTrue(m.isStrictSubset(of: [CInt(1), 3, 5, 7, 3]))
  expectFalse(m.isStrictSubset(of: [CInt(1), 5, 7]))
}

StdSetTestSuite.test("UnorderedSetOfCInt.isStrictSubset") {
  let m = initUnorderedSetOfCInt()
  
  expectFalse(m.isStrictSubset(of: Array<CInt>()))
  expectFalse(m.isStrictSubset(of: [CInt(2)]))
  expectFalse(m.isStrictSubset(of: [CInt(2), 4]))
  expectFalse(m.isStrictSubset(of: [CInt(2), 4, 6]))
  expectFalse(m.isStrictSubset(of: [CInt(2), 4, 6, 4]))
  expectTrue(m.isStrictSubset(of: [CInt(2), 4, 6, 8]))
  expectTrue(m.isStrictSubset(of: [CInt(2), 4, 6, 8, 4]))
  expectFalse(m.isStrictSubset(of: [CInt(2), 6, 8]))
}

StdSetTestSuite.test("SetOfCInt.isSuperset(set)") {
  let m = initSetOfCInt()
  
  expectTrue(m.isSuperset(of: initSetOfCIntEmpty()))
  expectTrue(m.isSuperset(of: initSetOfCIntSubset()))
  expectTrue(m.isSuperset(of: m))
  expectFalse(m.isSuperset(of: initSetOfCIntSuperset()))
  expectFalse(m.isSuperset(of: initSetOfCIntHasIntersection()))

  // Test with CxxUniqueSet, which type is not equal to Self.
  expectTrue(m.isSuperset(of: initUnorderedSetOfCIntEmpty()))
  expectFalse(m.isSuperset(of: initUnorderedSetOfCIntSubset()))
  expectTrue(m.isSuperset(of: initUnorderedSetOfCIntCrossVerift()))
  expectTrue(initUnorderedSetOfCIntCrossVeriftStrictSuperset().isSuperset(of: m))
}

StdSetTestSuite.test("UnorderedSetOfCInt.isSuperset(set)") {
  let m = initUnorderedSetOfCInt()
  
  expectTrue(m.isSuperset(of: initUnorderedSetOfCIntEmpty()))
  expectTrue(m.isSuperset(of: initUnorderedSetOfCIntSubset()))
  expectTrue(m.isSuperset(of: m))
  expectFalse(m.isSuperset(of: initUnorderedSetOfCIntSuperset()))
  expectFalse(m.isSuperset(of: initUnorderedSetOfCIntHasIntersection()))

  // Test with CxxUniqueSet, which type is not equal to Self.
  expectTrue(m.isSuperset(of: initSetOfCIntEmpty()))
  expectFalse(m.isSuperset(of: initSetOfCIntSubset()))
  expectTrue(m.isSuperset(of: initSetOfCIntCrossVerift()))
  expectTrue(initSetOfCIntCrossVeriftStrictSuperset().isSuperset(of: m))
}

StdSetTestSuite.test("SetOfCInt.isSuperset") {
  let m = initSetOfCInt()
  
  expectTrue(m.isSuperset(of: Array<CInt>()))
  expectTrue(m.isSuperset(of: [CInt(1)]))
  expectTrue(m.isSuperset(of: [CInt(1), 3]))
  expectTrue(m.isSuperset(of: [CInt(1), 3, 5]))
  expectFalse(m.isSuperset(of: [CInt(1), 3, 5, 7]))
  expectFalse(m.isSuperset(of: [CInt(1), 5, 7]))
}

StdSetTestSuite.test("UnorderedSetOfCInt.isSuperset") {
  let m = initUnorderedSetOfCInt()
  
  expectTrue(m.isSuperset(of: Array<CInt>()))
  expectTrue(m.isSuperset(of: [CInt(2)]))
  expectTrue(m.isSuperset(of: [CInt(2), 4]))
  expectTrue(m.isSuperset(of: [CInt(2), 4, 6]))
  expectFalse(m.isSuperset(of: [CInt(2), 4, 6, 8]))
  expectFalse(m.isSuperset(of: [CInt(2), 6, 8]))
}

StdSetTestSuite.test("SetOfCInt.isStrictSuperset(set)") {
  let m = initSetOfCInt()
  
  expectTrue(m.isStrictSuperset(of: initSetOfCIntEmpty()))
  expectTrue(m.isStrictSuperset(of: initSetOfCIntSubset()))
  expectFalse(m.isStrictSuperset(of: m))
  expectFalse(m.isStrictSuperset(of: initSetOfCIntSuperset()))
  expectFalse(m.isStrictSuperset(of: initSetOfCIntHasIntersection()))

  // Test with CxxUniqueSet, which type is not equal to Self.
  expectTrue(m.isStrictSuperset(of: initUnorderedSetOfCIntEmpty()))
  expectFalse(m.isStrictSuperset(of: initUnorderedSetOfCIntSubset()))
  expectFalse(m.isStrictSuperset(of: initUnorderedSetOfCIntCrossVerift()))
  expectTrue(initUnorderedSetOfCIntCrossVeriftStrictSuperset().isStrictSuperset(of: m))
}

StdSetTestSuite.test("UnorderedSetOfCInt.isStrictSuperset(set)") {
  let m = initUnorderedSetOfCInt()
  
  expectTrue(m.isStrictSuperset(of: initUnorderedSetOfCIntEmpty()))
  expectTrue(m.isStrictSuperset(of: initUnorderedSetOfCIntSubset()))
  expectFalse(m.isStrictSuperset(of: m))
  expectFalse(m.isStrictSuperset(of: initUnorderedSetOfCIntSuperset()))
  expectFalse(m.isStrictSuperset(of: initUnorderedSetOfCIntHasIntersection()))

  // Test with CxxUniqueSet, which type is not equal to Self.
  expectTrue(m.isStrictSuperset(of: initSetOfCIntEmpty()))
  expectFalse(m.isStrictSuperset(of: initSetOfCIntSubset()))
  expectFalse(m.isStrictSuperset(of: initSetOfCIntCrossVerift()))
  expectTrue(initSetOfCIntCrossVeriftStrictSuperset().isStrictSuperset(of: m))
}

StdSetTestSuite.test("SetOfCInt.isStrictSuperset") {
  let m = initSetOfCInt()
  
  expectTrue(m.isStrictSuperset(of: Array<CInt>()))
  expectTrue(m.isStrictSuperset(of: [CInt(1)]))
  expectTrue(m.isStrictSuperset(of: [CInt(1), 3]))
  expectFalse(m.isStrictSuperset(of: [CInt(1), 3, 5]))
  expectFalse(m.isStrictSuperset(of: [CInt(1), 3, 5, 3]))
  expectFalse(m.isStrictSuperset(of: [CInt(1), 3, 5, 7]))
  expectFalse(m.isStrictSuperset(of: [CInt(1), 3, 5, 7, 3]))
  expectFalse(m.isStrictSuperset(of: [CInt(1), 5, 7]))
}

StdSetTestSuite.test("UnorderedSetOfCInt.isStrictSuperset") {
  let m = initUnorderedSetOfCInt()
  
  expectTrue(m.isStrictSuperset(of: Array<CInt>()))
  expectTrue(m.isStrictSuperset(of: [CInt(2)]))
  expectTrue(m.isStrictSuperset(of: [CInt(2), 4]))
  expectFalse(m.isStrictSuperset(of: [CInt(2), 4, 6]))
  expectFalse(m.isStrictSuperset(of: [CInt(2), 4, 6, 4]))
  expectFalse(m.isStrictSuperset(of: [CInt(2), 4, 6, 8]))
  expectFalse(m.isStrictSuperset(of: [CInt(2), 4, 6, 8, 4]))
  expectFalse(m.isStrictSuperset(of: [CInt(2), 6, 8]))
}

StdSetTestSuite.test("SetOfCInt.isDisjoint(set)") {
  let m = initSetOfCInt()
  
  expectTrue(m.isDisjoint(with: initSetOfCIntEmpty()))
  expectFalse(m.isDisjoint(with: initSetOfCIntSubset()))
  expectFalse(m.isDisjoint(with: m))
  expectFalse(m.isDisjoint(with: initSetOfCIntSuperset()))
  expectFalse(m.isDisjoint(with: initSetOfCIntHasIntersection()))
  expectTrue(m.isDisjoint(with: initSetOfCIntDisjoint()))

  // Test with CxxUniqueSet, which type is not equal to Self.
  expectTrue(m.isDisjoint(with: initUnorderedSetOfCIntEmpty()))
  expectTrue(m.isDisjoint(with: initUnorderedSetOfCIntSubset()))
  expectFalse(m.isDisjoint(with: initUnorderedSetOfCIntCrossVerift()))
  expectFalse(m.isDisjoint(with: initUnorderedSetOfCIntCrossVeriftStrictSuperset()))
}

StdSetTestSuite.test("UnorderedSetOfCInt.isDisjoint(set)") {
  let m = initUnorderedSetOfCInt()
  
  expectTrue(m.isDisjoint(with: initUnorderedSetOfCIntEmpty()))
  expectFalse(m.isDisjoint(with: initUnorderedSetOfCIntSubset()))
  expectFalse(m.isDisjoint(with: m))
  expectFalse(m.isDisjoint(with: initUnorderedSetOfCIntSuperset()))
  expectFalse(m.isDisjoint(with: initUnorderedSetOfCIntHasIntersection()))
  expectTrue(m.isDisjoint(with: initUnorderedSetOfCIntDisjoint()))

  // Test with CxxUniqueSet, which type is not equal to Self.
  expectTrue(m.isDisjoint(with: initSetOfCIntEmpty()))
  expectTrue(m.isDisjoint(with: initSetOfCIntSubset()))
  expectFalse(m.isDisjoint(with: initSetOfCIntCrossVerift()))
  expectFalse(m.isDisjoint(with: initSetOfCIntCrossVeriftStrictSuperset()))
}

StdSetTestSuite.test("SetOfCInt.isDisjoint") {
  let m = initSetOfCInt()
  
  expectTrue(m.isDisjoint(with: Array<CInt>()))
  expectFalse(m.isDisjoint(with: [CInt(1)]))
  expectFalse(m.isDisjoint(with: [CInt(1), 3]))
  expectFalse(m.isDisjoint(with: [CInt(1), 3, 5]))
  expectFalse(m.isDisjoint(with: [CInt(1), 3, 5, 3]))
  expectFalse(m.isDisjoint(with: [CInt(1), 3, 5, 7]))
  expectFalse(m.isDisjoint(with: [CInt(1), 3, 5, 7, 3]))
  expectFalse(m.isDisjoint(with: [CInt(1), 5, 7]))
  expectTrue(m.isDisjoint(with: [CInt(2), 4]))
  expectTrue(m.isDisjoint(with: [CInt(2), 4, 6]))
  expectTrue(m.isDisjoint(with: [CInt(2), 4, 6, 8]))
}

StdSetTestSuite.test("UnorderedSetOfCInt.isDisjoint") {
  let m = initUnorderedSetOfCInt()
  
  expectTrue(m.isDisjoint(with: Array<CInt>()))
  expectFalse(m.isDisjoint(with: [CInt(2)]))
  expectFalse(m.isDisjoint(with: [CInt(2), 4]))
  expectFalse(m.isDisjoint(with: [CInt(2), 4, 6]))
  expectFalse(m.isDisjoint(with: [CInt(2), 4, 6, 4]))
  expectFalse(m.isDisjoint(with: [CInt(2), 4, 6, 8]))
  expectFalse(m.isDisjoint(with: [CInt(2), 4, 6, 8, 4]))
  expectFalse(m.isDisjoint(with: [CInt(2), 6, 8]))
  expectTrue(m.isDisjoint(with: [CInt(1), 3]))
  expectTrue(m.isDisjoint(with: [CInt(1), 3, 5]))
  expectTrue(m.isDisjoint(with: [CInt(1), 3, 5, 7]))
}

runAllTests()
