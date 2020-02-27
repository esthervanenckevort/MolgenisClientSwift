import Foundation

public struct AggregateResponse<X: Decodable, Y: Decodable>: Decodable {
    public struct AggregateData<X: Decodable, Y: Decodable>: Decodable {
        public let xLabels: [X]
        public let yLabels: [Y]
        public let matrix: [[Int]]
    }

    public let xAttr: Attribute
    public let yAttr: Attribute?
    public let aggs: AggregateData<X, Y>
}
