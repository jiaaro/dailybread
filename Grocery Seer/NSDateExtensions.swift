//
//  NSDateExtensions.swift
//  Daily Bread
//
//  Created by James Robert on 4/30/15.
//  Copyright (c) 2015 Jiaaro. All rights reserved.
//

import Foundation

extension Date {
    func toString(format:String = "yyyy'-'MM'-'dd'") -> String {
        let df = DateFormatter()
        df.dateFormat = format
        
        return df.string(from: self)
    }
}
