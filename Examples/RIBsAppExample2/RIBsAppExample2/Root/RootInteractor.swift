//
//  RootInteractor.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 1/10/26.
//

import RIBs
import RxSwift
import Foundation

protocol RootRouting: ViewableRouting {
    func routeToFirstViewableRIB() -> FirstViewableRIBActionableItem
    func routeAwayFromFirstViewableRIB()
}

protocol RootPresentable: Presentable {
    var listener: RootPresentableListener? { get set }
    // TODO: Declare methods the interactor can invoke the presenter to present data.
}

protocol RootListener: AnyObject {
    // TODO: Declare methods the interactor can invoke to communicate with other RIBs.
}

final class RootInteractor: PresentableInteractor<RootPresentable>, RootInteractable, RootPresentableListener, UrlHandler {

    weak var router: RootRouting?
    weak var listener: RootListener?

    private let firstViewableRIBActionableItemSubject = ReplaySubject<FirstViewableRIBActionableItem>.create(bufferSize: 1)

    // TODO: Add additional dependencies to constructor. Do not perform any logic
    // in constructor.
    override init(presenter: RootPresentable) {
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()

        if let firstItem = router?.routeToFirstViewableRIB() {
            firstViewableRIBActionableItemSubject.onNext(firstItem)
        }
    }

    override func willResignActive() {
        super.willResignActive()
        // TODO: Pause any business logic.
    }

    // MARK: - RootActionableItem

    func waitForFirstViewableRIB() -> Observable<(FirstViewableRIBActionableItem, ())> {
        return firstViewableRIBActionableItemSubject.map { ($0, ()) }
    }

    // MARK: - UrlHandler

    func handle(_ url: URL) {
        switch url.path {
        case "/example-deeplink":
            let workflow = OpenFourthViewableRIBWorkflow()
            workflow.subscribe(self).disposeOnDeactivate(interactor: self)
        default:
            break
        }
    }
}
