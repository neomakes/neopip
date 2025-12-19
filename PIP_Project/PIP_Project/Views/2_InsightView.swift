//
//  InsightView.swift
//  PIP_Project
//
//  Created by NEO on 12/19/25.
//

import SwiftUI

struct InsightView: View {
    @Environment(\.modelContext) private var modelContext
    @Query("insights") private var insights: [Insight]

    var body: some View {
        NavigationView {
            List {
                ForEach(insights) { insight in
                    NavigationLink {
                        Text("Insight at \(insight.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(insight.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteInsights)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addInsight) {
                        Label("Add Insight", systemImage: "plus")
                    }
                }
            }
        }
    }

    private func addInsight() {
        withAnimation {
            let newInsight = Insight(timestamp: Date())
            modelContext.insert(newInsight)
        }
    }

    private func deleteInsights(offsets:
