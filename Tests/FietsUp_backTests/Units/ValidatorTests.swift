@testable import FietsUp_back
import VaporTesting
import Testing

@Suite("Validator Tests")
struct ValidatorTests {
  @Test("A strong password passes the secure password validator")
  func securePasswordValid() {
    #expect(!Validator<String>.securePassword.validate("Passw0rd!").isFailure)
  }

  @Test(
    "A weak password fails with the missing rule in its message",
    arguments: [
      ("", "cannot be empty"),
      ("Pa0!", "must be at least 8 characters"),
      ("passw0rd!", "must contain at least 1 uppercase letter"),
      ("PASSW0RD!", "must contain at least 1 lowercase letter"),
      ("Password!", "must contain at least 1 number"),
      ("Passw0rdd", "must contain at least 1 special character"),
    ])
  func securePasswordInvalid(password: String, expectedError: String) throws {
    let result = Validator<String>.securePassword.validate(password)
    #expect(result.isFailure)
    #expect(try #require(result.failureDescription).contains(expectedError))
  }

  @Test("Valid international phone numbers pass", arguments: ["+33612345678", "0612345678", "1234"])
  func phoneNumberValid(number: String) {
    #expect(!Validator<String>.internationalPhoneNumber.validate(number).isFailure)
  }

  @Test(
    "Invalid international phone numbers fail",
    arguments: ["06 12 34 56 78", "06-12-34-56-78", "phone", "123", "+1234567890123456"])
  func phoneNumberInvalid(number: String) {
    #expect(Validator<String>.internationalPhoneNumber.validate(number).isFailure)
  }
}
