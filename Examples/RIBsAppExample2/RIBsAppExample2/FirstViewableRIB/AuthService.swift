//
//  AuthService.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 3/12/26.
//

protocol AuthServiceType {
    func login() async throws -> UserSession
}

final class FakeAuthService: AuthServiceType {

    func login() async throws -> UserSession {
        try await Task.sleep(nanoseconds: 2_000_000_000)
        return UserSession(userId: "u_42", username: "alexvbush", authToken: "tok_abc123")
    }
}
