@preconcurrency import Combine
import os.log

/// Similar to TCA store, but state is updated on a background thread.
public actor BackgroundStore<State: Sendable, Action: Sendable> {
  nonisolated private let subject: CurrentValueSubject<State, Never>
  private let reducer: @Sendable (inout State, Action) -> BackgroundEffect<Action>
  private var cancellablesDict = [String: Set<AnyCancellable>]()
  private let debug: Bool

  public init(
    initialState: State,
    initialAction: Action? = nil,
    debug: Bool = false,
    _ reducer: @escaping @Sendable (inout State, Action) -> BackgroundEffect<Action>
  ) {
    self.subject = CurrentValueSubject(initialState)
    self.reducer = reducer
    self.debug = debug

    if let initialAction {
      Task {
        await send(initialAction)
      }
    }
  }

  nonisolated public var state: State {
    return subject.value
  }

  nonisolated public var publisher: AnyPublisher<State, Never> {
    return subject.eraseToAnyPublisher()
  }

  public func send(_ action: Action) async {
    if debug, #available(macCatalyst 14.0, *) {
      os_log("store received action \(String(describing: action))")
    }
    var state = subject.value
    let effect = reducer(&state, action)
    subject.send(state)
    if debug, #available(macCatalyst 14.0, *) {
      os_log("state changes to \(String(describing: state))")
    }
    effect.perform(
      cancellablesDict: &cancellablesDict,
      send: { [weak self] action in
        await self?.send(action)
      })
  }
}
