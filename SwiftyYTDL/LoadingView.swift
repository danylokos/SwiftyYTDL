//
//  LoadingView.swift
//  SwiftyYTDL
//
//  Created by Danylo Kostyshyn on 23.07.2022.
//

import SwiftUI

struct LoadingView: View {
    
    var body: some View {
        ProgressView {
            Text("Loading...")
        }
        .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
        .padding(20.0)
        .background(.regularMaterial)
        .foregroundColor(.primary)
        .cornerRadius(10.0)
    }
    
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
        LoadingView().preferredColorScheme(.dark)
    }
}
