//
//  FormErrors.swift
//  App
//
//  Created by Gawish on 14/07/2020.
//

import Vapor

extension String {
    func urlEndcoded() -> String {
           return self
               .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?
               .replacingOccurrences(of: ", ", with: ",,")
               ?? self
       }
}
