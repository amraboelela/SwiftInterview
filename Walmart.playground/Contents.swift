import Foundation

// we want a function to split the bags of chocolates between your mother's daughter and son in a way that minimizes the difference in the total number of chocolates each of them receives, right? Let me write up a function for you.

func splitChocolates1(bags: [Int]) -> (daughter: [Int], son: [Int]) {
    let sortedBags = bags.sorted()
    var daughterChocolates = [Int]()
    var sonChocolates = [Int]()
    var daughterTotal = 0
    var sonTotal = 0
    
    for bag in sortedBags.reversed() {
        if daughterTotal <= sonTotal {
            daughterChocolates.append(bag)
            daughterTotal += bag
        } else {
            sonChocolates.append(bag)
            sonTotal += bag
        }
    }
    
    return (daughterChocolates, sonChocolates)
}

// Example usage:
var bagsOfChocolates = [1, 3, 4, 5, 7, 8]
var (daughter, son) = splitChocolates1(bags: bagsOfChocolates)
print("Daughter's chocolates: \(daughter)")
print("Daughter's chocolates sum: \(daughter.reduce(0, +))")
print("Son's chocolates: \(son)")
print("Son's chocolates sum: \(son.reduce(0, +))")

print("")
bagsOfChocolates = [5, 3, 2, 7, 4]
(daughter, son) = splitChocolates1(bags: bagsOfChocolates)
print("Daughter's chocolates: \(daughter)")
print("Daughter's chocolates sum: \(daughter.reduce(0, +))")
print("Son's chocolates: \(son)")
print("Son's chocolates sum: \(son.reduce(0, +))")

print("")
bagsOfChocolates = [9, 3, 5, 10, 13, 4, 7, 8]
(daughter, son) = splitChocolates1(bags: bagsOfChocolates)
print("Daughter's chocolates: \(daughter)")
print("Daughter's chocolates sum: \(daughter.reduce(0, +))")
print("Son's chocolates: \(son)")
print("Son's chocolates sum: \(son.reduce(0, +))")

func splitChocolates(bags: [Int]) -> (daughter: [Int], son: [Int]) {
    let totalChocolates = bags.reduce(0, +)
    let target = totalChocolates / 2
    var daughterChocolates = [Int]()
    var sonChocolates = [Int]()
    var daughterTotal = 0
    var sonTotal = 0
    
    for bag in bags.sorted(by: >) {
        if daughterTotal + bag <= target {
            daughterChocolates.append(bag)
            daughterTotal += bag
        } else {
            sonChocolates.append(bag)
            sonTotal += bag
        }
    }
    
    return (daughterChocolates, sonChocolates)
}

// Example usage:
print("")
bagsOfChocolates = [1, 3, 4, 5, 7, 8]
(daughter, son) = splitChocolates(bags: bagsOfChocolates)
print("Daughter's chocolates: \(daughter)")
print("Daughter's chocolates sum: \(daughter.reduce(0, +))")
print("Son's chocolates: \(son)")
print("Son's chocolates sum: \(son.reduce(0, +))")

print("")
bagsOfChocolates = [1, 3, 2, 4, 5, 7, 8]
(daughter, son) = splitChocolates(bags: bagsOfChocolates)
print("Daughter's chocolates: \(daughter)")
print("Daughter's chocolates sum: \(daughter.reduce(0, +))")
print("Son's chocolates: \(son)")
print("Son's chocolates sum: \(son.reduce(0, +))")

print("")
bagsOfChocolates = [1, 3, 2, 4, 5, 7, 6, 8]
(daughter, son) = splitChocolates(bags: bagsOfChocolates)
print("Daughter's chocolates: \(daughter)")
print("Daughter's chocolates sum: \(daughter.reduce(0, +))")
print("Son's chocolates: \(son)")
print("Son's chocolates sum: \(son.reduce(0, +))")

print("")
bagsOfChocolates = [9, 3, 5, 10, 13, 4, 7, 8]
(daughter, son) = splitChocolates(bags: bagsOfChocolates)
print("Daughter's chocolates: \(daughter)")
print("Daughter's chocolates sum: \(daughter.reduce(0, +))")
print("Son's chocolates: \(son)")
print("Son's chocolates sum: \(son.reduce(0, +))")

print("")
bagsOfChocolates = [9, 3, 5, 10, 13, 4, 7, 1, 8]
(daughter, son) = splitChocolates(bags: bagsOfChocolates)
print("Daughter's chocolates: \(daughter)")
print("Daughter's chocolates sum: \(daughter.reduce(0, +))")
print("Son's chocolates: \(son)")
print("Son's chocolates sum: \(son.reduce(0, +))")
