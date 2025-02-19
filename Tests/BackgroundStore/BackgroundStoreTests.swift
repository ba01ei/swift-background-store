@preconcurrency import Combine
import Testing
import Foundation
@testable import BackgroundStore

@available(iOS 15, *)
@Test func basicBackgroundStore() async throws {
  /// Obserses a source that publishes numbers, and write the latest value into UserDefaults
  struct NumberWriter {
    struct State {
      var value = 0
    }
    enum Action {
      case initialized
      case valueReceived(Int)
    }
    static func store(
      source: CurrentValueSubject<Int, Never>,
      userDefaults: UserDefaults = .standard
    ) -> BackgroundStore<State, Action> {
      return BackgroundStore(
        initialState: State(),
        initialAction: .initialized
      ) { state, action in
        switch action {
        case .initialized:
          return .run { send in
            for await number in source.values {
              await send(.valueReceived(number))
            }
          }
        case .valueReceived(let number):
          state.value = number
          return .run { [value = state.value] _ in
            userDefaults.set(value, forKey: "value")
          }
          .cancellable(id: "numberUpdate", cancelInFlight: true)
        }
      }
    }
  }
  
  let source = CurrentValueSubject<Int, Never>(0)
  let userDefaults = UserDefaults()
  let store = NumberWriter.store(source: source, userDefaults: userDefaults)
  #expect(store.state.value == 0)

  // value update from source subject
  source.send(100)
  await expectWithDelay { userDefaults.integer(forKey: "value") == 100 }
  #expect(store.state.value == 100)
  
  // value update by sending an action to the store
  await store.send(.valueReceived(200))
  await expectWithDelay { userDefaults.integer(forKey: "value") == 200 }
  #expect(store.state.value == 200)
}

func expectWithDelay(_ condition: () -> Bool, timeout: TimeInterval = 1) async {
  let interval = 0.1
  for _ in 0 ..< Int(timeout / interval) {
    if condition() {
      return
    }
    try? await Task.sleep(nanoseconds: UInt64(1e9 * interval))
  }
  Issue.record("condition not met after timeout")
}

extension UserDefaults: @retroactive @unchecked Sendable {}
