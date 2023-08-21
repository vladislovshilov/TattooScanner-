//
//  SwiftUIHostingController.swift
//  TattooScaner
//
//  Created by macbook pro max on 21/08/2023.
//

import SwiftUI

class SwiftUIViewController<Content>: UIHostingController<Content> where Content: View {
    init(@ViewBuilder rootView: () -> Content) {
        super.init(rootView: rootView())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
