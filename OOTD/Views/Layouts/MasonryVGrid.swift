//
//  MasonryVGrid.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/20.
//
// https://github.com/lukepistrol/MasonryStack/blob/main/Sources/MasonryStack/MasonryVStack.swift

import SwiftUI

public struct MasonryVGrid: Layout {
    private var columns: Int
    private var spacing: Double

    public init(columns: Int = 2, spacing: Double = 8.0) {
        self.columns = columns
        self.spacing = spacing
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        return calculateSize(for: subviews, in: proposal)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        calculateSize(for: subviews, in: proposal, placeInBounds: bounds)
    }

    @discardableResult
    private func calculateSize(
        for subviews: Subviews,
        in proposal: ProposedViewSize,
        placeInBounds bounds: CGRect? = nil
    ) -> CGSize {
        guard let maxWidth = proposal.width else { return .zero }
        let itemWidth = (maxWidth - spacing * Double(columns - 1)) / Double(columns)

        var xIndex = 0
        var columnsHeights: [Double] = Array(repeating: bounds?.minY ?? 0, count: columns)

        for view in subviews {
            let proposed = ProposedViewSize(
                width: itemWidth,
                height: view.sizeThatFits(.unspecified).height
            )

            if let bounds {
                let x = (itemWidth + spacing) * Double(xIndex) + bounds.minX
                view.place(
                    at: .init(x: x, y: columnsHeights[xIndex]),
                    anchor: .topLeading,
                    proposal: proposed
                )
            }

            let height = view.dimensions(in: proposed).height
            columnsHeights[xIndex] += height + spacing
            let minimum = columnsHeights.enumerated().min {
                $0.element < $1.element
            }?.offset ?? 0
            xIndex = minimum
        }

        guard let maxHeight = columnsHeights.max() else { return .zero }

        return .init(
            width: maxWidth,
            height: maxHeight - spacing
        )
    }

    public static var layoutProperties: LayoutProperties {
        var properties = LayoutProperties()
        properties.stackOrientation = .vertical
        return properties
    }
}

#Preview {
    ScrollView {
        MasonryVGrid {
            ForEach(sampleItems, id: \.self) {
                ImageCard(source: $0.imageSource)
            }
        }
    }
}
