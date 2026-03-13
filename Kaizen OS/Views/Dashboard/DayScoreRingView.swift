//
//  DayScoreRingView.swift
//  Kaizen OS
//

import SwiftUI

struct DayScoreRingView: View {
    let percent: Int
    var size: CGFloat = 80
    var strokeWidth: CGFloat = 8
    var color: Color = .kaizenTeal

    private var progress: Double {
        Double(percent) / 100.0
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: strokeWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.6), radius: 6)

            Text("\(percent)%")
                .font(.system(size: size * 0.2, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    DayScoreRingView(percent: 67, size: 90, strokeWidth: 9)
        .background(Color.bgPrimary)
}
