import SwiftUI

struct ClientListView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("LessonRepository") {
                    NavigationLink("fetchDetail(id:)") {
                        EndpointDetailView(endpoint: .lessonDetail)
                    }
                }
                Section("WordRepository") {
                    NavigationLink("fetchDetail(id:)") {
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
