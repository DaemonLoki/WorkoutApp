/// A Postgres column name as the records' property name: `session_exercise_id` → `sessionExerciseID`.
struct CamelCaseKey: CodingKey {
    let stringValue: String
    let intValue: Int? = nil

    init(snakeCase: String) {
        let words = snakeCase.split(separator: "_").enumerated().map { index, word in
            if index == 0 { return String(word) }
            return word == "id" ? "ID" : word.prefix(1).uppercased() + word.dropFirst()
        }
        stringValue = words.joined()
    }

    init?(stringValue: String) { self.init(snakeCase: stringValue) }
    init?(intValue: Int) { nil }
}
