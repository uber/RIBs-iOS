//
//  FourthViewableRIBPresenter.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 3/10/26.
//

import RIBs

protocol FourthViewableRIBPresentableListener: AnyObject {
    // TODO: Declare properties and methods that the view controller can invoke to perform
    // business logic, such as signIn(). This protocol is implemented by the corresponding
    // interactor class.
}

final class FourthViewableRIBPresenter: Presenter<FourthViewableRIBViewControllable>, FourthViewableRIBPresentable {
    
    weak var listener: FourthViewableRIBPresentableListener?
    
    func presentSomeStuff()  {
        viewController.renderSomeOtherColor()
    }
}
