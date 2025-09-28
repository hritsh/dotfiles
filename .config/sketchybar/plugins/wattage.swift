import Foundation

@main
struct WattSecCLI {
    static func main() {
        let key = "PSTR"
        if let wattage = SMC.shared.getValue(key) {
            print(wattage)
        } else {
            print("0")
        }
    }
}