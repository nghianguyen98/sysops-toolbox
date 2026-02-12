
import SwiftUI

struct SparklineView: View {
    let data: [Double]
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Fill
                Path { path in
                    guard data.count > 1 else { return }
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let maxVal = max(data.max() ?? 100, 50)
                    let stepX = width / CGFloat(data.count - 1)
                    let scaleY = height / CGFloat(maxVal)
                    
                    path.move(to: CGPoint(x: 0, y: height))
                    for (index, value) in data.enumerated() {
                        path.addLine(to: CGPoint(x: CGFloat(index) * stepX, y: height - CGFloat(value) * scaleY))
                    }
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.closeSubpath()
                }
                .fill(LinearGradient(
                    colors: [color.opacity(0.3), color.opacity(0.0)],
                    startPoint: .top,
                    endPoint: .bottom
                ))

                // Line Path
                Path { path in
                    guard data.count > 1 else { return }
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let maxVal = max(data.max() ?? 100, 50)
                    let stepX = width / CGFloat(data.count - 1)
                    let scaleY = height / CGFloat(maxVal)
                    
                    path.move(to: CGPoint(x: 0, y: height - CGFloat(data[0]) * scaleY))
                    for (index, value) in data.enumerated() {
                        path.addLine(to: CGPoint(x: CGFloat(index) * stepX, y: height - CGFloat(value) * scaleY))
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            }
        }
    }
}
