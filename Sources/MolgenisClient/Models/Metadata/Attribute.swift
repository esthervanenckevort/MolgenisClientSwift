//
//  File.swift
//  
//
//  Created by Esther van Enckevort on 21-02-2020.
//

import Foundation

public final class Attribute: Entity {
    public static var _entityName = "sys_md_Attribute"
    public var _id: String { String(describing: id) }
    public var _label: String { name }
    public let id: String?
    public let name: String
    public let entity: EntityType?
    public let sequenceNr: Int?
    public let type: Type?
    public let isIdAttribute: Bool?
    public let isLabelAttribute: Bool?
    public let lookupAttributeIndex: Int?
    public let parent: Attribute?
    public let children: [Attribute]?
    public let refEntityType: EntityType?
    public let isCascadeDelete: Bool?
    public let mappedBy: Attribute?
    public let orderBy: String?
    public let expression: String?
    public let isNullable: Bool?
    public let isAuto: Bool?
    public let isVisible: Bool?
    public let label: String?
    public let description: String?
    public let isAggregatable: Bool?
    public let enumOptions: String?
    public let rangeMin: Int?
    public let rangeMax: Int?
    public let isReadOnly: Bool?
    public let isUnique: Bool?
    public let tags: [Tag]?
    public let nullableExpression: String?
    public let visibleExpression: String?
    public let validationExpression: String?
    public let defaultValue: String?
    public let labelEn: String?
    public let descriptionEn: String?
    public let labelNl: String?
    public let descriptionNl: String?
    public let labelDe: String?
    public let descriptionDe: String?
    public let labelEs: String?
    public let descriptionEs: String?
    public let labelIt: String?
    public let descriptionIt: String?
    public let labelPt: String?
    public let descriptionPt: String?
    public let labelFr: String?
    public let descriptionFr: String?
    public let labelXx: String?
    public let descriptionXx: String?
}
