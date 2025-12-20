//
//  LicenseData.swift
//  PIP_Project
//
//  Created by NEO on 12/20/25.
//

import Foundation

// MARK: - License Model
struct LicenseItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let author: String
    let licenseType: String
    let url: String
}

// MARK: - License Data Store
// Simply add a new item here whenever you use a new Figma asset
struct LicenseData {
    static let items: [LicenseItem] = [
        LicenseItem(
            title: "Crystal Chrome Gems Pack",
            author: "Cristopher Echevarría",
            licenseType: "CC BY 4.0",
            url: "https://www.figma.com/community/file/1387261229967041993"
        ),
        LicenseItem(
            title: "3D Holographic Shapes",
            author: "BRIX Agency",
            licenseType: "CC BY 4.0",
            url: "https://www.figma.com/community/file/1332771130091317068"
        ),
        LicenseItem(
            title: "Gradient shapes",
            author: "lab.03",
            licenseType: "CC BY 4.0",
            url: "https://www.figma.com/community/file/1515021891739358393"
        )
        // Add more items here...
    ]
}
