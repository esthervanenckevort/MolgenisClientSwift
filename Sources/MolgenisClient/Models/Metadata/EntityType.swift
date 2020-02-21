//
//  File.swift
//  
//
//  Created by Esther van Enckevort on 21-02-2020.
//

import Foundation

public final class EntityType: Decodable {
    public let id: String
    public let label: String
    public let description: String?
    public let package: Package?
    public let attributes: [Attribute]?
    public let isAbstract: Bool
    public let extends: EntityType?
    public let tags: [Tag]?
    public let backend: Backend
    public let indexingDepth: Int
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
    public let descriptionXx: String?}
