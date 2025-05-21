//
//  AppIcon.swift
//  MovieRecommend
//
//  
//

import SwiftUI

struct MySwiftUIView : View {
    let gradientStart = Color(#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1))
    let gradientEnd = Color(#colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1))

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [gradientStart, gradientEnd]), startPoint: .leading, endPoint: .trailing) // Set startPoint to .leading and endPoint to .trailing
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .mask(
                    Rectangle()
                        .fill(LinearGradient(gradient: Gradient(colors: [.clear, .black, .clear]), startPoint: .leading, endPoint: .trailing)) // Set startPoint to .leading and endPoint to .trailing
                        .frame(height: 300) // Adjust the height to control the gradient position
                )
            
            Image("pie-chart")
                .resizable()
                .frame(width: 150, height: 150)
            
            Image("clapperboard")
                .resizable()
                .rotationEffect(.degrees(-5))
                .offset(x: -8, y: 0)
                .frame(width: 120, height: 120)
        }
    }
}

struct MySwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        MySwiftUIView()
            .frame(width: 1024, height: 1024)
    }
}
