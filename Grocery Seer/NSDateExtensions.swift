//
//  NSDateExtensions.swift
//  Daily Bread
//
//  Created by James Robert on 4/30/15.
//  Copyright (c) 2015 Jiaaro. All rights reserved.
//

import Foundation

extension NSDate {
    func toString(format:String = "yyyy'-'MM'-'dd'") -> String {
        let df = NSDateFormatter()
        df.dateFormat = format
        
        return df.stringFromDate(self)
    }
}