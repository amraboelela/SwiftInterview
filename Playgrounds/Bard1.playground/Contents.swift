
// Find the factorial of a number

func factorial(_ number: Int) -> Int {
    if number == 0 {
        return 1
    } else {
        return number * factorial(number - 1)
    }
}

factorial(5)


// Check if a number is prime

func isPrime(_ number: Int) -> Bool {
    if number == 1 {
        return false
    }
    for divisor in 2..<number {
        if number % divisor == 0 {
            return false
        }
    }
    return true
}

isPrime(5)
isPrime(6)
isPrime(7)


// Find the greatest common divisor (GCD) of two numbers

func gcd(_ number1: Int, _ number2: Int) -> Int {
    print("number1: \(number1), number2: \(number2)")
    if number2 == 0 {
        return number1
    } else {
        return gcd(number2, number1 % number2)
    }
}

gcd(12, 18)


// Find the least common multiple (LCM) of two numbers

func lcm(_ number1: Int, _ number2: Int) -> Int {
    return (number1 * number2) / gcd(number1, number2)
}

lcm(12, 18)

