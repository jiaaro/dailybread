//
//  ranking.swift
//  Grocery Seer
//
//  Created by James Robert on 8/25/14.
//  Copyright (c) 2014 Jiaaro. All rights reserved.
//

import Foundation

func normalize(x: Double, scale_min: Double, scale_max: Double) -> Double {
    return (x - scale_min) / (scale_max - scale_min);
}

// 3 times as long as the avg time between adds is how long the boosted
// likelihood lasts. For a weekly item this means it is boosted for 5 weeks
let RANK_FADE_PERIODS_TO_NOMINAL = 3.0

let FADE_UP_FROM = 0.2
let FADE_TO_MAX = 2.0

func grocery_rank_score(occurrances: [NSDate]) -> Double {
    var score = Double(occurrances.count)
    
    if occurrances.count >= 3 {
        let avg_time_between_adds = occurrances.last!.timeIntervalSinceDate(occurrances.first!) / Double(occurrances.count - 1)
        let time_since_last_add = -occurrances.last!.timeIntervalSinceNow
        
        if (time_since_last_add < avg_time_between_adds) {
            score *= FADE_UP_FROM + ((FADE_TO_MAX - FADE_UP_FROM) * time_since_last_add / avg_time_between_adds)
        }
        else if (time_since_last_add < (avg_time_between_adds * (1 + RANK_FADE_PERIODS_TO_NOMINAL))) {
            score *= 1.0 + (FADE_TO_MAX - 1.0) * normalize(
                avg_time_between_adds / time_since_last_add,
                1/(RANK_FADE_PERIODS_TO_NOMINAL+1), // min
                1.0 // max
            );
        }
    }
    
    return score
}