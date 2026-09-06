import SwiftUI

import DomainInterface

import Dependencies

struct EndpointDetailView: View {
    enum Endpoint {
        case lessonDetail
        case wordDetail
        case authSignIn

        var title: String {
            switch self {
            case .lessonDetail: "lessonRepository.fetchDetail(id:)"
            case .wordDetail: "wordRepository.fetchDetail(id:)"
            case .authSignIn: "signInWithApple(identityToken:)"
            }
        }

        var hasIdParam: Bool {
            switch self {
            case .lessonDetail, .wordDetail, .authSignIn: true
            }
        }

        var paramLabel: String {
            switch self {
            case .lessonDetail, .wordDetail: "id"
            case .authSignIn: "identityToken"
            }
        }

        var randomId: String {
            switch self {
            case .lessonDetail: String(Int.random(in: 1...244))
            case .wordDetail: "word_\(Int.random(in: 1...800))"
            case .authSignIn: ""
            }
        }
    }

    let endpoint: Endpoint

    @State private var idInput = ""
    @State private var response = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    @Dependency(\.lessonRepository) private var lessonRepository
    @Dependency(\.wordRepository) private var wordRepository
    @Dependency(\.signInWithAppleUseCase) private var signInWithAppleUseCase

    var body: some View {
        Form {
            if endpoint.hasIdParam {
                Section("파라미터") {
                    TextField(endpoint.paramLabel, text: $idInput)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }

            Section {
                Button {
                    Task { await call() }
                } label: {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("호출")
                                .bold()
                        }
                        Spacer()
                    }
                }
                .disabled(isLoading || (endpoint.hasIdParam && idInput.isEmpty))

                if endpoint.hasIdParam {
                    Button {
                        Task { await callWithRandomId() }
                    } label: {
                        HStack {
                            Spacer()
                            Text("랜덤 호출")
                                .bold()
                                .foregroundStyle(.orange)
                            Spacer()
                        }
                    }
                    .disabled(isLoading)
                }
            }

            if let error = errorMessage {
                Section("오류") {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.system(.caption, design: .monospaced))
                }
            }

            if !response.isEmpty {
                Section("응답") {
                    ScrollView {
                        Text(response)
                            .font(.system(.caption2, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 500)
                }
            }
        }
        .navigationTitle(endpoint.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    private func callWithRandomId() async {
        idInput = endpoint.randomId
        await call()
    }

    @MainActor
    private func call() async {
        isLoading = true
        errorMessage = nil
        response = ""
        defer { isLoading = false }

        do {
            switch endpoint {
            case .lessonDetail:
                let result = try await lessonRepository.fetchDetail(idInput)
                response = dumpString(result)
            case .wordDetail:
                let result = try await wordRepository.fetchDetail(idInput)
                response = dumpString(result)
            case .authSignIn:
                let result = try await signInWithAppleUseCase.execute(idInput)
                response = dumpString(result)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func dumpString<T>(_ value: T) -> String {
        var output = ""
        dump(value, to: &output)
        return output
    }
}
