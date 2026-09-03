import SwiftUI

struct ClientListView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("GetSessionDetailUseCase") {
                    NavigationLink("execute(id:)") {
                        EndpointDetailView(endpoint: .sessionDetail)
                    }
                }
                Section("GetWordDetailUseCase") {
                    NavigationLink("execute(id:)") {
                        EndpointDetailView(endpoint: .wordDetail)
                    }
                }
                Section("SignInWithAppleUseCase") {
                    NavigationLink("execute(identityToken:)") {
                        EndpointDetailView(endpoint: .authSignIn)
                    }
                }
            }
            .navigationTitle("Domain API Explorer")
        }
    }
}
