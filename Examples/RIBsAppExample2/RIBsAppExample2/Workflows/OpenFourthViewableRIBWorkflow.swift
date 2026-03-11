//
//  OpenFourthViewableRIBWorkflow.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 3/11/26.
//

import RIBs
import RxSwift

// MARK: - ActionableItem Protocols

/// The root interactor's actionable interface used by workflows.
protocol RootActionableItem: AnyObject {
    /// Emits when the First RIB is active and ready to accept workflow steps.
    func waitForFirstViewableRIB() -> Observable<(FirstViewableRIBActionableItem, ())>
}

/// The First RIB interactor's actionable interface used by workflows.
protocol FirstViewableRIBActionableItem: AnyObject {
    /// Routes directly to the Fourth RIB, bypassing the Second/Third path.
    func openFourthViewableRIB() -> Observable<(FourthViewableRIBActionableItem, ())>
}

/// The Fourth RIB interactor's actionable interface used by workflows.
protocol FourthViewableRIBActionableItem: AnyObject {}

// MARK: - Workflow

/// A workflow triggered by the `ribsappexample2:///example-deeplink` deep link.
///
/// Steps:
/// 1. Wait for the First RIB to become active (it starts automatically at launch).
/// 2. Route directly from First to Fourth, demonstrating cross-path navigation.
final class OpenFourthViewableRIBWorkflow: Workflow<RootActionableItem> {
    override init() {
        super.init()
        self
            .onStep { (rootItem: RootActionableItem) -> Observable<(FirstViewableRIBActionableItem, ())> in
                rootItem.waitForFirstViewableRIB()
            }
            .onStep { (firstItem: FirstViewableRIBActionableItem, _) -> Observable<(FourthViewableRIBActionableItem, ())> in
                firstItem.openFourthViewableRIB()
            }
            .commit()
    }
}
