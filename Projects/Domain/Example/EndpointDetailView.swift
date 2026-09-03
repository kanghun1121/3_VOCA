import SwiftUI

import DomainInterface

import Dependencies

struct EndpointDetailView: View {
    enum Endpoint {
        case sessionDetail
        case wordDetail
        case authSignIn

        var title: String {
            switch self {
            case .sessionDetail: "fetchSessionDetail(id:)"
            case .wordDetail: "fetchWordDetail(id:)"
            case .authSignIn: "signInWithApple(identityToken:)"
            }
        }

        var hasIdParam: Bool {
            switch self {
            case .sessionDetail, .wordDetail, .authSignIn: true
            }
        }

        var paramLabel: String {
            switch self {
            case .sessionDetail, .wordDetail: "id"
            case .authSignIn: "identityToken"
            }
        }

        var randomId: String {
            switch self {
            case .sessionDetail: String(Int.random(in: 1...244))
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

    @Dependency(\.getSessionDetailUseCase) private var getSessionDetailUseCase
    @Dependency(\.getWordDetailUseCase) private var getWordDetailUseCase
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
            case .sessionDetail:
                let result = try await getSessionDetailUseCase.execute(idInput)
                response = dumpString(result)
            case .wordDetail:
                let result = try await getWordDetailUseCase.execute(idInput)
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
