//
//  WidgetBundle.swift
//  Widget
//
//  Created by 徐蔚起 on 03/05/2025.
//

import WidgetKit
import SwiftUI

@main
struct GoldTimeWidgetBundle: WidgetBundle {
    var body: some Widget {
        HourlyWageWidget()
        WidgetControl()
        WidgetLiveActivity()
    }
}
