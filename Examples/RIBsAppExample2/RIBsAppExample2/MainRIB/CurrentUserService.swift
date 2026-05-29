//
//  CurrentUserService.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 3/12/26.
//

protocol CurrentUserServiceType: AnyObject {
    var session: UserSession { get }
}

final class CurrentUserService: CurrentUserServiceType {

    let session: UserSession

    init(session: UserSession) {
        self.session = session
    }
}
