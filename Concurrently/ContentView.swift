import SwiftUI

@MainActor final class ViewModel: ObservableObject {
    @Published var status: String = "initial"

    deinit {
        print("ViewModel.deinit")
    }

    // Classes marked with @MainActor are implicitly sendable, because the main actor coordinates all access to its state. These classes can have stored properties that are mutable and nonsendable.
    @Sendable func refreshAction() async {
        do {
            var message = "\(#function): enter"
            print(message)
            status = message

            try await Task.sleep(for: .seconds(2))

            message = "\(#function): leave"
            print(message)
            status = message
        } catch {
            let message = "\(#function): \(error)"
            print(message)
            status = message
        }
    }
}

struct ContentView: View {

    @StateObject private var viewModel = ViewModel()

    var body: some View {
        ScrollView {
            Text(viewModel.status).padding(50)
        }

        /*
         ❌
         Result: enter -> CancellationError()
         Swift Concurrency Instrument - total tasks: 2
         implicitly capturing self
         */
//        .refreshable {
//            await viewModel.refreshAction()
//        }

        /*
         ❌
         Result: enter -> CancellationError()
         Swift Concurrency Instrument - total tasks: 2
         explicitly capturing self
         */
//        .refreshable { [self] in
//            await viewModel.refreshAction()
//        }

        /*
         ✅
         Result: enter -> 2s -> leave
         Swift Concurrency Instrument - total tasks: 2
         capturing viewModel
         */
//        .refreshable { [viewModel] in
//            await viewModel.refreshAction()
//        }

        /*
         ❌
         Result: enter -> CancellationError()
         Swift Concurrency Instrument - total tasks: 2
         capturing viewModel.refreshAction function
         */
//        .refreshable { [refreshAction = viewModel.refreshAction] in
//            await refreshAction()
//        }

        /*
         ✅
         Result: enter -> 2s -> leave
         Swift Concurrency Instrument - total tasks: 2
         capturing self? or viewModel?
         */
        .refreshable(action: viewModel.refreshAction)

        /*
         ⚠️
         Result: enter -> leave immediately
         Swift Concurrency Instrument - total tasks: 3
         */
//        .refreshable {
//            Task { await viewModel.refreshAction() }
//        }

        /*
         ✅
         Result: enter -> 2s -> leave
         Swift Concurrency Instrument - total tasks: 3
         */
//        .refreshable {
//            let t = Task { await viewModel.refreshAction() }
//            await t.value
//        }
    }
}

#Preview {
    ContentView()
}
