//
//  MindsetChartView.swift
//  Kaizen OS
//

import SwiftUI

struct MindsetChartView: View {
    let data: [MindsetLog]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Trends")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)

            if data.count >= 2 {
                GeometryReader { geo in
                    let width = geo.size.width
                    let height: CGFloat = 70

                    ZStack {
                        // Energy line
                        TrendLine(
                            values: data.map { Double($0.energy) },
                            color: .kaizenOrange,
                            size: CGSize(width: width, height: height)
                        )
                        // Focus line
                        TrendLine(
                            values: data.map { Double($0.focus) },
                            color: .kaizenTeal,
                            size: CGSize(width: width, height: height)
                        )
                        // Mood line
                        TrendLine(
                            values: data.map { Double($0.mood) },
                            color: .kaizenPurple,
                            size: CGSize(width: width, height: height)
                        )
                    }
                }
                .frame(height: 70)
            } else {
                Text("Log at least 2 days to see trends")
                    .font(.system(size: 12))
                    .foregroundColor(Color.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }

            // Legend
            HStack(spacing: 16) {
                Spacer()
                LegendItem(label: "Energy", color: .kaizenOrange)
                LegendItem(label: "Focus", color: .kaizenTeal)
                LegendItem(label: "Mood", color: .kaizenPurple)
                Spacer()
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.borderDefault, lineWidth: 1)
        )
    }
}

// MARK: - Trend Line

private struct TrendLine: View {
    let values: [Double]
    let color: Color
    let size: CGSize

    var body: some View {
        Path { path in
            guard values.count >= 2 else { return }
            let stepX = size.width / CGFloat(values.count - 1)

            for (index, value) in values.enumerated() {
                let x = CGFloat(index) * stepX
                let y = size.height - (CGFloat(value) / 100.0) * (size.height * 0.875)
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
        .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        .shadow(color: color.opacity(0.4), radius: 4)
    }
}

// MARK: - Legend Item

private struct LegendItem: View {
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 20, height: 3)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Color.textSecondary)
        }
    }
}

#Preview {
    MindsetChartView(data: [])
        .padding(20)
        .background(Color.bgPrimary)
}
