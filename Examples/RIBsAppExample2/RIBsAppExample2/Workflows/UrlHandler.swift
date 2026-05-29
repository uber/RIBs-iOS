//
//  UrlHandler.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 3/11/26.
//

import Foundation

protocol UrlHandler: AnyObject {
    func handle(_ url: URL)
}
